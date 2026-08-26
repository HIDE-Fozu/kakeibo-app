import 'package:drift/drift.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../../domain/services/payment_schedule.dart';
import '../db/database.dart';

/// 支払い区分（カード）の読み書き。
class DriftPaymentCardRepository implements PaymentCardRepository {
  final AppDatabase _db;
  DriftPaymentCardRepository(this._db);

  SimpleSelectStatement<$PaymentCardsTable, PaymentCardRow> _query(
      bool includeArchived) {
    final q = _db.select(_db.paymentCards);
    if (!includeArchived) q.where((t) => t.isArchived.equals(false));
    q.orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]);
    return q;
  }

  @override
  Stream<List<PaymentCardEntity>> watchAll({bool includeArchived = false}) =>
      _query(includeArchived).watch().map((r) => r.map(_toEntity).toList());

  @override
  Future<List<PaymentCardEntity>> all({bool includeArchived = false}) async =>
      (await _query(includeArchived).get()).map(_toEntity).toList();

  @override
  Future<int> add(PaymentCardEntity card) =>
      _db.into(_db.paymentCards).insert(_companion(card));

  @override
  Future<void> update(PaymentCardEntity card) async {
    await (_db.update(_db.paymentCards)..where((t) => t.id.equals(card.id!)))
        .write(_companion(card).copyWith(updatedAt: Value(DateTime.now())));
  }

  @override
  Future<void> archive(int cardId, {bool archived = true}) async {
    await (_db.update(_db.paymentCards)..where((t) => t.id.equals(cardId)))
        .write(PaymentCardsCompanion(
      isArchived: Value(archived),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> delete(int cardId) async {
    // 未払金から参照されていれば FK restrict で落ちる。呼び出し側が
    // 判断できるよう、件数を先に見て読める例外にする。
    final used = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM payables WHERE card_id = ?',
          variables: [Variable.withInt(cardId)],
        )
        .getSingle();
    if (used.read<int>('c') > 0) {
      throw StateError('このカードは未払金から使われているため削除できません（アーカイブしてください）');
    }
    await (_db.delete(_db.paymentCards)..where((t) => t.id.equals(cardId))).go();
  }

  PaymentCardEntity _toEntity(PaymentCardRow r) => PaymentCardEntity(
        id: r.id,
        name: r.name,
        payDay: r.payDay,
        businessDayRule: r.businessDayRule,
        annualRatePercent: r.annualRatePercent,
        sortOrder: r.sortOrder,
        isArchived: r.isArchived,
      );

  PaymentCardsCompanion _companion(PaymentCardEntity c) =>
      PaymentCardsCompanion.insert(
        name: c.name,
        payDay: c.payDay,
        businessDayRule: Value(c.businessDayRule),
        annualRatePercent: Value(c.annualRatePercent),
        sortOrder: Value(c.sortOrder),
        isArchived: Value(c.isArchived),
      );
}

/// 未払金の読み書き。**スケジュールの合計＝総額**をここで必ず検証してから
/// 書く（不整合をDBに入れない唯一の門番）。
class DriftPayableRepository implements PayableRepository {
  final AppDatabase _db;
  DriftPayableRepository(this._db);

  @override
  Future<PayableEntity?> forTransaction(int transactionId) async {
    final row = await (_db.select(_db.payables)
          ..where((t) => t.transactionId.equals(transactionId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row, await _scheduleOf(row.id));
  }

  @override
  Stream<List<PayableEntity>> watchForPaymentYm(int ym) {
    // その月に支払いがある未払金だけを引く（分割なら該当月の行があるもの）。
    final q = _db.select(_db.payables).join([
      innerJoin(_db.payableSchedules,
          _db.payableSchedules.payableId.equalsExp(_db.payables.id)),
    ])
      ..where(_db.payableSchedules.ym.equals(ym))
      ..orderBy([OrderingTerm.asc(_db.payables.id)]);
    return q.watch().asyncMap((rows) async => [
          for (final r in rows)
            _toEntity(r.readTable(_db.payables),
                await _scheduleOf(r.readTable(_db.payables).id)),
        ]);
  }

  @override
  Future<int> add(PayableEntity p) {
    _verify(p);
    return _db.transaction(() async {
      final id = await _db.into(_db.payables).insert(PayablesCompanion.insert(
            transactionId: p.transactionId,
            cardId: p.cardId,
            totalMinor: p.totalMinor,
            installmentCount: Value(p.installmentCount),
            annualRatePercent: Value(p.annualRatePercent),
          ));
      await _writeSchedule(id, p.schedule);
      return id;
    });
  }

  @override
  Future<void> replace(PayableEntity p) {
    _verify(p);
    final id = p.id!;
    return _db.transaction(() async {
      await (_db.update(_db.payables)..where((t) => t.id.equals(id)))
          .write(PayablesCompanion(
        cardId: Value(p.cardId),
        installmentCount: Value(p.installmentCount),
        annualRatePercent: Value(p.annualRatePercent),
        totalMinor: Value(p.totalMinor),
        updatedAt: Value(DateTime.now()),
      ));
      await (_db.delete(_db.payableSchedules)
            ..where((t) => t.payableId.equals(id)))
          .go();
      await _writeSchedule(id, p.schedule);
    });
  }

  @override
  Future<void> delete(int payableId) async {
    // 予定は FK cascade で消える。購入取引は残す（＝即時払いに戻る）。
    await (_db.delete(_db.payables)..where((t) => t.id.equals(payableId))).go();
  }

  /// 合計が総額と一致しない/月が重複する等は書かせない。
  void _verify(PayableEntity p) {
    if (p.installmentCount < 1) {
      throw ArgumentError('支払い回数は1以上です: ${p.installmentCount}');
    }
    if (p.installmentCount != p.schedule.length) {
      throw ArgumentError('支払い回数 ${p.installmentCount} と'
          'スケジュール ${p.schedule.length} 件が一致しません');
    }
    final why =
        validateSchedule(p.schedule, expectedTotalMinor: p.totalMinor);
    if (why != null) throw ArgumentError(why);
  }

  Future<void> _writeSchedule(
      int payableId, List<PayableInstallment> schedule) async {
    await _db.batch((b) {
      for (final s in schedule) {
        b.insert(
          _db.payableSchedules,
          PayableSchedulesCompanion.insert(
            payableId: payableId,
            ym: s.ym,
            amountMinor: s.amountMinor,
          ),
        );
      }
    });
  }

  Future<List<PayableInstallment>> _scheduleOf(int payableId) async {
    final rows = await (_db.select(_db.payableSchedules)
          ..where((t) => t.payableId.equals(payableId))
          ..orderBy([(t) => OrderingTerm.asc(t.ym)]))
        .get();
    return [
      for (final r in rows)
        PayableInstallment(ym: r.ym, amountMinor: r.amountMinor),
    ];
  }

  PayableEntity _toEntity(PayableRow r, List<PayableInstallment> schedule) =>
      PayableEntity(
        id: r.id,
        transactionId: r.transactionId,
        cardId: r.cardId,
        installmentCount: r.installmentCount,
        annualRatePercent: r.annualRatePercent,
        totalMinor: r.totalMinor,
        schedule: schedule,
      );
}
