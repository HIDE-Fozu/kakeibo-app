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
  testWidgets('通常入力: メモは品目行のセル内ボタン→ダイアログで入力（独立欄は無い）',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();

    // 品目行のセル内にメモボタンがあり、旧・独立した「詳細メモ」欄は無い
    final row = find.byKey(const Key('single-item-row'));
    expect(row, findsOneWidget);
    expect(
        find.descendant(
            of: row, matching: find.byKey(const Key('entry-memo-btn'))),
        findsOneWidget);
    expect(
        find.byKey(ValueKey(
            'memo-field-${c.read(entryFormControllerProvider)!.formSeq}')),
        findsNothing);

    // タップ→ダイアログ→保存で state.memo に入り、ボタンに本文が出る
    await tester.tap(find.byKey(const Key('entry-memo-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-memo-field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('split-memo-field')), '牛乳とパン');
    await tester.tap(find.byKey(const Key('split-memo-save')));
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.memo, '牛乳とパン');
    expect(
        find.descendant(of: row, matching: find.text('牛乳とパン')),
        findsOneWidget);

    // キャンセルは変更しない
    await tester.tap(find.byKey(const Key('entry-memo-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('split-memo-field')), '書き換え');
    await tester.tapAt(const Offset(10, 60)); // バリアタップで閉じる
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.memo, '牛乳とパン');
  });
}
