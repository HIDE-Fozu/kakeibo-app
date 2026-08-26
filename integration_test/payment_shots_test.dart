import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payable_builder.dart';
import 'package:kakeibo_app/features/calendar/application/calendar_providers.dart';
import 'package:kakeibo_app/features/payment/application/payment_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 支払い区分モード（2026-08-26要望）の目視確認（使い捨て）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('payment mode shots', (t) async {
    SharedPreferences.setMockInitialValues({
      'onboardingDone': true,
      'chorePermissionAsked': true,
      'paymentModeEnabled': true,
    });
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    final c = ProviderScope.containerOf(
        t.element(find.byType(MaterialApp).first),
        listen: false);
    final cats = await c.read(categoryRepositoryProvider).active();
    final food = cats.firstWhere((x) => x.name == '食費');
    final today = c.read(clockProvider)();

    final cardId = await c.read(paymentCardRepositoryProvider).add(
        const PaymentCardEntity(
            name: '楽天カード', payDay: 27, annualRatePercent: 15.0));

    // 今月10日にカードで 32,000円、現金で 800円
    final buyDay = CivilDate(today.year, today.month, 10);
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: 32000,
            date: buyDay,
            categoryId: food.id,
            storeName: '家電量販店',
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: 32000,
          purchaseDate: buyDay,
        ));
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 800,
        date: buyDay,
        categoryId: food.id,
        storeName: 'コンビニ',
        source: TxnSource.manual));
    await settle(t);

    // 1) 購入日: 「未払」バッジ付きの行（現金の行と並ぶ）
    c.read(selectedDayProvider.notifier).select(buyDay);
    await settle(t);
    await shot(t, 'payment_1_purchase_day');

    // 2) 数え方の切り替えシート
    await t.tap(find.byKey(const Key('summary-basis-gear')));
    await settle(t);
    await shot(t, 'payment_2_basis_sheet');
    await t.tap(find.byKey(const Key('summary-basis-cash')));
    await settle(t);

    // 3) 引き落とし日（翌月27日・営業日調整済み）
    final nextMonth = today.month == 12
        ? CivilDate(today.year + 1, 1, 27)
        : CivilDate(today.year, today.month + 1, 27);
    c.read(currentMonthProvider.notifier).set(nextMonth.year, nextMonth.month);
    await settle(t);
    final lines = c.read(cardPaymentsProvider((nextMonth.year, nextMonth.month)));
    c.read(selectedDayProvider.notifier).select(lines.single.date);
    await settle(t);
    await shot(t, 'payment_3_billing_day');

    // 4) 設定のカード管理
    await t.tap(find.text('設定'));
    await settle(t);
    await t.scrollUntilVisible(find.byKey(const Key('payment-cards-tile')), 200,
        scrollable: find.byType(Scrollable).first);
    await shot(t, 'payment_4_settings');
    await t.tap(find.byKey(const Key('payment-cards-tile')));
    await settle(t);
    await t.tap(find.byKey(const Key('payment-card-1')));
    await settle(t);
    await shot(t, 'payment_5_card_edit');
  });
}
