import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payable_builder.dart';
import 'package:kakeibo_app/features/calendar/application/calendar_providers.dart';

import '../support/test_app.dart';
import 'calendar_chore_ghost_test.dart' show containerOf, foodCategoryId;

/// 支払い区分の表示。固定時計 = 2026-07-15（createHarness既定）。
/// 要点は「購入か引き落としのどちらか一方しか数えない（二重計上しない）」。
void main() {
  Map<String, Object> paymentPrefs({bool cashBasis = true}) => {
        'onboardingDone': true,
        'locale': 'ja',
        'paymentModeEnabled': true,
        'summaryBasisCash': cashBasis,
      };


  /// 7/10 にカードで3,000円買う。引き落としは8/27（木）。
  Future<int> buyOnCard(dynamic c, {int amount = 3000}) async {
    final cardId = await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: amount,
            date: const CivilDate(2026, 7, 10),
            categoryId: await foodCategoryId(c),
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: amount,
          purchaseDate: const CivilDate(2026, 7, 10),
        ));
    return cardId;
  }

  testWidgets('現金主義: 見出しが「支払い」になり、歯車で「支出」に戻せる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: paymentPrefs());
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    final cardFinder = find.byKey(const Key('month-summary-card'));
    expect(find.descendant(of: cardFinder, matching: find.text('支払い')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('summary-basis-gear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('summary-basis-accrual')));
    await tester.pumpAndSettle();

    expect(h.prefs.getBool('summaryBasisCash'), isFalse);
    expect(find.descendant(of: cardFinder, matching: find.text('支出')),
        findsOneWidget);
  });

  testWidgets('モードOFF: 歯車は出ない（切り替える意味がない）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.byKey(const Key('summary-basis-gear')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('month-summary-card')),
            matching: find.text('支出')),
        findsOneWidget);
  });

  testWidgets('購入日の行に「未払」バッジ、引き落とし日に引き落とし行が出る',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: paymentPrefs());
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);
    await buyOnCard(c);
    await tester.pumpAndSettle();

    // 7/10 の日別リスト
    c.read(selectedDayProvider.notifier).select(const CivilDate(2026, 7, 10));
    await tester.pumpAndSettle();
    expect(find.text('未払'), findsOneWidget);
    expect(find.text('楽天カード 引き落とし'), findsNothing);

    // 8/27（引き落とし日）へ移動
    c.read(currentMonthProvider.notifier).set(2026, 8);
    c.read(selectedDayProvider.notifier).select(const CivilDate(2026, 8, 27));
    await tester.pumpAndSettle();
    expect(find.text('楽天カード 引き落とし'), findsOneWidget);
    expect(find.text('¥3,000'), findsWidgets);
  });

  testWidgets('引き落とし日が日曜なら翌営業日にずれる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: paymentPrefs());
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);
    final cardId = await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: 5000,
            date: const CivilDate(2026, 8, 10),
            categoryId: await foodCategoryId(c),
            source: TxnSource.manual));
    // 8月購入 → 9/27（日）→ 9/28（月）へ
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: 5000,
          purchaseDate: const CivilDate(2026, 8, 10),
        ));
    await tester.pumpAndSettle();

    c.read(currentMonthProvider.notifier).set(2026, 9);
    c.read(selectedDayProvider.notifier).select(const CivilDate(2026, 9, 27));
    await tester.pumpAndSettle();
    expect(find.text('楽天カード 引き落とし'), findsNothing);

    c.read(selectedDayProvider.notifier).select(const CivilDate(2026, 9, 28));
    await tester.pumpAndSettle();
    expect(find.text('楽天カード 引き落とし'), findsOneWidget);
  });
}
