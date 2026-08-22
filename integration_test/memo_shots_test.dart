import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 買い物メモ（メモタブ・2026-08-23）の目視確認（使い捨て）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shopping memo shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 1) メモタブ（空・ヒント表示）
    await t.tap(find.byKey(const Key('day-tab-memo')));
    await settle(t);
    await shot(t, 'memo_1_empty');

    // 2) 編集ページ＋入力
    await t.tap(find.byKey(const Key('shopping-memo-pad')));
    await settle(t);
    await t.enterText(find.byKey(const Key('shopping-memo-field')),
        '牛乳\nトイレットペーパー\nたまご');
    await settle(t);
    await shot(t, 'memo_2_editor');

    // 3) 完了で閉じた後のタブ表示
    await t.tap(find.byKey(const Key('shopping-memo-done')));
    await settle(t);
    await shot(t, 'memo_3_filled');
  });
}
