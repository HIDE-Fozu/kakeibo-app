import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('3タブが表示され、タップで切り替わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.text('カレンダー'), findsOneWidget); // NavigationBarラベル
    expect(find.text('(カレンダー 準備中)'), findsOneWidget);

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();
    expect(find.text('(サマリ 準備中)'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('(設定 準備中)'), findsOneWidget);
  });
}
