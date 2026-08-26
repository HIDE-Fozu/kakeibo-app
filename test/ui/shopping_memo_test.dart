import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// 買い物メモ（日別カードの「メモ」タブ・2026-08-23要望）。
/// 家計簿の入力とは無関係の自由テキストで、prefs に保存される。
void main() {
  /// 日別カードの高さ（せり上がっているかの判定に使う）。
  double sheetHeight(WidgetTester tester) => tester
      .getSize(find.byKey(const Key('shopping-memo-pad')).hitTestable())
      .height;


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

  testWidgets('メモを開くとカードがせり上がり、背景タップで戻る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    // 日付タブのときはせり上げ用のオーバーレイは無い
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget);
    final expandedH = sheetHeight(tester);

    // 背景（カレンダー側）をタップすると戻る
    await tester.tapAt(const Offset(200, 260));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);

    // 戻ったあとは元の高さ（せり上がりぶん低い）
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 260));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day-tab-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(sheetHeight(tester), expandedH);
  });

  testWidgets('せり上げ中に日付・つきいちを押しても高さは変わらない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    final expandedH = sheetHeight(tester);

    // つきいち → 日付 → メモ と回っても、せり上げは維持される
    await tester.tap(find.byKey(const Key('day-tab-chores')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget);

    await tester.tap(find.byKey(const Key('day-tab-label')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(sheetHeight(tester), expandedH);
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
