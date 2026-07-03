import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

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
            rowHeight: 56,
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            selectedDayPredicate: (d) => civilOfDateTime(d) == selected,
            onDaySelected: (sel, _) => ref
                .read(selectedDayProvider.notifier)
                .select(civilOfDateTime(sel)),
            onPageChanged: (focused) => ref
                .read(currentMonthProvider.notifier)
                .set(focused.year, focused.month),
            eventLoader: (d) {
              final t = totals[civilOfDateTime(d)] ?? 0;
              return t > 0 ? [t] : const [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 2,
                  child: Text(
                    compactYen(events.first),
                    style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.error),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: DayTransactionList(day: selected)),
        ],
      ),
    );
  }
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
                  style: Theme.of(context).textTheme.bodySmall,
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
