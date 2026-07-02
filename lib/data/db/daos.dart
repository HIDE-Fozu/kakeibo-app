import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';
import 'enums.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);
  // 読み書き/集計は Task 6, 7 で追加する。
}

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<CategoryRow>> allCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

  Future<int> uncategorizedId(CategoryType type) async {
    final row = await (select(categories)
          ..where((c) => c.isSystem.equals(true) & c.type.equalsValue(type)))
        .getSingle();
    return row.id;
  }
}
