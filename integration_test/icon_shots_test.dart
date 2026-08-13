import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/data/db/category_seeds.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-08-11 カテゴリアイコン差し替えの目視確認用スクショ（使い捨て）:
/// 入力グリッド・選択状態・内訳の帯・カレンダー一覧・カテゴリ管理。
///
/// 実行: flutter drive --driver=test_driver/integration_test.dart \
///        --target=integration_test/icon_shots_test.dart -d `<sim udid>`

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 120));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)), warnIfMissed: false);
  await settle(t);
}

Future<void> typeDigits(WidgetTester t, String s) async {
  for (final ch in s.split('')) {
    await t.tap(
        find.descendant(of: find.byType(Numpad), matching: find.text(ch)).first);
    await t.pump(const Duration(milliseconds: 40));
  }
  await settle(t);
}

Future<void> tapCategory(WidgetTester t, String slug) async {
  await t.tap(
      find
          .descendant(
              of: find.byType(EntryScreen),
              matching: find.textContaining(seedCategoryName(slug, 'ja')))
          .first,
      warnIfMissed: false);
  await settle(t);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('category icon shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // デモ取引を数件（カレンダー一覧にアイコンを出すため）
    for (final (slug, amt) in const [
      ('food', '1280'),
      ('dailyGoods', '3480'),
      ('transport', '680'),
      ('utilities', '9800'),
    ]) {
      await tapKey(t, 'fab-entry');
      await typeDigits(t, amt);
      await tapCategory(t, slug);
      await tapKey(t, 'save-btn');
      await t.pumpAndSettle(const Duration(milliseconds: 250));
    }

    // 1) カレンダー（一覧のアイコン）
    await shot(t, 'icons_1_calendar');

    // 2) 入力画面のカテゴリグリッド（未選択）
    await tapKey(t, 'fab-entry');
    await typeDigits(t, '800');
    await shot(t, 'icons_2_grid');

    // 3) カテゴリ選択済み（選択中の見え方）
    await tapCategory(t, 'food');
    await shot(t, 'icons_3_selected');

    // 4) 内訳モードの帯（電卓の上に常設）
    await tapKey(t, 'start-split');
    await shot(t, 'icons_4_split_strip');

    // 5) 帯を2行に開いた状態
    await t.tap(find.byKey(const Key('split-pickcat-0')), warnIfMissed: false);
    await shot(t, 'icons_5_split_expanded');

    await tapKey(t, 'entry-back');

    // 6) 設定 → カテゴリ管理（親＋内訳の一覧）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.byIcon(Icons.settings)));
    await settle(t);
    await t.scrollUntilVisible(find.byKey(const Key('category-manage-tile')), 200,
        scrollable: find.byType(Scrollable).first);
    await settle(t);
    await tapKey(t, 'category-manage-tile');
    await shot(t, 'icons_6_category_manage');
  });
}
