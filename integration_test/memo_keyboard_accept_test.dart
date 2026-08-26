import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 実機/シミュレータでの受入: メモをタップしたとき、本物のキーボードが
/// 出たままか（＝フォーカスが落ちないか）。
/// 単体テストは viewInsets を偽装するだけなので、こちらで本物を確かめる。
late IntegrationTestWidgetsFlutterBinding binding;

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('本物のキーボードが出てもメモのフォーカスは落ちない', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    await t.tap(find.byKey(const Key('day-tab-memo')));
    await t.pumpAndSettle(const Duration(milliseconds: 300));

    final field = find.byKey(const Key('shopping-memo-field'));
    final before = t.widget<TextField>(field).focusNode;

    await t.tap(find.byKey(const Key('shopping-memo-pad')));
    // キーボードのせり上がりアニメーションが終わるまで待つ。
    await t.pumpAndSettle(const Duration(milliseconds: 1200));

    final insets =
        MediaQueryData.fromView(t.view).viewInsets.bottom;
    debugPrint('KB_INSETS=$insets');

    final after = t.widget<TextField>(field).focusNode;
    debugPrint('SAME_FOCUSNODE=${identical(before, after)}');
    debugPrint('HAS_FOCUS=${after?.hasFocus}');
    await binding.takeScreenshot('kb_1_focused');

    // 本物のキーボードが出ていること（出ていないと検証にならない）
    expect(insets, greaterThan(0),
        reason: 'ソフトウェアキーボードが出ていない＝この検証は無意味');
    expect(identical(before, after), isTrue,
        reason: 'メモの State が作り直されている');
    expect(after?.hasFocus, isTrue, reason: 'キーボードが閉じてしまう');

    // そのまま書けること
    await t.enterText(field, '牛乳\nたまご');
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await binding.takeScreenshot('kb_2_typed');
    expect(t.widget<TextField>(field).focusNode?.hasFocus, isTrue);
  });
}
