import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

ParsedReceipt receiptOf({int? yen, required CivilDate date}) {
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
}
