import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../application/entry_form_controller.dart';

/// 詳細入力（分割）パネル。
/// 行をタップでアクティブ化→テンキー（＋−×÷付き）とカテゴリグリッドが
/// その行に入る。末尾の空行は自動的に「残り」を担う。
class SplitEntryPanel extends ConsumerWidget {
  final EntryFormState state;

  /// id→カテゴリ名（親・内訳とも）。行のカテゴリ表示に使う。
  final Map<int, String> categoryNames;

  const SplitEntryPanel({
    super.key,
    required this.state,
    required this.categoryNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.call_split, size: 16, color: scheme.outline),
            const SizedBox(width: 4),
            Text('詳細入力（合計 ${formatYen(state.amountYen)}）',
                style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            TextButton(
              key: const Key('cancel-split'),
              onPressed: ctrl.cancelSplit,
              child: const Text('やめる'),
            ),
          ],
        ),
        for (var i = 0; i < lines.length; i++) _line(context, ref, i),
        if (state.splitRemainder < 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '合計を ${formatYen(-state.splitRemainder)} 超えています',
              key: const Key('split-over'),
              style: TextStyle(color: scheme.error),
            ),
          ),
      ],
    );
  }

  Widget _line(BuildContext context, WidgetRef ref, int i) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final line = lines[i];
    final scheme = Theme.of(context).colorScheme;
    final active = i == state.activeSplitIndex;
    final catName =
        line.categoryId == null ? null : categoryNames[line.categoryId];

    // 金額表示: 空の式は末尾行のみ「残り」を担う
    final amount = state.splitLineAmount(i);
    final String amountLabel;
    if (line.expr.isEmpty) {
      amountLabel = amount != null ? '残り ${formatYen(amount)}' : '¥ —';
    } else {
      final hasOp = RegExp(r'[+\-×÷]').hasMatch(line.expr);
      final tail = amount == null ? ' = ?' : ' = ${formatYen(amount)}';
      amountLabel =
          (hasOp || line.taxPercent != 0) ? '${line.expr}$tail' : line.expr;
    }

    Widget taxChip(int percent) {
      final selected = line.taxPercent == percent;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: InkWell(
          key: Key('split-tax$percent-$i'),
          onTap: () => ctrl.setSplitTax(i, percent),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : null,
              border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('外税$percent%',
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? scheme.onPrimary : scheme.outline)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        key: Key('split-line-$i'),
        onTap: () => ctrl.setActiveSplit(i),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
            border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.4 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catName ?? 'カテゴリ未選択',
                      style: TextStyle(
                        fontSize: 12,
                        color: catName == null ? scheme.error : scheme.outline,
                      ),
                    ),
                    Text(
                      amountLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontFeatures: kTabularFigures,
                        color: line.expr.isEmpty ? scheme.outline : null,
                      ),
                    ),
                  ],
                ),
              ),
              taxChip(8),
              taxChip(10),
              if (lines.length > 1)
                IconButton(
                  key: Key('split-remove-$i'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  onPressed: () => ctrl.removeSplitLine(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
