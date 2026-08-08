import '../entities.dart';
import '../money/civil_date.dart';
import 'recurring_schedule.dart' show daysInMonth;

/// つきいちタスクの期日計算。DBに触れない純関数群
/// （routine-reminder の due_logic.dart を CivilDate ベースに移植。
/// v2.2.0で「間隔日数」→「毎月N日」方式に変更・固定費ルールと同じ語彙）。

/// iOSのpending通知上限64に対する安全マージン込みの予約上限。
const kChoreMaxScheduled = 60;
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
  final int dayOfMonth;
  final CivilDate date;

  /// その期日時点の「超過見込み件数」。通知バッジに使う。
  final int badge;

  const PlannedChore({
    required this.taskId,
    required this.emoji,
    required this.name,
    required this.dayOfMonth,
    required this.date,
    required this.badge,
  });
}

/// y年m月の「毎月day日」。短い月は月末に丸める（固定費のdueDateInと同じ規則）。
CivilDate _dueInMonth(int year, int month, int day) {
  final last = daysInMonth(year, month);
  return CivilDate(year, month, day > last ? last : day);
}

CivilDate _dueInNextMonth(int year, int month, int day) => month == 12
    ? _dueInMonth(year + 1, 1, day)
    : _dueInMonth(year, month + 1, day);

/// 次回期日 = 記録が無ければ anchorDate（作成日）以降で最初の「毎月N日」、
/// あれば最後にやった月の翌月の「毎月N日」（その月にやった＝その月は済み）。
CivilDate nextChoreDue(ChoreTask task, List<ChoreRecord> recordsOfTask) {
  if (recordsOfTask.isEmpty) {
    final a = task.anchorDate;
    final inAnchorMonth = _dueInMonth(a.year, a.month, task.dayOfMonth);
    if (!inAnchorMonth.isBefore(a)) return inAnchorMonth;
    return _dueInNextMonth(a.year, a.month, task.dayOfMonth);
  }
  final latest = recordsOfTask
      .map((r) => r.doneDate)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  return _dueInNextMonth(latest.year, latest.month, task.dayOfMonth);
}

/// [doneDate] に記録した直後の次回期日（スナックバーの近似表示用）。
CivilDate choreDueAfterDone(ChoreTask task, CivilDate doneDate) =>
    _dueInNextMonth(doneDate.year, doneDate.month, task.dayOfMonth);

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
      dayOfMonth: s.task.dayOfMonth,
      date: s.due,
      badge: badge,
    );
  }).toList();
}

/// 現在超過中の件数（アプリアイコンのバッジ数）。
int choreOverdueCount(
        List<ChoreTask> tasks, List<ChoreRecord> allRecords, CivilDate today) =>
    buildChoreStatuses(tasks, allRecords, today).where((s) => s.isOverdue).length;
