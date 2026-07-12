import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('3タブ（入力タブ無し）・タップで切り替わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.text('カレンダー'), findsOneWidget); // NavigationBarラベル
    expect(find.text('サマリ'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('2026年7月'), findsOneWidget); // CalendarScreen（固定時計）
    // 入力タブは廃止（カレンダー上に「入力」の文字は無い）
    expect(find.text('入力'), findsNothing);

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('summary-next')), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backup-now')), findsOneWidget);
  });

  testWidgets('FAB「金額を入力する」で入力→戻る（入力中はタブ非表示）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    // カレンダーのFABにラベルが付く
    expect(find.text('金額を入力する'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fab-entry')));
    await tester.pumpAndSettle();

    // 入力画面（テンキー）＋ 下部タブは隠れる（縦スペース確保）
    expect(find.byKey(const Key('np-00')), findsOneWidget);
    expect(find.text('サマリ'), findsNothing);

    // 左上の戻るでカレンダーへ（タブが戻る）
    await tester.tap(find.byKey(const Key('entry-back')));
    await tester.pumpAndSettle();
    expect(find.text('2026年7月'), findsOneWidget);
    expect(find.byKey(const Key('np-00')), findsNothing);
    expect(find.text('サマリ'), findsOneWidget);
  });
}
