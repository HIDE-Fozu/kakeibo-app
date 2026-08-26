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

  /// タブ行を上へ [dy] px ドラッグする。
  Future<void> dragTabsUp(WidgetTester tester, double dy) async {
    await tester.drag(find.byKey(const Key('day-sheet-drag')), Offset(0, -dy));
    await tester.pumpAndSettle();
  }


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

  testWidgets('メモは1タップで書ける（画面は動かない）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    final before = sheetHeight(tester);

    // 1回タップしただけで入力できる。タップで画面が動かないので
    // 「1回目は空振り、2回目でやっと入力」にならない。
    await tester.tap(find.byKey(const Key('shopping-memo-pad')));
    await tester.pumpAndSettle();
    expect(sheetHeight(tester), before);
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);

    await tester.enterText(
        find.byKey(const Key('shopping-memo-field')), 'たまご');
    await tester.pumpAndSettle();
    expect(h.prefs.getString('shoppingMemo'), 'たまご');
  });

  testWidgets('入力欄は1行から始まり、書いた行数だけ伸びる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('shopping-memo-field'));
    final oneLine = tester.getSize(field).height;
    // 1行ぶん＝カード全体よりずっと低い
    expect(oneLine, lessThan(sheetHeight(tester) / 2));

    await tester.enterText(field, '牛乳\nトイレットペーパー\nたまご');
    await tester.pumpAndSettle();
    expect(tester.getSize(field).height, greaterThan(oneLine));
  });

  testWidgets('タブ行を上へドラッグするとカードが広がる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    final before = sheetHeight(tester);
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);

    await dragTabsUp(tester, 200);
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget);
    expect(sheetHeight(tester), greaterThan(before + 150));
  });

  testWidgets('わずかなドラッグは通常位置へ戻す', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    final before = sheetHeight(tester);

    await dragTabsUp(tester, 10); // 指のブレ程度
    expect(sheetHeight(tester), before);
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);
  });

  testWidgets('広げたあと背景タップで戻る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    final before = sheetHeight(tester);
    await dragTabsUp(tester, 200);
    expect(sheetHeight(tester), greaterThan(before));

    // 背景（カレンダー側）をタップすると戻る
    await tester.tapAt(const Offset(200, 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsNothing);
    expect(sheetHeight(tester), before);
  });

  testWidgets('広げている間に日付・つきいちを押しても高さは変わらない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();
    await dragTabsUp(tester, 200);
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
