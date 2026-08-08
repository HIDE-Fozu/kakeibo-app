import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/repositories/drift_chore_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'support/test_db.dart';

/// routine-reminder の db_test.dart を移植（DAO直→repository経由）。
void main() {
  late DriftChoreRepository repo;

  setUp(() {
    final db = newMemoryDb();
    addTearDown(db.close);
    repo = DriftChoreRepository(db);
  });

  test('タスクCRUD・並びはid昇順・アーカイブも含む', () async {
    final id1 = await repo.addTask(
        name: 'ハブラシ交換',
        emoji: '🪥',
        dayOfMonth: 30,
        anchorDate: CivilDate.parse('2026-06-01'));
    final id2 = await repo.addTask(
        name: 'まくら干し',
        emoji: '🛏',
        dayOfMonth: 14,
        anchorDate: CivilDate.parse('2026-07-01'));

    var tasks = await repo.allTasks();
    expect(tasks.map((t) => t.id).toList(), [id1, id2]);
    expect(tasks.first.anchorDate, CivilDate.parse('2026-06-01'));

    await repo.updateTask(ChoreTask(
      id: id1,
      name: 'ハブラシ',
      emoji: '🦷',
      dayOfMonth: 15,
      anchorDate: CivilDate.parse('2026-06-15'),
      archived: false,
    ));
    tasks = await repo.allTasks();
    expect(tasks.first.name, 'ハブラシ');
    expect(tasks.first.dayOfMonth, 15);

    await repo.setArchived(id2, true);
    tasks = await repo.allTasks();
    expect(tasks.map((t) => t.id).toList(), [id1, id2]); // アーカイブも一覧に残る
    expect(tasks.last.archived, isTrue);

    // watch版も同じ内容（Future版と一致）
    final watched = await repo.watchTasks().first;
    expect(watched.map((t) => t.id).toList(), [id1, id2]);
  });

  test('記録CRUDとhasRecordOn', () async {
    final tid = await repo.addTask(
        name: 'ハブラシ交換',
        emoji: '🪥',
        dayOfMonth: 30,
        anchorDate: CivilDate.parse('2026-06-01'));
    final rid = await repo.addRecord(
        taskId: tid, doneDate: CivilDate.parse('2026-07-10'), memo: '新しいやつ');

    expect(await repo.hasRecordOn(tid, CivilDate.parse('2026-07-10')), isTrue);
    expect(await repo.hasRecordOn(tid, CivilDate.parse('2026-07-11')), isFalse);

    final rec = (await repo.allRecords()).single;
    expect(rec.memo, '新しいやつ');

    await repo.updateRecord(ChoreRecord(
      id: rid,
      taskId: tid,
      doneDate: CivilDate.parse('2026-07-11'),
      memo: '',
      createdAt: rec.createdAt,
    ));
    final updated = (await repo.allRecords()).single;
    expect(updated.doneDate, CivilDate.parse('2026-07-11'));
    expect(updated.memo, '');

    await repo.deleteRecord(rid);
    expect(await repo.allRecords(), isEmpty);
  });

  test('タスク削除で記録もカスケード削除（FK ON）', () async {
    final tid = await repo.addTask(
        name: 'ハブラシ交換',
        emoji: '🪥',
        dayOfMonth: 30,
        anchorDate: CivilDate.parse('2026-06-01'));
    await repo.addRecord(taskId: tid, doneDate: CivilDate.parse('2026-07-10'));
    await repo.addRecord(taskId: tid, doneDate: CivilDate.parse('2026-07-11'));
    expect((await repo.allRecords()).length, 2);

    await repo.deleteTask(tid);
    expect(await repo.allTasks(), isEmpty);
    expect(await repo.allRecords(), isEmpty); // ここが空にならなければFK OFFの回帰
  });
}
