import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/navigation.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/category_emoji.dart';
import '../../../core/dates.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/ocr/receipt_capture.dart';
import '../../../l10n/app_localizations.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/entry_category_providers.dart';
import '../application/entry_form_controller.dart';
import 'batch_itemize_panel.dart';
import 'category_grid.dart';
import 'numpad.dart';
import 'receipt_review_panel.dart';
import 'split_category_strip.dart';
import 'split_entry_panel.dart';
import 'subcategory_chips.dart';

class EntryScreen extends ConsumerWidget {
  /// true=ボトムタブに埋め込み（Xで閉じず、保存後はカレンダーへ切替）。
  /// false=編集モーダル（fullscreenDialog・保存でpop）。
  final bool embedded;

  const EntryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(entryFormControllerProvider);
    if (state == null) return const Scaffold(body: SizedBox());
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final mf = ref.watch(moneyFormatterProvider);
    final currency = ref.watch(currencyProvider);

    final title = switch (state.mode) {
      EntryMode.create => l.entryTitleCreate,
      EntryMode.receiptConfirm => l.entryTitleReceiptConfirm,
      EntryMode.edit => l.commonEdit,
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
    // 分割の行・税ダイアログに出すカテゴリ表示ラベル（絵文字＋名前）。
    final categoryNames = {
      for (final c in allCats)
        c.id: '${categoryEmoji(c.icon, c.slug)} ${c.name}'
    };
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
          // レシートOCRは日本語レシート専用。日本円のときだけ入口を出す。
          if (state.mode == EntryMode.create && currency.code == 'JPY')
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // 編集では型不変（DBのupdateFieldsがtypeを書かない。返品はspec §4.4）。
                      // 詳細入力/一括内訳中は場所を空けるため隠す（型は開始前に確定済み）。
                      if (state.mode != EntryMode.edit && !splitMode && !batchMode)
                        SegmentedButton<TxnType>(
                          segments: [
                            ButtonSegment(
                              value: TxnType.expense,
                              label: Text(l.entryTypeExpense),
                            ),
                            ButtonSegment(
                              value: TxnType.income,
                              label: Text(l.entryTypeIncome),
                            ),
                          ],
                          selected: {state.type},
                          onSelectionChanged: (s) => ctrl.setType(s.single),
                        ),
                      if (state.mode == EntryMode.receiptConfirm)
                        ReceiptReviewPanel(state: state),
                      // 日付（年月日・タップで変更）と金額を1行に統合。金額は右寄せ大、
                      // 日付は同じ行の左（重なってOK＝独立の日付行を廃止して縦を詰める）。
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            InkWell(
                              key: const Key('date-tile'),
                              onTap: () => _pickDate(context, ref, state.date),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: state.mode == EntryMode.receiptConfirm
                                      ? confidenceTint(
                                          state.matchedDateCandidate?.confidence)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                    const SizedBox(width: 4),
                                    Text(_dateLabel(l, state.date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 金額は残り幅いっぱいで右寄せ。大きな額でも溢れないよう縮小。
                            Expanded(
                              child: Container(
                                key: const Key('amount-display'),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: state.mode == EntryMode.receiptConfirm
                                      ? confidenceTint(state
                                          .matchedTotalCandidate?.confidence)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    mf.format(state.amountYen),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                            fontFeatures: kTabularFigures),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                          // 分割中はグリッド（2行）が1行の帯になるぶん
                          // 空いた縦を電卓に回して大きく。通常モードは従来の詰め高さ。
                          cellHeight: splitMode ? 60 : 46,
                          onDigit:
                              splitMode ? ctrl.splitTapDigit : ctrl.tapDigit,
                          onDoubleZero: splitMode
                              ? ctrl.splitTapDoubleZero
                              : ctrl.tapDoubleZero,
                          onBackspace:
                              splitMode ? ctrl.splitBackspace : ctrl.backspace,
                          onOperator: splitMode ? ctrl.splitTapOperator : null,
                          // 小数桁のある通貨だけ「.」キーを出す。
                          onDecimal: currency.decimals > 0
                              ? (splitMode
                                  ? ctrl.splitTapDecimal
                                  : ctrl.tapDecimal)
                              : null,
                        ),
                      const SizedBox(height: 8),
                      // 詳細入力（分割/一括内訳）ボタンはカテゴリの上に置く。
                      // 分割/一括/編集中と金額0では出さない。
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
                            label: Text(l.entryStartSplitButton),
                          ),
                        ),
                      // カテゴリ: 分割中もグリッドと同じ位置（電卓の下・見出し付き）に
                      // 常設の1行帯を出す（split_category_strip・タップ=アクティブ行へ割当）。
                      // 通常/一括内訳では見出し＋グリッドを従来どおり表示。
                      if (splitMode) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 4),
                          child: Text(l.entryCategoryHeading,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.outline)),
                        ),
                        const SplitCategoryStrip(),
                      ],
                      if (!splitMode) ...[
                      // カテゴリ見出し。一括内訳中は右に詳細メモ欄を置く。
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 4),
                        child: Row(
                          children: [
                            Text(l.entryCategoryHeading,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.outline)),
                            // 分割は行ごとのメモ。一括内訳はグループのメモ欄をここに。
                            if (batchMode) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('split-memo-${state.formSeq}'),
                                  initialValue: state.memo,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: l.entryDetailMemoLabel,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    border: const UnderlineInputBorder(),
                                  ),
                                  onChanged: ctrl.setMemo,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
                      ],
                      // 詳細入力/一括内訳中は店舗名/詳細メモを隠して場所を空ける
                      // （取引全体の項目。保存前に通常画面で入力できる）。
                      if (!splitMode && !batchMode) ...[
                        const SizedBox(height: 8),
                        // レシート確認では店舗名は上のレビューパネルで扱うため詳細メモのみ。
                        if (state.mode != EntryMode.receiptConfirm) ...[
                          TextFormField(
                            key: ValueKey('store-field-${state.formSeq}'),
                            initialValue: state.storeName,
                            decoration: InputDecoration(
                              labelText: l.entryStoreNameLabel,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: ctrl.setStoreName,
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextFormField(
                          key: ValueKey('memo-field-${state.formSeq}'),
                          initialValue: state.memo,
                          decoration: InputDecoration(
                            labelText: l.entryDetailMemoLabel,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: ctrl.setMemo,
                        ),
                      ],
                  ],
                ),
              ),
            ),
            // 固定フッター: 保存エリアは常に見える（内容が伸びても隠れない）。
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!state.canSave && state.saveHint(l) != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        state.saveHint(l)!,
                        key: const Key('save-hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13),
                      ),
                    ),
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
                              child: Text(l.commonSave),
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
                                          SnackBar(
                                            content:
                                                Text(l.entrySavedSnackbar),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(l.entrySaveContinueButton),
                              ),
                            ),
                          ],
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(AppLocalizations l, CivilDate date) =>
      l.entryDateLabel(date.year, date.month, date.day);

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, CivilDate current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateTimeOfCivil(current),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      ref
          .read(entryFormControllerProvider.notifier)
          .setDate(civilOfDateTime(picked));
    }
  }

  Future<void> _scanReceipt(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final source = await _pickReceiptSource(context);
    if (source == null) return; // シート外タップ＝キャンセル
    final path = await ref.read(receiptCaptureProvider).capture(source);
    if (path == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.entryReceiptCaptureUnavailableSnackbar)),
      );
      return;
    }
    try {
      final blocks = await ref.read(ocrServiceProvider).recognize(path);
      // フィクスチャ収集（spec §8.2）。releaseでも記録する＝TestFlightテスター
      // （母親）が普通に使うだけで実レシートデータが端末内に溜まる。
      // テスト期間中は写真も同名で保存（kCollectReceiptPhotosDuringTest）。
      // 保存確定時に正解ラベルを書き戻すため、パスをフォームへ引き継ぐ。
      // 端末内保存のみで自動送信はしない（spec §2.1）。失敗してもスキャンは続行。
      String? fixturePath;
      try {
        fixturePath =
            ref.read(ocrFixtureRecorderProvider).record(blocks, imagePath: path);
      } catch (_) {}
      final parsed = ref.read(receiptParserProvider).parse(blocks);
      ref
          .read(entryFormControllerProvider.notifier)
          .startReceipt(parsed, imagePath: path, fixturePath: fixturePath);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.entryOcrFailedSnackbar('$e'))),
      );
    }
  }

  /// レシート画像の取得元を選ぶボトムシート。外タップ（キャンセル）は null。
  Future<ReceiptSource?> _pickReceiptSource(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<ReceiptSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('receipt-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.entryReceiptSourceCamera),
              onTap: () => Navigator.pop(ctx, ReceiptSource.camera),
            ),
            ListTile(
              key: const Key('receipt-source-library'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.entryReceiptSourceLibrary),
              onTap: () => Navigator.pop(ctx, ReceiptSource.library),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.entryDeleteConfirmTitle),
        content: Text(l.entryDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(entryFormControllerProvider.notifier).deleteEditing();
    if (context.mounted) Navigator.pop(context);
  }
}
