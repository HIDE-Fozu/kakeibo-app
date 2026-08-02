import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_recurring_rule_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftRecurringRuleRepository repo;
  late int foodId;
  late int salaryId;

  setUp(() async {
    db = newMemoryDb();
    repo = DriftRecurringRuleRepository(db);
    final cats = await db.categoryDao.allCategories();
    foodId = cats.firstWhere((c) => c.slug == 'food').id;
    salaryId = cats.firstWhere((c) => c.slug == 'salary').id;
  });

  tearDown(() => db.close());

  RecurringRuleEntity rule({
    TxnType type = TxnType.expense,
    int amount = 80000,
    int? categoryId,
    int day = 1,
    int startYm = 202608,
    int? endYm,
    bool isActive = true,
    String? storeName,
    String? memo,
  }) =>
      RecurringRuleEntity(
        type: type,
        amountMinor: amount,
        categoryId: categoryId ?? foodId,
        dayOfMonth: day,
        storeName: storeName,
        memo: memo,
        isActive: isActive,
        startYm: startYm,
        endYm: endYm,
      );

  test('applyDue: 期日到来分を起票し、再実行しても二重起票しない', () async {
    await repo.add(rule(day: 1, storeName: '大家さん', memo: '家賃'));
    const today = CivilDate(2026, 8, 3);

    expect(await repo.applyDue(today), 1);
    final txs = await db.transactionDao.transactionsInMonth(2026, 8);
    expect(txs, hasLength(1));
    expect(txs.single.amount, 80000);
    expect(txs.single.date, const CivilDate(2026, 8, 1));
    expect(txs.single.source, TxnSource.recurring);
    expect(txs.single.storeName, '大家さん');
    expect(txs.single.memo, '家賃');

    // 冪等: 同じ日にもう一度呼んでも増えない
    expect(await repo.applyDue(today), 0);
    expect(await db.transactionDao.transactionsInMonth(2026, 8), hasLength(1));
  });

  test('applyDue: 期日前は起票せず、期日が来たら起票する', () async {
    await repo.add(rule(day: 25));
    expect(await repo.applyDue(const CivilDate(2026, 8, 3)), 0);
    expect(await repo.applyDue(const CivilDate(2026, 8, 25)), 1);
    final txs = await db.transactionDao.transactionsInMonth(2026, 8);
    expect(txs.single.date, const CivilDate(2026, 8, 25));
  });

  test('applyDue: 数か月分のキャッチアップ＋収入ルールも起票', () async {
    await repo.add(rule(day: 10, startYm: 202606));
    await repo.add(rule(
        type: TxnType.income, amount: 250000, categoryId: salaryId, day: 25,
        startYm: 202606));
    // 6月・7月分＋8月は支出(10日)のみ期日到来
    expect(await repo.applyDue(const CivilDate(2026, 8, 15)), 5);
    final aug = await db.transactionDao.transactionsInMonth(2026, 8);
    expect(aug, hasLength(1)); // 支出のみ（給料25日はまだ）
    final jul = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(jul, hasLength(2));
    expect(jul.map((t) => t.type).toSet(), {TxnType.expense, TxnType.income});
  });

  test('applyDue: 停止中は起票しない・削除してもFK制約に触れない', () async {
    final id = await repo.add(rule(isActive: false));
    expect(await repo.applyDue(const CivilDate(2026, 8, 3)), 0);
    await repo.delete(id);
    await repo.delete(id); // 冪等
    expect(await db.recurringRuleDao.allRules(), isEmpty);
  });

  test('update: 停止→再開で停止期間をさかのぼり起票しない', () async {
    final id = await repo.add(rule(day: 1, startYm: 202605));
    await repo.applyDue(const CivilDate(2026, 5, 2)); // 5月分起票
    final r1 = (await db.recurringRuleDao.allRules()).single;
    expect(r1.lastGeneratedYm, 202605);

    // 停止して3か月後に再開
    final entity = RecurringRuleEntity(
      id: id, type: TxnType.expense, amountMinor: 80000, categoryId: foodId,
      dayOfMonth: 1, startYm: 202605, isActive: false,
      lastGeneratedYm: 202605,
    );
    await repo.update(entity, today: const CivilDate(2026, 5, 20));
    expect(await repo.applyDue(const CivilDate(2026, 8, 3)), 0); // 停止中

    await repo.update(
      RecurringRuleEntity(
        id: id, type: TxnType.expense, amountMinor: 80000, categoryId: foodId,
        dayOfMonth: 1, startYm: 202605, isActive: true,
        lastGeneratedYm: 202605,
      ),
      today: const CivilDate(2026, 8, 3),
    );
    // 6月・7月分は飛ばし、8月分だけ起票される
    expect(await repo.applyDue(const CivilDate(2026, 8, 3)), 1);
    final txs = await db.transactionDao.transactionsInMonth(2026, 8);
    expect(txs.single.date, const CivilDate(2026, 8, 1));
    expect(await db.transactionDao.transactionsInMonth(2026, 6), isEmpty);
    expect(await db.transactionDao.transactionsInMonth(2026, 7), isEmpty);
  });

  test('update: 金額などの編集が反映され、起票済みは巻き戻らない', () async {
    final id = await repo.add(rule(day: 1));
    await repo.applyDue(const CivilDate(2026, 8, 3));
    await repo.update(
      RecurringRuleEntity(
        id: id, type: TxnType.expense, amountMinor: 90000, categoryId: foodId,
        dayOfMonth: 1, startYm: 202608, isActive: true, lastGeneratedYm: 202608,
      ),
      today: const CivilDate(2026, 8, 3),
    );
    // 8月分は起票済みのまま（金額変更で再起票しない）
    expect(await repo.applyDue(const CivilDate(2026, 8, 3)), 0);
    // 9月分は新金額で起票
    expect(await repo.applyDue(const CivilDate(2026, 9, 1)), 1);
    final sep = await db.transactionDao.transactionsInMonth(2026, 9);
    expect(sep.single.amount, 90000);
  });

  test('endYm 以降は起票されない', () async {
    await repo.add(rule(day: 1, startYm: 202606, endYm: 202607));
    expect(await repo.applyDue(const CivilDate(2026, 9, 1)), 2);
    expect(await db.transactionDao.transactionsInMonth(2026, 8), isEmpty);
    expect(await db.transactionDao.transactionsInMonth(2026, 9), isEmpty);
  });

  test('watchAll: 追加・削除が流れる', () async {
    final stream = repo.watchAll();
    final first = await stream.first;
    expect(first, isEmpty);
    final id = await repo.add(rule());
    final after = await repo.watchAll().first;
    expect(after.single.id, id);
    expect(after.single.amountMinor, 80000);
  });
}
