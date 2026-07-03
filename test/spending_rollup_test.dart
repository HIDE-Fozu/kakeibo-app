import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/daos.dart' show CategorySpendRow;
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/services/spending_rollup.dart';

CategoryEntity cat(int id, String name, {int? parentId, bool archived = false}) =>
    CategoryEntity(
      id: id,
      name: name,
      type: CategoryType.expense,
      icon: null,
      sortOrder: id,
      isArchived: archived,
      isSystem: false,
      parentId: parentId,
    );

CategorySpendRow row(int id, String name, int total,
        {int? parentId, bool archived = false}) =>
    CategorySpendRow(
      categoryId: id,
      categoryName: name,
      isArchived: archived,
      parentId: parentId,
      total: total,
    );

void main() {
  final cats = [
    cat(1, '食費'),
    cat(2, '外食', parentId: 1),
    cat(3, 'スーパー', parentId: 1),
    cat(4, '日用品'),
  ];

  test('内訳は親にロールアップされ、直接分はdirectTotalに残る', () {
    final groups = rollupSpending([
      row(1, '食費', 1200),
      row(2, '外食', 800, parentId: 1),
      row(3, 'スーパー', 300, parentId: 1),
      row(4, '日用品', 500),
    ], cats);
    final food = groups.firstWhere((g) => g.categoryId == 1);
    expect(food.total, 2300);
    expect(food.directTotal, 1200);
    expect(food.subs.map((s) => s.name).toList(), ['外食', 'スーパー']); // 降順
    expect(food.hasSubs, isTrue);
    // INVARIANT: 内訳和 + 直接分 == 親計
    expect(food.subs.fold<int>(0, (a, s) => a + s.total) + food.directTotal,
        food.total);
    // INVARIANT: 親計和 == 全行合計
    expect(groups.fold<int>(0, (a, g) => a + g.total), 2800);
  });

  test('直接計上のない親（内訳にだけ支出）もグループになり名前はcategoriesから引く', () {
    final groups = rollupSpending([row(2, '外食', 800, parentId: 1)], cats);
    final food = groups.single;
    expect(food.categoryId, 1);
    expect(food.name, '食費');
    expect(food.directTotal, 0);
    expect(food.total, 800);
  });

  test('グループは合計の降順', () {
    final groups = rollupSpending([
      row(4, '日用品', 5000),
      row(1, '食費', 100),
      row(2, '外食', 200, parentId: 1),
    ], cats);
    expect(groups.map((g) => g.categoryId).toList(), [4, 1]);
  });

  test('防御: parentIdがcategoriesに解決できない行は自分自身が親', () {
    final groups = rollupSpending([row(9, '謎', 100, parentId: 999)], cats);
    expect(groups.single.categoryId, 9);
    expect(groups.single.name, '謎');
    expect(groups.single.total, 100);
  });

  test('アーカイブフラグが親・内訳それぞれに伝播する', () {
    final archivedCats = [
      cat(1, '食費', archived: true),
      cat(2, '外食', parentId: 1, archived: true),
    ];
    final groups = rollupSpending(
        [row(2, '外食', 800, parentId: 1, archived: true)], archivedCats);
    expect(groups.single.isArchived, isTrue);
    expect(groups.single.subs.single.isArchived, isTrue);
  });
}
