import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = newMemoryDb());
  tearDown(() => db.close());

  test('opening the database succeeds', () async {
    final count = await db.customSelect('SELECT 1 AS one').getSingle();
    expect(count.read<int>('one'), 1);
  });

  test('foreign_keys PRAGMA is enforced (insert with unknown categoryId fails)',
      () async {
    expect(
      () => db.into(db.transactions).insert(TransactionsCompanion.insert(
            type: TxnType.expense,
            amount: 1200,
            date: const CivilDate(2026, 7, 3),
            categoryId: 999, // 存在しないカテゴリ
            source: TxnSource.manual,
          )),
      throwsA(isA<SqliteException>()),
    );
  });
}
