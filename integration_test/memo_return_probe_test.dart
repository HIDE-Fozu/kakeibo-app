import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 調査用（使い捨て）: メモ→カレンダーに戻るときの「ホワイトアウト」を
/// コマ送りで撮り、何フレーム・何ミリ秒その状態が続くかを測る。
late IntegrationTestWidgetsFlutterBinding binding;

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('memo -> calendar 復帰のコマ送り', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    double insets() => MediaQueryData.fromView(t.view).viewInsets.bottom;
    bool scrim() =>
        find.byKey(const Key('day-sheet-scrim')).evaluate().isNotEmpty;

    await t.tap(find.byKey(const Key('day-tab-memo')));
    await t.pumpAndSettle(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const Key('shopping-memo-pad')));
    await t.pumpAndSettle(const Duration(milliseconds: 1200));
    debugPrint('PROBE up: insets=${insets()} scrim=${scrim()}');
    await binding.takeScreenshot('ret_00_typing');

    // 背景（カレンダー側）をタップして戻る
    await t.tapAt(const Offset(200, 200));
    // コマ送り: 100ms ずつ 2 秒ぶん
    for (var i = 1; i <= 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
      debugPrint('PROBE t=${i * 100}ms insets=${insets()} scrim=${scrim()}');
      if (i <= 10) await binding.takeScreenshot('ret_${i.toString().padLeft(2, '0')}');
    }
    await t.pumpAndSettle(const Duration(seconds: 2));
    debugPrint('PROBE settled: insets=${insets()} scrim=${scrim()}');
    await binding.takeScreenshot('ret_99_settled');
  });
}
