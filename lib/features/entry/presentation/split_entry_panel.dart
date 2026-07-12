import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../application/entry_form_controller.dart';

/// 詳細入力（分割）パネル。
/// 行をタップでアクティブ化→テンキー（＋−×÷付き）とカテゴリグリッドがその行に入る。
/// 税は行ごとに「税込/税抜」と「8%/10%」の2軸。上部に一括選択。末尾の空行は残額を担う。
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

    // 一括の選択表示: 全行が同じなら点灯、まちまちなら無点灯。
    final incVals = {for (final l in lines) l.taxIncluded};
    final bulkInc = incVals.length == 1 ? incVals.first : null;
    final rateVals = {for (final l in lines) l.rate};
    final bulkRate = rateVals.length == 1 ? rateVals.first : null;

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
        // 一括: 全行の税をまとめて設定
        Container(
          margin: const EdgeInsets.only(top: 2, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(11),
          ),
          // 「一括」は見出しとして上に置き、セグメントは下の行と左端を揃える。
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('一括',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.outline)),
                  const Spacer(),
                  Text('全行にまとめて適用',
                      style: TextStyle(fontSize: 10, color: scheme.outline)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _seg(scheme, [
                    _SegItem('税込', bulkInc == true,
                        () => ctrl.setSplitBulkIncluded(true),
                        key: const Key('split-bulk-incl')),
                    _SegItem('税抜', bulkInc == false,
                        () => ctrl.setSplitBulkIncluded(false),
                        key: const Key('split-bulk-excl')),
                  ]),
                  const SizedBox(width: 6),
                  _seg(scheme, [
                    _SegItem(
                        '8%', bulkRate == 8, () => ctrl.setSplitBulkRate(8)),
                    _SegItem('10%', bulkRate == 10,
                        () => ctrl.setSplitBulkRate(10)),
                  ]),
                ],
              ),
            ],
          ),
        ),
        for (var i = 0; i < lines.length; i++) _line(context, ref, i),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('split-add'),
            onPressed: ctrl.addSplitLine,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('行を追加'),
          ),
        ),
        _recon(context),
      ],
    );
  }

  // --- 税セグメント（共通） ---
  Widget _seg(ColorScheme scheme, List<_SegItem> items, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in items)
            InkWell(
              key: it.key,
              onTap: it.onTap,
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: it.selected
                      ? (muted ? scheme.outlineVariant : scheme.primary)
                      : null,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(it.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            it.selected ? FontWeight.w600 : FontWeight.normal,
                        color: it.selected
                            ? (muted ? scheme.onSurface : scheme.onPrimary)
                            : scheme.onSurfaceVariant)),
              ),
            ),
        ],
      ),
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
    final net = state.splitLineAmount(i); // 税込値（末尾空行=残額）
    final entered = line.enteredYen;
    final isRemainder = line.expr.isEmpty;

    // 入力額の表示（手入力/自動で同形式の¥金額。入力中で式のときだけ式を見せる）
    final String mainLabel;
    if (isRemainder) {
      mainLabel = net == null ? '' : '自動 ${formatYen(net)}';
    } else if (active && RegExp(r'[+\-×÷]').hasMatch(line.expr)) {
      mainLabel = line.expr;
    } else {
      mainLabel = entered == null ? '¥ —' : '入力 ${formatYen(entered)}';
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
              // 1段目: 税(税込/税抜)・税率(8/10) ／ 右に税込換算
              Row(
                children: [
                  _seg(scheme, [
                    _SegItem('税込', line.taxIncluded,
                        () => ctrl.setSplitIncluded(i, true),
                        key: Key('split-incl-$i')),
                    _SegItem('税抜', !line.taxIncluded,
                        () => ctrl.setSplitIncluded(i, false),
                        key: Key('split-excl-$i')),
                  ]),
                  const SizedBox(width: 6),
                  _seg(scheme, muted: line.taxIncluded, [
                    _SegItem('8%', line.rate == 8, () => ctrl.setSplitRate(i, 8),
                        key: Key('split-rate8-$i')),
                    _SegItem('10%', line.rate == 10,
                        () => ctrl.setSplitRate(i, 10),
                        key: Key('split-rate10-$i')),
                  ]),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(isRemainder ? '残り（税込）' : '税込',
                          style:
                              TextStyle(fontSize: 10, color: scheme.outline)),
                      Text(net == null ? '¥ —' : formatYen(net),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFeatures: kTabularFigures)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 2段目: カテゴリ ／ 入力額 ／ クリア・削除
              Row(
                children: [
                  Text(
                    catName ?? 'カテゴリ未選択',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: catName == null ? scheme.error : scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(mainLabel,
                      style: TextStyle(
                          fontSize: 13,
                          color: scheme.outline,
                          fontFeatures: kTabularFigures)),
                  InkWell(
                    key: Key('split-clear-$i'),
                    onTap: () => ctrl.clearSplitLine(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text('クリア',
                          style:
                              TextStyle(fontSize: 12, color: scheme.primary)),
                    ),
                  ),
                  if (lines.length > 1)
                    InkWell(
                      key: Key('split-remove-$i'),
                      onTap: () => ctrl.removeSplitLine(i),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 18, color: scheme.outline),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 合計との一致確認 ---
  Widget _recon(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = state.splitRemainder < 0;
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: over
            ? scheme.errorContainer.withValues(alpha: 0.5)
            : scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: over
          ? Text(
              '合計を ${formatYen(-state.splitRemainder)} 超えています',
              key: const Key('split-over'),
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
            )
          : Row(
              children: [
                Text('内わけ合計',
                    style: TextStyle(fontSize: 13, color: scheme.outline)),
                const SizedBox(width: 8),
                Text(formatYen(state.amountYen),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: kTabularFigures)),
                const Spacer(),
                Icon(Icons.check_circle, size: 15, color: scheme.primary),
                const SizedBox(width: 4),
                Text('合計と一致',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
              ],
            ),
    );
  }
}

/// セグメント1項目の指定。
class _SegItem {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Key? key;
  const _SegItem(this.label, this.selected, this.onTap, {this.key});
}
