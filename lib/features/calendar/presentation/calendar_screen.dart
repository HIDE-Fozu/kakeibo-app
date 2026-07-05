import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../application/calendar_providers.dart';
import 'backup_banner.dart';
import 'day_transaction_list.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (year, month) = ref.watch(currentMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final summary = ref.watch(monthSummaryProvider((year, month))).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final totals =
        ref.watch(dayExpenseTotalsProvider((year, month))).valueOrNull ??
            const <CivilDate, int>{};

    return SafeArea(
      child: Column(
        children: [
          const BackupBanner(),
          _MonthHeader(year: year, month: month, summary: summary),
          TableCalendar<int>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: dateTimeOfCivil(CivilDate(year, month, 1)),
            headerVisible: false,
            rowHeight: 58,
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
                final (label, color) = _dowLabelColor(day.weekday);
                return Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                );
              },
              // 数字を上・金額を下に分離（選択/今日の丸は数字だけを囲む小さめの丸）。
              defaultBuilder: (context, day, _) =>
                  _dayCell(context, day, _DayStyle.normal, totals),
              todayBuilder: (context, day, _) =>
                  _dayCell(context, day, _DayStyle.today, totals),
              selectedBuilder: (context, day, _) =>
                  _dayCell(context, day, _DayStyle.selected, totals),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: DayTransactionList(day: selected)),
        ],
      ),
    );
  }
}

/// 曜日ヘッダの日本語ラベルと色（日曜=薄赤 / 土曜=薄青 / 平日=既定）。
(String, Color?) _dowLabelColor(int weekday) => switch (weekday) {
      DateTime.sunday => ('日', kSunday),
      DateTime.monday => ('月', null),
      DateTime.tuesday => ('火', null),
      DateTime.wednesday => ('水', null),
      DateTime.thursday => ('木', null),
      DateTime.friday => ('金', null),
      _ => ('土', kSaturday),
    };

enum _DayStyle { normal, selected, today }

// 選択/今日のリング色（数字に被らないよう小さめの丸で数字だけを囲む）。
const _kSelectedRing = Color(0xFF5C6BC0);
const _kTodayRing = Color(0xFF9FA8DA);

/// カレンダーの1日セル。数字を上・支出額を下に分離して被りを解消する。
Widget _dayCell(
  BuildContext context,
  DateTime day,
  _DayStyle style,
  Map<CivilDate, int> totals,
) {
  final total = totals[civilOfDateTime(day)] ?? 0;
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
  return Align(
    alignment: Alignment.topCenter,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
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
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              manYen(total),
              style: TextStyle(
                fontSize: 10,
                fontFeatures: kTabularFigures,
                color: context.kakeiboColors.expense,
              ),
            ),
          ),
      ],
    ),
  );
}

class _MonthHeader extends ConsumerWidget {
  final int year;
  final int month;
  final MonthlySummary summary;
  const _MonthHeader(
      {required this.year, required this.month, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = summary.net;
    final netLabel = net >= 0 ? '+${formatYen(net)}' : formatYen(net);
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
                Text('$year年$month月',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '支出 ${formatYen(summary.expense)}　収入 ${formatYen(summary.income)}　差引 $netLabel',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFeatures: kTabularFigures),
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
}
