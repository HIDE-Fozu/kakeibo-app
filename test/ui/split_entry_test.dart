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
  testWidgets('詳細入力: 開始→式入力→残額行→2件保存できる状態になる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();

    // 金額0では詳細入力ボタンは出ない
    expect(find.byKey(const Key('start-split')), findsNothing);

    // 合計 1000 を入力 → ボタン出現 → 開始
    await tester.tap(find.byKey(const Key('np-0')).first); // 0（無効）
    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // パネルとテンキー演算子列が出る
    expect(find.text('詳細入力（合計 ¥1,000）'), findsOneWidget);
    expect(find.byKey(const Key('np-op-+')), findsOneWidget);

    // 行1: 300+100 → 残額行が自動生成され「残り ¥600」表示
    for (final k in ['np-op-+', 'np-op-+']) {
      // 先頭+を2回押しても置換で1つのまま（例外にならない）
      await tester.tap(find.byKey(Key(k)));
    }
    ctrl.splitTapDigit(3);
    ctrl.splitTapDoubleZero();
    await tester.tap(find.byKey(const Key('np-op-+')));
    ctrl.splitTapDigit(1);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-line-1')), findsOneWidget);
    expect(find.textContaining('¥600'), findsOneWidget); // 残額行=手入力と同形式の¥表示
    expect(find.textContaining('= ¥400'), findsOneWidget);

    // 外税8%: +300+100=400 → 432
    await tester.tap(find.byKey(const Key('split-tax8-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('= ¥432'), findsOneWidget);
    expect(find.textContaining('¥568'), findsOneWidget); // 残額行が自動更新

    // やめる → 通常モードへ戻り合計は保持
    await tester.tap(find.byKey(const Key('cancel-split')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-split')), findsOneWidget);
    expect(c.read(entryFormControllerProvider)!.amountYen, 1000);
  });
}
