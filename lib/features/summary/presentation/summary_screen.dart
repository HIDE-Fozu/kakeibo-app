import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/theme.dart';
import '../../../core/money.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/spending_rollup.dart';
import '../../../l10n/app_localizations.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/summary_providers.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final (year, month) = ref.watch(currentMonthProvider);
    final summary = ref.watch(monthSummaryProvider((year, month))).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final groups =
        ref.watch(monthSpendingRollupProvider((year, month))).valueOrNull ??
            const <CategorySpendGroup>[];
    final isEmpty = summary.income == 0 && summary.expense == 0;
    final mf = ref.watch(moneyFormatterProvider);

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
                child: Text(l.summaryMonthHeader(year, month),
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
                    Text(l.summaryEmptyTitle),
                    const SizedBox(height: 4),
                    Text(l.summaryEmptyHint, // spec §5.5 空サマリの入力導線
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
                          _totalRow(context, l.summaryIncomeLabel, mf.net(summary.income),
                              color: context.kakeiboColors.income),
                          _totalRow(context, l.summaryExpenseLabel, summary.expense > 0
                                  ? '-${mf.format(summary.expense)}'
                                  : mf.format(summary.expense),
                              color: context.kakeiboColors.expense),
                          const Divider(),
                          _totalRow(
                            context,
                            l.summaryNetLabel,
                            mf.net(summary.net),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l.summaryCategoryBreakdownTitle,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final g in groups)
                    _GroupRow(group: g, grandTotal: summary.expense, mf: mf),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, String value,
          {bool emphasize = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value,
                style: (emphasize
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyLarge)
                    ?.copyWith(color: color, fontFeatures: kTabularFigures)),
          ],
        ),
      );
}

class _GroupRow extends StatefulWidget {
  final CategorySpendGroup group;
  final int grandTotal;
  final MoneyFormatter mf;
  const _GroupRow(
      {required this.group, required this.grandTotal, required this.mf});

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow> {
  var _expanded = false; // 複数同時展開可（モックのまま）

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final g = widget.group;
    final ratio = widget.grandTotal == 0 ? 0.0 : g.total / widget.grandTotal;
    final name = g.isArchived ? l.summaryArchivedSuffix(g.name) : g.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              Text(widget.mf.format(g.total),
                  style: const TextStyle(fontFeatures: kTabularFigures)),
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
          if (g.hasSubs)
            _StackedBar(group: g, widthFactor: ratio)
          else
            LinearProgressIndicator(value: ratio, minHeight: 6),
          if (g.hasSubs)
            InkWell(
              key: Key('expand-${g.categoryId}'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                    _expanded ? l.summaryBreakdownCollapse : l.summaryBreakdownExpand,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          if (_expanded)
            for (final (name, amount) in _expandedEntries(g))
              _subRow(context, name, amount, g.total),
        ],
      ),
    );
  }

  /// 内訳と直接分（（内訳なし））を同列・金額降順で並べる（モック準拠）。
  List<(String, int)> _expandedEntries(CategorySpendGroup g) {
    final l = AppLocalizations.of(context);
    return <(String, int)>[
      for (final s in g.subs)
        (s.isArchived ? l.summaryArchivedSuffix(s.name) : s.name, s.total),
      if (g.directTotal > 0) (l.summaryNoBreakdownLabel, g.directTotal),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  Widget _subRow(BuildContext context, String name, int amount, int parentTotal) {
    final pct = parentTotal == 0 ? 0 : (amount * 100 / parentTotal).round();
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      child: Row(
        children: [
          Expanded(
              child: Text(name, style: small, overflow: TextOverflow.ellipsis)),
          Text(widget.mf.format(amount),
              style: small?.copyWith(fontFeatures: kTabularFigures)),
          SizedBox(
            width: 40,
            child: Text('$pct%', textAlign: TextAlign.right, style: small),
          ),
        ],
      ),
    );
  }
}

/// 深緑濃淡の積み上げバー。全体幅=月支出に対する比率、区間=内訳比率。
/// 区間は（内訳なし）も含め金額降順、色は降順位置で割当（モック準拠）。
class _StackedBar extends StatelessWidget {
  final CategorySpendGroup group;
  final double widthFactor;
  const _StackedBar({required this.group, required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    if (group.total == 0) return const SizedBox(height: 6);
    final amounts = <int>[
      for (final s in group.subs) s.total,
      if (group.directTotal > 0) group.directTotal,
    ]..sort((a, b) => b.compareTo(a));
    final segments = <(int, Color)>[
      for (final (i, a) in amounts.indexed) (a, kSubScale[i % kSubScale.length]),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor.clamp(0.0, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                for (final (amount, color) in segments)
                  if (amount > 0)
                    Expanded(flex: amount, child: ColoredBox(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
