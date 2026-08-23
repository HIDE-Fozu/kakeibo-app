import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../support/test_app.dart';
import 'calendar_chore_ghost_test.dart' show containerOf, foodCategoryId;

/// 毎月の予算（設定でオンオフ・毎月共通の1金額・2026-08-23要望）。
/// 固定時計 = 2026-07-15（createHarness既定）。
void main() {
  testWidgets('既定オフ: 上部サマリに予算行は出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.byKey(const Key('budget-line')), findsNothing);
  });

  testWidgets('設定でオン→金額を入れると上部サマリに「予算の残り」が出る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);

    // 今日（7/15）に支出 30,000
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 30000,
        date: const CivilDate(2026, 7, 15),
        categoryId: await foodCategoryId(c),
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    // 設定タブ → 予算オン
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    // 金額タイルはオンにするまで出ない
    expect(find.byKey(const Key('budget-amount-tile')), findsNothing);
    await tester.scrollUntilVisible(
        find.byKey(const Key('budget-switch')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('budget-switch')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.byKey(const Key('budget-amount-tile')), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('budget-amount-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget-amount-field')), '50000');
    await tester.tap(find.byKey(const Key('budget-amount-save')));
    await tester.pumpAndSettle();
    expect(h.prefs.getInt('monthlyBudgetMinor'), 50000);

    // カレンダーへ戻ると「予算の残り ¥20,000」（= 50,000 − 支出 30,000）
    await tester.tap(find.text('カレンダー'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget-line')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('budget-line')),
            matching: find.text('¥20,000')),
        findsOneWidget);
  });

  testWidgets('使いすぎ: 残りがマイナスでも出る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'budgetEnabled': true,
      'monthlyBudgetMinor': 20000,
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);

    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 30000,
        date: const CivilDate(2026, 7, 15),
        categoryId: await foodCategoryId(c),
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    expect(
        find.descendant(
            of: find.byKey(const Key('budget-line')),
            matching: find.text('-¥10,000')),
        findsOneWidget);
  });

  testWidgets('オンでも金額0なら行は出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'budgetEnabled': true,
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.byKey(const Key('budget-line')), findsNothing);
  });
}
