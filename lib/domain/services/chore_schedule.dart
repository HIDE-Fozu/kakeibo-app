import '../entities.dart';
import '../money/civil_date.dart';

/// つきいちタスクの期日計算。DBに触れない純関数群
/// （routine-reminder の due_logic.dart を CivilDate ベースに移植）。

/// iOSのpending通知上限64に対する安全マージン込みの予約上限。
const kChoreMaxScheduled = 60;
const kChoreIntervalMin = 1;
const kChoreIntervalMax = 999;
const kChoreNameMax = 30;
const kChoreMemoMax = 100;
const kChoreDefaultNotifyHour = 9;
const kChoreDefaultNotifyMinute = 0;

/// 予約すべき通知1件分。文言はここでは組み立てない（ロケールは通知予約時点の
/// アプリ設定に従うため、表示文字列は ChoreActions が l10n で組み立てる）。
class PlannedChore {
  final int taskId;
  final String emoji;
  final String name;
  final int intervalDays;
  final CivilDate date;

  /// その期日時点の「超過見込み件数」。通知バッジに使う。
  final int badge;

  const PlannedChore({
    required this.taskId,
    required this.emoji,
    required this.name,
    required this.intervalDays,
    required this.date,
    required this.badge,
  });
}

/// 次回期日 = 最後にやった日 + intervalDays（記録なしなら anchorDate + intervalDays）。
CivilDate nextChoreDue(ChoreTask task, List<ChoreRecord> recordsOfTask) {
  if (recordsOfTask.isEmpty) return task.anchorDate.addDays(task.intervalDays);
  final latest = recordsOfTask
      .map((r) => r.doneDate)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  return latest.addDays(task.intervalDays);
}

int choreDaysLeft(CivilDate today, CivilDate due) => due.differenceInDays(today);

List<ChoreRecord> _of(int taskId, List<ChoreRecord> all) =>
    all.where((r) => r.taskId == taskId).toList();

List<ChoreTask> _actives(List<ChoreTask> tasks) =>
    tasks.where((t) => !t.archived).toList();

/// アクティブ全タスクの期日状況（期日昇順・同日はid昇順）。
List<ChoreStatus> buildChoreStatuses(
    List<ChoreTask> tasks, List<ChoreRecord> allRecords, CivilDate today) {
  final list = _actives(tasks).map((t) {
    final due = nextChoreDue(t, _of(t.id, allRecords));
    return ChoreStatus(task: t, due: due, daysLeft: choreDaysLeft(today, due));
  }).toList()
    ..sort((a, b) {
      final c = a.due.compareTo(b.due);
      return c != 0 ? c : a.task.id.compareTo(b.task.id);
    });
  return list;
}

/// 月カレンダーのドット情報（やった=done / 期日=due / 超過=hasOverdue）。
Map<CivilDate, ChoreDayMarks> choreMonthMarks(int year, int month,
    List<ChoreTask> tasks, List<ChoreRecord> allRecords, CivilDate today) {
  final actives = _actives(tasks);
  final activeIds = actives.map((t) => t.id).toSet();
  final done = <CivilDate, List<int>>{};
  final due = <CivilDate, List<int>>{};
  final overdue = <CivilDate, bool>{};
  for (final r in allRecords) {
    if (r.doneDate.year == year &&
        r.doneDate.month == month &&
        activeIds.contains(r.taskId)) {
      done.putIfAbsent(r.doneDate, () => []).add(r.taskId);
    }
  }
  for (final t in actives) {
    final d = nextChoreDue(t, _of(t.id, allRecords));
    if (d.year == year && d.month == month) {
      due.putIfAbsent(d, () => []).add(t.id);
      if (d.isBefore(today)) overdue[d] = true;
    }
  }
  return {
    for (final day in {...done.keys, ...due.keys})
      day: ChoreDayMarks(
        doneTaskIds: done[day] ?? const [],
        dueTaskIds: due[day] ?? const [],
        hasOverdue: overdue[day] ?? false,
      ),
  };
}

/// 予約すべき通知プラン（期日が today 以降のもの・期日昇順・最大 [limit] 件）。
///
/// badge は「その期日時点の超過見込み件数」。すでに超過中の項目（プラン対象外）も
/// 発火時点ではまだ超過しているとみなして数えるため、母集合はアクティブ全項目。
List<PlannedChore> buildChorePlans(
    List<ChoreTask> tasks, List<ChoreRecord> allRecords, CivilDate today,
    {int limit = kChoreMaxScheduled}) {
  final all = buildChoreStatuses(tasks, allRecords, today);
  final eligible = all.where((s) => !s.due.isBefore(today)).toList();
  return eligible.take(limit).map((s) {
    final badge = all.where((o) => !o.due.isAfter(s.due)).length;
    return PlannedChore(
      taskId: s.task.id,
      emoji: s.task.emoji,
      name: s.task.name,
      intervalDays: s.task.intervalDays,
      date: s.due,
      badge: badge,
    );
  }).toList();
}

/// 現在超過中の件数（アプリアイコンのバッジ数）。
int choreOverdueCount(
        List<ChoreTask> tasks, List<ChoreRecord> allRecords, CivilDate today) =>
    buildChoreStatuses(tasks, allRecords, today).where((s) => s.isOverdue).length;
