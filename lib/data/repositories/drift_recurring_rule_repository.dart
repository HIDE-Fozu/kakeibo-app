import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/enums.dart';
import '../../domain/entities.dart';
import '../../domain/money/civil_date.dart';
import '../../domain/repositories.dart';
import '../../domain/services/recurring_schedule.dart';

class DriftRecurringRuleRepository implements RecurringRuleRepository {
  final AppDatabase _db;
  DriftRecurringRuleRepository(this._db);

  @override
  Stream<List<RecurringRuleEntity>> watchAll() =>
      _db.recurringRuleDao.watchAllRules().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<int> add(RecurringRuleEntity rule) {
    assert(rule.amountMinor >= 0, 'amount must be non-negative');
    assert(rule.dayOfMonth >= 1 && rule.dayOfMonth <= 31);
    return _db.recurringRuleDao.insertRule(RecurringRulesCompanion.insert(
      type: rule.type,
      amount: rule.amountMinor,
      categoryId: rule.categoryId,
      dayOfMonth: rule.dayOfMonth,
      storeName: Value(rule.storeName),
      memo: Value(rule.memo),
      isActive: Value(rule.isActive),
      startYm: rule.startYm,
      endYm: Value(rule.endYm),
      // 「毎月の費用/収入」（入力画面トグル）は手入力分を1回目扱いにするため
      // watermark 付きでルールを作る。落とすと当月分が二重起票される。
      lastGeneratedYm: Value(rule.lastGeneratedYm),
    ));
  }

  @override
  Future<void> update(RecurringRuleEntity rule, {required CivilDate today}) async {
    final id = rule.id;
    if (id == null) {
      throw ArgumentError('update requires a persisted rule (id != null)');
    }
    assert(rule.amountMinor >= 0, 'amount must be non-negative');
    assert(rule.dayOfMonth >= 1 && rule.dayOfMonth <= 31);
    await _db.transaction(() async {
      final rows = await _db.recurringRuleDao.allRules();
      final old = rows.where((r) => r.id == id).firstOrNull;
      // 停止→再開: 停止期間のさかのぼり起票を防ぐため、前月まで起票済み扱いに
      // する（当月分は次の applyDue で期日到来なら起票される）。
      // すでに前月以降まで進んでいる場合は巻き戻さない。
      Value<int?> lastYm = const Value.absent();
      if (old != null && !old.isActive && rule.isActive) {
        final skipTo = _prevYm(ymOf(today));
        if ((old.lastGeneratedYm ?? 0) < skipTo) lastYm = Value(skipTo);
      }
      await _db.recurringRuleDao.updateRule(
        id,
        RecurringRulesCompanion(
          type: Value(rule.type),
          amount: Value(rule.amountMinor),
          categoryId: Value(rule.categoryId),
          dayOfMonth: Value(rule.dayOfMonth),
          storeName: Value(rule.storeName),
          memo: Value(rule.memo),
          isActive: Value(rule.isActive),
          startYm: Value(rule.startYm),
          endYm: Value(rule.endYm),
          lastGeneratedYm: lastYm,
        ),
      );
    });
  }

  @override
  Future<void> delete(int id) => _db.recurringRuleDao.deleteRule(id);

  @override
  Future<int> applyDue(CivilDate today) => _db.transaction(() async {
        final rules = await _db.recurringRuleDao.allRules();
        var generated = 0;
        for (final r in rules.where((r) => r.isActive)) {
          final p = pendingOccurrences(
            startYm: r.startYm,
            endYm: r.endYm,
            lastGeneratedYm: r.lastGeneratedYm,
            dayOfMonth: r.dayOfMonth,
            today: today,
          );
          for (final d in p.due) {
            await _db.transactionDao
                .insertTransaction(TransactionsCompanion.insert(
              type: r.type,
              amount: r.amount,
              date: d,
              categoryId: r.categoryId,
              source: TxnSource.recurring,
              storeName: Value(r.storeName),
              memo: Value(r.memo),
            ));
            generated++;
          }
          if (p.newLastYm != r.lastGeneratedYm) {
            await _db.recurringRuleDao.markGenerated(r.id, p.newLastYm!);
          }
        }
        return generated;
      });

  /// 前の月（202701 → 202612）。
  int _prevYm(int ym) {
    final m = ym % 100;
    return m == 1 ? ym - 100 + 11 : ym - 1;
  }

  RecurringRuleEntity _toEntity(RecurringRuleRow r) => RecurringRuleEntity(
        id: r.id,
        type: r.type,
        amountMinor: r.amount,
        categoryId: r.categoryId,
        dayOfMonth: r.dayOfMonth,
        storeName: r.storeName,
        memo: r.memo,
        isActive: r.isActive,
        startYm: r.startYm,
        endYm: r.endYm,
        lastGeneratedYm: r.lastGeneratedYm,
      );
}
