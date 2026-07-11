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
    final amount = state.splitLineAmount(i);

    // 金額表示: 手入力でも自動（残額）でも同じ「¥金額」。入力中の行だけ式を見せる
    // （電卓フィードバック）。灰色や「残り」は使わない＝自動でも当たり前に見せる。
    final String amountLabel;
    if (active && line.expr.isNotEmpty) {
      final hasOp = RegExp(r'[+\-×÷]').hasMatch(line.expr);
      amountLabel = (hasOp || line.taxPercent != 0)
          ? '${line.expr}${amount == null ? ' = ?' : ' = ${formatYen(amount)}'}'
          : formatYen(amount ?? 0);
    } else {
      amountLabel = amount == null ? '¥ —' : formatYen(amount);
    }

    // 税方式チップ（税込/外税8%/外税10%）。選択は塗り、非選択も読める色に。
    Widget taxChip(String label, int percent) {
      final selected = line.taxPercent == percent;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: InkWell(
          key: Key('split-tax$percent-$i'),
          onTap: () => ctrl.setSplitTaxPercent(i, percent),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  selected ? scheme.primary : scheme.surfaceContainerHighest,
              border: Border.all(
                  color: selected ? scheme.primary : scheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? scheme.onPrimary : scheme.onSurface)),
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
            color:
                active ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
            border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.4 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1段目: カテゴリ名 ／ クリア ／ 削除
              Row(
                children: [
                  Expanded(
                    child: Text(
                      catName ?? 'カテゴリ未選択',
                      style: TextStyle(
                        fontSize: 12,
                        color: catName == null ? scheme.error : scheme.outline,
                      ),
                    ),
                  ),
                  InkWell(
                    key: Key('split-clear-$i'),
                    onTap: () => ctrl.clearSplitLine(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text('クリア',
                          style:
                              TextStyle(fontSize: 12, color: scheme.primary)),
                    ),
                  ),
                  if (lines.length > 1)
                    IconButton(
                      key: Key('split-remove-$i'),
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close),
                      onPressed: () => ctrl.removeSplitLine(i),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              // 2段目: 金額（手入力/自動で同形式） ／ 税方式(税込・外税8・外税10)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      amountLabel,
                      style: const TextStyle(
                          fontSize: 16, fontFeatures: kTabularFigures),
                    ),
                  ),
                  taxChip('税込', 0),
                  taxChip('外税8%', 8),
                  taxChip('外税10%', 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
