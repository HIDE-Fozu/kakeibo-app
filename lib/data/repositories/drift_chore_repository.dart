import 'package:drift/drift.dart';

import '../../domain/entities.dart';
import '../../domain/money/civil_date.dart';
import '../../domain/repositories.dart';
import '../db/daos.dart';
import '../db/database.dart';

/// つきいちタスクのリポジトリ。DAO行 ↔ domain 変換をここに閉じ込める。
class DriftChoreRepository implements ChoreRepository {
  DriftChoreRepository(this._db);

  final AppDatabase _db;

  ChoreDao get _dao => _db.choreDao;

  @override
  Stream<List<ChoreTask>> watchTasks() =>
      _dao.watchTasks().map((rows) => rows.map(_toTask).toList());

  @override
  Stream<List<ChoreRecord>> watchRecords() =>
      _dao.watchRecords().map((rows) => rows.map(_toRecord).toList());

  @override
  Future<List<ChoreTask>> allTasks() async =>
      (await _dao.allTasks()).map(_toTask).toList();

  @override
  Future<List<ChoreRecord>> allRecords() async =>
      (await _dao.allRecords()).map(_toRecord).toList();

  @override
  Future<int> addTask({
    required String name,
    required String emoji,
    required int intervalDays,
    required CivilDate anchorDate,
  }) {
    assert(intervalDays >= 1, 'intervalDays must be >= 1');
    return _dao.insertTask(ChoreTasksCompanion.insert(
      name: name,
      emoji: Value(emoji),
      intervalDays: intervalDays,
      anchorDate: anchorDate,
    ));
  }

  @override
  Future<void> updateTask(ChoreTask task) => _dao.updateTask(
        task.id,
        ChoreTasksCompanion(
          name: Value(task.name),
          emoji: Value(task.emoji),
          intervalDays: Value(task.intervalDays),
          anchorDate: Value(task.anchorDate),
          archived: Value(task.archived),
        ),
      );

  @override
  Future<void> setArchived(int taskId, bool archived) =>
      _dao.setArchived(taskId, archived);

  @override
  Future<void> deleteTask(int taskId) => _dao.deleteTask(taskId);

  @override
  Future<int> addRecord({
    required int taskId,
    required CivilDate doneDate,
    String memo = '',
  }) =>
      _dao.insertRecord(ChoreRecordsCompanion.insert(
        taskId: taskId,
        doneDate: doneDate,
        memo: Value(memo),
      ));

  @override
  Future<void> updateRecord(ChoreRecord record) => _dao.updateRecord(
        record.id,
        ChoreRecordsCompanion(
          doneDate: Value(record.doneDate),
          memo: Value(record.memo),
        ),
      );

  @override
  Future<void> deleteRecord(int recordId) => _dao.deleteRecord(recordId);

  @override
  Future<bool> hasRecordOn(int taskId, CivilDate date) =>
      _dao.hasRecordOn(taskId, date);

  ChoreTask _toTask(ChoreTaskRow r) => ChoreTask(
        id: r.id,
        name: r.name,
        emoji: r.emoji,
        intervalDays: r.intervalDays,
        anchorDate: r.anchorDate,
        archived: r.archived,
      );

  ChoreRecord _toRecord(ChoreRecordRow r) => ChoreRecord(
        id: r.id,
        taskId: r.taskId,
        doneDate: r.doneDate,
        memo: r.memo,
        createdAt: r.createdAt,
      );
}
