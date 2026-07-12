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
  testWidgets('詳細入力: 税込/税抜・8%/10%で税込換算、残額は2行目・やめるで合計保持',
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

    // 金額0では詳細入力ボタンは出ない
    expect(find.byKey(const Key('start-split')), findsNothing);

    // 合計 1000 → 開始
    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();
    expect(find.text('詳細入力（合計 ¥1,000）'), findsOneWidget);
    expect(find.byKey(const Key('np-op-+')), findsOneWidget);

    // 1行目は自動額なし
    expect(st().splitLineAmount(0), isNull);

    // 行1に500入力 → 既定=税抜10% → 税込550。残額行(2行目)が自動生成
    ctrl.splitTapDigit(5);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-line-1')), findsOneWidget);
    expect(st().splits![0].amountYen, 550); // 税抜10%の税込換算

    // 税込に切替 → そのまま500
    await tester.tap(find.byKey(const Key('split-incl-0')));
    await tester.pumpAndSettle();
    expect(st().splits![0].taxIncluded, isTrue);
    expect(st().splits![0].amountYen, 500);

    // 税抜へ戻して8% → 540
    await tester.tap(find.byKey(const Key('split-excl-0')));
    await tester.tap(find.byKey(const Key('split-rate8-0')));
    await tester.pumpAndSettle();
    expect(st().splits![0].amountYen, 540);

    // 一括で全行を税込に
    await tester.tap(find.byKey(const Key('split-bulk-incl')));
    await tester.pumpAndSettle();
    expect(st().splits!.every((l) => l.taxIncluded), isTrue);

    // やめる → 通常モードへ戻り合計は保持
    await tester.tap(find.byKey(const Key('cancel-split')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-split')), findsOneWidget);
    expect(st().amountYen, 1000);
  });
}
