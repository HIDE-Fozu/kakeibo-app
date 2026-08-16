import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「まず合計を入力」フェーズ（金額0でカテゴリを追加・FB 2026-08-16）の
/// 目視確認用スクショ（使い捨て）:
/// フェーズ中のディム＋ヒント＋金額ハイライト → 合計入力 → 解除後の通常内訳。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('split total-first shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    Finder pad(String label) =>
        find.descendant(of: find.byType(Numpad), matching: find.text(label));

    // 金額0のまま「カテゴリを追加」→ まず合計を入力フェーズ
    await t.tap(find.byKey(const Key('fab-entry')));
    await settle(t);
    await t.tap(find.byKey(const Key('start-split')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'tf_1_total_pending'); // 行はディム・ヒント・金額枠ハイライト

    // 合計1000を入力（電卓は合計へ）
    for (final d in ['1', '0', '0', '0']) {
      await t.tap(pad(d), warnIfMissed: false);
    }
    await settle(t);
    await shot(t, 'tf_2_total_typed'); // ヘッダ¥1,000・まだフェーズ中

    // 行をタップしてフェーズ解除 → 通常のトップダウン内訳
    // 行中央はメモボタンなので番号バッジを狙う（ダイアログを開かない）
    await t.tap(find.byKey(const Key('split-lineno-0')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'tf_3_phase_done'); // ディム解除・演算子列・残り¥1,000

    // 品目1: 480円＋食費 → 残り520
    for (final d in ['4', '8', '0']) {
      await t.tap(pad(d), warnIfMissed: false);
    }
    await settle(t);
    await t.tap(find.textContaining('食費').first, warnIfMissed: false);
    await settle(t);
    await shot(t, 'tf_4_item_and_rest'); // 残り¥520
  });
}
