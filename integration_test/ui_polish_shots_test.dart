import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-08-09 UI改善の目視確認用スクショ（使い捨て）:
/// セル幅プルダウン（ルール日/つきいち日/入力ピル）・＋追加ボタン・会社名ラベル。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ui polish shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 毎月タブ（＋追加ボタン）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_repeat)));
    await settle(t);
    await shot(t, 'polish_1_hub_add_buttons');

    // 固定費フォーム: 記録する日メニューを開いた状態（セル幅・直下）
    await t.tap(find.byKey(const Key('hub-rule-add')));
    await settle(t);
    await t.tap(find.byKey(const Key('recurring-day')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'polish_2_rule_day_menu');
    await t.tapAt(const Offset(30, 120)); // バリアタップで閉じる
    await settle(t);

    // カテゴリメニューも開いて確認
    await t.tap(find.byKey(const Key('recurring-category-expense')));
    await settle(t);
    await shot(t, 'polish_3_rule_category_menu');
    await t.tapAt(const Offset(30, 120));
    await settle(t);
    await t.tap(find.byType(BackButton));
    await settle(t);

    // つきいちフォーム: 繰り返し単位＋値の2列
    await t.tap(find.byKey(const Key('hub-chore-add')));
    await settle(t);
    await shot(t, 'polish_4_chore_form');
    await t.tap(find.byKey(const Key('chore-form-day')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'polish_5_chore_day_menu');
    await t.tapAt(const Offset(30, 120));
    await settle(t);
    // 繰り返し単位を「日ごと」へ → 右が間隔プルダウンに変わる
    await t.tap(find.byKey(const Key('chore-form-unit')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'polish_8_chore_unit_menu');
    await t.tap(find.text('日ごと').last, warnIfMissed: false);
    await settle(t);
    await shot(t, 'polish_9_chore_interval');
    await t.tap(find.byKey(const Key('chore-form-interval')),
        warnIfMissed: false);
    await settle(t);
    await shot(t, 'polish_10_chore_interval_menu');
    await t.tapAt(const Offset(30, 120));
    await settle(t);
    await t.tap(find.byType(BackButton));
    await settle(t);

    // 入力: 収入タブ→会社名ラベル（FABはカレンダータブにある）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month)));
    await settle(t);
    await t.tap(find.byKey(const Key('fab-entry')));
    await settle(t);
    await t.tap(find.text('収入'));
    await settle(t);
    await t.ensureVisible(find.text('会社名'));
    await shot(t, 'polish_6_income_company_label');

    // 支出に戻し金額入力→毎月の費用ON→ピルのメニュー
    await t.tap(find.text('支出'));
    await settle(t);
    await t.tap(find.text('1'), warnIfMissed: false);
    await t.tap(find.byKey(const Key('np-00')), warnIfMissed: false);
    await settle(t);
    await t.tap(find.byKey(const Key('entry-recurring-btn')));
    await settle(t);
    await t.tap(find.byKey(const Key('entry-recurring-day')));
    await settle(t);
    await shot(t, 'polish_7_entry_pill_menu');
  });
}
