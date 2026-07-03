import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

/// EntryScreen はpushして開く（popの検証のため）。
class Host extends ConsumerWidget {
  final void Function(WidgetRef ref) onOpen;
  const Host({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              onOpen(ref);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EntryScreen()));
            },
            child: const Text('open'),
          ),
        ),
      );
}

// EntryScreenをpushするとHostはoffstageになるため、常時onstageのMaterialApp基準で取る
ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

void main() {
  testWidgets('新規入力: テンキー→カテゴリ→保存でpopし、DBに入る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    final container = containerOf(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('入力'), findsOneWidget);
    expect(find.text('2026/07/15'), findsOneWidget); // 日付は常に表示

    // 保存はamount+categoryが揃うまで無効
    expect(
        tester.widget<FilledButton>(find.byKey(const Key('save-btn'))).onPressed,
        isNull);

    await tester.tap(find.text('5'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();
    expect(find.text('¥500'), findsOneWidget);

    await tester.tap(find.textContaining('食費')); // ラベルは「食費 ▾」（内訳あり）
    await tester.pump();
    // チップ列が開いて保存ボタンが押し下げられるためスクロールしてから押す
    await tester.ensureVisible(find.byKey(const Key('save-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget); // popして戻った
    final list =
        await container.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(list.single.amountYen, 500);
  });

  testWidgets('収入へ切替でカテゴリ候補が変わり選択がクリアされる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('食費')); // ラベルは「食費 ▾」（内訳あり）
    await tester.pump();
    await tester.tap(find.text('収入'));
    await tester.pumpAndSettle();
    expect(find.text('給与'), findsOneWidget);
    expect(find.textContaining('食費'), findsNothing);
    expect(containerOf(tester).read(entryFormControllerProvider)!.categoryId,
        isNull);
  });

  testWidgets('メモは折りたたみ→展開で入力できる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memo-field')), findsNothing);
    await tester.tap(find.byKey(const Key('memo-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('memo-field')), 'スーパーA');
    expect(containerOf(tester).read(entryFormControllerProvider)!.memo, 'スーパーA');
  });

  testWidgets('保存して続ける: 画面に留まり金額リセット・日付維持', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('8'));
    await tester.tap(find.textContaining('食費')); // ラベルは「食費 ▾」（内訳あり）
    await tester.pump();
    // チップ列が開いてボタンが押し下げられるためスクロールしてから押す
    await tester.ensureVisible(find.byKey(const Key('save-continue-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-continue-btn')));
    await tester.pumpAndSettle();

    expect(find.text('入力'), findsOneWidget); // 留まっている
    expect(find.text('保存しました'), findsOneWidget); // SnackBar
    expect(find.text('¥0'), findsOneWidget); // 金額リセット
    expect(find.text('2026/07/15'), findsOneWidget); // 日付維持

    // SnackBarの自動消滅Timer(既定4s)をFakeAsyncで消化（pending timer検出での失敗を回避）
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('編集モード: 値ロード・型トグル非表示・削除ボタン（確認つき）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    late TransactionEntity seeded;
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startEdit(seeded)));
    final container = containerOf(tester);
    final repo = container.read(transactionRepositoryProvider);
    final cats = await waitForData(container, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 1200,
        date: day,
        categoryId: foodId,
        source: TxnSource.manual,
        memo: '弁当'));
    seeded = (await repo.forMonth(2026, 7)).single;

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('編集'), findsOneWidget);
    expect(find.text('¥1,200'), findsOneWidget);
    expect(find.byKey(const Key('memo-field')), findsOneWidget); // memoありは展開済み
    expect(find.byType(SegmentedButton<TxnType>), findsNothing); // 編集では型不変

    await tester.tap(find.byKey(const Key('delete-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(await repo.forMonth(2026, 7), isEmpty);
  });

  testWidgets('内訳: チップはテンキー上のオーバーレイ・選択で自動格納→再タップで開閉→保存は内訳idに',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    final container = containerOf(tester);
    final cats = await waitForData(container, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 金額入力（500）
    await tester.tap(find.text('5'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();

    // 食費タイル（▾付き）をタップ → チップ列がテンキー上に被さって出る
    // （レイアウトシフト0: 保存ボタンの位置は動かない）
    final saveRectBefore = tester.getRect(find.byKey(const Key('save-btn')));
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subcategory-overlay')), findsOneWidget);
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('save-btn'))), saveRectBefore);

    // 外食チップを選択 → ラベルが「外食 ▾」に変わり、チップ列は自動格納
    await tester.tap(find.byKey(Key('sub-chip-$eatOutId')));
    await tester.pumpAndSettle();
    final tileTexts = tester.widgetList<Text>(find.descendant(
        of: find.byKey(Key('cat-tile-$foodId')), matching: find.byType(Text)));
    expect(tileTexts.any((t) => t.data == '外食 ▾'), isTrue);
    expect(find.byKey(const Key('subcategory-overlay')), findsNothing);

    // 同じタイルを再タップ → 再展開（選択は維持）→ もう一度で格納
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsOneWidget);
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsNothing);

    // 保存 → categoryIdは外食のid
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();
    final txs =
        await container.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.categoryId, eatOutId);
    expect(txs.single.amountYen, 500);
  });

  testWidgets('内訳未選択のまま保存すると親カテゴリに計上される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    final container = containerOf(tester);
    final cats = await waitForData(container, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(Key('cat-tile-$foodId')));
    await tester.pump();
    await tester.tap(find.byKey(Key('cat-tile-$foodId'))); // チップは開くが選ばない
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    final txs =
        await container.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.categoryId, foodId); // 親に計上
  });
}
