import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

/// 「合計 ¥1,080」「2026/07/14 12:34」を含む正準ブロック列（P3のパーサが抽出できる形）
const goodBlocks = [
  OcrBlock(text: 'スーパーA', rect: OcrRect(0.1, 0.05, 0.5, 0.03), confidence: 0.9),
  OcrBlock(
      text: '2026/07/14 12:34',
      rect: OcrRect(0.1, 0.12, 0.5, 0.03),
      confidence: 0.95),
  OcrBlock(
      text: '合計 ¥1,080', rect: OcrRect(0.1, 0.5, 0.8, 0.03), confidence: 0.99),
];

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

void main() {
  testWidgets('スキャン成功: レシート確認モードでプリフィルされる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final img = File('${h.root.path}${Platform.pathSeparator}cap.jpg')
      ..writeAsBytesSync([1]);
    await pumpApp(tester, h,
        home: const EntryScreen(),
        extra: [
          receiptCaptureProvider.overrideWith((ref) => FakeReceiptCapture(img.path)),
          ocrServiceProvider.overrideWith((ref) => const FakeOcrService(goodBlocks)),
        ]);
    final c = containerOf(tester);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-receipt')));
    await tester.pumpAndSettle();

    expect(find.text('レシート確認'), findsOneWidget);
    expect(find.text('¥1,080'), findsWidgets); // 金額表示＋候補chip
    expect(find.text('2026/07/14'), findsOneWidget); // 日付プリフィル
  });

  testWidgets('候補切替: chipタップで金額・日付が変わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);

    const cand1 = AmountCandidate(
        yen: 1080,
        confidence: ExtractionConfidence.high,
        sourceText: '合計 ¥1,080',
        reason: 'total');
    const cand2 = AmountCandidate(
        yen: 980,
        confidence: ExtractionConfidence.medium,
        sourceText: '¥980',
        reason: 'max-fallback');
    const d1 = DateCandidate(
        date: CivilDate(2026, 7, 14),
        confidence: ExtractionConfidence.high,
        sourceText: '2026/07/14',
        reason: 'issue');
    const d2 = DateCandidate(
        date: CivilDate(2026, 7, 13),
        confidence: ExtractionConfidence.medium,
        sourceText: '2026/07/13',
        reason: 'other');
    const parsed = ParsedReceipt(
        total: cand1,
        totalCandidates: [cand1, cand2],
        date: d1,
        dateCandidates: [d1, d2]);
    c.read(entryFormControllerProvider.notifier).startReceipt(parsed);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '¥980'));
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.amountYen, 980);

    await tester.tap(find.widgetWithText(ChoiceChip, '2026-07-13'));
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.date, const CivilDate(2026, 7, 13));
  });

  testWidgets('OCR空: 金額0＋注記＋今日既定（空フォームフォールバック）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final img = File('${h.root.path}${Platform.pathSeparator}cap2.jpg')
      ..writeAsBytesSync([1]);
    await pumpApp(tester, h,
        home: const EntryScreen(),
        extra: [
          receiptCaptureProvider.overrideWith((ref) => FakeReceiptCapture(img.path)),
          // 既定harness = FakeOcrService(const []) → 候補なし
        ]);
    final c = containerOf(tester);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-receipt')));
    await tester.pumpAndSettle();
    expect(find.text('レシート確認'), findsOneWidget);
    expect(find.text('¥0'), findsOneWidget);
    expect(find.byKey(const Key('ocr-fallback-note')), findsOneWidget);
    expect(find.text('2026/07/15'), findsOneWidget); // 今日既定（固定時計）
  });

  testWidgets('撮影未対応: SnackBarでcreateに留まる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen()); // 既定=Unavailable
    final c = containerOf(tester);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-receipt')));
    await tester.pumpAndSettle();
    expect(find.text('この端末ではレシート撮影を利用できません'), findsOneWidget);
    expect(find.text('入力'), findsOneWidget);

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
