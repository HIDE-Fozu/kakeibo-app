import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/features/calendar/presentation/day_transaction_list.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

ReceiptItem itemOf(int yen, {bool mark = false}) => ReceiptItem(
    text: 'ﾃｽﾄﾋﾝ-$yen',
    yen: yen,
    rect: const OcrRect(0.05, 0.2, 0.9, 0.03),
    reducedTaxMark: mark);

ParsedReceipt parsedWithItems(int total, List<ReceiptItem> items) {
  final d = DateCandidate(
      date: day,
      confidence: ExtractionConfidence.high,
      sourceText: day.toIso(),
      reason: 'issue');
  return ParsedReceipt(
    total: AmountCandidate(
        yen: total,
        confidence: ExtractionConfidence.high,
        sourceText: '合計 ¥$total',
        reason: 'total'),
    totalCandidates: const [],
    date: d,
    dateCandidates: [d],
    storeName: 'サミット',
    itemLines: items,
  );
}

void main() {
  testWidgets('一括内訳: 詳細入力→D1割当→紙の照合→保存可能', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    ctrl.startReceipt(parsedWithItems(700, [itemOf(300), itemOf(400)]));
    await tester.pumpAndSettle();

    // OCR明細あり → 詳細入力ボタンで一括内訳が開く
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('batch-mode-toggle')), findsOneWidget);
    expect(find.byKey(const Key('batch-item-0')), findsOneWidget);
    // 画像なし → 行はOCRテキストにフォールバック
    expect(find.text('ﾃｽﾄﾋﾝ-300'), findsOneWidget);

    // D1: 2行選択 → グリッドで食費 → 全額割当（差額0）
    await tester.tap(find.byKey(const Key('batch-item-0')));
    await tester.tap(find.byKey(const Key('batch-item-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('選択中 2件'), findsOneWidget);
    c.read(entryFormControllerProvider.notifier).tapCategory(
        categoryId: foodId, hasSubs: false, isSameGroup: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('batch-total-row')), findsOneWidget);
    expect(find.textContaining('✓'), findsWidgets); // 合計一致
    expect(c.read(entryFormControllerProvider)!.canSave, isTrue);

    // 行の%上書き → 超過 → ✗表示
    await tester.tap(find.byKey(const Key('batch-tax10-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('超過'), findsOneWidget);
    expect(c.read(entryFormControllerProvider)!.canSave, isFalse);
  });

  testWidgets('日別一覧: 同一groupIdはC1グループカード・単独は通常行', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const Scaffold(body: DayTransactionList(day: day)));
    final c = containerOf(tester);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final dailyId = cats.firstWhere((x) => x.name == '日用品').id;
    final repo = c.read(transactionRepositoryProvider);

    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 300,
        date: day,
        categoryId: foodId,
        source: TxnSource.manual,
        memo: 'サミット',
        splitGroupId: 'g1'));
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 400,
        date: day,
        categoryId: dailyId,
        source: TxnSource.manual,
        memo: 'サミット',
        splitGroupId: 'g1'));
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 210,
        date: day,
        categoryId: foodId,
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('txg-g1')), findsOneWidget); // カード
    expect(find.text('サミット'), findsOneWidget); // ヘッダ（子はdenseでmemo非表示）
    expect(find.text('-¥700'), findsOneWidget); // グループ合計
    expect(find.text('-¥210'), findsOneWidget); // 単独行はそのまま

    // ヘッダタップ → 内訳入力で開き直し（保存済み2行＋末尾の空残額行・合計700）
    await tester.tap(find.byKey(const ValueKey('txg-head-g1')));
    await tester.pumpAndSettle();
    final st = c.read(entryFormControllerProvider)!;
    expect(st.splits, hasLength(3));
    expect(st.amountYen, 700);
    expect(st.replacesTxIds, hasLength(2));
    // 分割UIが出ている（行のカテゴリチップと残額行で確認）。
    expect(find.byKey(const Key('split-pickcat-0')), findsOneWidget);
    expect(find.byKey(const Key('split-line-remainder')), findsOneWidget);
  });
}
