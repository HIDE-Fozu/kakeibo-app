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
  testWidgets('金額0で「カテゴリを追加」→ ボトムアップ内訳・末尾は「合計」行',
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

    // 内訳モードに入る（旧・案Aの「先に金額」ゲートは無い）
    final st = c.read(entryFormControllerProvider)!;
    expect(st.splits, isNotNull);
    expect(st.splitBottomUp, isTrue);
    expect(find.byKey(const Key('split-tax-mode')), findsOneWidget);

    // 末尾の行は従来どおり「残り」（総和＝合計なので常に¥0・超過にならない）。
    // 合計はヘッダの金額表示に一本化（FB 2026-08-16: 合計の重複は却下）
    final label =
        tester.widget<Text>(find.byKey(const Key('split-tail-label')));
    expect(label.data, '残り');
    expect(find.byKey(const Key('split-remainder')), findsOneWidget);

    // 品目を打つとヘッダの金額表示が総和で追従する。末尾は「残り」のまま超過にならない
    ctrl.splitTapDigit(5);
    ctrl.splitTapDoubleZero(); // 500
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.displayAmountYen, 500);
    expect(
        tester
            .widget<Text>(find.byKey(const Key('split-tail-label')))
            .data,
        '残り');
  });

  testWidgets('金額を入れてから入ると従来どおり「残り」行（トップダウン）', (tester) async {
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

    final st = c.read(entryFormControllerProvider)!;
    expect(st.splits, isNotNull);
    expect(st.splitBottomUp, isFalse);
    final label =
        tester.widget<Text>(find.byKey(const Key('split-tail-label')));
    expect(label.data, '残り');
    expect(find.byKey(const Key('split-remainder')), findsOneWidget);
  });
}
