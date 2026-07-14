import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../application/entry_form_controller.dart';
import 'split_category_sheet.dart';

/// 詳細入力（内訳）パネル。行はスクロール枠に収め、電卓・カテゴリは下に固定される。
/// 税は行ごとに「税込/税抜」と「8%/10%」の2軸。上部に一括選択。カテゴリは行の
/// 「カテゴリを選択」を押した時だけ電卓に被せてシートで選ぶ（常設グリッドは出さない）。
class SplitEntryPanel extends ConsumerStatefulWidget {
  final EntryFormState state;

  /// id→カテゴリ名（親・内訳とも）。行のカテゴリ表示に使う。
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

    // アクティブ行が変わったら（自動追加で末尾が増えた時など）、その行が電卓に
    // 隠れないよう枠を最下部までスクロールして見せる。
    final active = state.activeSplitIndex;
    if (active != _lastActive || lines.length != _lastLen) {
      _lastActive = active;
      _lastLen = lines.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && active >= lines.length - 1) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // 一括の選択表示: 全行が同じなら点灯、まちまちなら無点灯。
    final incVals = {for (final l in lines) l.taxIncluded};
    final bulkInc = incVals.length == 1 ? incVals.first : null;
    final rateVals = {for (final l in lines) l.rate};
    final bulkRate = rateVals.length == 1 ? rateVals.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 見出し行: 店名を入力（内訳の位置）… やめる
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
        const SizedBox(height: 6),
        // 税率選択（固定・行全体を色付け）。既定は一括のみ＝ここで全行まとめて設定し、
        // 各行に税ボタンは出さない。「個別に税率を設定」ONで各行に税率選択ボタンが出る
        // （商品ごとに税率が違うのはレアなので既定OFF）。
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _incSeg(scheme, ctrl, bulkInc, bulk: true),
              const SizedBox(width: 6),
              _rateSeg(scheme, ctrl, bulkRate, muted: false, bulk: true),
              const Spacer(),
              InkWell(
                key: const Key('split-perline-toggle'),
                onTap: () => ctrl.setSplitPerLineTax(!state.splitPerLineTax),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      state.splitPerLineTax
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text('個別に税率を設定',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // 行の表示は2行までに抑える（電卓を大きく取るため）。3行目以降は
        // アクティブ行まで自動スクロール（カテゴリ選択が電卓に隠れない）。
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: SingleChildScrollView(
            controller: _scroll,
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
                  // 選択中はパステル＝主色の淡いティント塗り＋濃い主色の文字。
                  // 従来の「濃緑塗り＋白文字」より柔らかい（custom accentでも自動でパステル化）。
                  color: it.selected
                      ? (muted
                          ? scheme.outlineVariant
                          : scheme.primary.withValues(alpha: 0.22))
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(it.label,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            it.selected ? FontWeight.w700 : FontWeight.normal,
                        color: it.selected
                            ? (muted ? scheme.onSurface : scheme.primary)
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
    final entered = line.enteredYen; // 入力した生の値（税抜/税込どちらでも）
    final isRemainder = line.expr.isEmpty;
    final hasOp = RegExp(r'[+\-×÷]').hasMatch(line.expr);

    // 主表示は「入力した値」（勝手に税込へ化けない）。末尾空行は残額。
    final String mainLabel;
    if (isRemainder) {
      mainLabel = net == null ? '残り ¥ —' : '残り ${formatYen(net)}';
    } else if (active && hasOp) {
      mainLabel = line.expr; // 入力中の式（電卓）
    } else {
      mainLabel = entered == null ? '¥ —' : formatYen(entered);
    }
    // 税抜のときだけ、空いた場所に税込換算を小さく併記。
    final String? subLabel = (!isRemainder && !line.taxIncluded && net != null)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 税率選択ボタンは「個別に税率を設定」ON時のみ各行に出す。
                  // 既定（一括のみ）は上の税率選択に従うので行には出さない。
                  if (state.splitPerLineTax) ...[
                    _incSeg(scheme, ctrl, line.taxIncluded, lineIndex: i),
                    const SizedBox(width: 6),
                    _rateSeg(scheme, ctrl, line.rate,
                        lineIndex: i, muted: line.taxIncluded),
                  ],
                  const Spacer(),
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
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  // カテゴリは常設グリッドを出さず、押した時だけ電卓に被せてシートで選ぶ。
                  // 未選択は主色の呼びかけボタン、選択済みはその名前（タップで選び直し）。
                  InkWell(
                    key: Key('split-pickcat-$i'),
                    onTap: () => openSplitCategorySheet(context, ref, i),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: catName == null
                            ? scheme.primary
                            : scheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            catName == null ? Icons.add : Icons.category,
                            size: 14,
                            color: catName == null
                                ? scheme.onPrimary
                                : scheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            catName ?? 'カテゴリを選択',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: catName == null
                                  ? scheme.onPrimary
                                  : scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // カテゴリを選んだら、その右に行ごとの詳細メモ欄を出す。
                  if (line.categoryId != null) ...[
                    const SizedBox(width: 8),
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
                    ),
                  ] else
                    const Spacer(),
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
