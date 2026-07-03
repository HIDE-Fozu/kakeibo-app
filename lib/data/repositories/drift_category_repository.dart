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

/// 階層制約違反（2段超・システム親・type不一致・親不在・幽霊化するアーカイブ）。
class CategoryHierarchyError implements Exception {
  final String message;
  const CategoryHierarchyError(this.message);
  @override
  String toString() => 'CategoryHierarchyError($message)';
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
  Stream<List<CategoryEntity>> watchAll() =>
      _db.categoryDao.watchAllCategories().map(_hierarchical);

  /// 親をsortOrder順、各親の直後にその内訳をsortOrder順で並べる。
  List<CategoryEntity> _hierarchical(List<CategoryRow> rows) {
    final ents = rows.map(_toEntity).toList(); // DAOがsortOrder昇順で返す
    final byParent = <int, List<CategoryEntity>>{};
    for (final e in ents) {
      final p = e.parentId;
      if (p != null) byParent.putIfAbsent(p, () => []).add(e);
    }
    return [
      for (final e in ents)
        if (e.parentId == null) ...[e, ...byParent[e.id] ?? const []],
    ];
  }

  CategoryEntity _toEntity(CategoryRow r) => CategoryEntity(
        id: r.id,
        name: r.name,
        type: r.type,
        icon: r.icon,
        sortOrder: r.sortOrder,
        isArchived: r.isArchived,
        isSystem: r.isSystem,
        parentId: r.parentId,
      );

  @override
  Future<void> archive(int categoryId) => setArchived(categoryId, true);

  @override
  Future<void> changeType(int categoryId, CategoryType type) async {
    final row = await _db.categoryDao.byId(categoryId);
    if (row.parentId != null) {
      throw const CategoryHierarchyError('内訳のtypeは変更できません（親と一致が必要）');
    }
    if (await _db.categoryDao.countChildrenOf(categoryId) > 0) {
      throw const CategoryHierarchyError('内訳を持つカテゴリのtypeは変更できません');
    }
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
    int? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '空にできません');
    if (parentId != null) {
      final CategoryRow parent;
      try {
        parent = await _db.categoryDao.byId(parentId);
      } on StateError {
        throw CategoryHierarchyError('親カテゴリ $parentId が存在しません');
      }
      if (parent.parentId != null) {
        throw const CategoryHierarchyError('内訳の下に内訳は作れません（階層は2段まで）');
      }
      if (parent.isSystem) {
        throw const CategoryHierarchyError('システムカテゴリには内訳を作れません');
      }
      if (parent.type != type) {
        throw const CategoryHierarchyError('内訳のtypeは親と一致させる必要があります');
      }
    }
    final next = await _db.categoryDao.maxSortOrderWithin(parentId) + 1;
    return _db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: trimmed,
      type: type,
      icon: Value(icon),
      sortOrder: Value(next),
      parentId: Value(parentId),
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
    if (archived) {
      final row = await _db.categoryDao.byId(categoryId);
      if (row.parentId == null &&
          await _db.categoryDao.countActiveChildrenOf(categoryId) > 0) {
        throw const CategoryHierarchyError(
            'アクティブな内訳が残っています（先に内訳をアーカイブしてください）');
      }
    }
    await _db.categoryDao.setArchived(categoryId, archived);
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    int? scope;
    var first = true;
    for (final id in orderedIds) {
      final row = await _db.categoryDao.byId(id);
      if (row.isSystem) throw SystemCategoryError(id);
      if (first) {
        scope = row.parentId;
        first = false;
      } else if (row.parentId != scope) {
        throw ArgumentError('並べ替えは同一スコープ（同じ親）内のみです');
      }
    }
    await _db.categoryDao.updateSortOrders({
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    });
  }
}
