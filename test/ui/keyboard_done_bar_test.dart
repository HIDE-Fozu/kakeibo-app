import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/navigation.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/recurring/presentation/recurring_rules_page.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

void main() {
  testWidgets('入力画面(HomeShell内): 店舗名欄フォーカスで「完了」バーが出て、タップで閉じる',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    // 実機と同じネスト（HomeShellのScaffold内のEntryScreen）で検証する。
    // viewInsets方式は外側Scaffoldがinsetを消費して実機で出なかった（回帰確認）。
    await pumpApp(tester, h, home: const HomeShell());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
        listen: false);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    c.read(homeTabIndexProvider.notifier).set(kInputTabIndex);
    await tester.pumpAndSettle();

    // フォーカスなし: バーなし
    expect(find.byKey(const Key('kb-done')), findsNothing);

    // 店舗名欄にフォーカス → バー表示（旧・詳細メモ欄は品目行の
    // メモボタン→ダイアログ方式に変わったため、常設のテキスト欄で検証）
    final storeField = find.byKey(ValueKey(
        'store-field-${c.read(entryFormControllerProvider)!.formSeq}'));
    await tester.ensureVisible(storeField);
    await tester.pumpAndSettle();
    await tester.tap(storeField);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kb-done')), findsOneWidget);

    // 完了 → unfocus（実機はこれでキーボードが閉じる）→ バーが消える
    await tester.tap(find.byKey(const Key('kb-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kb-done')), findsNothing);
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.context?.widget, isNot(isA<EditableText>()));
  });

  testWidgets('定期ルール編集: 金額欄フォーカス中も「完了」バーが出る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const RecurringRuleEditPage(rule: null));

    expect(find.byKey(const Key('kb-done')), findsNothing);
    await tester.tap(find.byKey(const Key('recurring-amount')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kb-done')), findsOneWidget);
  });
}
