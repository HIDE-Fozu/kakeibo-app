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

  setUp(() async {
    db = newMemoryDb();
    repo = DriftTransactionRepository(db);
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
  });
  tearDown(() => db.close());

  test('update bumps updatedAt and preserves source and createdAt', () async {
    final id = await repo.add(TransactionEntity(
      type: TxnType.expense,
      amountYen: 1000,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      source: TxnSource.receiptOcr,
    ));

    final before = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    // updatedAt の差が観測できるよう少し待つ
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await repo.update(TransactionEntity(
      id: id,
      type: TxnType.expense, // 変更対象外（source と同様、type は編集で不変前提）
      amountYen: 2500, // 変更
      date: const CivilDate(2026, 7, 4), // 変更
      categoryId: foodId,
      source: TxnSource.manual, // ここを変えても無視され、source は不変であること
    ));

    final after = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    expect(after.amount, 2500);
    expect(after.date, const CivilDate(2026, 7, 4));
    expect(after.source, TxnSource.receiptOcr); // 不変
    expect(after.createdAt, before.createdAt); // 不変
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue); // 更新
  });
}
