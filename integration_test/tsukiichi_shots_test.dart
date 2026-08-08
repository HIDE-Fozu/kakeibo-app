import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v2.2.0（つきいち合体）UIの目視確認用スクショ撮影（使い捨てハーネス）。
/// 実行例（実行前に app を uninstall しておく）:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/tsukiichi_shots_test.dart -d `<udid>`
///
/// 実時計で動く。撮るもの:
/// 毎月タブ（空/ルール+タスク+見込み）→ 統合カレンダー（ゴースト+凡例+見込み行）
/// → 基準日シート → 入力の「毎月の費用」トグル → 保存後の毎月タブ。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

/// 日付ドロップダウン（1..31）はメニューが遅延構築で遠い項目が木に無いため、
/// メニュー内をスクロールしながら該当項目を出してからタップする。
/// 注意: `.last` 付きファインダは空一致で "Bad state" を投げるので
/// scrollUntilVisible には素のファインダを渡す（既知の罠）。
Future<void> pickDropdownDay(WidgetTester t, int day) async {
  await t.testTextInput.receiveAction(TextInputAction.done); // キーボードを閉じる
  await settle(t);
  await t.ensureVisible(find.byKey(const Key('recurring-day')));
  await settle(t);
  await t.tap(find.byKey(const Key('recurring-day')), warnIfMissed: false);
  await settle(t);
  await pickCellMenuItem(t, find.text('$day日'));
}

/// セル幅メニュー（cell_dropdown）の項目を選ぶ。メニューは遅延構築＋
/// コンパクト高（約5.5行）なので、見えるまでスクロールしてからタップする。
Future<void> pickCellMenuItem(WidgetTester t, Finder item) async {
  await t.scrollUntilVisible(item, 88,
      scrollable: find.byType(Scrollable).last);
  await settle(t);
  await t.tap(item, warnIfMissed: false);
  await settle(t);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tsukiichi merge UI shots', (t) async {
    // chorePermissionAsked: 初回記録時の通知許可ダイアログ（OSモーダル）で
    // createTask の await が止まるのを防ぐ（simではダイアログを閉じられない）。
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 毎月タブ（空状態）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_repeat)));
    await settle(t);
    await shot(t, 'tsukiichi_0_hub_empty');

    // 固定費ルール: 家賃 85,000 / 毎月27日
    await t.tap(find.byKey(const Key('hub-rule-add')));
    await settle(t);
    await t.enterText(find.byKey(const Key('recurring-amount')), '85000');
    await settle(t);
    await t.tap(find.byKey(const Key('recurring-category-expense')));
    await settle(t);
    await pickCellMenuItem(t, find.textContaining('住居'));
    await pickDropdownDay(t, 27);
    await t.enterText(find.byKey(const Key('recurring-store')), '家賃');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    await t.tap(find.byKey(const Key('recurring-save')));
    await settle(t);

    // 収入ルール: 給料 280,000 / 毎月25日
    await t.tap(find.byKey(const Key('hub-rule-add')));
    await settle(t);
    await t.tap(find.text('収入').last, warnIfMissed: false);
    await settle(t);
    await t.enterText(find.byKey(const Key('recurring-amount')), '280000');
    await settle(t);
    await t.tap(find.byKey(const Key('recurring-category-income')));
    await settle(t);
    await pickCellMenuItem(t, find.textContaining('給与'));
    await pickDropdownDay(t, 25);
    await t.tap(find.byKey(const Key('recurring-save')));
    await settle(t);

    // つきいちタスク: まくら干し 14日ごと
    await t.tap(find.byKey(const Key('hub-chore-add')));
    await settle(t);
    await t.enterText(find.byKey(const Key('chore-form-name')), 'まくら干し');
    await t.enterText(find.byKey(const Key('chore-form-emoji')), '🛏');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    await t.tap(find.byKey(const Key('chore-form-save')));
    await settle(t);
    await shot(t, 'tsukiichi_1_hub_filled');

    // 統合カレンダー（ゴースト額・凡例・見込み行・家事ドット）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month)));
    await settle(t);
    await shot(t, 'tsukiichi_2_calendar_ghosts');

    // 未来の期日日（27日）を選択 → 日パネルに予定行
    await t.tap(find.text('27').last, warnIfMissed: false);
    await settle(t);
    await shot(t, 'tsukiichi_3_daypanel_ghost');

    // 見込み行タップ → 基準日シート
    await t.tap(find.byKey(const Key('forecast-line')));
    await settle(t);
    await shot(t, 'tsukiichi_4_anchor_sheet');
    await t.tap(find.byKey(const Key('forecast-anchor-day')));
    await settle(t);
    await shot(t, 'tsukiichi_5_forecast_day25');

    // 入力: 「毎月の費用」トグル
    await t.tap(find.byKey(const Key('fab-entry')));
    await settle(t);
    await t.tap(find.text('1'), warnIfMissed: false);
    await t.tap(find.text('4'), warnIfMissed: false);
    await t.tap(find.text('8'), warnIfMissed: false);
    await t.tap(find.byKey(const Key('np-0')), warnIfMissed: false);
    await settle(t);
    await t.tap(find.byKey(const Key('entry-recurring-btn')));
    await settle(t);
    await shot(t, 'tsukiichi_6_entry_toggle_on');
    await t.tap(find.textContaining('食費').first, warnIfMissed: false);
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('save-btn')));
    await settle(t);
    await t.tap(find.byKey(const Key('save-btn')));
    await settle(t);
    await shot(t, 'tsukiichi_7_calendar_after_save');

    // 保存後の毎月タブ（新ルールが増えている）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_repeat)));
    await settle(t);
    await shot(t, 'tsukiichi_8_hub_after_save');
  });
}
