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
    final food = cats.firstWhere((x) => x.name == '食費');

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
            x.type == CategoryType.expense && !x.isSystem && !x.isArchived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(expenseActive[2].name, '食費');
  });
}
