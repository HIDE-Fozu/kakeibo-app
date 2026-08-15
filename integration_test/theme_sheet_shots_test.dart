import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-08-15「色」統合の目視確認用スクショ（使い捨て）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 120));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme sheet shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 設定 → 色シート
    await t.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.byIcon(Icons.settings)));
    await settle(t);
    await t.scrollUntilVisible(
        find.byKey(const Key('theme-color-tile')), 200);
    await settle(t);
    await shot(t, 'ts_1_settings_tile');
    await t.tap(find.byKey(const Key('theme-color-tile')));
    await settle(t);
    await shot(t, 'ts_2_sheet_default');

    // グリーンをタップ → ライブプレビュー
    await t.tap(find.byKey(const Key('theme-preset-1')));
    await settle(t);
    await shot(t, 'ts_3_sheet_green');
    // 適用 → カレンダーで導出色を確認
    await t.tap(find.byKey(const Key('theme-apply')));
    await settle(t);
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month)));
    await settle(t);
    await shot(t, 'ts_4_calendar_green');

    // 入力画面も
    await t.tap(find.byKey(const Key('fab-entry')));
    await settle(t);
    await shot(t, 'ts_5_entry_green');
    await t.tap(find.byIcon(Icons.arrow_back).first, warnIfMissed: false);
    await settle(t);

    // ローズも一周
    await t.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.byIcon(Icons.settings)));
    await settle(t);
    await t.scrollUntilVisible(
        find.byKey(const Key('theme-color-tile')), 200);
    await settle(t);
    await t.tap(find.byKey(const Key('theme-color-tile')));
    await settle(t);
    await t.tap(find.byKey(const Key('theme-preset-4')));
    await settle(t);
    await t.tap(find.byKey(const Key('theme-apply')));
    await settle(t);
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month)));
    await settle(t);
    await shot(t, 'ts_6_calendar_rose');
  });
}
