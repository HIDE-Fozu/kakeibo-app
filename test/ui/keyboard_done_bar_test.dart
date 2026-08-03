import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';
import 'package:kakeibo_app/features/recurring/presentation/recurring_rules_page.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

void main() {
  testWidgets('入力画面: キーボードが開くと「完了」バーが出て、タップで閉じる（unfocus）',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
        listen: false);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    // キーボード閉: バーなし
    expect(find.byKey(const Key('kb-done')), findsNothing);

    // メモ欄にフォーカス＋キーボードのinsetを疑似発生
    await tester.ensureVisible(find.byKey(ValueKey(
        'memo-field-${c.read(entryFormControllerProvider)!.formSeq}')));
    await tester.tap(find.byKey(ValueKey(
        'memo-field-${c.read(entryFormControllerProvider)!.formSeq}')));
    tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kb-done')), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    // 完了 → unfocus（実機はこれでキーボードが閉じる）
    await tester.tap(find.byKey(const Key('kb-done')));
    tester.view.viewInsets = FakeViewPadding.zero;
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

    await tester.tap(find.byKey(const Key('recurring-amount')));
    tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kb-done')), findsOneWidget);
  });
}
