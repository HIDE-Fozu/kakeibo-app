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
import '../../settings/application/settings_controller.dart';

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
    // 支払い区分（モードOFFなら選択UI自体を出さない＝従来どおり）。
    final paymentMode = ref.watch(appSettingsProvider).paymentModeEnabled;
    final cards = paymentMode
        ? (ref.watch(paymentCardsProvider).valueOrNull ??
            const <PaymentCardEntity>[])
        : const <PaymentCardEntity>[];

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

    // 分割中は帯（1行）に譲るぶん電卓を大きく。通常モードは従来の詰め高さ。
    // 「まず合計を入力」フェーズ（金額0で内訳開始）は電卓を合計に配線する
    // （行の式は打てない＝演算子列も出さない）。
    final splitTyping = splitMode && !state.splitTotalPending;
    final numpad = Numpad(
      cellHeight: splitMode ? 60 : 46,
      onDigit: splitTyping ? ctrl.splitTapDigit : ctrl.tapDigit,
      onDoubleZero:
          splitTyping ? ctrl.splitTapDoubleZero : ctrl.tapDoubleZero,
      onBackspace: splitTyping ? ctrl.splitBackspace : ctrl.backspace,
      onOperator: splitTyping ? ctrl.splitTapOperator : null,
      // 小数桁のある通貨だけ「.」キーを出す。
      onDecimal: currency.decimals > 0
          ? (splitTyping ? ctrl.splitTapDecimal : ctrl.tapDecimal)
          : null,
    );

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
                      // 内訳中も出す（隠すと「カテゴリを追加」の前後で品目行と
                      // カテゴリの位置が飛ぶ・2026-08-13のFB）。
                      if (state.mode != EntryMode.edit && !batchMode)
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
                                // 「まず合計を入力」フェーズはここが入力先。
                                // アクティブ行と同じ主色の枠＋薄い地で示す。
                                decoration: BoxDecoration(
                                  color: state.splitTotalPending
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.35)
                                      : state.mode == EntryMode.receiptConfirm
                                          ? confidenceTint(state
                                              .matchedTotalCandidate
                                              ?.confidence)
                                          : null,
                                  border: state.splitTotalPending
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 1.4)
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
                        // 帯は「1行ぶんの枠」だけ確保し、2行に開いたときは電卓に
                        // 重ねる（内訳チップの浮かせ表示と同じ手）。開閉で電卓や
                        // 保存ボタンが動かないので、開いたまま数字も打てる。
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: kCatTileH + 6),
                                if (!batchMode) numpad,
                              ],
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              // 合計入力フェーズは合計0の間だけ帯も触れない
                              // （合計が入ったらタップでフェーズ解除できる）。
                              child: IgnorePointer(
                                ignoring: state.splitTotalPending &&
                                    state.amountYen <= 0,
                                child: Opacity(
                                  opacity: state.splitTotalPending &&
                                          state.amountYen <= 0
                                      ? 0.45
                                      : 1,
                                  child: const SplitCategoryStrip(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      // 通常/一括内訳のカテゴリは見出し＋グリッド（電卓の下）。
                      // 分割中の帯は行のすぐ下＝電卓の上（上の splitMode ブロック）。
                      // 1品目の状態でも「内訳の1行目」として見せる（2026-08-12の
                      // FB。ここから「カテゴリを追加」で2行に増えて内訳画面に
                      // 育つ、という連続した流れにするため）。行の見た目は
                      // split_entry_panel の行に合わせてある。
                      // 店名は品目行の上（内訳画面と同じ位置）。
                      if (!splitMode &&
                          !batchMode &&
                          state.mode != EntryMode.receiptConfirm) ...[
                        TextFormField(
                          key: ValueKey('store-field-${state.formSeq}'),
                          initialValue: state.storeName,
                          decoration: InputDecoration(
                            // 収入は店ではなく勤め先なので「会社名」（2026-08-09 FB）。
                            labelText: state.type == TxnType.income
                                ? l.entryCompanyNameLabel
                                : l.entryStoreNameLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: ctrl.setStoreName,
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 「カテゴリを追加」は**消費税行と同じ位置**に置く（2026-08-13のFB）。
                      // 押すと内訳になりここに消費税行が出るので、ボタン⇄消費税行の
                      // 入れ替わりだけになり、品目行とカテゴリの位置が動かない。
                      // 金額0でも出す＝初期表示（2026-08-13のFB）。保存できない理由は
                      // 「保存」を押すまで出さないので、縦は増えない。
                      if (!splitMode &&
                          !batchMode &&
                          state.mode != EntryMode.edit) ...[
                        const SizedBox(height: 4),
                        // 左=毎月の費用 / 右=カテゴリを追加。内訳の「内訳＋消費税」行と
                        // 同じ左右構成・同じ位置に揃える（2026-08-13のFB）。
                        // Wrap: 幅が足りない言語では2行に折り返す。
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // 支払い区分（モードON・支出・新規のときだけ）。
                            // 押すと現金/登録カードから選ぶ。カード＝未払金になる。
                            if (paymentMode &&
                                state.type == TxnType.expense &&
                                state.mode == EntryMode.create)
                              TextButton.icon(
                                key: const Key('entry-payment-btn'),
                                onPressed: () =>
                                    _pickPaymentCard(context, ref, cards),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: state.paymentCardId != null
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  foregroundColor: state.paymentCardId != null
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                                icon: Icon(
                                    state.paymentCardId == null
                                        ? Icons.payments_outlined
                                        : Icons.credit_card,
                                    size: 18),
                                label: Text(
                                  cards
                                          .where((c) =>
                                              c.id == state.paymentCardId)
                                          .firstOrNull
                                          ?.name ??
                                      l.paymentCash,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                              // 金額0でも押せる（案B: 残り行が合計行になる
                              // ボトムアップ内訳。旧・案Aのグレー＋SnackBarは撤去）。
                              // 一括内訳（レシート品目）は総額が前提なので従来どおり
                              // 金額があるときだけ。
                              onPressed: () {
                                final hasItems =
                                    state.receipt?.itemLines.isNotEmpty ??
                                        false;
                                if (hasItems && state.amountYen > 0) {
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
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l.entryStartSplitButton),
                            ),
                          ],
                        ),
                      // ON時の予告帯: 「毎月N日に自動で記帳します（この入力が1回目）」
                      // 記帳日は入力日付の日が既定。「記帳日を変更」で毎月N日を上書き
                      // できる（8/8に入力して引き落としは毎月25日、のようなケース）。
                      // 金額未入力でも出す。以前は amountYen > 0 を条件にしていて、
                      // 金額を入れる前に押すとボタンだけ緑になって帯も記帳日も
                      // 出ず「効かない」ように見えた（FB 2026-08-15）。
                      if (!splitMode && !batchMode && state.recurringOn)
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
                      ],
                      if (!splitMode && !batchMode)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 2, right: 2, bottom: 6),
                          child: Container(
                            key: const Key('single-item-row'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Text('1',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontFeatures: kTabularFigures,
                                      )),
                                ),
                                // 金額は上部に大きく出ているので行には出さない
                                // （1品目では必ず総額と同じ＝二重表示になる）。
                                // 長い言語(de)で溢れないよう Flexible + 省略。
                                Flexible(
                                  child: _singleCatChip(context,
                                      categoryNames[state.categoryId], l),
                                ),
                                const SizedBox(width: 7),
                                // メモも内訳の行と同じくセル内に（2026-08-16 FB。
                                // 独立した「詳細メモ」欄は廃止し、1品目の情報が
                                // この行に揃う。ボタン→ダイアログも内訳と共通）。
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: MemoPillButton(
                                      key: const Key('entry-memo-btn'),
                                      memo: state.memo,
                                      onTap: () async {
                                        final result =
                                            await showDialog<String>(
                                          context: context,
                                          builder: (_) => SplitMemoDialog(
                                              title: l.splitMemoDialogTitle,
                                              initial: state.memo),
                                        );
                                        if (result == null) return;
                                        ctrl.setMemo(result.trim());
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                            child: _subcategoryPanel(context, state, ctrl, gridSelectedId),
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
                                // 一括内訳中はテンキー不要（金額は明細から）。スペースを譲る
                                // （分割中は上の Stack の中で電卓を出すのでここでは出さない）。
                                if (!batchMode && !splitMode) numpad,
                                const SizedBox(height: 8),
                                // 旧・独立した「詳細メモ」欄はここにあったが、
                                // 品目行のセル内メモボタンへ移動（2026-08-16 FB）。
                              ],
                            ),
                            if (state.expandedParentId != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: kCatGridHeight + 4,
                                height: 66,
                                child: _subcategoryPanel(
                                    context,
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
                  // 押す前は出さない（常時表示だと縦を1行占める・2026-08-13のFB）
                  if (state.saveAttempted &&
                      !state.canSave &&
                      state.saveHint(l) != null)
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
                              onPressed: () async {
                                // 押せないボタンにはせず、押したら未入力の理由を出す（2026-08-13のFB）
                                if (!state.canSave) return ctrl.markSaveAttempted();

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
                                  ,
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
                                onPressed: () async {
                                  // 押せないボタンにはせず、押したら未入力の理由を出す（2026-08-13のFB）
                                  if (!state.canSave) return ctrl.markSaveAttempted();

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
                                },
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
    BuildContext context,
    EntryFormState state,
    EntryFormController ctrl,
    int? gridSelectedId,
  ) =>
      Container(
        key: const Key('subcategory-chips'),
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          // ソフト面（背景に馴染みすぎず主張しすぎない）＋ボーダー色の枠。
          // 浮かせて出すので下の内容と区別できるよう軽い影を付ける。
          color: context.kakeiboPalette.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.kakeiboPalette.line),
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
          onDone: ctrl.confirmParentCategory,
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
    // messengerはpop後も生きるroot ScaffoldMessenger（戻り先の画面に出す）。
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(entryFormControllerProvider.notifier).deleteEditing();
    if (context.mounted) Navigator.pop(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(l.trashMovedSnack),
      showCloseIcon: true,
      duration: const Duration(seconds: 10),
    ));
  }
}

/// 1品目行のカテゴリ表示。内訳行のチップと同じ見た目に揃える（未選択は赤茶の枠）。
/// 内訳行と違いタップ対象は下のグリッドなので、ここは表示専用。
/// 支払い区分を選ぶボトムシート（現金＋登録カード）。
Future<void> _pickPaymentCard(
    BuildContext context, WidgetRef ref, List<PaymentCardEntity> cards) async {
  final l = AppLocalizations.of(context);
  final current = ref.read(entryFormControllerProvider)?.paymentCardId;
  final picked = await showModalBottomSheet<int?>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('payment-pick-cash'),
            leading: const Icon(Icons.payments_outlined),
            title: Text(l.paymentCash),
            selected: current == null,
            // 「選ばない」を返すため、現金は sentinel の -1 で伝える。
            onTap: () => Navigator.pop(ctx, -1),
          ),
          for (final c in cards)
            ListTile(
              key: Key('payment-pick-${c.id}'),
              leading: const Icon(Icons.credit_card),
              title: Text(c.name),
              selected: current == c.id,
              onTap: () => Navigator.pop(ctx, c.id),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return; // シートを閉じただけ
  ref
      .read(entryFormControllerProvider.notifier)
      .setPaymentCard(picked == -1 ? null : picked);
}

Widget _singleCatChip(BuildContext context, String? label, AppLocalizations l) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: label == null ? null : scheme.primaryContainer,
      border: Border.all(
          color: label == null
              ? kWarnMuted
              : scheme.primary.withValues(alpha: 0.45)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label ?? l.splitCategoryUnselected,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: label == null ? kWarnMuted : scheme.primary,
      ),
    ),
  );
}
