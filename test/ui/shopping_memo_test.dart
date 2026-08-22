import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// 買い物メモ（日別カードの「メモ」タブ・2026-08-23要望）。
/// 家計簿の入力とは無関係の自由テキストで、prefs に保存される。
void main() {
  testWidgets('メモタブ: 入力が保存され、タブを往復しても残る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    // タブ内は表示専用（空はヒント文言）。タップで編集シートが開く。
    await tester.tap(find.byKey(const Key('shopping-memo-pad')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('shopping-memo-field')), '牛乳\nトイレットペーパー');
    await tester.pumpAndSettle();
    expect(h.prefs.getString('shoppingMemo'), '牛乳\nトイレットペーパー');

    // 完了で閉じるとタブ内に内容が見える
    await tester.tap(find.byKey(const Key('shopping-memo-done')));
    await tester.pumpAndSettle();
    expect(find.text('牛乳\nトイレットペーパー'), findsOneWidget);

    // 日付タブへ移って戻っても内容が残る（保存済みを再表示）
    await tester.tap(find.byKey(const Key('day-tab-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(find.text('牛乳\nトイレットペーパー'), findsOneWidget);
  });

  testWidgets('起動時: prefs の既存メモが表示される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'shoppingMemo': '卵を買う',
    });
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(find.text('卵を買う'), findsOneWidget);
  });
}
