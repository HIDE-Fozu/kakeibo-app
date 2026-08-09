import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cell_dropdown.dart';
import '../../../app/keyboard_done_bar.dart';
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

    final entryCats =
        ref.watch(entryCategoriesProvider(state.type)).valueOrNull ?? const [];

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
                      // 分割中は「行 → カテゴリ帯 → 電卓」の順（2026-08-10・
                      // ユーザー選択）。割り当て先の行と帯が隣接して視線移動が減り、
                      // 電卓が下がって親指に近くなる。通常モードは従来どおり
                      // 「電卓 → カテゴリ」で、帯/グリッドの位置がモードで入れ替わる。
                      if (splitMode) ...[
                        SplitEntryPanel(
                            state: state, categoryNames: categoryNames),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 2, top: 6, bottom: 4),
                          child: Text(l.entryCategoryHeading,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ),
                        const SplitCategoryStrip(),
                        const SizedBox(height: 4),
                      ],
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
                      // 左隣に「毎月の費用/収入」トグル（単体登録専用。グループ
                      // 再保存=replacesTxIds中とレシート確認では出さない）。
                      // Wrap: 幅が足りない言語では2行に折り返す（Spacer+Flexibleの
                      // Rowはflex均等割りで右ボタンが「複数のカ…」に切れる罠がある）。
                      if (!splitMode &&
                          !batchMode &&
                          state.mode != EntryMode.edit &&
                          state.amountYen > 0)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (state.mode == EntryMode.create &&
                                state.replacesTxIds == null)
                              TextButton.icon(
                                key: const Key('entry-recurring-btn'),
                                onPressed: ctrl.toggleRecurring,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: state.recurringOn
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  foregroundColor: state.recurringOn
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                                icon: const Icon(Icons.event_repeat, size: 18),
                                label: Text(
                                  state.type == TxnType.expense
                                      ? l.entryRecurringExpense
                                      : l.entryRecurringIncome,
                                ),
                              ),
                            TextButton.icon(
                              key: const Key('start-split'),
                              onPressed: () {
                                final hasItems =
                                    state.receipt?.itemLines.isNotEmpty ??
                                        false;
                                if (hasItems) {
                                  ctrl.startBatchItemize();
                                } else {
                                  ctrl.startSplit();
                                }
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.call_split, size: 18),
                              label: Text(l.entryStartSplitButton),
                            ),
                          ],
                        ),
                      // ON時の予告帯: 「毎月N日に自動で記帳します（この入力が1回目）」
                      // 記帳日は入力日付の日が既定。「記帳日を変更」で毎月N日を上書き
                      // できる（8/8に入力して引き落としは毎月25日、のようなケース）。
                      if (!splitMode &&
                          !batchMode &&
                          state.recurringOn &&
                          state.amountYen > 0)
                        Container(
                          key: const Key('entry-recurring-note'),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // 「毎月［27▾］日に自動で記帳します」— 日は帯の中の
                          // プルダウンで直接変更（取引の日付は変えない）。
                          // 語順が言語で違うため前後テキストは別キー。
                          child: Builder(builder: (context) {
                            final noteStyle = TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            );
                            return Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(l.entryRecurringNotePrefix,
                                    style: noteStyle),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  // 白ピル（行メモ・内訳チップと同じ文法）で
                                  // 帯から浮かせ、押せる場所だと分かるようにする。
                                  // メニューはピル幅・直下展開（cell_dropdown）。
                                  child: Builder(builder: (pillContext) {
                                    return InkWell(
                                      key: const Key('entry-recurring-day'),
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final picked =
                                            await showCellDropdown<int>(
                                          pillContext,
                                          centerItems: true,
                                          value:
                                              state.effectiveRecurringDay,
                                          items: [
                                            for (var d = 1; d <= 31; d++)
                                              CellDropdownItem(d, '$d'),
                                          ],
                                        );
                                        if (picked != null) {
                                          ctrl.setRecurringDay(picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 1桁/2桁とも同じ幅の箱の中央に
                                            // 置き、▾ が数字の右に密着する。
                                            SizedBox(
                                              width: 20,
                                              child: Center(
                                                child: Text(
                                                  '${state.effectiveRecurringDay}',
                                                  style: noteStyle.copyWith(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                Text(l.entryRecurringNoteSuffix,
                                    style: noteStyle),
                              ],
                            );
                          }),
                        ),
                      // 通常/一括内訳のカテゴリは見出し＋グリッド（電卓の下）。
                      // 分割中の帯は行のすぐ下＝電卓の上（上の splitMode ブロック）。
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
                                        Theme.of(context).colorScheme.onSurfaceVariant)),
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
                      if (batchMode) ...[
                        CategoryGrid(
                          type: state.type,
                          selectedId: gridSelectedId,
                          onTapCategory: ctrl.tapCategory,
                        ),
                        // 一括内訳ではこの下に要素が無いので、in-flowでも何も動かさない。
                        if (state.expandedParentId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _subcategoryPanel(state, ctrl, gridSelectedId),
                          ),
                      ] else
                        // 通常/レシート確認: 内訳チップはグリッド直下に「浮かせて」出す。
                        // タイルに被せず、下の店舗名/メモも動かさない
                        // （開いている間だけ店舗名欄に一時的に重なる）。
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CategoryGrid(
                                  type: state.type,
                                  selectedId: gridSelectedId,
                                  onTapCategory: ctrl.tapCategory,
                                ),
                                const SizedBox(height: 8),
                                // レシート確認では店舗名は上のレビューパネルで扱うため
                                // 詳細メモのみ。
                                if (state.mode != EntryMode.receiptConfirm) ...[
                                  TextFormField(
                                    key: ValueKey('store-field-${state.formSeq}'),
                                    initialValue: state.storeName,
                                    decoration: InputDecoration(
                                      // 収入は店ではなく勤め先なので「会社名」
                                      // （2026-08-09 FB）。
                                      labelText:
                                          state.type == TxnType.income
                                              ? l.entryCompanyNameLabel
                                              : l.entryStoreNameLabel,
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
                            ),
                            if (state.expandedParentId != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: kCatGridHeight + 4,
                                height: 66,
                                child: _subcategoryPanel(
                                    state, ctrl, gridSelectedId),
                              ),
                          ],
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
                              // 「毎月の費用/収入」ON時はルールも作ることを予告
                              child: Text(state.recurringOn
                                  ? (state.type == TxnType.expense
                                      ? l.entrySaveWithRuleExpense
                                      : l.entrySaveWithRuleIncome)
                                  : l.commonSave),
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
            // キーボード直上の「完了」バー（テキスト入力中だけ自分で表示される）。
            const KeyboardDoneBar(),
          ],
        ),
      ),
    );
  }

  /// 内訳チップのパネル（薄緑・66高）。通常モードではグリッド直下に浮かせ、
  /// 一括内訳では in-flow で使う（見た目は共通）。
  Widget _subcategoryPanel(
    EntryFormState state,
    EntryFormController ctrl,
    int? gridSelectedId,
  ) =>
      Container(
        key: const Key('subcategory-chips'),
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          // 淡い緑（背景に馴染みすぎず主張しすぎない）＋柔らかい緑枠。
          // 浮かせて出すので下の内容と区別できるよう軽い影を付ける。
          color: const Color(0xFFEAF4EF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCFE4DB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SubcategoryChips(
          parentId: state.expandedParentId!,
          selectedId: gridSelectedId,
          onToggle: ctrl.toggleSubcategory,
        ),
      );

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
