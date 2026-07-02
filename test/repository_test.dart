import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_transaction_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  test('MonthlySummary.net is income minus expense', () {
    const s = MonthlySummary(income: 300000, expense: 120000);
    expect(s.net, 180000);
  });

  test('repository add + forMonth + summary work over domain types', () async {
    final db = newMemoryDb();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;

    await repo.add(TransactionEntity(
      type: TxnType.expense,
      amountYen: 1200,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
    await repo.add(TransactionEntity(
      type: TxnType.income,
      amountYen: 300000,
      date: const CivilDate(2026, 7, 25),
      categoryId: foodId,
      source: TxnSource.manual,
    ));

    final month = await repo.forMonth(2026, 7);
    expect(month.length, 2);
    expect(month.map((t) => t.amountYen).toSet(), {1200, 300000});

    final summary = await repo.summary(2026, 7);
    expect(summary.expense, 1200);
    expect(summary.income, 300000);
    expect(summary.net, 298800);
  });
}
