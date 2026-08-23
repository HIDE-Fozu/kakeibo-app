import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 毎月の予算（2026-08-23要望）の目視確認（使い捨て）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('budget shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 当月の支出を1件（予算の残りが引き算で確認できるように）
    final c = ProviderScope.containerOf(
        t.element(find.byType(MaterialApp).first),
        listen: false);
    final cats = await c.read(categoryRepositoryProvider).active();
    final food = cats.firstWhere((x) => x.name == '食費');
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 32000,
        date: c.read(clockProvider)(),
        categoryId: food.id,
        storeName: 'スーパー',
        source: TxnSource.manual));
    await settle(t);

    // 1) 設定: 予算オフ（既定）→ オンにすると金額行が出る
    await t.tap(find.text('設定'));
    await settle(t);
    await t.scrollUntilVisible(find.byKey(const Key('budget-switch')), 200,
        scrollable: find.byType(Scrollable).first);
    await shot(t, 'budget_1_settings_off');
    await t.tap(find.byKey(const Key('budget-switch')));
    await settle(t);
    await shot(t, 'budget_2_settings_on');

    // 2) 金額入力ダイアログ
    await t.tap(find.byKey(const Key('budget-amount-tile')));
    await settle(t);
    await t.enterText(find.byKey(const Key('budget-amount-field')), '50000');
    await settle(t);
    await shot(t, 'budget_3_amount_dialog');
    await t.tap(find.byKey(const Key('budget-amount-save')));
    await settle(t);

    // 3) カレンダー上部サマリに「予算の残り」（50,000 − 32,000 = 18,000）
    await t.tap(find.text('カレンダー'));
    await settle(t);
    await shot(t, 'budget_4_calendar');
  });
}
