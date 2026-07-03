import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_transaction_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftTransactionRepository repo;
  late int foodId;

  TransactionEntity tx(int yen, {int day = 10, TxnType type = TxnType.expense}) =>
      TransactionEntity(
        type: type,
        amountYen: yen,
        date: CivilDate(2026, 7, day),
        categoryId: foodId,
        source: TxnSource.manual,
      );

  setUp(() async {
    db = newMemoryDb();
    repo = DriftTransactionRepository(db);
    final cats = await db.categoryDao.allCategories();
    foodId = cats.firstWhere((c) => c.name == '食費').id;
  });

  tearDown(() => db.close());

  test('watchMonth: 追加/削除で再発火し月外は含まない', () async {
    final emissions = <List<TransactionEntity>>[];
    final sub = repo.watchMonth(2026, 7).listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    final id = await repo.add(tx(500));
    await repo.add(TransactionEntity(
      type: TxnType.expense,
      amountYen: 999,
      date: const CivilDate(2026, 8, 1),
      categoryId: foodId,
      source: TxnSource.manual,
    )); // 月外
    await pumpEventQueue();
    expect(emissions.last.map((t) => t.amountYen), [500]);

    await repo.delete(id);
    await pumpEventQueue();
    expect(emissions.last, isEmpty);
  });

  test('delete は冪等（存在しないIDでも例外なし）', () async {
    await repo.delete(99999);
  });

  test('watchSummary: income/expense/netが追う', () async {
    await repo.add(tx(300));
    await repo.add(tx(1000, type: TxnType.income));
    final s = await repo.watchSummary(2026, 7).first;
    expect(s.expense, 300);
    expect(s.income, 1000);
    expect(s.net, 700);
  });

  test('watchSpendingByCategory: isArchivedが載る', () async {
    await repo.add(tx(300));
    final rows = await repo.watchSpendingByCategory(2026, 7).first;
    expect(rows.single.categoryName, '食費');
    expect(rows.single.isArchived, isFalse);
    expect(rows.single.total, 300);
  });

  test('watchLastUsedByCategory: カテゴリごとの最終利用日(date基準)', () async {
    await repo.add(tx(100, day: 3));
    await repo.add(tx(200, day: 20));
    final map = await repo.watchLastUsedByCategory().first;
    expect(map[foodId], const CivilDate(2026, 7, 20));
  });

  test('imagePath が add で保存され entity に戻る', () async {
    await repo.add(TransactionEntity(
      type: TxnType.expense,
      amountYen: 100,
      date: const CivilDate(2026, 7, 10),
      categoryId: foodId,
      source: TxnSource.receiptOcr,
      imagePath: '/tmp/r.jpg',
    ));
    final list = await repo.forMonth(2026, 7);
    expect(list.single.imagePath, '/tmp/r.jpg');
  });
}
