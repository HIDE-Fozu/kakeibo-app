import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('3タブが表示され、タップで切り替わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.text('カレンダー'), findsOneWidget); // NavigationBarラベル
    expect(find.text('2026年7月'), findsOneWidget); // CalendarScreen（固定時計）

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('summary-next')), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backup-now')), findsOneWidget);
  });
}
