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

    // 1) メモタブに切り替えただけ＝1行の入力欄が出るだけ
    await t.tap(find.byKey(const Key('day-tab-memo')));
    await settle(t);
    await shot(t, 'memo_1_one_line');

    // 2) 1タップで入力できる（画面は動かない）。キーボードを出したまま撮る。
    await t.tap(find.byKey(const Key('shopping-memo-pad')));
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_2_tap_to_type');
    await t.enterText(find.byKey(const Key('shopping-memo-field')),
        '牛乳\nトイレットペーパー\nたまご');
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_3_typed');

    // 3) タブ行を上へドラッグすると広がる
    await t.drag(find.byKey(const Key('day-sheet-drag')), const Offset(0, -260));
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_4_dragged_up');

    // 4) 広げたまま つきいち へ切り替えても高さは維持
    await t.tap(find.byKey(const Key('day-tab-chores')));
    await settle(t);
    await shot(t, 'memo_5_dragged_chores');
    await t.tap(find.byKey(const Key('day-tab-memo')));
    await settle(t);

    // 5) 背景（カレンダー）をタップすると元に戻る
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle(const Duration(milliseconds: 400));
    await t.tapAt(const Offset(200, 200));
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_6_back');
  });
}
