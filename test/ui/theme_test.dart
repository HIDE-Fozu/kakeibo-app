import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/theme.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('生成りの背景・深緑primary・拡張色（紅/藍）が適用される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h); // home指定なし=KakeiboApp（テーマが乗る）

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, kPaper);
    expect(theme.colorScheme.primary, kPrimary);
    expect(theme.colorScheme.error, kExpense);
    final ext = theme.extension<KakeiboColors>();
    expect(ext, isNotNull);
    expect(ext!.expense, kExpense);
    expect(ext.income, kIncome);
  });
}
