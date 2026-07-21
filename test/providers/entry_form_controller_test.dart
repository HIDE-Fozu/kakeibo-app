import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:kakeibo_app/app/l10n_providers.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/l10n/app_localizations.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/receipt_fixtures.dart';
import '../support/test_app.dart';

ReceiptItem itemOf(int yen, {bool mark = false}) => ReceiptItem(
    text: 'item-$yen',
    yen: yen,
    rect: const OcrRect(0.05, 0.2, 0.9, 0.03),
    reducedTaxMark: mark);

ParsedReceipt receiptOf(
    {int? yen,
    required CivilDate date,
    String? store,
    List<ReceiptItem> items = const []}) {
  final total = yen == null
      ? null
      : AmountCandidate(
          yen: yen,
          confidence: ExtractionConfidence.high,
          sourceText: '合計 ¥$yen',
          reason: 'total-label');
  final d = DateCandidate(
      date: date,
      confidence: ExtractionConfidence.high,
      sourceText: date.toIso(),
      reason: 'issue-date');
  return ParsedReceipt(
    total: total,
    totalCandidates: [?total],
    date: d,
    dateCandidates: [d],
    storeName: store,
    itemLines: items,
  );
}

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late int foodId;
  const day = CivilDate(2026, 7, 15);

  EntryFormController ctrl() => c.read(entryFormControllerProvider.notifier);
  EntryFormState st() => c.read(entryFormControllerProvider)!;

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
  });

  test('startCreate: 既定値とcanSave遷移', () {
    ctrl().startCreate(day);
    expect(st().mode, EntryMode.create);
    expect(st().type, TxnType.expense);
    expect(st().amountYen, 0);
    expect(st().canSave, isFalse);
    ctrl().tapDigit(5);
    expect(st().canSave, isFalse); // カテゴリ未選択
    ctrl().selectCategory(foodId);
    expect(st().canSave, isTrue);
  });

  test('テンキー: 累積・00・backspace・上限', () {
    ctrl().startCreate(day);
    ctrl().tapDigit(1);
    ctrl().tapDigit(2);
    ctrl().tapDoubleZero();
    expect(st().amountYen, 1200);
    ctrl().backspace();
    expect(st().amountYen, 120);
    for (var i = 0; i < 10; i++) {
      ctrl().tapDigit(9);
    }
    expect(st().amountYen, lessThanOrEqualTo(9999999));
    // amount=0 のとき00は無効
    ctrl().startCreate(day);
    ctrl().tapDoubleZero();
    expect(st().amountYen, 0);
  });

  test('setType でカテゴリ選択がクリアされる（spec §4.5）', () {
    ctrl().startCreate(day);
    ctrl().selectCategory(foodId);
    ctrl().setType(TxnType.income);
    expect(st().categoryId, isNull);
    expect(st().type, TxnType.income);
  });

  test('編集モードでは setType が無効（型/カテゴリdesync防止）', () async {
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 100,
        date: day,
        categoryId: foodId,
        source: TxnSource.manual));
    final tx = (await repo.forMonth(2026, 7)).single;
    ctrl().startEdit(tx);
    ctrl().setType(TxnType.income);
    expect(st().type, TxnType.expense);
    expect(st().categoryId, foodId);
  });

  test('save: 手入力が保存される（memo空はnull）', () async {
    ctrl().startCreate(day);
    ctrl().tapDigit(8);
    ctrl().selectCategory(foodId);
    await ctrl().save();
    final list = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(list.single.amountYen, 8);
    expect(list.single.source, TxnSource.manual);
    expect(list.single.memo, isNull);
  });

  test('save: 店舗名と詳細メモが別々に保存される', () async {
    ctrl().startCreate(day);
    ctrl().tapDigit(8);
    ctrl().selectCategory(foodId);
    ctrl().setStoreName('スーパーA');
    ctrl().setMemo('ポイント2倍');
    await ctrl().save();
    final list = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(list.single.storeName, 'スーパーA');
    expect(list.single.memo, 'ポイント2倍');
  });

  test('canSave=false の save は StateError', () {
    ctrl().startCreate(day);
    expect(() => ctrl().save(), throwsStateError);
  });

  test('saveAndContinue: date/memo/type維持・amount/categoryクリア', () async {
    ctrl().startCreate(day);
    ctrl().tapDigit(5);
    ctrl().selectCategory(foodId);
    ctrl().setMemo('スーパーA');
    await ctrl().saveAndContinue();
    expect(st().mode, EntryMode.create);
    expect(st().amountYen, 0);
    expect(st().categoryId, isNull);
    expect(st().memo, 'スーパーA');
    expect(st().date, day);
  });

  test('startEdit -> save は update（id/source不変）', () async {
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 100,
        date: day,
        categoryId: foodId,
        source: TxnSource.receiptOcr));
    final tx = (await repo.forMonth(2026, 7)).single;
    ctrl().startEdit(tx);
    expect(st().mode, EntryMode.edit);
    expect(st().amountYen, 100);
    ctrl().backspace();
    ctrl().tapDigit(5); // 100 -> 10 -> 105
    await ctrl().save();
    final after = (await repo.forMonth(2026, 7)).single;
    expect(after.id, tx.id);
    expect(after.amountYen, 105);
    expect(after.source, TxnSource.receiptOcr);
  });

  test('deleteEditing で行が消える', () async {
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 100,
        date: day,
        categoryId: foodId,
        source: TxnSource.manual));
    final tx = (await repo.forMonth(2026, 7)).single;
    ctrl().startEdit(tx);
    await ctrl().deleteEditing();
    expect(await repo.forMonth(2026, 7), isEmpty);
  });

  test('startReceipt: プリフィルと候補切替・手修正でmatched解除', () {
    final parsed = receiptOf(yen: 1080, date: const CivilDate(2026, 7, 14));
    ctrl().startReceipt(parsed);
    expect(st().mode, EntryMode.receiptConfirm);
    expect(st().amountYen, 1080);
    expect(st().date, const CivilDate(2026, 7, 14));
    expect(st().source, TxnSource.receiptOcr);
    expect(st().matchedTotalCandidate, isNotNull);
    ctrl().tapDigit(0); // 手修正 10800
    expect(st().matchedTotalCandidate, isNull);
    ctrl().selectTotalCandidate(parsed.totalCandidates.single);
    expect(st().amountYen, 1080);
  });

  test('startReceipt: 合計なし→amount 0（空フォームフォールバック）', () {
    ctrl().startReceipt(receiptOf(yen: null, date: day));
    expect(st().amountYen, 0);
    expect(st().receipt!.total, isNull);
  });

  group('詳細入力（分割）', () {
    late int dailyId;
    late int eatOutId;
    setUp(() async {
      final cats = await waitForData(c, allCategoriesProvider);
      dailyId = cats.firstWhere((x) => x.name == '日用品').id;
      eatOutId = cats.firstWhere((x) => x.name == '外食').id;
    });

    test('カテゴリ自動税率: 食費→8%・外食→10%・手動は上書きしない', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit();
      // 既定=内税（入力額そのまま）。自動税率は rate に記録され、外税にした時に効く
      expect(st().splits![0].taxIncluded, isTrue);
      expect(st().splits![0].rate, 10);

      // 食費を割り当て → 軽減税率8%が自動
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().splits![0].rate, 8);

      // 外食に変えると10%（店内は標準税率）
      ctrl().tapCategory(
          categoryId: eatOutId, hasSubs: false, isSameGroup: false);
      expect(st().splits![0].rate, 10);

      // 手で8%にした後は、カテゴリ変更で上書きされない
      ctrl().setSplitRate(0, 8);
      ctrl().tapCategory(
          categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().splits![0].rate, 8);
    });

    test('行ごとの詳細メモが各取引に保存される', () async {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit();
      ctrl().setSplitBulkIncluded(true); // 税込で単純化

      // 行0: 300 ＋ 日用品 ＋ メモ「洗剤」
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero();
      ctrl().tapCategory(categoryId: dailyId, hasSubs: false, isSameGroup: false);
      ctrl().setSplitMemo(0, '洗剤');
      // 行1（残額700） ＋ 食費 ＋ メモ「牛乳」
      ctrl().setActiveSplit(1);
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      ctrl().setSplitMemo(1, '牛乳');
      expect(st().canSave, isTrue);

      await ctrl().save();
      final txs =
          await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      expect(txs, hasLength(2));
      final byMemo = {for (final t in txs) t.memo: t.amountYen};
      expect(byMemo['洗剤'], 300);
      expect(byMemo['牛乳'], 700);
    });

    test('saveHint: 詳細入力は開始直後も未カテゴリも理由が出る・完了で消える', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit();
      // 開いた直後（金額未入力）でも理由が出る
      final jaL = lookupAppLocalizations(const Locale('ja'));
      expect(st().canSave, isFalse);
      expect(st().saveHint(jaL), '金額とカテゴリを入力してください');

      ctrl().setSplitBulkIncluded(true);
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero(); // 300 → 残額行700が未カテゴリ
      ctrl().tapCategory(categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().canSave, isFalse);
      expect(st().saveHint(jaL), 'カテゴリを選んでください');

      // 残額行にカテゴリ → 保存可・ヒント消える
      ctrl().setActiveSplit(1);
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().canSave, isTrue);
      expect(st().saveHint(jaL), isNull);
    });

    test('＋品目は残額行の直前に挿入・残額行への打鍵は新しい行で受ける', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit();
      expect(st().splits, hasLength(2)); // 入力1行＋残額行(末尾)で開始

      // 入力行への打鍵では行は増えない
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero(); // 行0=300
      expect(st().splits, hasLength(2));

      // 残額行(末尾)への打鍵→直前に入力行が挿入されそちらで受ける
      ctrl().setActiveSplit(1);
      ctrl().splitTapDigit(2);
      ctrl().splitTapDoubleZero(); // 200
      expect(st().splits, hasLength(3));
      expect(st().activeSplitIndex, 1);
      expect(st().splits![1].expr, '200');
      expect(st().splits![2].expr, ''); // 残額行は空のまま末尾に固定

      // 「＋品目」も残額行の直前に挿入・アクティブに
      ctrl().addSplitLine();
      expect(st().splits, hasLength(4));
      expect(st().activeSplitIndex, 2);
      expect(st().splits![3].expr, ''); // 残額行は常に末尾
    });

    test('フロー: 2行で開始→行1入力で2行目に残額→保存で2取引', () async {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0);
      expect(st().amountYen, 1000);

      ctrl().startSplit();
      ctrl().setSplitBulkIncluded(true); // 税込で入力＝入力額そのまま（残額の検証を単純化）
      expect(st().splits, hasLength(2)); // 2行で開始（自動では増やさない）
      expect(st().canSave, isFalse);
      // 何も入れていないうちは残額を出さない
      expect(st().splitLineAmount(0), isNull);
      expect(st().splitLineAmount(1), isNull);

      // 行1: 300円（税込）＋食費
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero();
      // 行が増えず2行のまま。2行目（末尾の空行）に残額700が出る
      expect(st().splits, hasLength(2));
      expect(st().splitLineAmount(0), 300); // 手入力した1行目
      expect(st().splitLineAmount(1), 700); // 2行目=残額
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().splits![0].categoryId, foodId);

      // 行2（残額行）: カテゴリだけ選べば残額700で確定できる
      ctrl().setActiveSplit(1);
      ctrl().tapCategory(
          categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().canSave, isTrue);

      await ctrl().save();
      final txs =
          await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      expect(txs, hasLength(2));
      expect(txs.map((t) => t.amountYen).toSet(), {300, 700});
      expect(txs.map((t) => t.categoryId).toSet(), {foodId, dailyId});
    });

    test('3分割: 残額行への打鍵で行が挿入され、残額カテゴリ確定で3取引', () async {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit(); // 既定=内税（入力額そのまま）
      expect(st().splits, hasLength(2));

      // 行0: 300＋食費（カテゴリ確定で行は増えない）
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero();
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().splits, hasLength(2));

      // 残額行(末尾)へ400を打鍵→直前に入力行が挿入され、日用品を割当
      ctrl().setActiveSplit(1);
      ctrl().splitTapDigit(4);
      ctrl().splitTapDoubleZero(); // 400
      expect(st().splits, hasLength(3));
      expect(st().activeSplitIndex, 1);
      ctrl().tapCategory(
          categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().splits, hasLength(3)); // カテゴリ確定でも増えない
      expect(st().splitLineAmount(2), 300); // 末尾の残額行が差分300を担う

      // 残額行＋外食 → 保存可
      ctrl().setActiveSplit(2);
      ctrl().tapCategory(
          categoryId: eatOutId, hasSubs: false, isSameGroup: false);
      expect(st().splits, hasLength(3));
      expect(st().canSave, isTrue);

      await ctrl().save();
      final txs =
          await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      expect(txs, hasLength(3));
      expect(txs.map((t) => t.amountYen).toList()..sort(), [300, 300, 400]);
    });

    test('自動追加しない: 末尾の空行がそのまま残額を担う2分割では増えない', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit();
      ctrl().setSplitBulkIncluded(true);

      // 行0: 300＋食費、行1(末尾・空)はカテゴリだけ＝残額700を担う → 増えない
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero();
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      ctrl().setActiveSplit(1);
      ctrl().tapCategory(
          categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().splits, hasLength(2)); // 末尾は空(expr無し)なので自動追加しない
      expect(st().canSave, isTrue);
    });

    test('税: 100+100 は既定内税でそのまま200・外税10%で220・8%で216', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(5);
      ctrl().tapDoubleZero(); // 500
      ctrl().startSplit();

      ctrl().splitTapDigit(1);
      ctrl().splitTapDoubleZero();
      ctrl().splitTapOperator('+');
      ctrl().splitTapDigit(1);
      ctrl().splitTapDoubleZero(); // "100+100" = 200
      expect(st().splits![0].enteredYen, 200);
      expect(st().splits![0].amountYen, 200); // 既定=内税（そのまま）
      ctrl().setSplitIncluded(0, false);
      expect(st().splits![0].amountYen, 220); // 外税10%
      ctrl().setSplitRate(0, 8);
      expect(st().splits![0].amountYen, 216); // 外税8%
      ctrl().setSplitIncluded(0, true);
      expect(st().splits![0].amountYen, 200); // 内税=そのまま

      // 行1にカテゴリ（税は手動済みなので自動上書きされない）、残額行にもカテゴリ→保存可
      ctrl().tapCategory(categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().canSave, isFalse); // 残額行が未カテゴリ
      ctrl().setActiveSplit(1);
      ctrl().tapCategory(
          categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().splitLineAmount(1), 300); // line0=税込200 → 残り300
      expect(st().canSave, isTrue);
    });

    test('入れ過ぎ（残額マイナス）は保存不可・演算子の置換・キャンセル', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero(); // 100
      ctrl().startSplit();

      // 連続演算子は置換される: "5+×" → "5×"
      ctrl().splitTapDigit(5);
      ctrl().splitTapOperator('+');
      ctrl().splitTapOperator('×');
      expect(st().splits![0].expr, '5×');
      ctrl().splitBackspace();
      ctrl().splitTapDigit(0);
      ctrl().splitTapDigit(0); // "500" > 合計100
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().splitRemainder, lessThan(0));
      expect(st().canSave, isFalse);

      ctrl().cancelSplit();
      expect(st().splits, isNull);
      expect(st().amountYen, 100); // 合計は保持
    });

    test('編集モード・金額0では開始できない', () {
      ctrl().startCreate(day);
      ctrl().startSplit(); // 金額0
      expect(st().splits, isNull);
    });
  });

  group('一括内訳（OCR明細）', () {
    late int dailyId;
    setUp(() async {
      final cats = await waitForData(c, allCategoriesProvider);
      dailyId = cats.firstWhere((x) => x.name == '日用品').id;
    });

    test('D1: 選択→割当→差額0→保存で同一groupIdの取引群', () async {
      // 明細: 198(※軽減) + 398。ヘッダ外税10% → ※行は8%: 213 + 437 = 650
      ctrl().startReceipt(receiptOf(
          yen: 650,
          date: day,
          items: [itemOf(198, mark: true), itemOf(398)]));
      ctrl().startBatchItemize();
      expect(st().batchItems, hasLength(2));
      ctrl().setBatchHeaderTax(10);
      expect(st().batchItemAmount(st().batchItems![0]), 213); // ※→8%
      expect(st().batchItemAmount(st().batchItems![1]), 437);

      ctrl().tapBatchItem(0); // D1選択
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().batchItems![0].categoryId, foodId);
      expect(st().batchItems![0].selected, isFalse); // 割当後は選択解除
      expect(st().canSave, isFalse); // 残り437が未割当=差額あり・差額カテゴリなし

      ctrl().tapBatchItem(1);
      ctrl().tapCategory(
          categoryId: dailyId, hasSubs: false, isSameGroup: false);
      expect(st().batchDiff, 0);
      expect(st().canSave, isTrue);

      await ctrl().save();
      final txs =
          await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      expect(txs, hasLength(2));
      expect(txs.map((t) => t.amountYen).toSet(), {213, 437});
      final gids = txs.map((t) => t.splitGroupId).toSet();
      expect(gids, hasLength(1));
      expect(gids.single, isNotNull);
    });

    test('D2: 塗り分け（同色再タップで剥がす）と行の%上書き', () {
      ctrl().startReceipt(
          receiptOf(yen: 1000, date: day, items: [itemOf(300), itemOf(500)]));
      ctrl().startBatchItemize();
      ctrl().setBatchPaintMode(true);
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().batchPaintCategoryId, foodId);
      ctrl().tapBatchItem(0);
      expect(st().batchItems![0].categoryId, foodId);
      ctrl().tapBatchItem(0); // 再タップで剥がす
      expect(st().batchItems![0].categoryId, isNull);

      // 行の%上書き: ヘッダ内税のまま行だけ外税8%
      ctrl().setBatchItemTax(1, 8);
      expect(st().batchItemAmount(st().batchItems![1]), 540);
      ctrl().setBatchItemTax(1, 8); // 再タップでヘッダ既定へ
      expect(st().batchItemAmount(st().batchItems![1]), 500);
    });

    test('差額: 未割当分を差額行として保存（合計一致）', () async {
      ctrl().startReceipt(
          receiptOf(yen: 700, date: day, items: [itemOf(300), itemOf(350)]));
      ctrl().startBatchItemize();
      ctrl().tapBatchItem(0);
      ctrl().tapBatchItem(1);
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      expect(st().batchDiff, 50); // 読み落とし分
      expect(st().canSave, isFalse);
      ctrl().setBatchDiffCategory(dailyId);
      expect(st().canSave, isTrue);

      await ctrl().save();
      final txs =
          await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      expect(txs.fold(0, (a, t) => a + t.amountYen), 700);
      expect(txs.map((t) => t.splitGroupId).toSet(), hasLength(1));
    });

    test('開き直し: グループを詳細入力で開いて置換保存（groupId引き継ぎ）', () async {
      // まず分割保存で2件のグループを作る
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDoubleZero();
      ctrl().tapDigit(0); // 1000
      ctrl().startSplit();
      ctrl().splitTapDigit(3);
      ctrl().splitTapDoubleZero(); // 300
      ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
      ctrl().setActiveSplit(1);
      ctrl().tapCategory(
          categoryId: dailyId, hasSubs: false, isSameGroup: false);
      await ctrl().save();
      var txs = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      final gid = txs.first.splitGroupId;
      expect(gid, isNotNull);
      final oldIds = txs.map((t) => t.id).toSet();

      // 開き直し → 行1を350に修正して保存
      ctrl().startEditSplitGroup(txs);
      expect(st().amountYen, 1000);
      expect(st().splits, hasLength(3)); // 保存済み2行＋末尾の空残額行
      ctrl().setActiveSplit(0);
      ctrl().splitBackspace();
      ctrl().splitBackspace();
      ctrl().splitTapDigit(5);
      ctrl().splitTapDigit(0); // 300 → 350
      // 合計1000に合わせて行2も直す: 700 → 650
      ctrl().setActiveSplit(1);
      for (var i = 0; i < 3; i++) {
        ctrl().splitBackspace();
      }
      ctrl().splitTapDigit(6);
      ctrl().splitTapDigit(5);
      ctrl().splitTapDigit(0);
      expect(st().canSave, isTrue);
      await ctrl().save();

      txs = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
      expect(txs, hasLength(2)); // 置換（増殖しない）
      expect(txs.map((t) => t.amountYen).toSet(), {350, 650});
      expect(txs.map((t) => t.splitGroupId).toSet().single, gid); // 引き継ぎ
      expect(txs.map((t) => t.id).toSet().intersection(oldIds), isEmpty);
    });
  });

  test('保存で正解ラベルがフィクスチャへ書き戻る（普通に使う=ラベル付きデータ）', () async {
    // スキャン相当: フィクスチャを記録
    final recorder = c.read(ocrFixtureRecorderProvider);
    final fixturePath = recorder.record(const [
      OcrBlock(text: '合計 ¥650', rect: OcrRect(0.1, 0.5, 0.8, 0.03), confidence: 0.9),
    ]);

    // 確認画面で金額を候補切替で修正して保存（人間の確定値=700）
    ctrl().startReceipt(receiptOf(yen: 650, date: day, store: 'サミット'),
        fixturePath: fixturePath);
    ctrl().selectTotalCandidate(const AmountCandidate(
        yen: 700,
        confidence: ExtractionConfidence.medium,
        sourceText: 'クレジット',
        reason: 'payment-line'));
    ctrl().tapCategory(categoryId: foodId, hasSubs: false, isSameGroup: false);
    await ctrl().save();

    final fx = loadFixture(fixturePath);
    expect(fx.expectedTotalYen, 700); // 確定値がexpectedに
    expect(fx.expectedDate, day);
  });

  test('startReceipt: 店名を店舗名にプリフィル・詳細メモは空 / 無ければ空', () {
    ctrl().startReceipt(receiptOf(yen: 500, date: day, store: 'スーパーA'));
    expect(st().storeName, 'スーパーA');
    expect(st().memo, ''); // 店名は詳細メモに混ぜない

    ctrl().startReceipt(receiptOf(yen: 500, date: day));
    expect(st().storeName, '');
    expect(st().memo, '');
  });

  test('レシート保存: 保持OFFで一時画像が消える', () async {
    final tmp = File('${h.root.path}${Platform.pathSeparator}r1.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    ctrl().startReceipt(receiptOf(yen: 500, date: day), imagePath: tmp.path);
    ctrl().selectCategory(foodId);
    await ctrl().save();
    expect(tmp.existsSync(), isFalse);
    final tx =
        (await c.read(transactionRepositoryProvider).forMonth(2026, 7)).single;
    expect(tx.imagePath, isNull);
    expect(tx.source, TxnSource.receiptOcr);
  });

  test('レシート保存: 保持ONで画像がimagesDirへ移動しパスが残る', () async {
    await c.read(appSettingsProvider.notifier).setRetainReceiptImages(true);
    final tmp = File('${h.root.path}${Platform.pathSeparator}r2.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    ctrl().startReceipt(receiptOf(yen: 500, date: day), imagePath: tmp.path);
    ctrl().selectCategory(foodId);
    await ctrl().save();
    expect(tmp.existsSync(), isFalse);
    final tx =
        (await c.read(transactionRepositoryProvider).forMonth(2026, 7)).single;
    expect(tx.imagePath, isNotNull);
    expect(File(tx.imagePath!).existsSync(), isTrue);
    expect(tx.imagePath!, contains(h.imagesDir.path));
  });

  group('内訳チップの状態機械', () {
    test('内訳ありカテゴリのタップ: 選択＋チップ列が開く', () {
      ctrl().startCreate(day);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      expect(st().categoryId, 1);
      expect(st().expandedParentId, 1);
    });

    test('内訳なしカテゴリのタップ: 選択のみ・チップ列は閉じる', () {
      ctrl().startCreate(day);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().tapCategory(categoryId: 4, hasSubs: false, isSameGroup: false);
      expect(st().categoryId, 4);
      expect(st().expandedParentId, isNull);
    });

    test('チップ選択でチップ列が自動格納される（テンキーのオーバーレイを閉じる）', () {
      ctrl().startCreate(day);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      expect(st().expandedParentId, 1);
      ctrl().toggleSubcategory(2); // 内訳を選択
      expect(st().categoryId, 2);
      expect(st().expandedParentId, isNull); // 選択と同時に格納
    });

    test('同じ親の再タップ: チップ列の開閉のみ・選択は維持', () {
      ctrl().startCreate(day);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().toggleSubcategory(2); // 内訳を選択（チップ列は自動格納）
      expect(st().categoryId, 2);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: true); // 再展開
      expect(st().expandedParentId, 1);
      expect(st().categoryId, 2); // 再展開でも選択維持
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: true); // 格納
      expect(st().expandedParentId, isNull);
      expect(st().categoryId, 2); // 選択は維持（確定挙動）
    });

    test('チップ再タップで親に戻る（列は再度格納）', () {
      ctrl().startCreate(day);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().toggleSubcategory(2);
      expect(st().categoryId, 2);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: true); // 再展開
      ctrl().toggleSubcategory(2); // 選択中チップの再タップ
      expect(st().categoryId, 1); // 親に計上する状態へ
      expect(st().expandedParentId, isNull);
    });

    test('setTypeで選択とチップ列が両方クリアされる', () {
      ctrl().startCreate(day);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().setType(TxnType.income);
      expect(st().categoryId, isNull);
      expect(st().expandedParentId, isNull);
    });

    test('saveAndContinue後はチップ列が閉じる', () async {
      ctrl().startCreate(day);
      ctrl().tapDigit(5);
      ctrl().tapCategory(categoryId: foodId, hasSubs: true, isSameGroup: false);
      expect(st().expandedParentId, foodId);
      await ctrl().saveAndContinue();
      expect(st().expandedParentId, isNull); // 再初期化でチップ列も閉じる
      expect(st().categoryId, isNull);
    });
  });

  group('小数通貨の入力', () {
    test('JPY(既定): 小数点キーは無効・整数のまま', () {
      ctrl().startCreate(day);
      ctrl().tapDigit(1);
      ctrl().tapDigit(2);
      ctrl().tapDecimal(); // decimals=0 → 無視
      ctrl().tapDigit(5);
      expect(st().amountText, '125');
      expect(st().amountYen, 125);
    });

    test('USD(小数2桁): 12 . 5 0 → amountYen=1250 cent', () async {
      final hu = await createHarness(
          prefs: {'onboardingDone': true, 'locale': 'en', 'currency': 'USD'});
      addTearDown(hu.dispose);
      final cu = ProviderContainer(overrides: hu.overrides());
      addTearDown(cu.dispose);
      final ctl = cu.read(entryFormControllerProvider.notifier);
      ctl.startCreate(day);
      ctl.tapDigit(1);
      ctl.tapDigit(2);
      ctl.tapDecimal();
      ctl.tapDigit(5);
      ctl.tapDigit(0);
      final s = cu.read(entryFormControllerProvider)!;
      expect(s.amountText, '12.50');
      expect(s.amountYen, 1250); // $12.50 = 1250 cent
      // 小数3桁目は無視（上限=2）
      ctl.tapDigit(9);
      expect(cu.read(entryFormControllerProvider)!.amountText, '12.50');
    });

    test('taxProfile: JPYは日本税・USDは税なし', () async {
      expect(c.read(taxProfileProvider).enabled, isTrue); // 既定JPY
      expect(c.read(taxProfileProvider).reducedRateSupported, isTrue);
      final hu = await createHarness(
          prefs: {'onboardingDone': true, 'currency': 'USD'});
      addTearDown(hu.dispose);
      final cu = ProviderContainer(overrides: hu.overrides());
      addTearDown(cu.dispose);
      expect(cu.read(taxProfileProvider).enabled, isFalse);
      expect(cu.read(taxProfileProvider).reducedRateSupported, isFalse);
    });

    test('USD: バックスペースは1文字ずつ', () async {
      final hu = await createHarness(
          prefs: {'onboardingDone': true, 'locale': 'en', 'currency': 'USD'});
      addTearDown(hu.dispose);
      final cu = ProviderContainer(overrides: hu.overrides());
      addTearDown(cu.dispose);
      final ctl = cu.read(entryFormControllerProvider.notifier);
      ctl.startCreate(day);
      for (final d in [1, 2, -1, 5]) {
        if (d == -1) {
          ctl.tapDecimal();
        } else {
          ctl.tapDigit(d);
        }
      }
      expect(cu.read(entryFormControllerProvider)!.amountText, '12.5');
      ctl.backspace(); // "12."
      ctl.backspace(); // "12"
      final s = cu.read(entryFormControllerProvider)!;
      expect(s.amountText, '12');
      expect(s.amountYen, 1200); // $12.00
    });
  });
}
