import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';
import 'enums.dart';
import '../../domain/money/civil_date.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// 半開区間 [firstOfMonth, firstOfNextMonth) を ISO 文字列比較で表現。
  /// date 列はゼロ埋め YYYY-MM-DD なので辞書順比較＝日付順比較。
  Expression<bool> _inMonth(int year, int month) {
    final startIso = CivilDate.firstOfMonthIso(year, month);
    final endIso = CivilDate.firstOfNextMonthIso(year, month);
    return transactions.date.isBiggerOrEqualValue(startIso) &
        transactions.date.isSmallerThanValue(endIso);
  }

  Future<int> insertTransaction(TransactionsCompanion c) =>
      into(transactions).insert(c);

  Future<List<TransactionRow>> transactionsInMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
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
