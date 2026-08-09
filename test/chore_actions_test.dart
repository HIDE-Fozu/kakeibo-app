import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_chore_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/chores/application/chore_actions.dart';
import 'package:kakeibo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/chore_fakes.dart';
import 'support/test_db.dart';

/// routine-reminder の record_actions_test.dart を移植。
/// 変更点: DB直依存→ChoreRepository / 固定Clock→ラムダ / 文言はl10n(ja)で検証。
/// v2.2.0で繰り返しは二本立て（毎月N日 / N日ごと）。
void main() {
  late DriftChoreRepository repo;
  late FakeNotificationService notif;
  late FakeBadgeService badge;
  late SharedPreferences prefs;
  late ChoreActions actions;

  final l10nJa = lookupAppLocalizations(const Locale('ja'));

  ChoreActions actionsWith(CivilDate today) => ChoreActions(
        repo,
        notif,
        badge,
        () => today,
        prefs,
        () => l10nJa,
      );

  setUp(() async {
    final db = newMemoryDb();
    addTearDown(db.close);
    repo = DriftChoreRepository(db);
    notif = FakeNotificationService();
    badge = FakeBadgeService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    actions = actionsWith(CivilDate.parse('2026-07-15'));
  });

  test('recordDone→記録が入りrescheduleAllとsetCountが正しい内容で呼ばれる', () async {
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      dayOfMonth: 14,
      anchorDate: CivilDate.parse('2026-06-10'),
    );
    final r = await actions.recordDone(tid, CivilDate.parse('2026-07-15'));
    expect(r.outcome, ChoreRecordOutcome.done);
    final plans = notif.rescheduleCalls.single;
    expect(plans.single.date, CivilDate.parse('2026-08-14')); // 7月に実施→8/14
    expect(plans.single.title, '🪥 ハブラシ交換');
    expect(plans.single.body, '毎月14日の予定です'); // l10n(ja)で組み立て（毎月N日）
    expect(notif.lastHour, 9); // 既定の通知時刻
    expect(badge.setCalls.single, 0); // 超過なし
  });

  test('undo→記録が消え期日が元に戻る', () async {
    final localActions = actionsWith(CivilDate.parse('2026-07-01'));
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      dayOfMonth: 10,
      anchorDate: CivilDate.parse('2026-07-01'),
    );
    final r = await localActions.recordDone(tid, CivilDate.parse('2026-07-01'));
    expect(r.recordId, isNotNull);
    var plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-08-10')); // 7月は済み
    await localActions.undo(r.recordId!);
    plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-07-10')); // 7/10に戻る
  });

  test('同日重複はneedsConfirm・force=trueで挿入', () async {
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      dayOfMonth: 14,
      anchorDate: CivilDate.parse('2026-06-10'),
    );
    final first = await actions.recordDone(tid, CivilDate.parse('2026-07-15'));
    expect(first.outcome, ChoreRecordOutcome.done);

    final dup = await actions.recordDone(tid, CivilDate.parse('2026-07-15'));
    expect(dup.outcome, ChoreRecordOutcome.needsConfirm);
    expect(dup.recordId, isNull);
    var sameDay = (await repo.allRecords())
        .where((r) => r.doneDate == CivilDate.parse('2026-07-15'));
    expect(sameDay.length, 1);

    final forced = await actions
        .recordDone(tid, CivilDate.parse('2026-07-15'), force: true);
    expect(forced.outcome, ChoreRecordOutcome.done);
    sameDay = (await repo.allRecords())
        .where((r) => r.doneDate == CivilDate.parse('2026-07-15'));
    expect(sameDay.length, 2);
  });

  test('editRecord/removeRecordで再計算される', () async {
    final localActions = actionsWith(CivilDate.parse('2026-07-01'));
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      dayOfMonth: 31,
      anchorDate: CivilDate.parse('2026-07-01'),
    );
    final r = await localActions.recordDone(tid, CivilDate.parse('2026-06-20'));
    final rec = (await repo.allRecords()).single;
    expect(r.recordId, rec.id);
    var plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-07-31')); // 6月実施→7/31

    // 日付を7/01に修正→7月は済み→8/31
    await localActions.editRecord(ChoreRecord(
      id: rec.id,
      taskId: tid,
      doneDate: CivilDate.parse('2026-07-01'),
      memo: rec.memo,
      createdAt: rec.createdAt,
    ));
    plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-08-31'));

    // 削除→anchor基準（作成月の7/31）に戻る
    await localActions.removeRecord(rec.id);
    plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-07-31'));
  });

  test('setNotifyTime→lastHour/lastMinuteが変わる', () async {
    await actions.setNotifyTime(21, 30);
    expect(notif.lastHour, 21);
    expect(notif.lastMinute, 30);
  });

  test('初回記録の直後に一度だけrequestPermission', () async {
    final tid = await actions.createTask(
        name: 'ハブラシ交換', emoji: '🪥', dayOfMonth: 20);
    expect(notif.requestCount, 1);
    // 2回目以降の記録では再要求されない
    await actions.recordDone(tid, CivilDate.parse('2026-07-15'));
    expect(notif.requestCount, 1);
  });

  test('createTask: anchorDate=today・初回期日=今日以降で最初の毎月N日', () async {
    await actions.createTask(name: 'まくら干し', emoji: '🛏', dayOfMonth: 20);
    final t = (await repo.allTasks()).single;
    expect(t.anchorDate, CivilDate.parse('2026-07-15'));
    final plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-07-20')); // 今月の20日
  });

  test('createTask: 今月の予定日を過ぎていれば初回は翌月', () async {
    await actions.createTask(name: 'まくら干し', emoji: '🛏', dayOfMonth: 10);
    final plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-08-10')); // 7/10は経過済み
  });

  test('createTask（N日ごと）: 初回期日=today+間隔・通知文言も間隔版', () async {
    await actions.createTask(
      name: 'まくら干し',
      emoji: '🛏',
      repeatUnit: ChoreRepeatUnit.everyDays,
      dayOfMonth: 1,
      intervalDays: 14,
    );
    final t = (await repo.allTasks()).single;
    expect(t.repeatUnit, ChoreRepeatUnit.everyDays);
    expect(t.intervalDays, 14);
    final plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-07-29')); // 7/15+14
    expect(plans.single.body, '前回から14日たちました');
  });

  test('N日ごとの記録→次回は記録日+間隔（毎月N日と挙動が違う）', () async {
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      repeatUnit: ChoreRepeatUnit.everyDays,
      dayOfMonth: 1,
      intervalDays: 30,
      anchorDate: CivilDate.parse('2026-06-10'),
    );
    await actions.recordDone(tid, CivilDate.parse('2026-07-15'));
    final plans = notif.rescheduleCalls.last;
    expect(plans.single.date, CivilDate.parse('2026-08-14')); // 7/15+30
  });

  test('未来日付のrecordDoneはArgumentError', () async {
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      dayOfMonth: 14,
      anchorDate: CivilDate.parse('2026-06-10'),
    );
    expect(
      () => actions.recordDone(tid, CivilDate.parse('2026-07-16')),
      throwsArgumentError,
    );
  });

  test('許可要求の例外でもresyncは走る（不変条件）', () async {
    notif.throwOnRequestPermission = true;
    final tid = await repo.addTask(
      name: 'ハブラシ交換',
      emoji: '🪥',
      dayOfMonth: 30,
      anchorDate: CivilDate.parse('2026-06-10'),
    );
    notif.rescheduleCalls.clear();
    badge.setCalls.clear();
    final r = await actions.recordDone(tid, CivilDate.parse('2026-07-15'));
    expect(r.outcome, ChoreRecordOutcome.done); // 例外を投げずに完了
    expect(notif.requestCount, 1); // 許可要求自体は呼ばれた（そしてthrowした）
    expect((await repo.allRecords()).length, 1); // 記録が入っている
    expect(notif.rescheduleCalls, hasLength(1)); // resyncが走った
    expect(badge.setCalls, hasLength(1));
  });

  test('updateTaskInfoの全フィールドroundtrip', () async {
    final tid = await actions.createTask(
        name: 'ハブラシ交換', emoji: '🪥', dayOfMonth: 20);
    final updated = ChoreTask(
      id: tid,
      name: 'マットレス向き替え',
      emoji: '🛏️',
      repeatUnit: ChoreRepeatUnit.everyDays,
      dayOfMonth: 25,
      intervalDays: 90,
      anchorDate: CivilDate.parse('2026-05-01'),
      archived: true,
    );
    await actions.updateTaskInfo(updated);
    final t = (await repo.allTasks()).singleWhere((t) => t.id == tid);
    expect(t.name, 'マットレス向き替え');
    expect(t.emoji, '🛏️');
    expect(t.repeatUnit, ChoreRepeatUnit.everyDays); // 単位の切替も保存される
    expect(t.dayOfMonth, 25);
    expect(t.intervalDays, 90);
    expect(t.anchorDate, CivilDate.parse('2026-05-01'));
    expect(t.archived, isTrue);
  });
}
