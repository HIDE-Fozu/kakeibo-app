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

  /// 全取引の件数（通貨ロック判定用: 1件でもあれば通貨変更を禁止する）。
  Future<int> count() async {
    final cnt = transactions.id.count();
    final q = selectOnly(transactions)..addColumns([cnt]);
    return (await q.getSingle()).read(cnt) ?? 0;
  }

  /// 編集で変わりうるフィールドだけを更新し、updatedAt を現在時刻に。
  /// type / source / createdAt は触らない（source は由来として不変）。
  Future<void> updateFields(
    int id, {
    required int amount,
    required CivilDate date,
    required int categoryId,
    PaymentMethod? paymentMethod,
    String? storeName,
    String? memo,
  }) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amount: Value(amount),
        date: Value(date),
        categoryId: Value(categoryId),
        paymentMethod: Value(paymentMethod),
        storeName: Value(storeName),
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
      ..addColumns([
        categories.id, categories.name, categories.isArchived,
        categories.parentId, amountSum,
      ])
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
              parentId: row.read(categories.parentId),
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
      ..addColumns([
        categories.id, categories.name, categories.isArchived,
        categories.parentId, amountSum,
      ])
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
          parentId: row.read(categories.parentId),
          total: row.read(amountSum) ?? 0,
        ),
    ];
  }
}

class CategorySpendRow {
  final int categoryId;
  final String categoryName;
  final bool isArchived;
  final int? parentId; // 非null=このカテゴリは内訳
  final int total;
  const CategorySpendRow({
    required this.categoryId,
    required this.categoryName,
    required this.isArchived,
    required this.parentId,
    required this.total,
  });
}

/// 毎月の固定費・収入ルールのCRUD。起票ロジックは repository 側
/// （DriftRecurringRuleRepository.applyDue）が担い、DAOは素朴な読み書きに徹する。
@DriftAccessor(tables: [RecurringRules, Transactions])
class RecurringRuleDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRuleDaoMixin {
  RecurringRuleDao(super.db);

  Future<List<RecurringRuleRow>> allRules() =>
      (select(recurringRules)..orderBy([(r) => OrderingTerm.asc(r.id)])).get();

  Stream<List<RecurringRuleRow>> watchAllRules() =>
      (select(recurringRules)..orderBy([(r) => OrderingTerm.asc(r.id)]))
          .watch();

  Future<int> insertRule(RecurringRulesCompanion c) =>
      into(recurringRules).insert(c);

  Future<void> updateRule(int id, RecurringRulesCompanion c) async {
    await (update(recurringRules)..where((r) => r.id.equals(id)))
        .write(c.copyWith(updatedAt: Value(DateTime.now())));
  }

  /// 冪等（存在しないIDでも例外を投げない）。
  Future<void> deleteRule(int id) =>
      (delete(recurringRules)..where((r) => r.id.equals(id))).go();

  /// 起票済みの月を記録する（applyDue 専用。updatedAt はユーザー編集の
  /// 目印として温存したいので触らない）。
  Future<void> markGenerated(int id, int ym) async {
    await (update(recurringRules)..where((r) => r.id.equals(id)))
        .write(RecurringRulesCompanion(lastGeneratedYm: Value(ym)));
  }
}

/// つきいちタスク（家事リマインダー）の素朴な読み書き。
/// 期日導出・通知計画は domain（chore_schedule.dart）と ChoreActions が担う。
@DriftAccessor(tables: [ChoreTasks, ChoreRecords])
class ChoreDao extends DatabaseAccessor<AppDatabase> with _$ChoreDaoMixin {
  ChoreDao(super.db);

  Stream<List<ChoreTaskRow>> watchTasks() =>
      (select(choreTasks)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Stream<List<ChoreRecordRow>> watchRecords() => select(choreRecords).watch();

  /// resync 用のFuture版。widget test（fake async）内で stream.first を
  /// await するとハングする既知の罠があるため、一括読みは必ずこちらを使う。
  Future<List<ChoreTaskRow>> allTasks() =>
      (select(choreTasks)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<List<ChoreRecordRow>> allRecords() => select(choreRecords).get();

  Future<int> insertTask(ChoreTasksCompanion c) => into(choreTasks).insert(c);

  Future<void> updateTask(int id, ChoreTasksCompanion c) async {
    await (update(choreTasks)..where((t) => t.id.equals(id))).write(c);
  }

  Future<void> setArchived(int taskId, bool archived) async {
    await (update(choreTasks)..where((t) => t.id.equals(taskId)))
        .write(ChoreTasksCompanion(archived: Value(archived)));
  }

  /// 記録もカスケード削除される（FK ON が前提。database.dart beforeOpen 参照）。
  Future<void> deleteTask(int taskId) =>
      (delete(choreTasks)..where((t) => t.id.equals(taskId))).go();

  Future<int> insertRecord(ChoreRecordsCompanion c) =>
      into(choreRecords).insert(c);

  Future<void> updateRecord(int id, ChoreRecordsCompanion c) async {
    await (update(choreRecords)..where((r) => r.id.equals(id))).write(c);
  }

  Future<void> deleteRecord(int recordId) =>
      (delete(choreRecords)..where((r) => r.id.equals(recordId))).go();

  /// 同じタスク・同じ日にすでに記録があるか（重複確認ダイアログの判定用）。
  Future<bool> hasRecordOn(int taskId, CivilDate date) async {
    final rows = await (select(choreRecords)
          ..where((r) => r.taskId.equals(taskId) & r.doneDate.equals(date.toIso()))
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }
}

@DriftAccessor(tables: [Categories, Transactions])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  // sortOrderは同一スコープ（同じ親）内でのみ一意。フラットな並びのタイは
  // id昇順で決定的にする（食費=親スコープ0と外食=内訳スコープ0が同順位になるため）。
  Future<List<CategoryRow>> allCategories() => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .get();

  Stream<List<CategoryRow>> watchAllCategories() => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
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

  /// 同一スコープ（parentIdが同じ）内の最大sortOrder。行がなければ-1。
  Future<int> maxSortOrderWithin(int? parentId) async {
    final maxOrder = categories.sortOrder.max();
    final q = selectOnly(categories)
      ..addColumns([maxOrder])
      ..where(parentId == null
          ? categories.parentId.isNull()
          : categories.parentId.equals(parentId));
    final row = await q.getSingle();
    return row.read(maxOrder) ?? -1;
  }

  /// 内訳の数（アーカイブ込み）。
  Future<int> countChildrenOf(int categoryId) async {
    final cnt = categories.id.count();
    final q = selectOnly(categories)
      ..addColumns([cnt])
      ..where(categories.parentId.equals(categoryId));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
  }

  /// アクティブ（非アーカイブ）な内訳の数。
  Future<int> countActiveChildrenOf(int categoryId) async {
    final cnt = categories.id.count();
    final q = selectOnly(categories)
      ..addColumns([cnt])
      ..where(categories.parentId.equals(categoryId) &
          categories.isArchived.equals(false));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
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
