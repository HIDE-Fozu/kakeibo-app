import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

/// 最小の正当payload: システム未分類2 + 通常カテゴリ1 + 取引1（任意ID）
BackupPayload minimalPayload() => BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3),
      categories: const [
        BackupCategory(
            id: 100, name: '食費(旧端末)', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false,
            parentId: null),
        BackupCategory(
            id: 101, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 1, isArchived: false, isSystem: true,
            parentId: null),
        BackupCategory(
            id: 102, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 2, isArchived: false, isSystem: true,
            parentId: null),
      ],
      transactions: [
        BackupTxn(
          id: 500, type: TxnType.expense, amount: 4980,
          date: const CivilDate(2026, 6, 15), categoryId: 100,
          paymentMethod: null, memo: '旧端末の記録',
          source: TxnSource.manual, imagePath: null,
          createdAt: DateTime.utc(2026, 6, 15, 3),
          updatedAt: DateTime.utc(2026, 6, 15, 3),
        ),
      ],
    );

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newMemoryDb();
    service = BackupService(db);
  });
  tearDown(() => db.close());

  Future<int> seedOneTx() async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    return db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 999,
      date: const CivilDate(2026, 7, 1),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
  }

  test('applyRestore replaces everything and preserves ids verbatim', () async {
    await seedOneTx(); // 既存データ（プリセット20カテゴリ + 取引1）

    await service.applyRestore(minimalPayload());

    final cats = await db.categoryDao.allCategories();
    // プリセットの残骸なし＝payloadのカテゴリだけ（再シードも走らない）
    expect(cats.length, 3);
    expect(cats.map((c) => c.id).toSet(), {100, 101, 102});

    final txs = await db.select(db.transactions).get();
    final tx = txs.single;
    expect(tx.id, 500); // ID逐語保存
    expect(tx.categoryId, 100); // FKも逐語（再割当なし）
    expect(tx.amount, 4980);
    expect(tx.createdAt.toUtc(), DateTime.utc(2026, 6, 15, 3)); // 瞬間保存
  });

  test('export -> restore -> export is byte-identical (full fidelity)', () async {
    await seedOneTx();
    const codec = BackupCodec();
    final before = await service.exportJson();

    await service.applyRestore(codec.decode(before));
    final after = await service.exportJson();

    // exportedAt だけは現在時刻で変わるため、それ以外を比較
    String stripExportedAt(String s) =>
        s.replaceFirst(RegExp('"exportedAt": "[^"]*"'), '"exportedAt": "X"');
    expect(stripExportedAt(after), stripExportedAt(before));
  });

  test('mid-swap failure rolls back everything (atomicity)', () async {
    final keepId = await seedOneTx();

    // codecを迂回して不正payload（取引ID重複=PK衝突）を直接swapに流す
    final bad = minimalPayload();
    final dup = BackupPayload(
      formatVersion: bad.formatVersion,
      exportedAt: bad.exportedAt,
      categories: bad.categories,
      transactions: [...bad.transactions, ...bad.transactions], // id 500 が2回
    );

    await expectLater(service.applyRestore(dup), throwsA(anything));

    // 既存データが無傷（delete-allはロールバックされた）
    final cats = await db.categoryDao.allCategories();
    expect(cats.length, 20);
    final txs = await db.select(db.transactions).get();
    expect(txs.single.id, keepId);
    expect(txs.single.amount, 999);
  });

  test('restore: 内訳のidが親より小さくても復元できる（FK defer）', () async {
    const codec = BackupCodec();
    final payload = BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3),
      categories: const [
        BackupCategory(
            id: 2, name: '外食(旧)', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false,
            parentId: 50), // 子が親より小さいid → 挿入順が子先行になり即時FKなら落ちる
        BackupCategory(
            id: 50, name: '食費(旧)', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false,
            parentId: null),
        BackupCategory(
            id: 101, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 1, isArchived: false, isSystem: true,
            parentId: null),
        BackupCategory(
            id: 102, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 2, isArchived: false, isSystem: true,
            parentId: null),
      ],
      transactions: const [],
    );
    await service.applyRestore(codec.decode(codec.encode(payload)));
    final cats = await db.categoryDao.allCategories();
    expect(cats.map((c) => c.id).toSet(), {2, 50, 101, 102});
    expect(cats.firstWhere((c) => c.id == 2).parentId, 50);
  });

  test('restore: 内訳入りのシード済みDBを上書き復元できる（全行DELETEがFKで落ちない）',
      () async {
    // シード済みDB（外食が食費の内訳）に対し、最小payloadを復元して成功すること
    await service.applyRestore(minimalPayload());
    final cats = await db.categoryDao.allCategories();
    expect(cats.length, 3);
  });

  test('restore: つきいちタスク・記録（v5）が置換復元される', () async {
    // 復元前の既存chore（置換で消えるべき）
    await db.choreDao.insertTask(ChoreTasksCompanion.insert(
        name: '消えるタスク',
        dayOfMonth: 7,
        anchorDate: const CivilDate(2026, 7, 1)));

    final payload = BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3),
      categories: minimalPayload().categories,
      transactions: minimalPayload().transactions,
      choreTasks: [
        BackupChoreTask(
          id: 7, name: 'ハブラシ交換', emoji: '🪥', dayOfMonth: 30,
          anchorDate: const CivilDate(2026, 6, 1), archived: false,
          createdAt: DateTime.utc(2026, 6, 1),
        ),
      ],
      choreRecords: [
        BackupChoreRecord(
          id: 3, taskId: 7, doneDate: const CivilDate(2026, 6, 20), memo: '',
          createdAt: DateTime.utc(2026, 6, 20),
        ),
      ],
    );
    await service.applyRestore(payload);

    final tasks = await db.choreDao.allTasks();
    expect(tasks.single.id, 7); // IDまで逐語復元・既存は消えた
    expect(tasks.single.name, 'ハブラシ交換');
    final records = await db.choreDao.allRecords();
    expect(records.single.taskId, 7);
    expect(records.single.doneDate, const CivilDate(2026, 6, 20));

    // export→decode roundtrip にも chores が乗る
    final decoded = const BackupCodec().decode(await service.exportJson());
    expect(decoded.choreTasks.single.id, 7);
    expect(decoded.choreRecords.single.id, 3);
  });
}
