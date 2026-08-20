import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/navigation.dart';
import '../../chores/application/chore_providers.dart';
import '../../chores/presentation/chore_day_section.dart';
import '../../entry/application/entry_form_controller.dart';
import '../application/calendar_providers.dart';
import 'backup_banner.dart';
import 'day_transaction_list.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final (year, month) = ref.watch(currentMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    // 上部サマリは「今日までの実績」（FB 2026-08-21）。月全体・月末見込みとは
    // 役割分担: 未来分はセルと見込み収支が受け持つ。
    final summary =
        ref.watch(monthToDateSummaryProvider((year, month))).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final totals =
        ref.watch(dayExpenseTotalsProvider((year, month))).valueOrNull ??
        const <CivilDate, int>{};
    final incomes =
        ref.watch(dayIncomeTotalsProvider((year, month))).valueOrNull ??
        const <CivilDate, int>{};
    final ghosts = ref.watch(dayGhostTotalsProvider((year, month)));
    final choreMarks = ref.watch(choreMonthMarksProvider((year, month)));
    final mf = ref.watch(moneyFormatterProvider);

    return SafeArea(
      child: Column(
        children: [
          const BackupBanner(),
          _MonthHeader(year: year, month: month),
          _SummaryCard(year: year, month: month, summary: summary),
          // 紙デザイン（2026-08-20 モック）: ベース背景（紙）の上に、日セルは
          // 白の角丸カードを敷き詰め（週罫線は廃止）、日別リストは日付タブ付き
          // の白カードとして独立させる。旧「下半分を白いMaterial面」構成は撤去。
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LayoutBuilder(builder: (context, box) {
              // セルは正方形・比率1（FB 2026-08-20）: 行高＝セル幅（幅/7）。
              // マージン(_kCellMargin)は四辺同値なので白カード自体も正方形になる。
              final cellSize = box.maxWidth / 7;
              return TableCalendar<int>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: dateTimeOfCivil(CivilDate(year, month, 1)),
            headerVisible: false,
            rowHeight: cellSize,
            // 前後月のはみ出しマスも空の白カードで埋める（モック2枚目）。
            calendarStyle: const CalendarStyle(outsideDaysVisible: true),
            // 曜日ヘッダは日本語（日月火水木金土）。日曜=薄赤 / 土曜=薄青。
            daysOfWeekHeight: 20,
            selectedDayPredicate: (d) => civilOfDateTime(d) == selected,
            onDaySelected: (sel, _) => ref
                .read(selectedDayProvider.notifier)
                .select(civilOfDateTime(sel)),
            onPageChanged: (focused) => ref
                .read(currentMonthProvider.notifier)
                .set(focused.year, focused.month),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final (label, color) = _dowLabelColor(day.weekday, l);
                return Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                );
              },
              // 数字を上・金額を下に分離（選択/今日の丸は数字だけを囲む小さめの丸）。
              defaultBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.normal, totals, incomes, ghosts, choreMarks, mf),
              todayBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.today, totals, incomes, ghosts, choreMarks, mf),
              selectedBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.selected, totals, incomes, ghosts, choreMarks, mf),
              outsideBuilder: (context, day, _) => Container(
                margin: _kCellMargin,
                decoration: _kCellDeco,
              ),
            ),
              );
            }),
          ),
          // 凡例は家事ドットの分だけ。固定費の予定（ゴースト）はルールがある限り
          // 毎月出るため凡例が常時表示になっていた（「ずっと出てる」FB 2026-08-16）。
          // 意味は日別リストの「予定」バッジで伝わるので凡例からは外した。
          if (choreMarks.isNotEmpty)
            _CalendarLegend(hasChores: choreMarks.isNotEmpty),
          Expanded(child: _DaySection(day: selected)),
        ],
      ),
    );
  }
}

/// 日別リストのカード（画像1枚目参考・フラット近似）:
/// 選択日タブと「つきいち」タブ（FB 2026-08-20）で内容を切り替え、
/// 右端の「家計簿を入力」から選択日既定で入力画面へ。
class _DaySection extends ConsumerStatefulWidget {
  final CivilDate day;
  const _DaySection({required this.day});

  @override
  ConsumerState<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends ConsumerState<_DaySection> {
  /// つきいちタブ表示中か（日を切り替えても維持）。
  bool _chores = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat.MMMEd(tag).format(dateTimeOfCivil(widget.day));
    final fill = context.kakeiboPalette.fill;

    Widget tab({
      required Key key,
      required String text,
      required bool selected,
      required VoidCallback onTap,
    }) =>
        InkWell(
          key: key,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? fill : context.kakeiboPalette.soft,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : kMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ボタンのラベルは切らず、幅が足りないときはタブ側だけ縮む
              //（Flexibleの均等割り上限で日本語まで省略される罠の回避）。
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: tab(
                        key: const Key('day-tab-label'),
                        text: label,
                        selected: !_chores,
                        onTap: () => setState(() => _chores = false),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: tab(
                        key: const Key('day-tab-chores'),
                        text: l.calendarChoreTab,
                        selected: _chores,
                        onTap: () => setState(() => _chores = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 旧FABの後継。「＋だけでは分かりづらい」FBでラベル付きに。
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: FilledButton.icon(
                  key: const Key('fab-entry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: fill,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l.homeFabEntryLabel,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () {
                    ref
                        .read(entryFormControllerProvider.notifier)
                        .startCreate(widget.day);
                    ref
                        .read(homeTabIndexProvider.notifier)
                        .set(kInputTabIndex);
                  },
                ),
              ),
            ],
          ),
          Expanded(
            // Material にして白カード自体をインク波紋の面にする（旧構成と同じ理由）。
            child: Material(
              color: kCard,
              clipBehavior: Clip.antiAlias,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                side: BorderSide(color: kLine, width: 0.8),
              ),
              child: SizedBox(
                width: double.infinity,
                child: _chores
                    ? _ChoreDayList(day: widget.day)
                    : DayTransactionList(day: widget.day),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「つきいち」タブの中身: その日の実施記録・期日行（やったボタン付き）。
/// 行の実装は日別リストに埋まっていた buildChoreDayRows をそのまま使う。
class _ChoreDayList extends ConsumerWidget {
  final CivilDate day;
  const _ChoreDayList({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = buildChoreDayRows(context, ref, day);
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.calendarChoreTabEmpty,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(children: rows);
  }
}

/// 家事ドットの凡例（該当があるときだけ表示）。
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.hasChores});

  final bool hasChores;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget item(Color color, String label, {bool outlined = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: outlined ? null : color,
                border: outlined ? Border.all(color: color, width: 1.2) : null,
              ),
            ),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: muted)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Wrap(
        spacing: 12,
        children: [
          if (hasChores) ...[
            item(_kDotDue, l.calendarLegendChoreDue),
            item(_kDotOverdue, l.calendarLegendChoreOverdue),
            item(_kDotDone, l.calendarLegendChoreDone),
          ],
        ],
      ),
    );
  }
}

/// 曜日ヘッダの日本語ラベルと色（日曜=薄赤 / 土曜=薄青 / 平日=既定）。
(String, Color?) _dowLabelColor(int weekday, AppLocalizations l) =>
    switch (weekday) {
      DateTime.sunday => (l.calendarWeekdaySun, kSunday),
      DateTime.monday => (l.calendarWeekdayMon, null),
      DateTime.tuesday => (l.calendarWeekdayTue, null),
      DateTime.wednesday => (l.calendarWeekdayWed, null),
      DateTime.thursday => (l.calendarWeekdayThu, null),
      DateTime.friday => (l.calendarWeekdayFri, null),
      _ => (l.calendarWeekdaySat, kSaturday),
    };

enum _DayStyle { normal, selected, today }

/// 日セルの白カード（画像2枚目参考: 罫線ではなく角丸カードを敷き詰める）。
const _kCellMargin = EdgeInsets.all(1.5);
const _kCellDeco = BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.all(Radius.circular(9)),
  boxShadow: [
    BoxShadow(color: Color(0x0D2F3A3D), blurRadius: 3, offset: Offset(0, 1)),
  ],
);

// 家事ドットの色（やった=収入グリーン / 期日=注意アンバー / 超過=支出コーラル）。
const _kDotDone = kIncome;
const _kDotDue = kAttention;
const _kDotOverdue = kExpense;

/// カレンダーの1日セル。数字→家事ドット→支出額→予定額（グレー）の縦積み。
Widget _dayCell(
  BuildContext context,
  DateTime day,
  _DayStyle style,
  Map<CivilDate, int> totals,
  Map<CivilDate, int> incomes,
  Map<CivilDate, int> ghosts,
  Map<CivilDate, ChoreDayMarks> choreMarks,
  MoneyFormatter mf,
) {
  final civil = civilOfDateTime(day);
  final total = totals[civil] ?? 0;
  final income = incomes[civil] ?? 0;
  final ghost = ghosts[civil] ?? 0;
  final marks = choreMarks[civil];
  BoxDecoration? deco;
  var numColor = kInk;
  var weight = FontWeight.w400;
  // 選択/今日のリング色（数字に被らないよう小さめの丸で数字だけを囲む）。
  // 選択=主色塗り＋白数字、今日=主色の輪郭。カスタムテーマに追従させるため
  // 定数ではなくパレットから取る。
  final ring = context.kakeiboPalette.fill;
  switch (style) {
    case _DayStyle.selected:
      deco = BoxDecoration(color: ring, shape: BoxShape.circle);
      numColor = Colors.white;
      weight = FontWeight.w600;
    case _DayStyle.today:
      deco = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 1.6),
      );
      weight = FontWeight.w700;
    case _DayStyle.normal:
      break;
  }
  final iso = civil.toIso();
  // 縦の予算はセル幅-マージン3（SE級の375px幅で約48）。
  // 日付2+20 + ドット4 + 実績額11 + 予定額11 = 48 に収める。
  return Container(
    margin: _kCellMargin,
    decoration: _kCellDeco,
    // alignment を指定して白カードをセル一杯に広げる（無指定だと中身の
    // 高さに縮んで正方形にならない）。
    alignment: Alignment.topCenter,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 日付はセルの左上・金額は右揃え（FB 2026-08-20）
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 3, top: 2),
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: deco,
              child: Text(
                '${day.day}',
                style: TextStyle(
                    fontSize: 11, color: numColor, fontWeight: weight),
              ),
            ),
          ),
        ),
        if (marks != null)
          SizedBox(
            height: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (marks.doneTaskIds.isNotEmpty)
                  _dot(_kDotDone, Key('chore-dot-done-$iso')),
                if (marks.dueTaskIds.isNotEmpty)
                  _dot(
                    marks.hasOverdue ? _kDotOverdue : _kDotDue,
                    Key(marks.hasOverdue
                        ? 'chore-dot-overdue-$iso'
                        : 'chore-dot-due-$iso'),
                  ),
              ],
            ),
          ),
        // 金額レーン: 支出（−赤）→ 収入（+緑）→ 予定（グレー）の優先順で
        // 最大2行（正方形セルの縦予算のため。3つ重なる日は予定を省く）。
        ...[
          if (total > 0)
            _cellAmount('-${mf.compact(total)}',
                context.kakeiboColors.expense),
          if (income > 0)
            _cellAmount('+${mf.compact(income)}',
                context.kakeiboColors.income),
          // まだ起票されていない固定費・収入（予定）。グレーで実績と区別する。
          if (ghost != 0)
            _cellAmount(mf.compact(ghost.abs()), kMuted,
                key: Key('ghost-amount-$iso')),
        ].take(2),
      ],
    ),
  );
}

/// セル内の金額1行（右揃え・9pt）。
Widget _cellAmount(String text, Color color, {Key? key}) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Text(
          text,
          key: key,
          style: TextStyle(
            fontSize: 9,
            height: 1.15,
            fontFeatures: kTabularFigures,
            color: color,
          ),
        ),
      ),
    );

Widget _dot(Color color, Key key) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        key: key,
        width: 4,
        height: 4,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );

class _MonthHeader extends ConsumerWidget {
  final int year;
  final int month;
  const _MonthHeader({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('prev-month'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(currentMonthProvider.notifier).prev(),
          ),
          Expanded(
            child: Center(
              child: Text(
                l.calendarMonthYearHeader(year, month),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontFamily: kLedgerFontFamily),
              ),
            ),
          ),
          IconButton(
            key: const Key('next-month'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(currentMonthProvider.notifier).next(),
          ),
        ],
      ),
    );
  }
}

/// 月サマリのカード（画像1枚目参考・フラット近似）:
/// 支出/収入/差引の3カラム＋見込み収支の行。見込み収支のタップで
/// 基準日（月末/毎月N日）を変更できるのは従来のまま。
class _SummaryCard extends ConsumerWidget {
  final int year;
  final int month;
  final MonthlySummary summary;
  const _SummaryCard({
    required this.year,
    required this.month,
    required this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final net = summary.net;
    final netLabel = net >= 0 ? '+${mf.format(net)}' : mf.format(net);
    final forecast = ref.watch(monthForecastProvider((year, month)));
    final colors = context.kakeiboColors;

    Widget col(String label, String value, Color valueColor) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kMuted, fontFamily: kLedgerFontFamily)),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  fontFamily: kLedgerFontFamily,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
        );

    Widget vLine() => Container(width: 0.6, height: 40, color: kLine);

    return Container(
      key: const Key('month-summary-card'),
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            // 縦幅は広めに（「金額の場所が狭い」FB 2026-08-20）。
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                col(l.summaryExpenseLabel, mf.format(summary.expense),
                    colors.expense),
                vLine(),
                col(l.summaryIncomeLabel, mf.format(summary.income),
                    colors.income),
                vLine(),
                col(
                    l.summaryNetLabel,
                    netLabel,
                    net < 0
                        ? colors.expense
                        : Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          // 見込み収支 = 月全体の起票済み差引＋月末までの未起票予定。過去月は出ない。
          // （上の差引=今日まで実績とは定義が違う: 分割払いの将来回はこちらに入る）
          // 基準日（毎月N日）切り替えは「不要」FB（2026-08-20）で撤去し常に月末。
          if (forecast != null) ...[
            const Divider(height: 1, color: kLine),
            Padding(
              key: const Key('forecast-line'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.forecastLabelMonthEnd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: kLedgerFontFamily),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    forecast.forecast >= 0
                        ? '+${mf.format(forecast.forecast)}'
                        : mf.format(forecast.forecast),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: kLedgerFontFamily,
                      fontFeatures: kTabularFigures,
                      color: forecast.forecast < 0
                          ? colors.expense
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}
