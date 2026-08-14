import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-08-14 パレット差し替え（落ち着き×親しみやすさ）の目視確認用スクショ（使い捨て）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 120));

Future<void> tapIf(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return;
  await t.tap(f.first, warnIfMissed: false);
  await settle(t);
}

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('palette shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    await shot(t, 'pal_1_calendar');

    // 入力画面（金額を入れてカテゴリグリッドまで）
    await t.tap(find.byKey(const Key('fab-entry')));
    await settle(t);
    await shot(t, 'pal_2_entry_empty');
    Finder pad(String label) => find.descendant(
        of: find.byType(Numpad), matching: find.text(label));
    for (final d in ['8', '0', '0', '0', '8']) {
      await t.tap(pad(d), warnIfMissed: false);
    }
    await t.tap(find.byKey(const Key('np-00')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'pal_3_entry_amount');
    await t.tap(find.text('水道光熱費').first, warnIfMissed: false);
    await settle(t);
    await shot(t, 'pal_4_entry_selected');

    // 内訳
    await t.tap(find.byKey(const Key('start-split')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'pal_5_split');
    await t.tap(find.byKey(const Key('split-add')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'pal_6_split_two');
    await t.tap(find.byKey(const Key('split-pickcat-1')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'pal_7_strip_expanded');
    await tapIf(t, find.text('やめる'));
    await tapIf(t, find.byIcon(Icons.arrow_back));

    // 収入タブ
    await tapIf(t, find.byKey(const Key('fab-entry')));
    await tapIf(t, find.text('収入'));
    await shot(t, 'pal_8_income');
    await tapIf(t, find.byIcon(Icons.arrow_back));

    // 毎月 / サマリ / 設定
    Finder tab(IconData i) => find.descendant(
        of: find.byType(NavigationBar), matching: find.byIcon(i));
    await tapIf(t, tab(Icons.event_repeat));
    await shot(t, 'pal_9_monthly');
    await tapIf(t, tab(Icons.bar_chart));
    await shot(t, 'pal_10_summary');
    await tapIf(t, tab(Icons.settings));
    await shot(t, 'pal_11_settings');
  });
}
