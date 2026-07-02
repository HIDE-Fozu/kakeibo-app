import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

/// writeVerified が必ず失敗するストア（退避不能シナリオの注入）
class FailingStore extends AutoBackupStore {
  FailingStore(super.dir);
  @override
  Future<File> writeVerified(String json) async {
    throw AutoBackupWriteError('simulated disk failure');
  }
}

void main() {
  late AppDatabase db;
  late Directory tmp;
  late AutoBackupStore store;
  late BackupService service;
  const codec = BackupCodec();

  setUp(() {
    db = newMemoryDb();
    tmp = Directory.systemTemp.createTempSync('kakeibo_flow_test_');
    store = AutoBackupStore(tmp);
    service = BackupService(db, store: store);
  });
  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> seedTx(int amount) async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: amount,
      date: const CivilDate(2026, 7, 1),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
  }

  /// 別DB相当のpayload JSON（このDBの現在の中身とは無関係な正当データ）
  Future<String> foreignJson() async {
    final other = newMemoryDb();
    addTearDown(other.close);
    final all = await other.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await other.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 7777,
      date: const CivilDate(2026, 5, 5),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
    return BackupService(other).exportJson();
  }

  test('successful restore snapshots the OLD data first, then swaps', () async {
    await seedTx(999); // 旧データ
    final incoming = await foreignJson();

    await service.restoreFromJson(incoming);

    // DBは新データ
    final txs = await db.select(db.transactions).get();
    expect(txs.single.amount, 7777);

    // 退避には旧データ(999)のスナップショットが残っている
    final snapshot = codec.decode(store.latest()!.readAsStringSync());
    expect(snapshot.transactions.single.amount, 999);
  });

  test('empty payload without allowEmpty -> EmptyBackupError, nothing touched',
      () async {
    await seedTx(999);
    final other = newMemoryDb();
    addTearDown(other.close);
    final emptyJson = await BackupService(other).exportJson(); // 取引ゼロの正当JSON

    await expectLater(
      service.restoreFromJson(emptyJson),
      throwsA(isA<EmptyBackupError>()),
    );
    // DB無傷・スナップショットも書かれていない
    expect((await db.select(db.transactions).get()).single.amount, 999);
    expect(store.listGenerations(), isEmpty);
  });

  test('empty payload WITH allowEmpty=true restores (one-tap undo path)',
      () async {
    await seedTx(999);
    final other = newMemoryDb();
    addTearDown(other.close);
    final emptyJson = await BackupService(other).exportJson();

    await service.restoreFromJson(emptyJson, allowEmpty: true);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect((await db.categoryDao.allCategories()).length, 20);
  });

  test('snapshot failure aborts restore, DB untouched', () async {
    await seedTx(999);
    final failing = BackupService(db, store: FailingStore(tmp));
    final incoming = await foreignJson();

    await expectLater(
      failing.restoreFromJson(incoming),
      throwsA(isA<AutoBackupWriteError>()),
    );
    expect((await db.select(db.transactions).get()).single.amount, 999);
  });

  test('invalid json aborts before any side effect', () async {
    await seedTx(999);
    await expectLater(
      service.restoreFromJson('{"garbage": 1}'),
      throwsA(isA<BackupException>()),
    );
    expect((await db.select(db.transactions).get()).single.amount, 999);
    expect(store.listGenerations(), isEmpty);
  });
}
