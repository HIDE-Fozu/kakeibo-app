import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// 買い物メモ（日別カードの「メモ」タブ・2026-08-23要望）。
/// 家計簿の入力とは無関係の自由テキストで、prefs に保存される。
void main() {
  /// 日別カードの高さ（せり上がっているかの判定に使う）。
  double sheetHeight(WidgetTester tester) => tester
      .getSize(find.byKey(const Key('shopping-memo-field')).hitTestable())
      .height;


  testWidgets('メモタブ: 入力が保存され、タブを往復しても残る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    // その場で直接書ける（別ページへは飛ばない・FB 2026-08-27）
    await tester.enterText(
        find.byKey(const Key('shopping-memo-field')), '牛乳\nトイレットペーパー');
    await tester.pumpAndSettle();
    expect(h.prefs.getString('shoppingMemo'), '牛乳\nトイレットペーパー');

    // 日付タブへ移って戻っても内容が残る（保存済みを再表示）
    await tester.tap(find.byKey(const Key('day-tab-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(find.text('牛乳\nトイレットペーパー'), findsOneWidget);
  });

  testWidgets('メモは別ページに飛ばず、その場で書ける', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();

    // カレンダー画面のまま。下タブも消えない（＝別ルートへ遷移していない）
    expect(find.text('カレンダー'), findsOneWidget);
    expect(find.byKey(const Key('day-tab-memo')), findsOneWidget);
    // 入力欄がその場にあり、すぐ書ける
    expect(find.byKey(const Key('shopping-memo-field')), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('shopping-memo-field')), 'たまご');
    await tester.pumpAndSettle();
    expect(h.prefs.getString('shoppingMemo'), 'たまご');
    expect(find.byKey(const Key('day-tab-memo')), findsOneWidget);
  });

  testWidgets('メモタブを押しただけでは位置は変わらない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    // 日付タブのときはせり上げ用のオーバーレイは無い
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);

    // メモに切り替えただけでは、つきいちや日付を押したときと同じで動かない
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);
    final collapsedH = sheetHeight(tester);

    // メモ欄をタップして書き始めるとせり上がる
    await tester.tap(find.byKey(const Key('shopping-memo-field')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget);
    expect(sheetHeight(tester), greaterThan(collapsedH));
  });

  testWidgets('せり上げたあと背景タップで戻る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    final collapsedH = sheetHeight(tester);
    await tester.tap(find.byKey(const Key('shopping-memo-field')));
    await tester.pumpAndSettle();
    final expandedH = sheetHeight(tester);

    // 背景（カレンダー側）をタップすると戻る。キーボードも閉じる。
    await tester.tapAt(const Offset(200, 260));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);
    expect(sheetHeight(tester), collapsedH);
    expect(collapsedH, lessThan(expandedH));
  });

  testWidgets('せり上げ中に日付・つきいちを押しても高さは変わらない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping-memo-field')));
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
