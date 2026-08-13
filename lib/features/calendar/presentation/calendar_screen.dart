import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/cell_dropdown.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../chores/application/chore_providers.dart';
import '../../chores/presentation/chore_ui_common.dart';
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
          _MonthHeader(year: year, month: month, summary: summary),
          // ヘッダ（バックアップ帯＋月サマリ）はベース背景のまま、
          // カレンダー本体と記録一覧だけ白のカードにする（2026-08-13のFB）。
          // Container(color:) だと ListTile のインク波紋が隠れる（Flutterの警告）。
          // Material にして「白い面」自体を Material ancestor にする。
          Expanded(
            child: Material(
              color: kCard,
              child: Column(
                children: [
          TableCalendar<int>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: dateTimeOfCivil(CivilDate(year, month, 1)),
            headerVisible: false,
            // 62 = 数字26 + 家事ドット6 + 実績額13 + 予定額13 + 余白
            //（v2.2.0で家事ドットと予定額のレーンが増えたため58→62）。
            rowHeight: 62,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              // 週ごとの罫線（週の間に横線）＋ヘッダ下の区切り線。
              tableBorder: TableBorder(
                top: BorderSide(color: kLine, width: 0.6),
                horizontalInside: BorderSide(color: kLine, width: 0.6),
              ),
            ),
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
            ),
          ),
          if (choreMarks.isNotEmpty || ghosts.isNotEmpty)
            _CalendarLegend(
                hasChores: choreMarks.isNotEmpty, hasGhosts: ghosts.isNotEmpty),
          const Divider(height: 1),
          Expanded(child: DayTransactionList(day: selected)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 家事ドット・予定額の凡例（該当があるときだけ表示）。
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.hasChores, required this.hasGhosts});

  final bool hasChores;
  final bool hasGhosts;

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
          if (hasGhosts) item(kMuted, l.calendarLegendGhost, outlined: true),
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

// 選択/今日のリング色（数字に被らないよう小さめの丸で数字だけを囲む）。
const _kSelectedRing = Color(0xFF5C6BC0);
const _kTodayRing = Color(0xFF9FA8DA);

// 家事ドットの色（やった=緑 / 期日=橙 / 超過=赤。routine-reminder踏襲）。
const _kDotDone = Color(0xFF43A047);
const _kDotDue = Color(0xFFFB8C00);
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
  switch (style) {
    case _DayStyle.selected:
      deco = const BoxDecoration(color: _kSelectedRing, shape: BoxShape.circle);
      numColor = Colors.white;
      weight = FontWeight.w600;
    case _DayStyle.today:
      deco = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kTodayRing, width: 1.6),
      );
      weight = FontWeight.w700;
    case _DayStyle.normal:
      break;
  }
  final iso = civil.toIso();
  return Align(
    alignment: Alignment.topCenter,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: deco,
          child: Text(
            '${day.day}',
            style: TextStyle(fontSize: 13, color: numColor, fontWeight: weight),
          ),
        ),
        if (marks != null)
          SizedBox(
            height: 6,
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
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              mf.compact(total),
              style: TextStyle(
                fontSize: 10,
                fontFeatures: kTabularFigures,
                color: context.kakeiboColors.expense,
              ),
            ),
          ),
        // まだ起票されていない固定費・収入（予定）。グレーで実績と区別する。
        if (ghost != 0)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              mf.compact(ghost.abs()),
              key: Key('ghost-amount-$iso'),
              style: const TextStyle(
                fontSize: 10,
                fontFeatures: kTabularFigures,
                color: kMuted,
              ),
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
        width: 5,
        height: 5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );

class _MonthHeader extends ConsumerWidget {
  final int year;
  final int month;
  final MonthlySummary summary;
  const _MonthHeader({
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
            child: Column(
              children: [
                Text(
                  l.calendarMonthYearHeader(year, month),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l.calendarMonthSummary(
                    mf.format(summary.expense),
                    mf.format(summary.income),
                    netLabel,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFeatures: kTabularFigures,
                  ),
                ),
                // 見込み収支（実績差引 + 基準日までの固定費予定）。過去月は出ない。
                // タップで基準日（月末/毎月N日）を変更できる。
                if (forecast != null)
                  InkWell(
                    key: const Key('forecast-line'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showAnchorSheet(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      child: Text(
                        '${forecast.anchorIsMonthEnd ? l.forecastLabelMonthEnd : l.forecastLabelAtDate(choreShortDate(context, forecast.anchor))}'
                        '　${forecast.forecast >= 0 ? '+${mf.format(forecast.forecast)}' : mf.format(forecast.forecast)} ▾',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              fontFeatures: kTabularFigures,
                              fontWeight: FontWeight.w600,
                              color: forecast.forecast < 0
                                  ? context.kakeiboColors.expense
                                  : Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
              ],
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
