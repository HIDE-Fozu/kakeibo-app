import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int foodId;

  setUp(() async {
    db = newMemoryDb();
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
  });
  tearDown(() => db.close());

  Future<int> add(TxnType t, int yen, CivilDate d) =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: t,
        amount: yen,
        date: d,
        categoryId: foodId,
        source: TxnSource.manual,
      ));

  test('transactionsInMonth returns only that month, newest first', () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3));
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20));
    await add(TxnType.expense, 9999, const CivilDate(2026, 8, 1)); // 翌月・除外
    await add(TxnType.expense, 500, const CivilDate(2026, 6, 30)); // 前月・除外

    final rows = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(rows.map((r) => r.amount).toList(), [800, 1200]); // 日付降順
    expect(rows.every((r) => r.date.month == 7), isTrue);
  });

  test('December range does not leak into next year', () async {
    await add(TxnType.expense, 100, const CivilDate(2026, 12, 31));
    await add(TxnType.expense, 200, const CivilDate(2027, 1, 1)); // 除外

    final rows = await db.transactionDao.transactionsInMonth(2026, 12);
    expect(rows.map((r) => r.amount).toList(), [100]);
  });

  test('stored civil date round-trips exactly', () async {
    await add(TxnType.expense, 100, const CivilDate(2026, 12, 31));
    final rows = await db.transactionDao.transactionsInMonth(2026, 12);
    expect(rows.single.date, const CivilDate(2026, 12, 31));
  });
}
