import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payable_builder.dart';
import 'package:kakeibo_app/features/calendar/application/calendar_providers.dart';

import '../support/test_app.dart';
import 'calendar_chore_ghost_test.dart' show containerOf, foodCategoryId;

/// あとから分割。固定時計 = 2026-07-15。
void main() {
  final prefs = <String, Object>{
    'onboardingDone': true,
    'locale': 'ja',
    'paymentModeEnabled': true,
  };


  /// セルドロップダウンを開いて項目を選ぶ。メニューは ListView.builder で
  /// 遅延生成される上、選択中の項目を中央に置いて開くので、目的の項目は
  /// 現在位置の上にも下にもあり得る。両方向に探してから押す。
  Future<void> pickFromDropdown(
      WidgetTester tester, Key dropdown, String label) async {
    await tester.tap(find.byKey(dropdown), warnIfMissed: false);
    await tester.pumpAndSettle();
    final item = find.text(label);
    for (final dy in [-120.0, 120.0]) {
      for (var i = 0; i < 40 && item.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).last, Offset(0, dy));
        await tester.pump();
      }
      if (item.evaluate().isNotEmpty) break;
    }
    // 端に半分だけ出ている状態で押すと空振りするので、確実に見せてから押す。
    await tester.ensureVisible(item.last);
    await tester.pumpAndSettle();
    await tester.tap(item.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// 7/10 にカードで1万円。バッジをタップして詳細を開くところまで。
  Future<(ProviderContainer, int)> openDetail(
      WidgetTester tester, TestHarness h) async {
    await pumpApp(tester, h);
    final c = containerOf(tester);
    final cardId = await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(
            name: '楽天カード', payDay: 27, annualRatePercent: 15.0));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: 10000,
            date: const CivilDate(2026, 7, 10),
            categoryId: await foodCategoryId(c),
            storeName: '家電量販店',
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: 10000,
          purchaseDate: const CivilDate(2026, 7, 10),
        ));
    c.read(selectedDayProvider.notifier).select(const CivilDate(2026, 7, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('payable-badge-$txId')));
    await tester.pumpAndSettle();
    return (c, txId);
  }

  testWidgets('「未払」バッジから未払金の詳細が開く', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: prefs);
    addTearDown(h.dispose);
    await openDetail(tester, h);

    expect(find.text('未払金'), findsOneWidget);
    expect(find.text('家電量販店'), findsOneWidget);
    expect(find.text('1回（一括）'), findsOneWidget);
    expect(find.text('2026年8月'), findsWidgets); // 支払い開始月＝翌月
  });

  testWidgets('10回払いに変えると各月に割れ、合計＝総額で保存される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: prefs);
    addTearDown(h.dispose);
    final (c, txId) = await openDetail(tester, h);

    await pickFromDropdown(tester, const Key('payable-count'), '10回');
    // 手数料が乗るので総額は元本より大きい
    expect(find.text('うち手数料'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('payable-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payable-save')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    final p = await c.read(payableRepositoryProvider).forTransaction(txId);
    expect(p!.installmentCount, 10);
    expect(p.schedule, hasLength(10));
    expect(p.schedule.first.ym, 202608);
    expect(p.schedule.last.ym, 202705);
    expect(p.schedule.fold<int>(0, (a, s) => a + s.amountMinor), p.totalMinor);
    expect(p.totalMinor, greaterThan(10000));
  });

  testWidgets('10回払いを3回払いに再分割できる（同じオブジェクトのまま）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: prefs);
    addTearDown(h.dispose);
    final (c, txId) = await openDetail(tester, h);
    final before =
        (await c.read(payableRepositoryProvider).forTransaction(txId))!;

    await pickFromDropdown(tester, const Key('payable-count'), '10回');
    await tester.ensureVisible(find.byKey(const Key('payable-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payable-save')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    // もう一度開いて3回へ
    await tester.tap(find.byKey(ValueKey('payable-badge-$txId')));
    await tester.pumpAndSettle();
    await pickFromDropdown(tester, const Key('payable-count'), '3回');
    await tester.ensureVisible(find.byKey(const Key('payable-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payable-save')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    final after =
        (await c.read(payableRepositoryProvider).forTransaction(txId))!;
    expect(after.id, before.id); // 同一オブジェクト
    expect(after.installmentCount, 3);
    expect(after.schedule, hasLength(3)); // 10回分の行は残らない
  });

  testWidgets('支払い開始月を変えられる（「8月分じゃなく9月分」）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: prefs);
    addTearDown(h.dispose);
    final (c, txId) = await openDetail(tester, h);

    await pickFromDropdown(
        tester, const Key('payable-start-ym'), '2026年9月');
    await tester.ensureVisible(find.byKey(const Key('payable-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payable-save')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    final p = await c.read(payableRepositoryProvider).forTransaction(txId);
    expect(p!.schedule.single.ym, 202609);
  });

  testWidgets('未払金をやめると購入取引は残ったまま即時払いに戻る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: prefs);
    addTearDown(h.dispose);
    final (c, txId) = await openDetail(tester, h);

    await tester.tap(find.byKey(const Key('payable-remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payable-remove-confirm')));
    await tester.pumpAndSettle();

    expect(await c.read(payableRepositoryProvider).forTransaction(txId), isNull);
    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.amountYen, 10000);
    // バッジも消える
    expect(find.byKey(ValueKey('payable-badge-$txId')), findsNothing);
  });
}
