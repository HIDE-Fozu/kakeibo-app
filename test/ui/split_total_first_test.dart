import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

void main() {
  testWidgets('金額0で「カテゴリを追加」→ まず合計を入力するフェーズから開始',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    EntryFormState st() => c.read(entryFormControllerProvider)!;
    ctrl.startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // 内訳に入るが「まず合計を入力」フェーズ: 演算子列は無い。
    // 案内文は置かず、ハイライトは上部の合計のみ（行のアクティブ枠なし）
    expect(st().splits, isNotNull);
    expect(st().splitTotalPending, isTrue);
    expect(find.byKey(const Key('split-total-hint')), findsNothing);
    expect(find.byKey(const Key('np-op-+')), findsNothing);

    // 合計0の間は行に触れない（IgnorePointerでタップ無効）
    await tester.tap(find.byKey(const Key('split-line-0')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(st().splitTotalPending, isTrue);

    // 電卓は合計を編集する
    Finder pad(String label) =>
        find.descendant(of: find.byType(Numpad), matching: find.text(label));
    await tester.tap(pad('1'), warnIfMissed: false);
    await tester.tap(pad('00'), warnIfMissed: false);
    await tester.tap(pad('0'), warnIfMissed: false); // 1000
    await tester.pumpAndSettle();
    expect(st().amountYen, 1000);
    expect(st().splits![0].expr, isEmpty);
    expect(st().splitTotalPending, isTrue); // 打鍵だけでは解除しない

    // 合計が入った状態で行をタップするとフェーズ解除 → 通常のトップダウンへ
    // （行中央はメモボタンなので番号バッジを狙う）
    await tester.tap(find.byKey(const Key('split-lineno-0')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(st().splitTotalPending, isFalse);
    expect(find.byKey(const Key('np-op-+')), findsOneWidget); // 演算子列が戻る

    // 以後は従来どおり: 行0に300 → 残り700
    ctrl.splitTapDigit(3);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();
    expect(st().splitLineAmount(0), 300);
    expect(st().splitLineAmount(1), 700);
    final label =
        tester.widget<Text>(find.byKey(const Key('split-tail-label')));
    expect(label.data, '残り');
  });

  testWidgets('金額を入れてから入るとフェーズなし（従来どおり）', (tester) async {
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
    expect(st.splitTotalPending, isFalse);
    expect(find.byKey(const Key('np-op-+')), findsOneWidget);
  });
}
