import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/features/recurring/presentation/installment_page.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

void main() {
  testWidgets('分割払い: 33,000円・10回・17%・カード名 → 10取引＋カード保存',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    // 固定時計は 2026-07-15。既定 = 支払日15日・来月から → 初回 2026-08-15
    await pumpApp(tester, h, home: const InstallmentPage());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('installment-amount')), '33000');
    await tester.enterText(find.byKey(const Key('installment-rate')), '17');
    await tester.enterText(
        find.byKey(const Key('installment-card-name')), '楽天カード');
    await tester.pumpAndSettle();

    // カテゴリを選ぶまで保存は無効
    final saveBtn = find.byKey(const Key('installment-save'));
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('installment-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('installment-category')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('食費').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    // プレビュー: 月々3,562×10回・初回3,567・手数料2,625・総額35,625
    await tester.ensureVisible(find.byKey(const Key('installment-preview')));
    expect(find.textContaining('¥3,562'), findsWidgets);
    expect(find.textContaining('¥2,625'), findsOneWidget);
    expect(find.textContaining('¥35,625'), findsOneWidget);

    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 2026-08 から10ヶ月・毎月15日・初回だけ3,567
    final c = containerOf(tester);
    final repo = c.read(transactionRepositoryProvider);
    final aug = await repo.forMonth(2026, 8);
    expect(aug, hasLength(1));
    expect(aug.single.amountYen, 3567);
    expect(aug.single.date, const CivilDate(2026, 8, 15));
    expect(aug.single.storeName, '楽天カード');
    expect(aug.single.memo, '分割払い 1/10回');
    expect(aug.single.type, TxnType.expense);
    final sep = await repo.forMonth(2026, 9);
    expect(sep.single.amountYen, 3562);
    expect(sep.single.memo, '分割払い 2/10回');
    final may = await repo.forMonth(2027, 5); // 10回目
    expect(may.single.amountYen, 3562);
    expect(may.single.memo, '分割払い 10/10回');
    expect(await repo.forMonth(2027, 6), isEmpty);

    // カードが保存されている（名称＋年率）
    final cards = c.read(appSettingsProvider).installmentCards;
    expect(cards, hasLength(1));
    expect(cards.single.name, '楽天カード');
    expect(cards.single.annualRatePercent, 17.0);

    // 計画が保存され、取引が紐づいている（streamはfake asyncで固まるのでrunAsync）
    final plans = (await tester.runAsync(
        () => c.read(installmentPlanRepositoryProvider).watchAll().first))!;
    expect(plans, hasLength(1));
    expect(plans.single.principalMinor, 33000);
    expect(plans.single.count, 10);
    expect(plans.single.startYm, 202608);
    expect(aug.single.installmentPlanId, plans.single.id);
  });

  testWidgets('編集: 回数を変えて保存すると取引が作り直される・削除で消える',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    // 事前に計画を登録（リポジトリ直で3回払い・DBはハーネス側で永続）
    await pumpApp(tester, h, home: const SizedBox());
    await tester.pumpAndSettle();
    var c = containerOf(tester);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final planId = await c.read(installmentPlanRepositoryProvider).add(
      InstallmentPlanEntity(
        principalMinor: 30000,
        count: 3,
        annualRatePercent: 0,
        categoryId: foodId,
        dayOfMonth: 15,
        startYm: 202609,
      ),
      [
        for (var i = 0; i < 3; i++)
          TransactionEntity(
            type: TxnType.expense,
            amountYen: 10000,
            date: CivilDate(2026, 9 + i, 15),
            categoryId: foodId,
            memo: '分割払い ${i + 1}/3回',
            source: TxnSource.manual,
          ),
      ],
    );
    final plan = (await tester.runAsync(() =>
            c.read(installmentPlanRepositoryProvider).watchAll().first))!
        .singleWhere((p) => p.id == planId);

    // 編集ページを開く（pushで開く: 保存/削除の pop で履歴が空にならない）
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute(builder: (_) => InstallmentPage(plan: plan)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('installment-amount')))
            .controller!
            .text,
        '30000');

    // 回数を2回へ → 保存 → 取引が作り直される
    await tester.tap(find.byKey(const Key('installment-count')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2回').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('installment-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('installment-save')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    var txRepo = c.read(transactionRepositoryProvider);
    expect((await txRepo.forMonth(2026, 9)).single.amountYen, 15000);
    expect(await txRepo.forMonth(2026, 11), isEmpty); // 旧3回目は消えた

    // もう一度開いて削除 → 取引ごと消える
    final plan2 = (await tester.runAsync(() =>
            c.read(installmentPlanRepositoryProvider).watchAll().first))!
        .singleWhere((p) => p.id == planId);
    expect(plan2.count, 2);
    nav.push(MaterialPageRoute(builder: (_) => InstallmentPage(plan: plan2)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('installment-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('installment-delete-confirm')));
    await tester.pumpAndSettle();
    expect(await txRepo.forMonth(2026, 9), isEmpty);
    expect(
        await tester.runAsync(() =>
            c.read(installmentPlanRepositoryProvider).watchAll().first),
        isEmpty);
  });

  testWidgets('登録済みカードを選ぶと年率が入る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const InstallmentPage());
    await tester.pumpAndSettle();
    final c = containerOf(tester);
    await c
        .read(appSettingsProvider.notifier)
        .saveInstallmentCard('楽天カード', 17.0);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('installment-card-pick')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('楽天カード（17%）').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
        tester
            .widget<TextField>(find.byKey(const Key('installment-rate')))
            .controller!
            .text,
        '17');
    expect(
        tester
            .widget<TextField>(
                find.byKey(const Key('installment-card-name')))
            .controller!
            .text,
        '楽天カード');
  });
}
