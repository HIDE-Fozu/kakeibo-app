import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('CSV has BOM, CRLF, header, and localized values', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 1200,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      paymentMethod: const Value(PaymentMethod.eMoney),
      source: TxnSource.manual,
      memo: const Value('コンビニ'),
    ));

    final csv = await service.exportCsv();
    expect(csv.startsWith('\uFEFF'), isTrue); // Excel(日本語)向けBOM
    final lines = csv.substring(1).split('\r\n');
    expect(lines[0], '日付,種別,金額,カテゴリ,内訳,支払方法,店舗名,メモ,レシートID');
    expect(lines[1], '2026-07-03,支出,1200,食費,,電子マネー,,コンビニ,');
  });

  test('内訳の取引はカテゴリ列=親名・内訳列=自名になる', () async {
    final all = await db.categoryDao.allCategories();
    final eatOutId = all.firstWhere((c) => c.name == '外食').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 980,
      date: const CivilDate(2026, 7, 5),
      categoryId: eatOutId,
      source: TxnSource.manual,
    ));

    final csv = await service.exportCsv();
    final lines = csv.substring(1).split('\r\n');
    expect(lines[1], '2026-07-05,支出,980,食費,外食,,,,');
  });

  test('fields with comma / quote / newline are RFC-4180 escaped', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 500,
      date: const CivilDate(2026, 7, 4),
      categoryId: foodId,
      source: TxnSource.manual,
      memo: const Value('セブン-イレブン, 渋谷店 "改装中"\n2行目🍙'),
    ));

    final csv = await service.exportCsv();
    // カンマ・引用符・改行を含むmemoは全体をクオートし、内部の"は""に
    expect(
      csv,
      contains('"セブン-イレブン, 渋谷店 ""改装中""\n2行目🍙"'),
    );
  });

  test('null paymentMethod and null memo render as empty fields', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.income,
      amount: 300000,
      date: const CivilDate(2026, 7, 25),
      categoryId: foodId,
      source: TxnSource.manual,
    ));

    final csv = await service.exportCsv();
    final lines = csv.substring(1).split('\r\n');
    expect(lines[1], '2026-07-25,収入,300000,食費,,,,,');
  });
}
