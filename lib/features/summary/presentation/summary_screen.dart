import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../data/db/daos.dart' show CategorySpendRow;
import '../../../domain/entities.dart';
import '../../calendar/application/calendar_providers.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (year, month) = ref.watch(currentMonthProvider);
    final summary = ref.watch(monthSummaryProvider((year, month))).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final spending =
        ref.watch(monthSpendingProvider((year, month))).valueOrNull ??
            const <CategorySpendRow>[];
    final isEmpty = summary.income == 0 && summary.expense == 0;

    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('summary-prev'),
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(currentMonthProvider.notifier).prev(),
              ),
              Expanded(
                child: Text('$year年$month月',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                key: const Key('summary-next'),
                icon: const Icon(Icons.chevron_right),
                onPressed: () => ref.read(currentMonthProvider.notifier).next(),
              ),
            ],
          ),
          if (isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('この月のデータはまだありません'),
                    const SizedBox(height: 4),
                    Text('カレンダーの＋から入力できます', // spec §5.5 空サマリの入力導線
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _totalRow(context, '収入', '+${formatYen(summary.income)}'),
                          _totalRow(context, '支出', '-${formatYen(summary.expense)}'),
                          const Divider(),
                          _totalRow(
                            context,
                            '差引',
                            summary.net >= 0
                                ? '+${formatYen(summary.net)}'
                                : formatYen(summary.net),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('カテゴリ別支出',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final row in spending)
                    _SpendRow(row: row, grandTotal: summary.expense),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, String value,
          {bool emphasize = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value,
                style: emphasize
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}

class _SpendRow extends StatelessWidget {
  final CategorySpendRow row;
  final int grandTotal;
  const _SpendRow({required this.row, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    final ratio = grandTotal == 0 ? 0.0 : row.total / grandTotal;
    final name =
        row.isArchived ? '${row.categoryName}（アーカイブ）' : row.categoryName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              Text(formatYen(row.total)),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text('${(ratio * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: ratio, minHeight: 6),
        ],
      ),
    );
  }
}
