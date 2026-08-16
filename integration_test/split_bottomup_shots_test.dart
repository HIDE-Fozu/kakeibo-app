import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 案B（ボトムアップ内訳）の目視確認用スクショ（使い捨て）:
/// 金額0で「カテゴリを追加」→ ヘッダの金額が品目の総和で育つ流れ（末尾は
/// 従来どおり「残り」・常に¥0）と、トップダウン（残り行）の比較。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('split bottom-up shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    Finder pad(String label) =>
        find.descendant(of: find.byType(Numpad), matching: find.text(label));

    // 金額0のまま「カテゴリを追加」
    await t.tap(find.byKey(const Key('fab-entry')));
    await settle(t);
    await shot(t, 'bu_1_entry_zero');
    await t.tap(find.byKey(const Key('start-split')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'bu_2_bottomup_empty'); // 末尾=「残り ¥0」・ヘッダ¥0

    // 品目1: 480円＋食費
    for (final d in ['4', '8', '0']) {
      await t.tap(pad(d), warnIfMissed: false);
    }
    await settle(t);
    await t.tap(find.textContaining('食費').first, warnIfMissed: false);
    await settle(t);
    await shot(t, 'bu_3_one_item'); // ヘッダ¥480・残り¥0のまま

    // ＋品目 → 120円＋日用品
    await t.tap(find.byKey(const Key('split-add')), warnIfMissed: false);
    await settle(t);
    for (final d in ['1', '2', '0']) {
      await t.tap(pad(d), warnIfMissed: false);
    }
    await settle(t);
    await t.tap(find.textContaining('日用品').first, warnIfMissed: false);
    await settle(t);
    await shot(t, 'bu_4_two_items'); // ヘッダ¥600

    // 比較: 金額を先に入れる従来のトップダウン（残り行）
    await t.tap(find.text('やめる'), warnIfMissed: false);
    await settle(t);
    for (final d in ['1', '0', '0', '0']) {
      await t.tap(pad(d), warnIfMissed: false);
    }
    await t.tap(find.byKey(const Key('start-split')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'bu_5_topdown_compare'); // 末尾=「残り ¥1,000」
  });
}
