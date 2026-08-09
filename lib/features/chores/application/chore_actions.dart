import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/db/enums.dart';
import '../../../data/notifications/badge_service.dart';
import '../../../data/notifications/notification_service.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/repositories.dart';
import '../../../domain/services/chore_schedule.dart';
import '../../../l10n/app_localizations.dart';

/// [ChoreActions.recordDone]の結果種別。
enum ChoreRecordOutcome {
  /// 記録が入った。
  done,

  /// 同日にすでに記録がある。UI側で確認ダイアログを出し、
  /// 承諾されたら`force: true`で再度呼ぶ。
  needsConfirm,
}

/// prefsキー。設定画面の初期値読込と本クラスで同じキーを共有するため公開する。
const kChoreNotifyHourPrefsKey = 'choreNotifyHour';
const kChoreNotifyMinutePrefsKey = 'choreNotifyMinute';

/// 「許可ダイアログは初回記録直後の一度だけ」の管理フラグ。設定画面が
/// 「まだ要求していない＝OSを呼ばず案内文を出す」判定に参照するため公開する。
const kChorePermissionAskedPrefsKey = 'chorePermissionAsked';

/// つきいちタスクのユースケースを束ねる（記録→再スケジュール→バッジ更新）。
///
/// すべてのミューテーションの最後に必ず[resync]を呼ぶ。UI層はこのクラス経由
/// でのみ家事データを変更する（chore_providers.dart の choreActionsProvider）。
/// routine-reminder の RecordActions を移植（DB直依存→repository、l10n注入）。
class ChoreActions {
  ChoreActions(
    this._repo,
    this._notif,
    this._badge,
    this._today,
    this._prefs,
    this._l10n,
  );

  final ChoreRepository _repo;
  final NotificationService _notif;
  final BadgeService _badge;
  final CivilDate Function() _today;
  final SharedPreferences _prefs;
  final AppLocalizations Function() _l10n;

  /// 「やった」記録。強制しない限り同日重複はneedsConfirmを返し挿入しない。
  /// 未来日付は禁止（UI側でも防ぐ二重防御）。
  Future<({ChoreRecordOutcome outcome, int? recordId})> recordDone(
    int taskId,
    CivilDate date, {
    String memo = '',
    bool force = false,
  }) async {
    if (date.isAfter(_today())) {
      throw ArgumentError.value(date, 'date', 'cannot record a future date');
    }
    if (!force && await _repo.hasRecordOn(taskId, date)) {
      return (outcome: ChoreRecordOutcome.needsConfirm, recordId: null);
    }
    final id = await _repo.addRecord(taskId: taskId, doneDate: date, memo: memo);
    await _maybeRequestPermission();
    await resync();
    return (outcome: ChoreRecordOutcome.done, recordId: id);
  }

  /// 直前の記録を取り消す（SnackBarの[元に戻す]）。
  Future<void> undo(int recordId) async {
    await _repo.deleteRecord(recordId);
    await resync();
  }

  /// 記録の日付/メモを修正する。
  Future<void> editRecord(ChoreRecord updated) async {
    await _repo.updateRecord(updated);
    await resync();
  }

  /// 記録を削除する（履歴画面）。
  Future<void> removeRecord(int recordId) async {
    await _repo.deleteRecord(recordId);
    await resync();
  }

  /// 新規タスクの作成。anchorDate=today なので、初回期日は
  /// 毎月N日なら today 以降で最初のN日、N日ごとなら today+間隔。
  Future<int> createTask({
    required String name,
    required String emoji,
    ChoreRepeatUnit repeatUnit = ChoreRepeatUnit.monthlyDay,
    required int dayOfMonth,
    int intervalDays = 30,
  }) async {
    final taskId = await _repo.addTask(
      name: name,
      emoji: emoji,
      repeatUnit: repeatUnit,
      dayOfMonth: dayOfMonth,
      intervalDays: intervalDays,
      anchorDate: _today(),
    );
    await _maybeRequestPermission();
    await resync();
    return taskId;
  }

  /// タスクの名前・繰り返し設定・絵文字・anchorDate・archivedを更新する。
  Future<void> updateTaskInfo(ChoreTask task) async {
    await _repo.updateTask(task);
    await resync();
  }

  /// アーカイブ状態を切り替える。
  Future<void> setArchived(int taskId, bool archived) async {
    await _repo.setArchived(taskId, archived);
    await resync();
  }

  /// タスクを完全削除する（記録もカスケード削除）。
  Future<void> deleteTask(int taskId) async {
    await _repo.deleteTask(taskId);
    await resync();
  }

  /// 通知時刻（アプリ全体で1つ）を変更する。
  Future<void> setNotifyTime(int hour, int minute) async {
    await _prefs.setInt(kChoreNotifyHourPrefsKey, hour);
    await _prefs.setInt(kChoreNotifyMinutePrefsKey, minute);
    await resync();
  }

  /// DB現在値→通知プラン再計算→全再予約→バッジ更新。
  ///
  /// 全ミューテーションの最後に必ず呼ぶ。差分管理はせず毎回全キャンセル→
  /// 全再予約する（単純さ優先）。通知文言はこの時点のロケールで組み立てる
  /// （ロケール変更時は AppSettings.setLocale が resync を呼び直す）。
  Future<void> resync() async {
    final tasks = await _repo.allTasks();
    final records = await _repo.allRecords();
    final today = _today();
    final l = _l10n();
    final plans = buildChorePlans(tasks, records, today)
        .map((p) => ScheduledNotification(
              id: p.taskId,
              title: '${p.emoji} ${p.name}',
              body: switch (p.repeatUnit) {
                ChoreRepeatUnit.monthlyDay =>
                  l.choreNotificationBody(p.dayOfMonth),
                ChoreRepeatUnit.everyDays =>
                  l.choreNotificationBodyInterval(p.intervalDays),
              },
              date: p.date,
              badge: p.badge,
            ))
        .toList();
    final hour = _prefs.getInt(kChoreNotifyHourPrefsKey) ?? kChoreDefaultNotifyHour;
    final minute =
        _prefs.getInt(kChoreNotifyMinutePrefsKey) ?? kChoreDefaultNotifyMinute;
    await _notif.rescheduleAll(plans, hour: hour, minute: minute);
    await _badge.setCount(choreOverdueCount(tasks, records, today));
  }

  /// 初回記録の完了直後に一度だけ通知許可を要求する。
  /// prefsフラグ`chorePermissionAsked`で「一度だけ」を管理する。
  Future<void> _maybeRequestPermission() async {
    if (_prefs.getBool(kChorePermissionAskedPrefsKey) ?? false) return;
    await _prefs.setBool(kChorePermissionAskedPrefsKey, true);
    try {
      await _notif.requestPermission();
    } catch (_) {
      // 許可要求の失敗（platform channel例外等）が記録処理を壊してはならない。
      // 呼び出し元は必ず後続のresync()まで到達すること。
    }
  }
}
