import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newMemoryDb();
    service = BackupService(db);
  });
  tearDown(() => db.close());

  test('exportPayload carries all seeded categories and inserted transactions',
      () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    final txId = await db.transactionDao
        .insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 1200,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      source: TxnSource.receiptOcr,
      memo: const Value('コンビニ'),
    ));

    final p = await service.exportPayload();
    expect(p.formatVersion, BackupCodec.formatVersion);
    expect(p.exportedAt, isNotNull);
    expect(p.categories.length, 20); // プリセット18 + 未分類2
    expect(p.categories.where((c) => c.isSystem).length, 2);

    final tx = p.transactions.single;
    expect(tx.id, txId); // IDが逐語的に載る
    expect(tx.amount, 1200);
    expect(tx.date, const CivilDate(2026, 7, 3));
    expect(tx.categoryId, foodId);
    expect(tx.source, TxnSource.receiptOcr);
    expect(tx.memo, 'コンビニ');
  });

  test('exportJson decodes back to an identical payload (round-trip)', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.income,
      amount: 300000,
      date: const CivilDate(2026, 7, 25),
      categoryId: foodId,
      source: TxnSource.manual,
    ));

    const codec = BackupCodec();
    final json = await service.exportJson();
    final decoded = codec.decode(json);
    expect(codec.encode(decoded), json); // decode→encode が恒等＝完全な忠実度
    // createdAt はUTC瞬間として往復で不変
    final row = (await db.select(db.transactions).get()).single;
    expect(decoded.transactions.single.createdAt, row.createdAt.toUtc());
  });
}
