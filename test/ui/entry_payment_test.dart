import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';
import 'calendar_chore_ghost_test.dart' show containerOf, foodCategoryId;

const day = CivilDate(2026, 8, 10);

/// 入力画面の支払い区分。カードを選ぶと未払金ができ、翌月の引き落としに乗る。
void main() {
  testWidgets('モードOFF: 支払い区分のボタンは出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-payment-btn')), findsNothing);
  });

  testWidgets('モードON: 既定は現金。カードを選ぶとボタンの表示が変わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'paymentModeEnabled': true,
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(name: '楽天カード', payDay: 27));
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    final btn = find.byKey(const Key('entry-payment-btn'));
    expect(btn, findsOneWidget);
    expect(find.descendant(of: btn, matching: find.text('現金')), findsOneWidget);

    await tester.tap(btn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment-pick-1')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: btn, matching: find.text('楽天カード')),
        findsOneWidget);

    // 現金に戻せる
    await tester.tap(btn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment-pick-cash')));
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.paymentCardId, isNull);
  });

  testWidgets('カードで保存すると未払金ができ、翌月の支払いに乗る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'paymentModeEnabled': true,
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final cardId = await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final catId = await foodCategoryId(c);

    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();
    ctrl.tapCategory(categoryId: catId, hasSubs: false, isSameGroup: false);
    for (final d in [3, 0, 0, 0]) {
      ctrl.tapDigit(d);
    }
    ctrl.setPaymentCard(cardId);
    await ctrl.save();
    await tester.pumpAndSettle();

    // 購入取引は買った日（8/10）に立つ
    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 8);
    expect(txs.single.amountYen, 3000);
    expect(txs.single.date, day);

    // 未払金は9月の引き落としに乗る（月末締め・翌月払い）
    final p = await c
        .read(payableRepositoryProvider)
        .forTransaction(txs.single.id!);
    expect(p, isNotNull);
    expect(p!.cardId, cardId);
    expect(p.installmentCount, 1);
    expect(p.schedule.single.ym, 202609);
    expect(p.schedule.single.amountMinor, 3000);
  });

  testWidgets('現金のまま保存すれば未払金はできない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'paymentModeEnabled': true,
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final catId = await foodCategoryId(c);

    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();
    ctrl.tapCategory(categoryId: catId, hasSubs: false, isSameGroup: false);
    for (final d in [8, 0, 0]) {
      ctrl.tapDigit(d);
    }
    await ctrl.save();
    await tester.pumpAndSettle();

    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 8);
    expect(
        await c.read(payableRepositoryProvider).forTransaction(txs.single.id!),
        isNull);
  });

  testWidgets('収入はカードを選んでも未払金にならない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'paymentModeEnabled': true,
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final cardId = await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final cats = await waitForData(c, allCategoriesProvider);
    final incomeCat =
        cats.firstWhere((x) => x.type == CategoryType.income && !x.isSystem);

    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();
    ctrl.setType(TxnType.income);
    ctrl.tapCategory(
        categoryId: incomeCat.id, hasSubs: false, isSameGroup: false);
    for (final d in [5, 0, 0, 0]) {
      ctrl.tapDigit(d);
    }
    ctrl.setPaymentCard(cardId);
    await ctrl.save();
    await tester.pumpAndSettle();

    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 8);
    expect(
        await c.read(payableRepositoryProvider).forTransaction(txs.single.id!),
        isNull);
  });
}
