import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/cell_dropdown.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/navigation.dart';
import '../../chores/application/chore_providers.dart';
import '../../chores/presentation/chore_ui_common.dart';
import '../../entry/application/entry_form_controller.dart';
import '../../settings/application/settings_controller.dart';
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
    final summary =
        ref.watch(monthSummaryProvider((year, month))).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final totals =
        ref.watch(dayExpenseTotalsProvider((year, month))).valueOrNull ??
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
              defaultBuilder: (context, day, _) => _dayCell(
                  context, day, _DayStyle.normal, totals, ghosts, choreMarks, mf),
              todayBuilder: (context, day, _) => _dayCell(
                  context, day, _DayStyle.today, totals, ghosts, choreMarks, mf),
              selectedBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.selected, totals, ghosts, choreMarks, mf),
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
/// 選択日のタブラベル（主色の塗り）＋白カードにリストを載せる。
class _DaySection extends ConsumerWidget {
  final CivilDate day;
  const _DaySection({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat.MMMEd(tag).format(dateTimeOfCivil(day));
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                key: const Key('day-tab-label'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: context.kakeiboPalette.fill,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              // 旧FABの後継:「＋」で選択日を既定に入力画面へ。キーと文言を
              // 引き継ぎ、既存の導線・テストと互換（FABはカードを塞ぐため廃止）。
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: IconButton(
                  key: const Key('fab-entry'),
                  tooltip: l.homeFabEntryLabel,
                  style: IconButton.styleFrom(
                    backgroundColor: context.kakeiboPalette.fill,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add, size: 22),
                  onPressed: () {
                    ref
                        .read(entryFormControllerProvider.notifier)
                        .startCreate(day);
                    ref.read(homeTabIndexProvider.notifier).set(kInputTabIndex);
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
                child: DayTransactionList(day: day),
              ),
            ),
          ),
        ],
      ),
    );
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
  Map<CivilDate, int> ghosts,
  Map<CivilDate, ChoreDayMarks> choreMarks,
  MoneyFormatter mf,
) {
  final civil = civilOfDateTime(day);
  final total = totals[civil] ?? 0;
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
        // 日付はセルの左上（FB 2026-08-20・モック2枚目の配置）
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
        if (total > 0)
          Text(
            mf.compact(total),
            style: TextStyle(
              fontSize: 9,
              height: 1.15,
              fontFeatures: kTabularFigures,
              color: context.kakeiboColors.expense,
            ),
          ),
        // まだ起票されていない固定費・収入（予定）。グレーで実績と区別する。
        if (ghost != 0)
          Text(
            mf.compact(ghost.abs()),
            key: Key('ghost-amount-$iso'),
            style: const TextStyle(
              fontSize: 9,
              height: 1.15,
              fontFeatures: kTabularFigures,
              color: kMuted,
            ),
          ),
      ],
    ),
  );
}

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
                style: Theme.of(context).textTheme.titleMedium,
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: kMuted)),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
        );

    Widget vLine() => Container(width: 0.6, height: 30, color: kLine);

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
            padding: const EdgeInsets.symmetric(vertical: 8),
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
          // 見込み収支（実績差引 + 基準日までの固定費予定）。過去月は出ない。
          if (forecast != null) ...[
            const Divider(height: 1, color: kLine),
            InkWell(
              key: const Key('forecast-line'),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              onTap: () => _showAnchorSheet(context, ref),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        forecast.anchorIsMonthEnd
                            ? l.forecastLabelMonthEnd
                            : l.forecastLabelAtDate(
                                choreShortDate(context, forecast.anchor)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${forecast.forecast >= 0 ? '+${mf.format(forecast.forecast)}' : mf.format(forecast.forecast)} ▾',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: kTabularFigures,
                        color: forecast.forecast < 0
                            ? colors.expense
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 基準日の選択シート（月末 / 毎月N日）。ルール別ではなくアプリ設定。
  Future<void> _showAnchorSheet(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final current = ref.read(appSettingsProvider).forecastAnchorDay;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var day = current == 0 ? 25 : current; // 日指定へ切り替えた時の初期値
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.forecastAnchorSheetTitle,
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(l.forecastAnchorSheetNote,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  ListTile(
                    key: const Key('forecast-anchor-monthend'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.forecastAnchorMonthEnd),
                    trailing: current == 0
                        ? Icon(Icons.check,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, 0),
                  ),
                  ListTile(
                    key: const Key('forecast-anchor-day'),
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        // 白ピル＋セル幅・直下展開のメニュー（cell_dropdown）。
                        Builder(builder: (pillContext) {
                          final scheme = Theme.of(pillContext).colorScheme;
                          return InkWell(
                            key: const Key('forecast-anchor-day-dropdown'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final picked = await showCellDropdown<int>(
                                pillContext,
                                centerItems: true,
                                value: day,
                                items: [
                                  for (var d = 1; d <= 31; d++)
                                    CellDropdownItem(d, l.dayOfMonthItem(d)),
                                ],
                              );
                              if (picked != null) {
                                setSheetState(() => day = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                border:
                                    Border.all(color: scheme.outlineVariant),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.recurringEveryMonthDay(day)),
                                  Icon(Icons.arrow_drop_down,
                                      size: 20, color: scheme.primary),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    trailing: current != 0
                        ? Icon(Icons.check,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, day),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    await ref.read(appSettingsProvider.notifier).setForecastAnchorDay(picked);
  }
}
