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
  testWidgets('内訳: 税は内税⇄外税トグルで全行即適用・「個別」ダイアログで行単位',
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

    // 金額0では内訳入力ボタンは出ない
    expect(find.byKey(const Key('start-split')), findsNothing);

    // 合計 1000 → 開始
    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // タイトル行に「＋品目」と税トグル。行内に税UIは無い（個別はダイアログ）。
    expect(find.byKey(const Key('split-add')), findsOneWidget);
    expect(find.byKey(const Key('split-tax-mode')), findsOneWidget);
    expect(find.byKey(const Key('np-op-+')), findsOneWidget);
    expect(find.byKey(const Key('split-incl-0')), findsNothing);
    // 残額行は最下段に固定表示
    expect(find.byKey(const Key('split-remainder')), findsOneWidget);

    // 1行目は自動額なし
    expect(st().splitLineAmount(0), isNull);

    // 行0に500 → 既定=内税でそのまま500
    ctrl.splitTapDigit(5);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();
    expect(st().splits![0].taxIncluded, isTrue);
    expect(st().splits![0].amountYen, 500);

    // 内税を外す（外税トグル）→ 全行外税10% → 550
    await tester.tap(find.byKey(const Key('split-tax-mode')));
    await tester.pumpAndSettle();
    expect(st().splits![0].taxIncluded, isFalse);
    expect(st().splits![0].amountYen, 550);

    // 8%トグル → 540
    await tester.tap(find.byKey(const Key('split-tax-8')));
    await tester.pumpAndSettle();
    expect(st().splits![0].amountYen, 540);

    // 「個別」ダイアログ: 行0だけ内税へ戻す
    await tester.tap(find.byKey(const Key('split-tax-per')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-tax-done')), findsOneWidget);
    await tester.tap(find.byKey(const Key('split-incl-0')));
    await tester.pumpAndSettle();
    expect(st().splits![0].taxIncluded, isTrue);
    expect(st().splits![0].amountYen, 500);
    await tester.tap(find.byKey(const Key('split-tax-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-tax-done')), findsNothing);

    // まちまち状態からトグルで全行内税へ
    await tester.tap(find.byKey(const Key('split-tax-mode')));
    await tester.pumpAndSettle();
    expect(st().splits!.every((l) => l.taxIncluded), isTrue);

    // やめる → 通常モードへ戻り合計は保持
    await tester.tap(find.byKey(const Key('cancel-split')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-split')), findsOneWidget);
    expect(st().amountYen, 1000);
  });

  testWidgets('内訳: カテゴリは帯で選ぶ（カテゴリを追加→チップ割当＋閉じる・親は内訳展開）',
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

    // 合計1000 → 内訳入力開始
    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // 分割中は本体にカテゴリ見出し・常設グリッド・帯のどれも出ない
    expect(find.text('カテゴリ'), findsNothing);
    expect(find.textContaining('日用品'), findsNothing);
    expect(find.byKey(const Key('split-cat-strip')), findsNothing);

    // 行0に300（既定=内税）
    ctrl.splitTapDigit(3);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();

    // 行0の「＋ カテゴリ」→ 帯が電卓の上に開く
    await tester.tap(find.byKey(const Key('split-pickcat-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-cat-strip')), findsOneWidget);
    expect(find.textContaining('日用品'), findsOneWidget); // 帯内チップ（絵文字付き）

    // 日用品チップ → 行0へ割当・帯が閉じる
    await tester.tap(find.textContaining('日用品'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-cat-strip')), findsNothing);
    expect(st().splits![0].categoryId, isNotNull);
    expect(find.textContaining('日用品'), findsOneWidget); // 行のチップ表示

    // 残額行タップでも同じ帯が開く
    await tester.tap(find.byKey(const Key('split-remainder')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-cat-strip')), findsOneWidget);

    // 食費（内訳あり親）→ 親を割当しつつ帯は内訳チップ表示に切替
    await tester.tap(find.textContaining('食費'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('strip-back')), findsOneWidget);
    expect(find.textContaining('外食'), findsOneWidget);

    // 外食チップ → 残額行が外食に確定・帯が閉じる → 保存可
    await tester.tap(find.textContaining('外食'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-cat-strip')), findsNothing);
    expect(st().canSave, isTrue);
  });
}
