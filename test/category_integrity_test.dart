import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository catRepo;
  late int foodId;

  setUp(() async {
    db = newMemoryDb();
    catRepo = DriftCategoryRepository(db);
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
  });
  tearDown(() => db.close());

  Future<void> addExpense(int catId) =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: TxnType.expense,
        amount: 1000,
        date: const CivilDate(2026, 7, 3),
        categoryId: catId,
        source: TxnSource.manual,
      ));

  test('active categories exclude archived, include everything else', () async {
    await catRepo.archive(foodId);
    final active = await db.categoryDao.activeCategories();
    expect(active.any((c) => c.id == foodId), isFalse);
    // 未分類システムを含む他は残る
    expect(active.any((c) => c.name == '外食'), isTrue);
  });

  test('deleting a category with transactions is blocked by FK RESTRICT', () async {
    await addExpense(foodId);
    expect(
      () => (db.delete(db.categories)..where((c) => c.id.equals(foodId))).go(),
      throwsA(isA<SqliteException>()),
    );
  });

  test('changing a category type is blocked when it has transactions', () async {
    await addExpense(foodId);
    expect(
      () => catRepo.changeType(foodId, CategoryType.income),
      throwsA(isA<CategoryInUseError>()),
    );
  });

  test('changing a category type is allowed when it has no transactions', () async {
    final all = await db.categoryDao.allCategories();
    final special = all.firstWhere((c) => c.name == '特別費').id;
    await catRepo.changeType(special, CategoryType.income);
    final after = await db.categoryDao.allCategories();
    expect(after.firstWhere((c) => c.id == special).type, CategoryType.income);
  });
}
