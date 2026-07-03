import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/spending_rollup.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int foodId;
  late int eatOutId;

  setUp(() async {
    db = newMemoryDb();
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
    eatOutId = all.firstWhere((c) => c.name == '外食').id;
  });
  tearDown(() => db.close());

  Future<void> add(TxnType t, int yen, CivilDate d, int catId) =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: t, amount: yen, date: d, categoryId: catId,
        source: TxnSource.manual,
      ));

  test('totalsByType sums income and expense within the month only', () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3), foodId);
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20), eatOutId);
    await add(TxnType.income, 300000, const CivilDate(2026, 7, 25), foodId);
    await add(TxnType.expense, 9999, const CivilDate(2026, 8, 1), foodId); // 翌月

    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(totals[TxnType.expense], 2000);
    expect(totals[TxnType.income], 300000);
  });

  test('INVARIANT: sum of per-category expense subtotals == month expense total',
      () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3), foodId);
    await add(TxnType.expense, 300, const CivilDate(2026, 7, 4), foodId);
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20), eatOutId);

    final byCat = await db.transactionDao.spendingByCategory(2026, 7);
    final byCatSum = byCat.fold<int>(0, (a, r) => a + r.total);
    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(byCatSum, totals[TxnType.expense]);
    // 食費 1500 が外食 800 より上（降順）
    expect(byCat.first.categoryName, '食費');
    expect(byCat.first.total, 1500);
  });

  test('archived category still counts in aggregation', () async {
    await add(TxnType.expense, 5000, const CivilDate(2026, 7, 3), eatOutId);
    // 外食をアーカイブ
    await (db.update(db.categories)..where((c) => c.id.equals(eatOutId)))
        .write(const CategoriesCompanion(isArchived: Value(true)));

    final byCat = await db.transactionDao.spendingByCategory(2026, 7);
    final totals = await db.transactionDao.totalsByType(2026, 7);
    // アーカイブしても集計から消えない
    expect(byCat.any((r) => r.categoryId == eatOutId && r.total == 5000), isTrue);
    expect(totals[TxnType.expense], 5000);
  });

  test('INVARIANT: rollup後も 親グループ計の和==月次支出合計・内訳和+直接分==親計',
      () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3), foodId); // 直接
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20), eatOutId); // 内訳
    final rows = await db.transactionDao.spendingByCategory(2026, 7);
    // 外食の行はparentId付きで返る
    expect(rows.firstWhere((r) => r.categoryId == eatOutId).parentId, foodId);

    final cats = await DriftCategoryRepository(db).watchAll().first;
    final groups = rollupSpending(rows, cats);
    final food = groups.firstWhere((g) => g.categoryId == foodId);
    expect(food.total, 2000);
    expect(food.directTotal, 1200);
    expect(food.subs.single.categoryId, eatOutId);
    expect(food.subs.single.total, 800);

    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(groups.fold<int>(0, (a, g) => a + g.total),
        totals[TxnType.expense]);
  });
}
