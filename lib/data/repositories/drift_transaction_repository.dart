import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/enums.dart';
import '../db/daos.dart' show CategorySpendRow;
import '../../domain/entities.dart';
import '../../domain/money/civil_date.dart';
import '../../domain/repositories.dart';

class DriftTransactionRepository implements TransactionRepository {
  final AppDatabase _db;
  DriftTransactionRepository(this._db);

  @override
  Future<int> add(TransactionEntity tx) {
    assert(tx.amountYen >= 0, 'amount must be non-negative');
    return _db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: tx.type,
      amount: tx.amountYen,
      date: tx.date,
      categoryId: tx.categoryId,
      source: tx.source,
      paymentMethod: Value(tx.paymentMethod),
      storeName: Value(tx.storeName),
      memo: Value(tx.memo),
      imagePath: Value(tx.imagePath),
      splitGroupId: Value(tx.splitGroupId),
    ));
  }

  @override
  Future<List<TransactionEntity>> forMonth(int year, int month) async {
    final rows = await _db.transactionDao.transactionsInMonth(year, month);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<MonthlySummary> summary(int year, int month) async {
    final byType = await _db.transactionDao.totalsByType(year, month);
    return MonthlySummary(
      income: byType[TxnType.income] ?? 0,
      expense: byType[TxnType.expense] ?? 0,
    );
  }

  @override
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month) =>
      _db.transactionDao.spendingByCategory(year, month);

  @override
  Future<void> update(TransactionEntity tx) {
    final id = tx.id;
    if (id == null) {
      throw ArgumentError('update requires a persisted transaction (id != null)');
    }
    assert(tx.amountYen >= 0, 'amount must be non-negative');
    return _db.transactionDao.updateFields(
      id,
      amount: tx.amountYen,
      date: tx.date,
      categoryId: tx.categoryId,
      paymentMethod: tx.paymentMethod,
      storeName: tx.storeName,
      memo: tx.memo,
    );
  }

  @override
  Stream<List<TransactionEntity>> watchMonth(int year, int month) =>
      _db.transactionDao
          .watchTransactionsInMonth(year, month)
          .map((rows) => rows.map(_toEntity).toList());

  @override
  Stream<MonthlySummary> watchSummary(int year, int month) =>
      _db.transactionDao.watchTotalsByType(year, month).map(
            (byType) => MonthlySummary(
              income: byType[TxnType.income] ?? 0,
              expense: byType[TxnType.expense] ?? 0,
            ),
          );

  @override
  Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month) =>
      _db.transactionDao.watchSpendingByCategory(year, month);

  @override
  Stream<Map<int, CivilDate>> watchLastUsedByCategory() =>
      _db.transactionDao.watchLastUsedIsoByCategory().map(
          (m) => m.map((id, iso) => MapEntry(id, CivilDate.parse(iso))));

  @override
  Future<void> delete(int id) => _db.transactionDao.deleteById(id);

  TransactionEntity _toEntity(TransactionRow r) => TransactionEntity(
        id: r.id,
        type: r.type,
        amountYen: r.amount,
        date: r.date,
        categoryId: r.categoryId,
        paymentMethod: r.paymentMethod,
        storeName: r.storeName,
        memo: r.memo,
        source: r.source,
        imagePath: r.imagePath,
        splitGroupId: r.splitGroupId,
      );
}
