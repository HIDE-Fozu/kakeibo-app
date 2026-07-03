import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/enums.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class CategoryInUseError implements Exception {
  final int categoryId;
  const CategoryInUseError(this.categoryId);
  @override
  String toString() => 'CategoryInUseError(category $categoryId has transactions)';
}

class SystemCategoryError implements Exception {
  final int categoryId;
  const SystemCategoryError(this.categoryId);
  @override
  String toString() => 'SystemCategoryError(category $categoryId is protected)';
}

class DriftCategoryRepository implements CategoryRepository {
  final AppDatabase _db;
  DriftCategoryRepository(this._db);

  @override
  Future<List<CategoryEntity>> active() async {
    final rows = await _db.categoryDao.activeCategories();
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<CategoryEntity>> watchAll() => _db.categoryDao
      .watchAllCategories()
      .map((rows) => rows.map(_toEntity).toList());

  CategoryEntity _toEntity(CategoryRow r) => CategoryEntity(
        id: r.id,
        name: r.name,
        type: r.type,
        icon: r.icon,
        sortOrder: r.sortOrder,
        isArchived: r.isArchived,
        isSystem: r.isSystem,
      );

  @override
  Future<void> archive(int categoryId) => _db.categoryDao.archive(categoryId);

  @override
  Future<void> changeType(int categoryId, CategoryType type) async {
    final count = await _db.categoryDao.countTransactionsFor(categoryId);
    if (count > 0) {
      throw CategoryInUseError(categoryId);
    }
    await _db.categoryDao.setType(categoryId, type);
  }

  Future<void> _guardSystem(int categoryId) async {
    final row = await _db.categoryDao.byId(categoryId);
    if (row.isSystem) throw SystemCategoryError(categoryId);
  }

  @override
  Future<int> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '空にできません');
    final next = await _db.categoryDao.maxSortOrder() + 1;
    return _db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: trimmed,
      type: type,
      icon: Value(icon),
      sortOrder: Value(next),
    ));
  }

  @override
  Future<void> rename(int categoryId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '空にできません');
    await _guardSystem(categoryId);
    await _db.categoryDao.renameCategory(categoryId, trimmed);
  }

  @override
  Future<void> setArchived(int categoryId, bool archived) async {
    await _guardSystem(categoryId);
    await _db.categoryDao.setArchived(categoryId, archived);
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    for (final id in orderedIds) {
      await _guardSystem(id);
    }
    await _db.categoryDao.updateSortOrders({
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    });
  }
}
