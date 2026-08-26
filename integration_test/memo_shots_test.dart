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

    // 1) メモタブに切り替えただけ＝位置はそのまま
    await t.tap(find.byKey(const Key('day-tab-memo')));
    await settle(t);
    await shot(t, 'memo_1_tab_only');

    // 1b) メモ欄をタップするとせり上がる
    await t.tap(find.byKey(const Key('shopping-memo-field')));
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_1b_raised');

    // 1c) せり上げ中につきいちへ切り替えても高さは維持される
    await t.tap(find.byKey(const Key('day-tab-chores')));
    await settle(t);
    await shot(t, 'memo_1c_raised_chores');
    await t.tap(find.byKey(const Key('day-tab-memo')));
    await settle(t);

    // 2) その場で入力（別ページへ飛ばない）。キーボードを出したまま撮る。
    await t.enterText(find.byKey(const Key('shopping-memo-field')),
        '牛乳\nトイレットペーパー\nたまご');
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_2_typing');

    // 3) キーボードを閉じた状態
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, 'memo_3_filled');

    // 4) 背景（カレンダー）をタップすると元に戻る
    await t.tapAt(const Offset(200, 260));
    await settle(t);
    await shot(t, 'memo_4_collapsed');
  });
}
