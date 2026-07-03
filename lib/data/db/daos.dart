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

  /// 編集で変わりうるフィールドだけを更新し、updatedAt を現在時刻に。
  /// type / source / createdAt は触らない（source は由来として不変）。
  Future<void> updateFields(
    int id, {
    required int amount,
    required CivilDate date,
    required int categoryId,
    PaymentMethod? paymentMethod,
    String? memo,
  }) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amount: Value(amount),
        date: Value(date),
        categoryId: Value(categoryId),
        paymentMethod: Value(paymentMethod),
        memo: Value(memo),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<TransactionRow>> transactionsInMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<TransactionRow>> watchTransactionsInMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Stream<Map<TxnType, int>> watchTotalsByType(int year, int month) {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.type, amountSum])
      ..where(_inMonth(year, month))
      ..groupBy([transactions.type]);
    return query.watch().map((rows) => {
          for (final row in rows)
            row.readWithConverter(transactions.type)!: row.read(amountSum) ?? 0,
        });
  }

  Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month) {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId),
          useColumns: false),
    ])
      ..addColumns([categories.id, categories.name, categories.isArchived, amountSum])
      ..where(_inMonth(year, month) &
          transactions.type.equalsValue(TxnType.expense))
      ..groupBy([transactions.categoryId])
      ..orderBy([OrderingTerm.desc(amountSum)]);
    return query.watch().map((rows) => [
          for (final row in rows)
            CategorySpendRow(
              categoryId: row.read(categories.id)!,
              categoryName: row.read(categories.name)!,
              isArchived: row.read(categories.isArchived)!,
              total: row.read(amountSum) ?? 0,
            ),
        ]);
  }

  /// カテゴリ別の最終利用日。取引date（YYYY-MM-DD、辞書順=時系列順）のMAX。
  Stream<Map<int, String>> watchLastUsedIsoByCategory() {
    final maxDate = transactions.date.max();
    final query = selectOnly(transactions)
      ..addColumns([transactions.categoryId, maxDate])
      ..groupBy([transactions.categoryId]);
    return query.watch().map((rows) => {
          for (final row in rows)
            row.read(transactions.categoryId)!: row.read(maxDate)!,
        });
  }

  Future<void> deleteById(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<Map<TxnType, int>> totalsByType(int year, int month) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.type, amountSum])
      ..where(_inMonth(year, month))
      ..groupBy([transactions.type]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.readWithConverter(transactions.type)!: row.read(amountSum) ?? 0,
    };
  }

  Future<List<CategorySpendRow>> spendingByCategory(int year, int month) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId),
          useColumns: false),
    ])
      ..addColumns([categories.id, categories.name, categories.isArchived, amountSum])
      ..where(_inMonth(year, month) &
          transactions.type.equalsValue(TxnType.expense))
      ..groupBy([transactions.categoryId])
      ..orderBy([OrderingTerm.desc(amountSum)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        CategorySpendRow(
          categoryId: row.read(categories.id)!,
          categoryName: row.read(categories.name)!,
          isArchived: row.read(categories.isArchived)!,
          total: row.read(amountSum) ?? 0,
        ),
    ];
  }
}

class CategorySpendRow {
  final int categoryId;
  final String categoryName;
  final bool isArchived;
  final int total;
  const CategorySpendRow({
    required this.categoryId,
    required this.categoryName,
    required this.isArchived,
    required this.total,
  });
}

@DriftAccessor(tables: [Categories, Transactions])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<CategoryRow>> allCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

  Stream<List<CategoryRow>> watchAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<int> uncategorizedId(CategoryType type) async {
    final row = await (select(categories)
          ..where((c) => c.isSystem.equals(true) & c.type.equalsValue(type)))
        .getSingle();
    return row.id;
  }

  Future<List<CategoryRow>> activeCategories() =>
      (select(categories)
            ..where((c) => c.isArchived.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Future<int> countTransactionsFor(int categoryId) async {
    final cnt = transactions.id.count();
    final q = selectOnly(transactions)
      ..addColumns([cnt])
      ..where(transactions.categoryId.equals(categoryId));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
  }

  Future<void> archive(int categoryId) => setArchived(categoryId, true);

  Future<int> insertCategory(CategoriesCompanion c) => into(categories).insert(c);

  Future<void> renameCategory(int id, String name) async {
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(name)));
  }

  Future<void> setArchived(int id, bool archived) async {
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(isArchived: Value(archived)));
  }

  Future<int> maxSortOrder() async {
    final maxOrder = categories.sortOrder.max();
    final q = selectOnly(categories)..addColumns([maxOrder]);
    final row = await q.getSingle();
    return row.read(maxOrder) ?? -1;
  }

  Future<void> updateSortOrders(Map<int, int> orderById) => batch((b) {
        orderById.forEach((id, order) {
          b.update(
            categories,
            CategoriesCompanion(sortOrder: Value(order)),
            where: (c) => c.id.equals(id),
          );
        });
      });

  Future<CategoryRow> byId(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingle();

  Future<void> setType(int categoryId, CategoryType type) async {
    await (update(categories)..where((c) => c.id.equals(categoryId)))
        .write(CategoriesCompanion(type: Value(type)));
  }
}
