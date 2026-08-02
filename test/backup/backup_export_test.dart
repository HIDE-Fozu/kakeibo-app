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
    // slug（安定キー）がバックアップに載る（復元後も絵文字・税が壊れない）
    expect(p.categories.firstWhere((c) => c.name == '食費').slug, 'food');

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

  test('定期ルールがバックアップに載り、復元先で状態ごと引き継がれる', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.recurringRuleDao.insertRule(RecurringRulesCompanion.insert(
      type: TxnType.expense,
      amount: 80000,
      categoryId: foodId,
      dayOfMonth: 27,
      storeName: const Value('大家さん'),
      startYm: 202608,
      lastGeneratedYm: const Value(202608),
    ));

    final p = await service.exportPayload();
    final rule = p.recurringRules.single;
    expect(rule.amount, 80000);
    expect(rule.lastGeneratedYm, 202608); // 起票済み位置も引き継ぐ

    // 別DBへ復元 → ルールが同IDで再現される
    final db2 = newMemoryDb();
    addTearDown(db2.close);
    await BackupService(db2).applyRestore(p);
    final restored = await db2.recurringRuleDao.allRules();
    expect(restored.single.id, rule.id);
    expect(restored.single.storeName, '大家さん');
    expect(restored.single.lastGeneratedYm, 202608);
  });
}
