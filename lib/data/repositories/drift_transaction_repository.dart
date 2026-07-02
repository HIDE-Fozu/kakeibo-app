import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/enums.dart';
import '../db/daos.dart' show CategorySpendRow;
import '../../domain/entities.dart';
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
      memo: Value(tx.memo),
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

  TransactionEntity _toEntity(TransactionRow r) => TransactionEntity(
        id: r.id,
        type: r.type,
        amountYen: r.amount,
        date: r.date,
        categoryId: r.categoryId,
        paymentMethod: r.paymentMethod,
        memo: r.memo,
        source: r.source,
      );
}
