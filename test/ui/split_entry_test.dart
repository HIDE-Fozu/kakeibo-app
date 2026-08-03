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

    // 分割中もカテゴリは同じ位置に常設（見出し＋1行帯）。グリッドは出ない
    expect(find.text('カテゴリ'), findsOneWidget);
    expect(find.byKey(const Key('split-cat-strip')), findsOneWidget);
    expect(find.textContaining('日用品'), findsOneWidget); // 帯内チップ（絵文字付き）

    // 行0に300（既定=内税）
    ctrl.splitTapDigit(3);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();

    // 帯の日用品チップ → アクティブ行（行0）へ割当。帯は出たまま
    await tester.ensureVisible(find.byKey(const Key('split-cat-strip')));
    await tester.tap(find.textContaining('日用品'));
    await tester.pumpAndSettle();
    expect(st().splits![0].categoryId, isNotNull);
    expect(find.byKey(const Key('split-cat-strip')), findsOneWidget);
    // 帯内チップ＋行のチップ表示の2箇所
    expect(find.textContaining('日用品'), findsNWidgets(2));

    // 残額行タップ → 帯の割当先が残額行になる
    await tester.tap(find.byKey(const Key('split-remainder')));
    await tester.pumpAndSettle();

    // 食費（内訳あり親）→ 親を割当しつつ帯は内訳チップ表示に切替
    await tester.tap(find.textContaining('食費').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('strip-back')), findsOneWidget);
    expect(find.textContaining('外食'), findsOneWidget);

    // 外食チップ → 残額行が外食に確定・帯は親一覧表示に戻る → 保存可
    await tester.tap(find.textContaining('外食'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('strip-back')), findsNothing);
    expect(find.byKey(const Key('split-cat-strip')), findsOneWidget);
    expect(st().canSave, isTrue);
  });

  testWidgets('内訳: 残額行はどこをタップしてもアクティブに・「＋」の行追加は生きている',
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

    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // 行0に300を入れ、残額行の「余白」（残り表示のあたり）をタップ
    ctrl.splitTapDigit(3);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();
    expect(st().activeSplitIndex, 0);
    await tester.tap(find.byKey(const Key('split-line-remainder')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(st().activeSplitIndex, st().splits!.length - 1);

    // 行0のメモ欄タップでも行0がアクティブに戻る（メモ欄が行の大半を占めるため）
    await tester.tap(find.textContaining('日用品').first);
    await tester.pumpAndSettle(); // まず行末尾にカテゴリ… ではなく帯→残額行へ割当
    // ↑残額行に日用品が付いた。行0へ戻すためメモ欄をタップ
    await tester.tap(find.byKey(const Key('split-line-0')));
    await tester.pumpAndSettle();
    expect(st().activeSplitIndex, 0);

    // 「＋」ボタンは背面の行タップに奪われず行を追加する（アリーナ検証）
    final before = st().splits!.length;
    await tester.tap(find.byKey(const Key('split-add')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(st().splits!.length, before + 1);
  });

  testWidgets('内訳: 行メモはボタン→ダイアログで入力し、行に本文が表示される',
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

    ctrl.tapDigit(1);
    ctrl.tapDoubleZero();
    ctrl.tapDigit(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-split')));
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();

    // 行0: 300＋日用品 → メモボタンが出る（カテゴリ未選択の行には出ない）
    ctrl.splitTapDigit(3);
    ctrl.splitTapDoubleZero();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-memo-btn-0')), findsNothing);
    await tester.tap(find.textContaining('日用品'));
    await tester.pumpAndSettle();
    final memoBtn = find.byKey(const Key('split-memo-btn-0'));
    expect(memoBtn, findsOneWidget);

    // ボタン → ダイアログで入力・保存 → 行に本文表示＆stateに反映
    await tester.tap(memoBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('split-memo-field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('split-memo-field')), '洗剤');
    await tester.tap(find.byKey(const Key('split-memo-save')));
    await tester.pumpAndSettle();
    expect(st().splits![0].memo, '洗剤');
    expect(find.text('洗剤'), findsOneWidget);

    // 再度開くと現在値が入っている（編集）
    await tester.tap(memoBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('洗剤'), findsNWidgets(2)); // ダイアログ内+行表示
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(st().splits![0].memo, '洗剤'); // キャンセルは変更なし
  });
}
