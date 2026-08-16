import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-08-16 FB群の目視確認（使い捨て）: 凡例なしカレンダー・固定費の終了月。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fb0816 shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    await shot(t, 'fb_1_calendar'); // 凡例（固定費の予定）なし

    // 毎月タブ → 固定費フォーム → 終了月メニュー
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_repeat)));
    await settle(t);
    await t.tap(find.byKey(const Key('hub-rule-add')));
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('recurring-end')));
    await settle(t);
    await shot(t, 'fb_2_rule_form_end'); // 「終了」欄（既定=終了なし）
    await t.tap(find.byKey(const Key('recurring-end')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'fb_3_end_menu'); // 終了月メニュー（終了なし＋月一覧）
    await t.tapAt(const Offset(30, 120)); // メニューを閉じる
    await settle(t);
    await t.tap(find.byType(BackButton));
    await settle(t);

    // 分割払い: 毎月タブの「分割払い」→ フォーム＋プレビュー
    await t.tap(find.byKey(const Key('hub-installment-add')));
    await settle(t);
    await t.enterText(find.byKey(const Key('installment-amount')), '33000');
    await t.enterText(find.byKey(const Key('installment-rate')), '17');
    await t.enterText(
        find.byKey(const Key('installment-card-name')), '楽天カード');
    await settle(t);
    await t.tap(find.byKey(const Key('installment-category')),
        warnIfMissed: false);
    await settle(t);
    await t.tap(find.textContaining('食費').last, warnIfMissed: false);
    await settle(t);
    // 実機はキーボードでビューポートが縮み ListView が遅延構築のため、
    // ensureVisible ではなくドラッグでプレビューまでスクロールする。
    await t.drag(find.byType(ListView).last, const Offset(0, -500));
    await settle(t);
    await shot(t, 'fb_4_installment_form'); // 33,000×10回17%のプレビュー

    // 保存 → 毎月タブの「分割払い」セクションに一覧表示（タップで編集）
    await t.tap(find.byKey(const Key('installment-save')), warnIfMissed: false);
    await settle(t);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await settle(t);
    await shot(t, 'fb_5_hub_installment_section');
  });
}
