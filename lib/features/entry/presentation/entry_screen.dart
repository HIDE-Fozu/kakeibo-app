import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/ocr/receipt_capture.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/entry_category_providers.dart';
import '../application/entry_form_controller.dart';
import 'batch_itemize_panel.dart';
import 'category_grid.dart';
import 'numpad.dart';
import 'receipt_review_panel.dart';
import 'split_entry_panel.dart';
import 'subcategory_chips.dart';

class EntryScreen extends ConsumerWidget {
  /// true=ボトムタブに埋め込み（Xで閉じず、保存後はカレンダーへ切替）。
  /// false=編集モーダル（fullscreenDialog・保存でpop）。
  final bool embedded;

  const EntryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryFormControllerProvider);
    if (state == null) return const Scaffold(body: SizedBox());
    final ctrl = ref.read(entryFormControllerProvider.notifier);

    final title = switch (state.mode) {
      EntryMode.create => '入力',
      EntryMode.receiptConfirm => 'レシート確認',
      EntryMode.edit => '編集',
    };

    // グリッドは2行横スクロール（偶数index=上段 / 奇数index=下段）。
    // 内訳ありカテゴリが下段なら上段側に、上段なら下段側にオーバーレイを出す
    // （＝押した行を隠さず、押したカテゴリの隣に必ず出す）。
    final entryCats =
        ref.watch(entryCategoriesProvider(state.type)).valueOrNull ?? const [];
    final expandedIdx = state.expandedParentId == null
        ? -1
        : entryCats.indexWhere((c) => c.id == state.expandedParentId);
    // 押したカテゴリが下段なら内訳オーバーレイを上段側に出す（押した行を隠さない）。
    final overlayAbove = expandedIdx >= 0 && catIsBottomRow(expandedIdx);

    // 詳細入力（分割）モード: テンキー/グリッドはアクティブ行に入る
    final splitMode = state.splits != null;
    final activeSplitCategoryId =
        splitMode ? state.splits![state.activeSplitIndex].categoryId : null;
    // 一括内訳モード: グリッドは割当/塗り分けに使う
    final batchMode = state.batchItems != null;
    final allCats = ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final categoriesById = {for (final c in allCats) c.id: c};
    final categoryNames = {for (final c in allCats) c.id: c.name};
    // グリッドの選択表示: batch=塗るカテゴリ / split=アクティブ行 / 通常=state
    final gridSelectedId = batchMode
        ? (state.batchPaintMode ? state.batchPaintCategoryId : null)
        : splitMode
            ? activeSplitCategoryId
            : state.categoryId;

    return Scaffold(
      appBar: AppBar(
        // タブ埋め込み時は左上に戻る（カレンダーへ）。タブからもカレンダーへ戻れる。
        // モーダル(push)時は既定の閉じるボタンに任せる。
        leading: embedded
            ? IconButton(
                key: const Key('entry-back'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(homeTabIndexProvider.notifier).set(0),
              )
            : null,
        title: Text(title),
        actions: [
          if (state.mode == EntryMode.create)
            IconButton(
              key: const Key('scan-receipt'),
              icon: const Icon(Icons.receipt_long),
              onPressed: () => _scanReceipt(context, ref),
            ),
          if (state.mode == EntryMode.edit)
            IconButton(
              key: const Key('delete-entry'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      // 保存ボタンは最下部固定（収まる時はスクロールなし）。内訳チップはメモに重ねて
      // 出すので高さを取らず、メモ・保存は動かない。キーボード等で収まらない時だけスクロール。
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 編集では型不変（DBのupdateFieldsがtypeを書かない。返品はspec §4.4）
                      if (state.mode != EntryMode.edit)
                        SegmentedButton<TxnType>(
                          segments: const [
                            ButtonSegment(
                              value: TxnType.expense,
                              label: Text('支出'),
                            ),
                            ButtonSegment(
                              value: TxnType.income,
                              label: Text('収入'),
                            ),
                          ],
                          selected: {state.type},
                          onSelectionChanged: (s) => ctrl.setType(s.single),
                        ),
                      ListTile(
                        key: const Key('date-tile'),
                        dense: true,
                        leading: const Icon(Icons.event),
                        title: Text(_dateLabel(state.date)),
                        tileColor: state.mode == EntryMode.receiptConfirm
                            ? confidenceTint(
                                state.matchedDateCandidate?.confidence,
                              )
                            : null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateTimeOfCivil(state.date),
                            firstDate: DateTime(2000, 1, 1),
                            lastDate: DateTime(2100, 12, 31),
                          );
                          if (picked != null) {
                            ctrl.setDate(civilOfDateTime(picked));
                          }
                        },
                      ),
                      if (state.mode == EntryMode.receiptConfirm)
                        ReceiptReviewPanel(state: state),
                      Container(
                        key: const Key('amount-display'),
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: state.mode == EntryMode.receiptConfirm
                              ? confidenceTint(
                                  state.matchedTotalCandidate?.confidence,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.amountYen == 0
                              ? '¥0'
                              : formatYen(state.amountYen),
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontFeatures: kTabularFigures),
                        ),
                      ),
                      // 詳細入力: OCR明細があれば一括内訳、なければ電卓分割
                      if (!splitMode &&
                          !batchMode &&
                          state.mode != EntryMode.edit &&
                          state.amountYen > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const Key('start-split'),
                            onPressed: () {
                              final hasItems =
                                  state.receipt?.itemLines.isNotEmpty ?? false;
                              if (hasItems) {
                                ctrl.startBatchItemize();
                              } else {
                                ctrl.startSplit();
                              }
                            },
                            icon: const Icon(Icons.call_split, size: 18),
                            label: const Text('詳細入力'),
                          ),
                        ),
                      if (batchMode)
                        BatchItemizePanel(
                          state: state,
                          categoriesById: categoriesById,
                          pickableCategories: entryCats,
                        ),
                      if (splitMode)
                        SplitEntryPanel(
                            state: state, categoryNames: categoryNames),
                      // 一括内訳中はテンキー不要（金額は明細から）。スペースを譲る
                      if (!batchMode)
                        Numpad(
                          onDigit:
                              splitMode ? ctrl.splitTapDigit : ctrl.tapDigit,
                          onDoubleZero: splitMode
                              ? ctrl.splitTapDoubleZero
                              : ctrl.tapDoubleZero,
                          onBackspace:
                              splitMode ? ctrl.splitBackspace : ctrl.backspace,
                          onOperator: splitMode ? ctrl.splitTapOperator : null,
                        ),
                      const SizedBox(height: 8),
                      // 内訳チップは押したカテゴリの真下（グリッド下段＝日用品の位置）に
                      // 薄緑パネルで重ねる。背景と別色なので気づきやすい。高さは取らない。
                      Stack(
                        children: [
                          CategoryGrid(
                            type: state.type,
                            selectedId: gridSelectedId,
                            onTapCategory: ctrl.tapCategory,
                          ),
                          if (state.expandedParentId != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: overlayAbove ? 0 : null,
                              bottom: overlayAbove ? null : 0,
                              height: 66,
                              child: Container(
                                key: const Key('subcategory-chips'),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  // 淡い緑（背景に馴染みすぎず主張しすぎない）＋柔らかい緑枠
                                  color: const Color(0xFFEAF4EF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFCFE4DB),
                                  ),
                                ),
                                child: SubcategoryChips(
                                  parentId: state.expandedParentId!,
                                  selectedId: gridSelectedId,
                                  onToggle: ctrl.toggleSubcategory,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('memo-field-${state.formSeq}'),
                        initialValue: state.memo,
                        decoration: const InputDecoration(
                          labelText: 'メモ・店名',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: ctrl.setMemo,
                      ),
                      const Spacer(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              key: const Key('save-btn'),
                              onPressed: state.canSave
                                  ? () async {
                                      final date = state.date;
                                      await ctrl.save();
                                      if (embedded) {
                                        // 保存できたと分かるようカレンダーへ切替（その日を表示）
                                        ref
                                            .read(selectedDayProvider.notifier)
                                            .select(date);
                                        ctrl.startCreate(
                                          ref.read(clockProvider)(),
                                        );
                                        ref
                                            .read(homeTabIndexProvider.notifier)
                                            .set(0);
                                      } else if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  : null,
                              child: const Text('保存'),
                            ),
                          ),
                          if (state.mode != EntryMode.edit) ...[
                            // create + receiptConfirm（spec §7.4 分割入力）
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('save-continue-btn'),
                                onPressed: state.canSave
                                    ? () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        await ctrl.saveAndContinue();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('保存しました'),
                                          ),
                                        );
                                      }
                                    : null,
                                child: const Text('保存して続ける'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _dateLabel(CivilDate date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Future<void> _scanReceipt(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await _pickReceiptSource(context);
    if (source == null) return; // シート外タップ＝キャンセル
    final path = await ref.read(receiptCaptureProvider).capture(source);
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('この端末ではレシート撮影を利用できません')),
      );
      return;
    }
    try {
      final blocks = await ref.read(ocrServiceProvider).recognize(path);
      // フィクスチャ収集（spec §8.2）。releaseでも記録する＝TestFlightテスター
      // （母親）の実レシートデータを Files アプリ経由で回収できるようにする。
      // テスト期間中は写真も同名で保存（kCollectReceiptPhotosDuringTest）。
      // 端末内保存のみで自動送信はしない（spec §2.1）。失敗してもスキャンは続行。
      try {
        ref.read(ocrFixtureRecorderProvider).record(blocks, imagePath: path);
      } catch (_) {}
      final parsed = ref.read(receiptParserProvider).parse(blocks);
      ref
          .read(entryFormControllerProvider.notifier)
          .startReceipt(parsed, imagePath: path);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('読み取りに失敗しました: $e')));
    }
  }

  /// レシート画像の取得元を選ぶボトムシート。外タップ（キャンセル）は null。
  Future<ReceiptSource?> _pickReceiptSource(BuildContext context) {
    return showModalBottomSheet<ReceiptSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('receipt-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.pop(ctx, ReceiptSource.camera),
            ),
            ListTile(
              key: const Key('receipt-source-library'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('写真から選ぶ'),
              onTap: () => Navigator.pop(ctx, ReceiptSource.library),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この取引を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(entryFormControllerProvider.notifier).deleteEditing();
    if (context.mounted) Navigator.pop(context);
  }
}
