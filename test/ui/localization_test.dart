import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// UI がロケールに応じて翻訳される smoke test（英語）。
/// ja 固定の既存テストとは別に、locale 切替が効くことを確認する。
void main() {
  testWidgets('英語ロケール: 設定・入力が英訳される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(
        prefs: {'onboardingDone': true, 'locale': 'en'});
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    // 設定タブへ（ナビは英語ラベル）。
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Back up now'), findsOneWidget);
    // 日本語UIが残っていない（上部の主要タイル）。
    expect(find.text('今すぐバックアップ'), findsNothing);
    // 言語/通貨タイルは下方なのでスクロールしてから確認。
    await tester.scrollUntilVisible(
        find.byKey(const Key('language-tile')), 200);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);

    // 入力タブへ（FABは英語）。
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Add entry'), findsOneWidget); // 入力ボタン（英語）
  });

  // ドイツ語は最長になりやすくレイアウト崩れ（オーバーフロー）を検知しやすい。
  // widget test はオーバーフローで失敗するので、各タブを描画して破綻がないか確認。
  testWidgets('ドイツ語ロケール: 全タブが破綻なく描画される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(
        prefs: {'onboardingDone': true, 'locale': 'de', 'currency': 'EUR'});
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.text('Kalender'), findsWidgets);
    await tester.tap(find.text('Übersicht').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Jetzt sichern'), findsOneWidget);
  });

  // v2.2.0: 入力画面の「毎月の費用」+「複数のカテゴリを選択」の横並びは
  // 長い言語で溢れやすいので、de で金額入力後の状態まで描画して検知する。
  testWidgets('ドイツ語ロケール: 入力画面のトグル行が溢れない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(
        prefs: {'onboardingDone': true, 'locale': 'de', 'currency': 'EUR'});
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('fab-entry')));
    await tester.pumpAndSettle();
    // 金額を入れるとトグル行（毎月の費用/内訳）が現れる
    // （EURは小数通貨で 00 キーが小数点キーに変わるため数字キーだけで入力）
    await tester.tap(find.text('5'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-recurring-btn')), findsOneWidget);
    expect(find.byKey(const Key('start-split')), findsOneWidget);
    // ONにして帯と保存文言も描画（オーバーフローがあればここで落ちる）
    await tester.tap(find.byKey(const Key('entry-recurring-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-recurring-note')), findsOneWidget);
  });
}
