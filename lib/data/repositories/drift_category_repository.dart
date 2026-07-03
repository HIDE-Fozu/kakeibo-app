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
}
