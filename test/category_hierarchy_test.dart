import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository repo;
  late int foodId;
  late int eatOutId;

  setUp(() async {
    db = newMemoryDb();
    repo = DriftCategoryRepository(db);
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
    eatOutId = all.firstWhere((c) => c.name == '外食').id;
  });
  tearDown(() => db.close());

  test('addCategory(parentId): 内訳が同スコープ末尾のsortOrderで追加される', () async {
    final superId = await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: foodId);
    final rows = await db.categoryDao.allCategories();
    final sup = rows.firstWhere((c) => c.id == superId);
    expect(sup.parentId, foodId);
    expect(sup.sortOrder, 1); // 外食=0 の次
  });

  test('内訳の下に内訳は作れない（2段まで）', () async {
    expect(
      () => repo.addCategory(
          name: 'ラーメン', type: CategoryType.expense, parentId: eatOutId),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('システムカテゴリには内訳を作れない', () async {
    final uncat = await db.categoryDao.uncategorizedId(CategoryType.expense);
    expect(
      () => repo.addCategory(
          name: 'x', type: CategoryType.expense, parentId: uncat),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('typeが親と不一致なら拒否', () async {
    expect(
      () => repo.addCategory(
          name: 'x', type: CategoryType.income, parentId: foodId),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('存在しない親は拒否', () async {
    expect(
      () => repo.addCategory(
          name: 'x', type: CategoryType.expense, parentId: 99999),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('watchAll: 親の直後にその内訳が並ぶ（階層整列）', () async {
    await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: foodId);
    final list = await repo.watchAll().first;
    final foodIdx = list.indexWhere((c) => c.id == foodId);
    expect(list[foodIdx + 1].name, '外食');
    expect(list[foodIdx + 1].parentId, foodId);
    expect(list[foodIdx + 2].name, 'スーパー');
    // 親同士はsortOrder昇順を保つ
    final parents = list.where((c) => c.parentId == null).toList();
    final orders = parents.map((c) => c.sortOrder).toList();
    expect(orders, List.of(orders)..sort());
  });

  test('reorder: 異なるスコープの混在は拒否・同一スコープ（内訳同士）はOK', () async {
    final superId = await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: foodId);
    expect(() => repo.reorder([foodId, eatOutId]), throwsArgumentError);
    await repo.reorder([superId, eatOutId]);
    final rows = await db.categoryDao.allCategories();
    expect(rows.firstWhere((c) => c.id == superId).sortOrder, 0);
    expect(rows.firstWhere((c) => c.id == eatOutId).sortOrder, 1);
  });

  test('内訳のアーカイブは親と独立（内訳→親の順ならアーカイブ可）', () async {
    await repo.setArchived(eatOutId, true);
    final rows = await db.categoryDao.allCategories();
    expect(rows.firstWhere((c) => c.id == eatOutId).isArchived, isTrue);
    expect(rows.firstWhere((c) => c.id == foodId).isArchived, isFalse); // 親は無傷
    // アクティブな内訳が残っていないので親もアーカイブできる
    await repo.setArchived(foodId, true);
    final rows2 = await db.categoryDao.allCategories();
    expect(rows2.firstWhere((c) => c.id == foodId).isArchived, isTrue);
    expect(rows2.firstWhere((c) => c.id == eatOutId).isArchived, isTrue);
  });

  test('アクティブな内訳が残る親はアーカイブできない（幽霊カテゴリ防止）', () async {
    expect(() => repo.setArchived(foodId, true),
        throwsA(isA<CategoryHierarchyError>()));
    expect(() => repo.archive(foodId),
        throwsA(isA<CategoryHierarchyError>()));
  });

  test('changeType: 内訳自身も内訳を持つ親も拒否（不変条件: typeは親と一致）', () async {
    expect(() => repo.changeType(eatOutId, CategoryType.income),
        throwsA(isA<CategoryHierarchyError>()));
    expect(() => repo.changeType(foodId, CategoryType.income),
        throwsA(isA<CategoryHierarchyError>()));
  });
}
