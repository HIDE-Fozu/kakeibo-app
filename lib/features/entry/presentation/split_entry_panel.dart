import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../application/entry_form_controller.dart';

/// 詳細入力（内訳）パネル。行はスクロール枠に収め、電卓・カテゴリは下に固定される。
/// 税は行ごとに「税込/税抜」と「8%/10%」の2軸。上部に一括選択と「＋追加」。
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
        // 見出し: 内訳 … やめる
        Row(
          children: [
            Icon(Icons.call_split, size: 15, color: scheme.outline),
            const SizedBox(width: 4),
            Text('内訳',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.outline)),
            const Spacer(),
            TextButton(
              key: const Key('cancel-split'),
              onPressed: ctrl.cancelSplit,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32)),
              child: const Text('やめる'),
            ),
          ],
        ),
        // 一括（1行）＋「＋追加」。セグメントは行と左端を揃える。
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _incSeg(scheme, ctrl, bulkInc, bulk: true),
              const SizedBox(width: 6),
              _rateSeg(scheme, ctrl, bulkRate, muted: false, bulk: true),
              const Spacer(),
              Text('一括',
                  style: TextStyle(fontSize: 10.5, color: scheme.outline)),
              const SizedBox(width: 6),
              InkWell(
                key: const Key('split-add'),
                onTap: ctrl.addSplitLine,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 15, color: scheme.primary),
                    const SizedBox(width: 2),
                    Text('追加',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 行はスクロール枠に収める（追加しても電卓・カテゴリは動かない）。
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 176),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++) _line(context, ref, i),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 税セグメント ---
  Widget _incSeg(ColorScheme scheme, EntryFormController ctrl, bool? included,
      {int? lineIndex, bool bulk = false}) {
    return _seg(scheme, [
      _SegItem('税込', included == true, () {
        bulk ? ctrl.setSplitBulkIncluded(true) : ctrl.setSplitIncluded(lineIndex!, true);
      }, key: Key(bulk ? 'split-bulk-incl' : 'split-incl-$lineIndex')),
      _SegItem('税抜', included == false, () {
        bulk ? ctrl.setSplitBulkIncluded(false) : ctrl.setSplitIncluded(lineIndex!, false);
      }, key: Key(bulk ? 'split-bulk-excl' : 'split-excl-$lineIndex')),
    ]);
  }

  Widget _rateSeg(ColorScheme scheme, EntryFormController ctrl, int? rate,
      {int? lineIndex, bool muted = false, bool bulk = false}) {
    return _seg(scheme, muted: muted, [
      _SegItem('8%', rate == 8, () {
        bulk ? ctrl.setSplitBulkRate(8) : ctrl.setSplitRate(lineIndex!, 8);
      }, key: bulk ? null : Key('split-rate8-$lineIndex')),
      _SegItem('10%', rate == 10, () {
        bulk ? ctrl.setSplitBulkRate(10) : ctrl.setSplitRate(lineIndex!, 10);
      }, key: bulk ? null : Key('split-rate10-$lineIndex')),
    ]);
  }

  Widget _seg(ColorScheme scheme, List<_SegItem> items, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in items)
            InkWell(
              key: it.key,
              onTap: it.onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: it.selected
                      ? (muted ? scheme.outlineVariant : scheme.primary)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(it.label,
                    style: TextStyle(
                        fontSize: 11.5,
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

    // l2の金額: 手入力は入力額、末尾空行は残額。入力/自動の語は付けず、自動は太字。
    final shown = isRemainder ? net : entered;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
      child: InkWell(
        key: Key('split-line-$i'),
        onTap: () => ctrl.setActiveSplit(i),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color:
                active ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
            border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.4 : 1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _incSeg(scheme, ctrl, line.taxIncluded, lineIndex: i),
                  const SizedBox(width: 6),
                  _rateSeg(scheme, ctrl, line.rate,
                      lineIndex: i, muted: line.taxIncluded),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(isRemainder ? '残り(税込)' : '税込',
                          style:
                              TextStyle(fontSize: 9.5, color: scheme.outline)),
                      Text(net == null ? '¥ —' : formatYen(net),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFeatures: kTabularFigures)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
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
                  Text(shown == null ? '' : formatYen(shown),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isRemainder ? FontWeight.w700 : FontWeight.normal,
                          color: scheme.outline,
                          fontFeatures: kTabularFigures)),
                  const SizedBox(width: 6),
                  InkWell(
                    key: Key('split-clear-$i'),
                    onTap: () => ctrl.clearSplitLine(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                        child:
                            Icon(Icons.close, size: 17, color: scheme.outline),
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
}

/// セグメント1項目の指定。
class _SegItem {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Key? key;
  const _SegItem(this.label, this.selected, this.onTap, {this.key});
}
