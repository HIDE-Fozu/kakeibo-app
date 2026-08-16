import 'package:drift/drift.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../db/database.dart';

/// 分割払いの計画（installment_plans）＋紐づく取引の読み書き。
/// add/replace は1トランザクション。取引の削除は FK cascade に頼らず明示で消す
/// （replace は計画を残すので cascade が効かないため統一して明示削除）。
class DriftInstallmentPlanRepository implements InstallmentPlanRepository {
  final AppDatabase _db;
  DriftInstallmentPlanRepository(this._db);

  @override
  Stream<List<InstallmentPlanEntity>> watchAll() {
    final q = _db.select(_db.installmentPlans)
      ..orderBy([(t) => OrderingTerm.desc(t.id)]);
    return q.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<int> add(
      InstallmentPlanEntity plan, List<TransactionEntity> payments) {
    return _db.transaction(() async {
      final id = await _db.into(_db.installmentPlans).insert(_companion(plan));
      await _insertPayments(id, payments);
      return id;
    });
  }

  @override
  Future<void> replace(
      InstallmentPlanEntity plan, List<TransactionEntity> payments) {
    final id = plan.id!;
    return _db.transaction(() async {
      await (_db.update(_db.installmentPlans)..where((t) => t.id.equals(id)))
          .write(_companion(plan).copyWith(updatedAt: Value(DateTime.now())));
      await (_db.delete(_db.transactions)
            ..where((t) => t.installmentPlanId.equals(id)))
          .go();
      await _insertPayments(id, payments);
    });
  }

  @override
  Future<void> delete(int planId) {
    return _db.transaction(() async {
      await (_db.delete(_db.transactions)
            ..where((t) => t.installmentPlanId.equals(planId)))
          .go();
      await (_db.delete(_db.installmentPlans)
            ..where((t) => t.id.equals(planId)))
          .go();
    });
  }

  Future<void> _insertPayments(
      int planId, List<TransactionEntity> payments) async {
    for (final tx in payments) {
      assert(tx.amountYen >= 0);
      await _db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: tx.type,
        amount: tx.amountYen,
        date: tx.date,
        categoryId: tx.categoryId,
        source: tx.source,
        storeName: Value(tx.storeName),
        memo: Value(tx.memo),
        installmentPlanId: Value(planId),
      ));
    }
  }

  InstallmentPlanEntity _toEntity(InstallmentPlanRow r) => InstallmentPlanEntity(
        id: r.id,
        principalMinor: r.principal,
        count: r.count,
        annualRatePercent: r.annualRatePercent,
        categoryId: r.categoryId,
        dayOfMonth: r.dayOfMonth,
        startYm: r.startYm,
        cardName: r.cardName,
      );

  InstallmentPlansCompanion _companion(InstallmentPlanEntity p) =>
      InstallmentPlansCompanion(
        principal: Value(p.principalMinor),
        count: Value(p.count),
        annualRatePercent: Value(p.annualRatePercent),
        categoryId: Value(p.categoryId),
        dayOfMonth: Value(p.dayOfMonth),
        startYm: Value(p.startYm),
        cardName: Value(p.cardName),
      );
}
