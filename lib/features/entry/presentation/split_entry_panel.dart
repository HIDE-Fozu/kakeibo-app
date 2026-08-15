import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/theme.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/db/enums.dart';
import '../application/entry_form_controller.dart';
import 'split_tax_dialog.dart';

/// 内訳入力パネル（確定モックv4）。
/// 構成: 店名行 → タイトル行（内訳・[内税|8%|10%]・個別・＋品目）→
///       入力行（2行分の高さでスクロール）→ 残額行（最下段固定・差分表示）。
/// 税は全行トグルが基本（既定=内税）。「個別」は品目ごとのダイアログ。
/// カテゴリは電卓下の常設帯（split_category_strip）で選ぶ。行のチップ／
/// 「カテゴリを追加」タップはその行を帯の割当先（アクティブ行）にする。
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
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final mf = ref.watch(moneyFormatterProvider);
    final taxEnabled = ref.watch(taxProfileProvider).enabled;
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
            Icon(Icons.call_split, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                key: ValueKey('split-store-${state.formSeq}'),
                initialValue: state.storeName,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  // 通常入力と同じラベルに統一（「店名」表記ゆれのFB 2026-08-15）。
                  hintText: state.type == TxnType.expense
                      ? l.entryStoreNameLabel
                      : l.entryCompanyNameLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: const UnderlineInputBorder(),
                ),
                onChanged: ctrl.setStoreName,
              ),
            ),
            TextButton(
              key: const Key('cancel-split'),
              onPressed: ctrl.cancelSplit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(l.splitCancel),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // タイトル行: 内訳＋消費税グループ（ラベル＋内税トグル＋8/10%＋個別を同背景に）。
        // ＋品目は残額行の右端へ移動。「品目を追加」等の独立行は置かない（3行を保つ）。
        Row(
          children: [
            Text(
              l.splitBreakdownLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const Spacer(),
            // 消費税グループ: 内税トグルと8/10%は分離。個別も含め同じ薄緑背景でまとめる。
            // 非JP（税プロファイル無効）では丸ごと非表示（入力額=税込扱い）。
            if (taxEnabled)
              Container(
                padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.splitTaxLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // 内税⇄外税トグル（単独・全行に即適用。外すと表記が「外税」に）
                    InkWell(
                      key: const Key('split-tax-mode'),
                      onTap: () => ctrl.setSplitBulkIncluded(!incAll),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          incAll
                              ? l.splitTaxIncludedToggle
                              : l.splitTaxExcludedToggle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // 8%/10%（内税のときは淡色＝適用なし。タップで外税へ切替）
                    Opacity(
                      opacity: incAll ? 0.4 : 1,
                      child: _seg(scheme, [
                        _SegItem('8%', excAll && bulkRate == 8, () {
                          ctrl.setSplitBulkIncluded(false);
                          ctrl.setSplitBulkRate(8);
                        }, key: const Key('split-tax-8')),
                        _SegItem(
                          '10%',
                          excAll && bulkRate == 10,
                          () {
                            ctrl.setSplitBulkIncluded(false);
                            ctrl.setSplitBulkRate(10);
                          },
                          key: const Key('split-tax-10'),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 5),
                    _chipButton(
                      scheme,
                      l.splitTaxIndividual,
                      key: const Key('split-tax-per'),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) =>
                              SplitTaxDialog(categoryLabels: categoryNames),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                for (var i = 0; i < inputCount; i++) _line(context, mf, i),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _remainderRow(context, mf),
      ],
    );
  }

  /// 消費税グループ内の「個別」ボタン（白ピルで背景から浮かせる）。
  Widget _chipButton(
    ColorScheme scheme,
    String label, {
    required Key key,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
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
                child: Text(
                  it.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: it.selected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: it.selected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 入力行（1行構成: カテゴリチップ｜メモ｜金額）。
  Widget _line(BuildContext context, MoneyFormatter mf, int i) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final line = lines[i];
    final scheme = Theme.of(context).colorScheme;
    final active = i == state.activeSplitIndex;
    final catLabel = line.categoryId == null
        ? null
        : categoryNames[line.categoryId];
    final net = state.splitLineAmount(i);
    final entered = line.enteredYen;
    final hasOp = RegExp(r'[+\-×÷]').hasMatch(line.expr);

    // 主表示は「入力した値」。入力中は式。外税のときだけ税込換算を下に併記。
    // 金額が空の行は「金額未入力」と書く（'—' では何が足りないか伝わらない、
    // というFB。カテゴリ未選択と違い黒字＝入力待ちの案内という位置づけ）。
    final String mainLabel;
    final bool amountEmpty = entered == null && !(active && hasOp);
    if (active && hasOp) {
      mainLabel = line.expr;
    } else {
      mainLabel = entered == null ? l.splitAmountEmpty : mf.format(entered);
    }
    final String? subLabel = (!line.taxIncluded && net != null)
        ? l.splitTaxIncludedAmount(mf.format(net))
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
            // 未選択の行も白（シートの「ホワイト＝カード・入力面」）。
            // アクティブ行だけソフトミントを薄く敷いて焦点を示す。
            color: active
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : kCard,
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
              width: active ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              // 行番号バッジ。保存ヒント「品目Nのカテゴリを…」と対応させる。
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  '${i + 1}',
                  key: Key('split-lineno-$i'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
              // カテゴリ: 未選択は「カテゴリ未選択」の警告表示（塗りなし・
              // 赤茶の文字と枠）、選択済みはチップ。どちらもタップで電卓下の
              // カテゴリ帯の割当先にする（選び直し可）。警告色を kExpense の
              // 赤ではなく赤茶（kWarnMuted）にしているのは、未選択の行では
              // 常時出るため強すぎない主張にしたいから。
              InkWell(
                key: Key('split-pickcat-$i'),
                onTap: () => ctrl.openSplitCatPicker(i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // 選択済みは濃いめの塗り＋緑枠（行の中でカテゴリの塊が
                    // どこまでか分かりにくい、というFB）。未選択は赤茶の枠のみ。
                    color: catLabel == null ? null : scheme.primaryContainer,
                    border: Border.all(
                        color: catLabel == null
                            ? kWarnMuted
                            : scheme.primary.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    catLabel ?? l.splitCategoryUnselected,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: catLabel == null ? kWarnMuted : scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              // メモはインライン入力ではなくボタン→ダイアログ入力に。
              // カテゴリ未選択でも常に出す。未入力は「個別」と同じ白ピルの
              // ボタン見た目（薄いグレー文字だとボタンと気づけないため）。
              // 入力済みは本文を1行表示（タップで編集）。
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    key: Key('split-memo-btn-$i'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ctrl.setActiveSplit(i);
                      _editSplitMemo(context, i, line.memo);
                    },
                    child: line.memo.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              border:
                                  Border.all(color: scheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_note,
                                    size: 15, color: scheme.primary),
                                const SizedBox(width: 2),
                                Text(l.splitMemoHint,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary)),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 4),
                            child: Text(
                              line.memo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mainLabel,
                    style: TextStyle(
                      // 文言のときは金額より一段小さく（桁揃えも不要）。
                      fontSize: amountEmpty ? 12.5 : 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: amountEmpty ? null : kTabularFigures,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
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
                    child: Icon(Icons.close,
                        size: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 行メモの入力ダイアログ。保存でその行（＝そのカテゴリの取引）のメモになる。
  Future<void> _editSplitMemo(
      BuildContext context, int i, String current) async {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final title =
        '${l.splitItemNumberLabel(i + 1)} — ${l.splitMemoDialogTitle}';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SplitMemoDialog(title: title, initial: current),
    );
    if (result == null) return; // キャンセル
    ctrl.setSplitMemo(i, result.trim());
  }

  /// 残額行（最下段固定・差分表示）。カテゴリを付けるだけで最後の1品になる。
  Widget _remainderRow(BuildContext context, MoneyFormatter mf) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;
    final i = lines.length - 1;
    final line = lines[i];
    final scheme = Theme.of(context).colorScheme;
    final active = i == state.activeSplitIndex;
    final rem = state.splitRemainder;
    final over = rem < 0;
    final catLabel = line.categoryId == null
        ? null
        : categoryNames[line.categoryId];
    final fg = over ? scheme.error : scheme.primary;

    // 行のどこをタップしてもアクティブ行になる（背面のGestureDetector）。
    // カテゴリ追加/＋品目のInkWellは前面の子なのでタップはそちらが勝つ
    // （7月の「入れ子InkWellで＋が死ぬ」事故はInkWell同士の入れ子が原因。
    //  背面をGestureDetectorにすれば競合しない）。
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: GestureDetector(
        key: const Key('split-line-remainder'),
        behavior: HitTestBehavior.opaque,
        onTap: () => ctrl.setActiveSplit(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            // 品目行と同じ扱い: 普段は白、アクティブ行のときだけソフトミント。
            // （超過だけは注意色を残す）
            color: over
                ? scheme.errorContainer
                : active
                    ? scheme.primaryContainer.withValues(alpha: 0.35)
                    : kCard,
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
              width: active ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              // 行番号。残額行も「カテゴリを選べばその番号の品目になる枠」なので
              // 入力行と同じ連番を振る（1品目なら2、＋品目で3…と自動で繰り上がる）。
              // 番号だけ無いと最終行が別物に見える、というFB。
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  '${i + 1}',
                  key: Key('split-lineno-$i'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
              // 左: 入力行と同じく「カテゴリ未選択」/選択済みチップ。
              // タップでカテゴリ帯を開き、その行を割当先にする。
              InkWell(
                key: const Key('split-remainder'),
                onTap: () => ctrl.openSplitCatPicker(i),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catLabel == null ? null : scheme.primaryContainer,
                      border: Border.all(
                          color: catLabel == null
                              ? kWarnMuted
                              : scheme.primary.withValues(alpha: 0.45)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catLabel ?? l.splitCategoryUnselected,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: catLabel == null ? kWarnMuted : scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // 右: 残り（差分・非タップ）
              Text(
                over ? l.splitOverLabel : l.splitRemainingLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                mf.format(over ? -rem : rem),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  fontFeatures: kTabularFigures,
                ),
              ),
              const SizedBox(width: 9),
              // 右端: ＋品目（残額行の直前に入力行を挿す・独立タップ）。
              InkWell(
                key: const Key('split-add'),
                onTap: ctrl.addSplitLine,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  // 主色の丸ボタン（＋品目）。カスタムテーマに追従。
                  decoration: BoxDecoration(
                    color: context.kakeiboPalette.fill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 行メモの入力ダイアログ。controllerの寿命をダイアログ自身に閉じ込める
/// （popアニメーション中のdispose事故防止・_CategoryEditDialogと同じ流儀）。
class _SplitMemoDialog extends StatefulWidget {
  final String title;
  final String initial;
  const _SplitMemoDialog({required this.title, required this.initial});

  @override
  State<_SplitMemoDialog> createState() => _SplitMemoDialogState();
}

class _SplitMemoDialogState extends State<_SplitMemoDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('split-memo-field'),
        controller: _text,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l.splitMemoHint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        FilledButton(
            key: const Key('split-memo-save'),
            onPressed: () => Navigator.pop(context, _text.text),
            child: Text(l.commonSave)),
      ],
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
