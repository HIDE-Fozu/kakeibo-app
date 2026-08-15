import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

void main() {
  testWidgets('金額0で「カテゴリを追加」→ 内訳に入らず「先に金額」のスナックバー',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // 内訳モードに入っていない（消費税トグルが出ない）
    expect(c.read(entryFormControllerProvider)?.splits, isNull);
    expect(find.byKey(const Key('split-tax-mode')), findsNothing);
    // 理由が一言出る
    expect(find.text('先に金額を入力してください'), findsOneWidget);
  });

  testWidgets('金額を入れれば「カテゴリを追加」で内訳に入れる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();

    ctrl.tapDigit(5);
    ctrl.tapDoubleZero();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    expect(c.read(entryFormControllerProvider)?.splits, isNotNull);
    expect(find.byKey(const Key('split-tax-mode')), findsOneWidget);
  });
}
