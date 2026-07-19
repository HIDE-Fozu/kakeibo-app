import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../application/entry_form_controller.dart';
import 'split_tax_dialog.dart';

/// 内訳入力パネル（確定モックv4）。
/// 構成: 店名行 → タイトル行（内訳・[内税|8%|10%]・個別・＋品目）→
///       入力行（2行分の高さでスクロール）→ 残額行（最下段固定・差分表示）。
/// 税は全行トグルが基本（既定=内税）。「個別」は品目ごとのダイアログ。
/// カテゴリは行のチップ／「カテゴリを追加」から電卓上の帯（split_category_strip）。
class SplitEntryPanel extends ConsumerStatefulWidget {
  final EntryFormState state;

  /// id→表示ラベル（絵文字＋名前）。行・ダイアログのカテゴリ表示に使う。
  final Map<int, String> categoryNames;

  const SplitEntryPanel({
    super.key,
    required this.state,
    required this.categoryNames,
  });

  @override
  ConsumerState<SplitEntryPanel> createState() => _SplitEntryPanelState();
}

class _SplitEntryPanelState extends ConsumerState<SplitEntryPanel> {
  final _scroll = ScrollController();
  int _lastActive = -1;
  int _lastLen = -1;

  EntryFormState get state => widget.state;
  Map<int, String> get categoryNames => widget.categoryNames;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final scheme = Theme.of(context).colorScheme;
    final inputCount = lines.length - 1; // 末尾は残額行（窓の外に固定描画）

    // 挿入で末尾側の入力行がアクティブになったら、その行が見えるようスクロール。
    final active = state.activeSplitIndex;
    if (active != _lastActive || lines.length != _lastLen) {
      _lastActive = active;
      _lastLen = lines.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && active >= inputCount - 1) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // 全行トグルの点灯状態: 全行内税→「内税」/ 全行外税→レート点灯。まちまちは無点灯。
    final incAll = lines.every((l) => l.taxIncluded);
    final excAll = lines.every((l) => !l.taxIncluded);
    final rateVals = {for (final l in lines) l.rate};
    final bulkRate = rateVals.length == 1 ? rateVals.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 店名行
        Row(
          children: [
            Icon(Icons.call_split, size: 15, color: scheme.outline),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                key: ValueKey('split-store-${state.formSeq}'),
                initialValue: state.storeName,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '店名',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                  border: UnderlineInputBorder(),
                ),
                onChanged: ctrl.setStoreName,
              ),
            ),
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
        const SizedBox(height: 4),
        // タイトル行: 内訳＋税トグル（内税⇄外税・8/10%）＋個別＋＋品目。
        // 「品目を追加」「カテゴリを選択」の独立行は置かない（行数を3行に保つ）。
        Row(
          children: [
            Text('内訳',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary)),
            const Spacer(),
            _seg(scheme, [
              // 内税を外すと表記が「外税」に変わる（タップでトグル・全行に即適用）
              _SegItem(incAll ? '内税' : '外税', incAll,
                  () => ctrl.setSplitBulkIncluded(!incAll),
                  key: const Key('split-tax-mode')),
              _SegItem('8%', excAll && bulkRate == 8, () {
                ctrl.setSplitBulkIncluded(false);
                ctrl.setSplitBulkRate(8);
              }, key: const Key('split-tax-8')),
              _SegItem('10%', excAll && bulkRate == 10, () {
                ctrl.setSplitBulkIncluded(false);
                ctrl.setSplitBulkRate(10);
              }, key: const Key('split-tax-10')),
            ]),
            const SizedBox(width: 6),
            _chipButton(scheme, '個別', key: const Key('split-tax-per'),
                onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => SplitTaxDialog(categoryLabels: categoryNames),
              );
            }),
            const SizedBox(width: 6),
            _chipButton(scheme, '＋ 品目',
                key: const Key('split-add'),
                solid: true,
                onTap: ctrl.addSplitLine),
          ],
        ),
        const SizedBox(height: 6),
        // 入力行は2行分の高さに収め、3品目〜はスクロール（アクティブ行へ自動）。
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 104),
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < inputCount; i++) _line(context, i),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _remainderRow(context),
      ],
    );
  }

  /// タイトル行の小ボタン（個別/＋品目）。
  Widget _chipButton(ColorScheme scheme, String label,
      {required Key key, bool solid = false, required VoidCallback onTap}) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: solid ? scheme.primary : scheme.primaryContainer,
          border: Border.all(
              color: solid ? scheme.primary : scheme.outlineVariant),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: solid ? scheme.onPrimary : scheme.primary)),
      ),
    );
  }

  // --- 税セグメント（パステル点灯） ---
  Widget _seg(ColorScheme scheme, List<_SegItem> items) {
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
                      ? scheme.primary.withValues(alpha: 0.22)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(it.label,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            it.selected ? FontWeight.w700 : FontWeight.normal,
                        color: it.selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }

  /// 入力行（1行構成: カテゴリチップ｜メモ｜金額）。
  Widget _line(BuildContext context, int i) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final line = lines[i];
    final scheme = Theme.of(context).colorScheme;
    final active = i == state.activeSplitIndex;
    final catLabel =
        line.categoryId == null ? null : categoryNames[line.categoryId];
    final net = state.splitLineAmount(i);
    final entered = line.enteredYen;
    final hasOp = RegExp(r'[+\-×÷]').hasMatch(line.expr);

    // 主表示は「入力した値」。入力中は式。外税のときだけ税込換算を下に併記。
    final String mainLabel;
    if (active && hasOp) {
      mainLabel = line.expr;
    } else {
      mainLabel = entered == null ? '¥ —' : formatYen(entered);
    }
    final String? subLabel = (!line.taxIncluded && net != null)
        ? '税込 ${formatYen(net)}'
        : null;

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
          child: Row(
            children: [
              // カテゴリ: 未選択は呼びかけボタン、選択済みはチップ。
              // どちらもタップで電卓上のカテゴリ帯を開く（選び直し可）。
              InkWell(
                key: Key('split-pickcat-$i'),
                onTap: () => ctrl.openSplitCatPicker(i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catLabel == null
                        ? scheme.primary
                        : scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    catLabel ?? '＋ カテゴリ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: catLabel == null
                          ? scheme.onPrimary
                          : scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              if (line.categoryId != null)
                Expanded(
                  child: TextFormField(
                    key: ValueKey('split-linememo-$i-${state.formSeq}'),
                    initialValue: line.memo,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'メモ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 2),
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (v) => ctrl.setSplitMemo(i, v),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(mainLabel,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFeatures: kTabularFigures)),
                  if (subLabel != null)
                    Text(subLabel,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: scheme.onSurfaceVariant,
                            fontFeatures: kTabularFigures)),
                ],
              ),
              if (lines.length > 2) ...[
                const SizedBox(width: 4),
                InkWell(
                  key: Key('split-remove-$i'),
                  onTap: () => ctrl.removeSplitLine(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 16, color: scheme.outline),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 残額行（最下段固定・差分表示）。カテゴリを付けるだけで最後の1品になる。
  Widget _remainderRow(BuildContext context) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final i = lines.length - 1;
    final line = lines[i];
    final scheme = Theme.of(context).colorScheme;
    final active = i == state.activeSplitIndex;
    final rem = state.splitRemainder;
    final over = rem < 0;
    final catLabel =
        line.categoryId == null ? null : categoryNames[line.categoryId];
    final fg = over ? scheme.error : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: InkWell(
        key: const Key('split-remainder'),
        onTap: () => ctrl.openSplitCatPicker(i),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: over
                ? scheme.errorContainer
                : scheme.primaryContainer.withValues(alpha: 0.45),
            border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.4 : 1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Text(over ? '超過' : '残り',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: fg)),
              const SizedBox(width: 6),
              Text(formatYen(over ? -rem : rem),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      fontFeatures: kTabularFigures)),
              const Spacer(),
              if (catLabel == null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 15, color: scheme.primary),
                    Text('カテゴリを追加',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                    Icon(Icons.chevron_right, size: 15, color: scheme.primary),
                  ],
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(catLabel,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary)),
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
