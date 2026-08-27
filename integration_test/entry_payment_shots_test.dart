import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 入力ページの支払い区分ボタン（日付の右隣）とカード追加の目視確認。
late IntegrationTestWidgetsFlutterBinding binding;

Future<void> shot(WidgetTester t, String name) async {
  await t.pumpAndSettle(const Duration(milliseconds: 300));
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('entry payment shots', (t) async {
    SharedPreferences.setMockInitialValues({
      'onboardingDone': true,
      'chorePermissionAsked': true,
      'paymentModeEnabled': true,
      'summaryBasisCash': true,
    });
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    await t.tap(find.byKey(const Key('fab-entry')));
    await shot(t, 'entry_1_cash_beside_date');

    await t.tap(find.byKey(const Key('entry-payment-btn')));
    await shot(t, 'entry_2_picker_with_add');

    await t.tap(find.byKey(const Key('payment-pick-add')));
    await shot(t, 'entry_3_add_card_page');
    // 保存まではウィジェットテスト（payment_display_test.dart）が見ている。
    // ここはソフトキーボードが保存ボタンを隠すので撮るだけにする。
  });
}
