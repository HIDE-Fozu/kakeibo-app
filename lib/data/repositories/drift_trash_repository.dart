import 'package:drift/drift.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../db/database.dart';

/// ごみ箱の保持期間。これより古い行は purgeExpired（ページを開いたとき）で消す。
const kTrashRetention = Duration(days: 30);

/// ごみ箱（deleted_transactions）の読み書き。deletedAt は now()（UTC）で
/// Dart側から入れる（SQL既定と書式が混ざるとテキスト日時の比較が壊れるため、
/// 期限判定も SQL 比較ではなく Dart 側で行う）。
class DriftTrashRepository implements TrashRepository {
  final AppDatabase _db;
  final DateTime Function() now;
  DriftTrashRepository(this._db, {required this.now});

  @override
  Stream<List<TrashEntry>> watchAll() {
    final q = _db.select(_db.deletedTransactions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.deletedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return q.watch().map((rows) => rows.map(_toEntry).toList());
  }

  @override
  Future<void> moveToTrash(int transactionId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.transactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingleOrNull();
      if (row == null) return; // 冪等
      await _db.into(_db.deletedTransactions).insert(
            DeletedTransactionsCompanion.insert(
              type: row.type,
              amount: row.amount,
              date: row.date,
              categoryId: row.categoryId,
              paymentMethod: Value(row.paymentMethod),
              storeName: Value(row.storeName),
              memo: Value(row.memo),
              source: row.source,
              imagePath: Value(row.imagePath),
              splitGroupId: Value(row.splitGroupId),
              installmentPlanId: Value(row.installmentPlanId),
              deletedAt: now(),
            ),
          );
      await (_db.delete(_db.transactions)
            ..where((t) => t.id.equals(transactionId)))
          .go();
    });
  }

  @override
  Future<void> restore(int trashId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.deletedTransactions)
            ..where((t) => t.id.equals(trashId)))
          .getSingleOrNull();
      if (row == null) return; // 冪等
      // 分割払いの計画が消えていれば紐付けを外す（FK違反の防止）。
      var planId = row.installmentPlanId;
      if (planId != null) {
        final plan = await (_db.select(_db.installmentPlans)
              ..where((t) => t.id.equals(planId!)))
            .getSingleOrNull();
        if (plan == null) planId = null;
      }
      await _db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: row.type,
        amount: row.amount,
        date: row.date,
        categoryId: row.categoryId,
        source: row.source,
        paymentMethod: Value(row.paymentMethod),
        storeName: Value(row.storeName),
        memo: Value(row.memo),
        imagePath: Value(row.imagePath),
        splitGroupId: Value(row.splitGroupId),
        installmentPlanId: Value(planId),
      ));
      await (_db.delete(_db.deletedTransactions)
            ..where((t) => t.id.equals(trashId)))
          .go();
    });
  }

  @override
  Future<int> purgeExpired() async {
    final cutoff = now().subtract(kTrashRetention);
    final rows = await _db.select(_db.deletedTransactions).get();
    final expired = [
      for (final r in rows)
        if (r.deletedAt.isBefore(cutoff)) r.id
    ];
    if (expired.isEmpty) return 0;
    return (_db.delete(_db.deletedTransactions)
          ..where((t) => t.id.isIn(expired)))
        .go();
  }

  @override
  Future<void> emptyTrash() => _db.delete(_db.deletedTransactions).go();

  TrashEntry _toEntry(DeletedTransactionRow r) => TrashEntry(
        id: r.id,
        deletedAt: r.deletedAt,
        tx: TransactionEntity(
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
          installmentPlanId: r.installmentPlanId,
        ),
      );
}
