import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 上部サマリの歯車（計算方法／予算）の目視確認。
late IntegrationTestWidgetsFlutterBinding binding;

Future<void> shot(WidgetTester t, String name) async {
  await t.pumpAndSettle(const Duration(milliseconds: 300));
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('summary gear shots', (t) async {
    SharedPreferences.setMockInitialValues({
      'onboardingDone': true,
      'chorePermissionAsked': true,
      'paymentModeEnabled': true,
      'summaryBasisCash': true,
    });
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    await t.tap(find.byKey(const Key('summary-basis-gear')));
    await shot(t, 'gear_1_menu');

    await t.tap(find.byKey(const Key('summary-gear-basis')));
    await shot(t, 'gear_2_basis');
    await t.tapAt(const Offset(200, 100)); // 閉じる
    await t.pumpAndSettle(const Duration(milliseconds: 400));

    await t.tap(find.byKey(const Key('summary-basis-gear')));
    await t.pumpAndSettle(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const Key('summary-gear-budget')));
    await shot(t, 'gear_3_budget_off');
    await t.tap(find.byKey(const Key('summary-budget-switch')));
    await shot(t, 'gear_4_budget_on');
  });
}
