import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/features/settings/presentation/category_manage_page.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    setPhoneSurface(tester);
    h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const CategoryManagePage());
    return ProviderScope.containerOf(
        tester.element(find.byType(CategoryManagePage)), listen: false);
  }

  testWidgets('追加: ダイアログから新カテゴリが現在タブのtypeで入る', (tester) async {
    final c = await pumpPage(tester);
    await tester.tap(find.byKey(const Key('add-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), 'ペット');
    await tester.enterText(find.byKey(const Key('category-icon-field')), '🐈');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    // 末尾sortOrderで追加されるためリスト末尾までスクロールして確認
    // （最初のScrollableはTabBarViewなので、リスト自身のScrollableを指定する）
    await tester.scrollUntilVisible(find.text('ペット'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ReorderableListView),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('ペット'), findsOneWidget);
    final cats = await waitForData(c, allCategoriesProvider);
    final added = cats.firstWhere((x) => x.name == 'ペット');
    expect(added.type, CategoryType.expense);
    expect(added.icon, '🐈');
  });

  testWidgets('改名とアーカイブ→復帰、systemは出ない', (tester) async {
    final c = await pumpPage(tester);
    expect(find.text('未分類'), findsNothing); // sentinel非表示
    final cats = await waitForData(c, allCategoriesProvider);
    // 食費はアクティブな内訳（外食）持ちでアーカイブガードに当たるため日用品を使う
    final food = cats.firstWhere((x) => x.name == '日用品');

    await tester.tap(find.byKey(Key('rename-${food.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), '食料品');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('食料品'), findsOneWidget);

    await tester.tap(find.byKey(Key('archive-${food.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('アーカイブ済み'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('unarchive-${food.id}')));
    await tester.pumpAndSettle();
    final after = await waitForData(c, allCategoriesProvider);
    expect(after.firstWhere((x) => x.id == food.id).isArchived, isFalse);
  });

  testWidgets('並べ替え: onReorderがsortOrderを振り直す', (tester) async {
    final c = await pumpPage(tester);
    final rlv = tester
        .widget<ReorderableListView>(find.byType(ReorderableListView).first);
    rlv.onReorderItem!(0, 2); // 先頭（食費）をindex2へ（調整済みインデックス）
    await tester.pumpAndSettle();
    final cats = await waitForData(c, allCategoriesProvider);
    final expenseActive = cats
        .where((x) =>
            x.type == CategoryType.expense &&
            !x.isSystem &&
            !x.isArchived &&
            x.parentId == null) // 内訳（外食）は親の並びに混ぜない
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(expenseActive[2].name, '食費');
  });

  testWidgets('＋内訳で内訳を追加でき、└付きでネスト表示される', (tester) async {
    final c = await pumpPage(tester);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    // シード済みの外食がネスト表示されている
    expect(find.textContaining('└'), findsWidgets);
    expect(find.text('外食'), findsOneWidget);

    // ＋内訳 → ダイアログ → 追加
    await tester.tap(find.byKey(Key('add-sub-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('内訳を追加'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('category-name-field')), 'スーパー');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(find.text('スーパー'), findsOneWidget);
    final all = await waitForData(c, allCategoriesProvider);
    final sup = all.firstWhere((x) => x.name == 'スーパー');
    expect(sup.parentId, foodId);
  });

  testWidgets('内訳行にはさらに＋内訳が付かない（2段まで）', (tester) async {
    final c = await pumpPage(tester);
    final cats = await waitForData(c, allCategoriesProvider);
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;
    expect(find.byKey(Key('add-sub-$eatOutId')), findsNothing);
  });

  testWidgets('内訳のアーカイブが親と独立に動く', (tester) async {
    final c = await pumpPage(tester);
    final cats = await waitForData(c, allCategoriesProvider);
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;

    await tester.tap(find.byKey(Key('archive-$eatOutId')));
    await tester.pumpAndSettle();
    // アクティブ一覧から消え、アーカイブ済みセクションに現れる
    await tester.scrollUntilVisible(find.text('アーカイブ済み'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ReorderableListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('アーカイブ済み'));
    await tester.pumpAndSettle();
    expect(find.text('外食（アーカイブ）'), findsOneWidget);
    final after = await waitForData(c, allCategoriesProvider);
    final food = after.firstWhere((x) => x.name == '食費');
    expect(food.isArchived, isFalse); // 親は無傷
  });

  testWidgets('アクティブな内訳が残る親のアーカイブはSnackBarで拒否される', (tester) async {
    final c = await pumpPage(tester);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    await tester.tap(find.byKey(Key('archive-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('内訳を先にアーカイブしてください'), findsOneWidget);
    final after = await waitForData(c, allCategoriesProvider);
    expect(after.firstWhere((x) => x.id == foodId).isArchived, isFalse);
    await tester.pump(const Duration(seconds: 5)); // SnackBarのpending timer回収
  });
}
