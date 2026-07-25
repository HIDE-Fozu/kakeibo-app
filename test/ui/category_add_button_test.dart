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
  testWidgets('入力グリッド: 末尾の「カテゴリを追加」タイルからカテゴリを新規作成できる',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    // 末尾タイルが存在し、タップで追加ダイアログが開く
    final addTile = find.byKey(const Key('cat-add'));
    expect(addTile, findsOneWidget);
    await tester.ensureVisible(addTile);
    await tester.pumpAndSettle();
    await tester.tap(addTile);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('category-name-field')), findsOneWidget);

    // 名前を入れて追加 → グリッドに新カテゴリが現れる
    await tester.enterText(
        find.byKey(const Key('category-name-field')), 'サブスク');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('category-name-field')), findsNothing);
    expect(find.textContaining('サブスク'), findsOneWidget);
    // 追加タイルは引き続き末尾に1つ
    expect(find.byKey(const Key('cat-add')), findsOneWidget);
  });

  testWidgets('内訳入力のカテゴリ帯: 末尾に「＋ カテゴリを追加」チップが出る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = containerOf(tester);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    ctrl.startCreate(day);
    await tester.pumpAndSettle();

    // 合計1000 → 内訳開始 → 残額行タップで帯を開く
    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('split-remainder')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('split-cat-strip')), findsOneWidget);
    final addChip = find.byKey(const Key('strip-add-category'));
    expect(addChip, findsOneWidget);

    // チップから追加ダイアログが開き、作成後は帯に新カテゴリチップが現れる
    await tester.ensureVisible(addChip);
    await tester.pumpAndSettle();
    await tester.tap(addChip, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('category-name-field')), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('category-name-field')), 'ペット');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ペット'), findsOneWidget);
  });
}
