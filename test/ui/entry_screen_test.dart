import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_category_providers.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

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
    expect(find.text('2026年7月15日'), findsOneWidget); // 日付は常に表示（年月日）

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

  testWidgets('店舗名は常時・詳細メモは「メモを追加」ボタンから開いて別々に入力できる',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 店舗名は常時表示（1欄）、詳細メモは畳まれ「メモを追加」ボタン
    expect(find.byType(TextFormField), findsOneWidget); // 店舗名のみ
    await tester.enterText(find.byType(TextFormField), 'スーパーA'); // 店舗名

    // 「メモを追加」→ 詳細メモ欄が出る
    await tester.ensureVisible(find.byKey(const Key('add-memo')));
    await tester.tap(find.byKey(const Key('add-memo')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2)); // 店舗名＋詳細メモ
    await tester.enterText(fields.at(1), 'ポイント2倍'); // 詳細メモ

    final s = containerOf(tester).read(entryFormControllerProvider)!;
    expect(s.storeName, 'スーパーA');
    expect(s.memo, 'ポイント2倍');
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
    expect(find.text('2026年7月15日'), findsOneWidget); // 日付維持

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
    expect(find.byType(TextFormField), findsNWidgets(2)); // 店舗名・詳細メモの2欄
    expect(find.byType(SegmentedButton<TxnType>), findsNothing); // 編集では型不変

    await tester.tap(find.byKey(const Key('delete-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(await repo.forMonth(2026, 7), isEmpty);
  });

  testWidgets('内訳: チップはカテゴリの真下に出る・選択で自動格納→保存は内訳idに',
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

    // 食費タイル（▾付き）をタップ → チップがグリッドの真下に出る
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subcategory-chips')), findsOneWidget);
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsOneWidget);
    // チップはグリッドより下（真下）にある
    final gridBottom =
        tester.getRect(find.byKey(Key('cat-tile-$foodId'))).bottom;
    expect(tester.getRect(find.byKey(Key('sub-chip-$eatOutId'))).top,
        greaterThanOrEqualTo(gridBottom - 1));

    // 外食チップを選択 → ラベルが「外食 ▾」に変わり、チップは自動格納
    await tester.tap(find.byKey(Key('sub-chip-$eatOutId')));
    await tester.pumpAndSettle();
    final tileTexts = tester.widgetList<Text>(find.descendant(
        of: find.byKey(Key('cat-tile-$foodId')), matching: find.byType(Text)));
    expect(tileTexts.any((t) => t.data == '外食 ▾'), isTrue);
    expect(find.byKey(const Key('subcategory-chips')), findsNothing);

    // 同じタイルを再タップ → 再展開（選択は維持）→ もう一度で格納
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsOneWidget);
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsNothing);

    // 保存 → categoryIdは外食のid
    await tester.ensureVisible(find.byKey(const Key('save-btn')));
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();
    final txs =
        await container.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.categoryId, eatOutId);
    expect(txs.single.amountYen, 500);
  });

  testWidgets('内訳チップの有無でメモ欄・保存ボタンが動かない（枠を予約）', (tester) async {
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

    // チップが出ていない状態のメモ欄（詳細メモ=最下段の欄）・保存ボタン位置
    final memoBefore = tester.getRect(find.byType(TextFormField).last);
    final saveBefore = tester.getRect(find.byKey(const Key('save-btn')));

    // 食費タップでチップが固定枠に出る → メモ・保存は1pxも動かない
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subcategory-chips')), findsOneWidget);
    expect(tester.getRect(find.byType(TextFormField).last), memoBefore);
    expect(tester.getRect(find.byKey(const Key('save-btn'))), saveBefore);
  });

  testWidgets('追加ダイアログの「既存の内容を編集」から内訳を削除できる', (tester) async {
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
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();

    // ＋追加 → ダイアログ → 折りたたみ「既存の内容を編集」を開く → 外食を削除
    await tester.tap(find.byKey(const Key('add-sub-inline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-existing-subs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('edit-sub-delete-$eatOutId')));
    await tester.pumpAndSettle();

    final after = container.read(allCategoriesProvider).valueOrNull!;
    expect(after.firstWhere((c) => c.id == eatOutId).isArchived, isTrue);
  });

  testWidgets('内訳追加ダイアログ「アイコンの表示順設定」で親アイコンを並べ替え→固定順保存',
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

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('cat-tile-$foodId'))); // 内訳チップを開く
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-sub-inline'))); // 追加ダイアログ
    await tester.pumpAndSettle();

    // 「アイコンの表示順設定」を開く → 先頭(食費)をindex3へ並べ替え
    await tester.tap(find.byKey(const Key('reorder-icons')));
    await tester.pumpAndSettle();
    final rlv = tester
        .widget<ReorderableListView>(find.byType(ReorderableListView).first);
    rlv.onReorderItem!(0, 3);
    await tester.pumpAndSettle();

    // 固定順に切替＆食費は先頭でなくなる（一覧には残る）
    expect(container.read(appSettingsProvider).categoryOrder,
        CategoryOrderMode.manual);
    final after = container.read(entryCategoriesProvider(TxnType.expense)).value!;
    expect(after.first.name, isNot('食費'));
    expect(after.map((c) => c.name), contains('食費'));
  });

  testWidgets('内訳チップ長押し→削除でその内訳がアーカイブされる', (tester) async {
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
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();

    // 外食チップを長押し → ボトムシート → 削除
    await tester.longPress(find.byKey(Key('sub-chip-$eatOutId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sub-delete')));
    await tester.pumpAndSettle();

    // 外食はアーカイブされ、アクティブ内訳から消える
    final after = container.read(allCategoriesProvider).valueOrNull!;
    expect(after.firstWhere((c) => c.id == eatOutId).isArchived, isTrue);
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsNothing);
  });

  testWidgets('内訳チップ長押し→名前変更で改名される', (tester) async {
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
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(Key('sub-chip-$eatOutId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sub-rename')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sub-rename-field')), 'ランチ');
    await tester.tap(find.byKey(const Key('sub-rename-save')));
    await tester.pumpAndSettle();

    final after = container.read(allCategoriesProvider).valueOrNull!;
    expect(after.firstWhere((c) => c.id == eatOutId).name, 'ランチ');
  });

  testWidgets('内訳チップ右端の＋でその場追加→追加した内訳が選択される', (tester) async {
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

    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-sub-inline')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('category-name-field')), 'カフェ');
    // ダイアログの「追加」ボタン（インラインの追加ボタンと同名なので型で限定）
    await tester.tap(find.widgetWithText(FilledButton, '追加'));
    await tester.pumpAndSettle();

    // DBに内訳として追加され、そのまま選択・チップ列は格納・ラベル変化
    final after = container.read(allCategoriesProvider).valueOrNull!;
    final cafe = after.firstWhere((c) => c.name == 'カフェ');
    expect(cafe.parentId, foodId);
    expect(container.read(entryFormControllerProvider)!.categoryId, cafe.id);
    expect(find.byKey(const Key('subcategory-chips')), findsNothing);
    final tileTexts = tester.widgetList<Text>(find.descendant(
        of: find.byKey(Key('cat-tile-$foodId')), matching: find.byType(Text)));
    expect(tileTexts.any((t) => t.data == 'カフェ ▾'), isTrue);
  });

  testWidgets('カテゴリ長押しドラッグで並べ替え→固定順で保存される', (tester) async {
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

    // 既定sortOrderで食費が先頭
    final before = container.read(entryCategoriesProvider(TxnType.expense)).value!;
    expect(before.first.name, '食費');
    expect(container.read(appSettingsProvider).categoryOrder,
        CategoryOrderMode.recentlyUsed);

    // 食費(左上)を長押し→右へドラッグ→ドロップ
    final start = tester.getCenter(find.byKey(Key('cat-tile-$foodId')));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600)); // 長押し成立
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    // 固定順に切替＆食費は先頭ではなくなる（後方へ移動）が一覧には残る
    expect(container.read(appSettingsProvider).categoryOrder,
        CategoryOrderMode.manual);
    final after = container.read(entryCategoriesProvider(TxnType.expense)).value!;
    expect(after.first.name, isNot('食費'));
    expect(after.map((c) => c.name), contains('食費'));
  });

  testWidgets('横スクロールで2ページ目の末尾カテゴリが見えてくる', (tester) async {
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

    // その他は2ページ目にあり初期は可視領域の右外
    final beforeLeft = tester.getRect(find.text('その他')).left;
    // タイル上を横ドラッグ（長押しでないのでグリッドがスクロールする）
    await tester.drag(find.byKey(Key('cat-tile-$foodId')), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('その他')).left, lessThan(beforeLeft));
  });

  testWidgets('右送りボタンで2ページ目のカテゴリが見えてくる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) =>
                ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final beforeLeft = tester.getRect(find.text('その他')).left;
    await tester.tap(find.byKey(const Key('cat-scroll-right')));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('その他')).left, lessThan(beforeLeft));
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
