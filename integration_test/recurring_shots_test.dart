import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定期取引（毎月の固定費・収入）UIの目視確認用スクショ撮影（使い捨てハーネス）。
/// 実行例（実行前に app を uninstall しておく）:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/recurring_shots_test.dart -d <udid>
///
/// 実時計で動く（clockProvider はデフォルト＝今日）。保存時に当月の期日到来分が
/// 起票され、カレンダーに現れるところまで確認する。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recurring UI shots', (t) async {
    SharedPreferences.setMockInitialValues({'onboardingDone': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 設定 → 毎月の固定費・収入
    await t.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.byIcon(Icons.settings)));
    await settle(t);
    await shot(t, 'recurring_0_settings');
    await t.tap(find.byKey(const Key('recurring-tile')));
    await settle(t);
    await shot(t, 'recurring_1_empty');

    // 追加ページ
    await t.tap(find.byKey(const Key('recurring-add')));
    await settle(t);
    await shot(t, 'recurring_2_edit_blank');
    await t.enterText(find.byKey(const Key('recurring-amount')), '80000');
    await settle(t);
    await t.tap(find.byKey(const Key('recurring-category-expense')));
    await settle(t);
    await t.tap(find.textContaining('住居').last, warnIfMissed: false);
    await settle(t);
    await t.enterText(find.byKey(const Key('recurring-store')), '大家さん');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    await shot(t, 'recurring_3_edit_filled');
    await t.tap(find.byKey(const Key('recurring-save')));
    await settle(t);
    await shot(t, 'recurring_4_list');

    // 一覧はフルスクリーンrouteなので、設定タブへ戻ってからカレンダーへ
    // （下のNavigationBarはoffstageでfindが失敗する）。
    await t.tap(find.byType(BackButton)); // pageBackはiOSでCupertino前提のため不可
    await settle(t);
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month)));
    await settle(t);
    // カレンダーに当月分（毎月1日→今日より前なので起票済み）が出るはず
    await shot(t, 'recurring_5_calendar');
  });
}
