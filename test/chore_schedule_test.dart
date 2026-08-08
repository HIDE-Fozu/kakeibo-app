import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/chore_schedule.dart';

/// routine-reminder の due_logic_test.dart を移植（DateOnly→CivilDate・
/// Task→ChoreTask・buildPlans は文言レスの PlannedChore に変更）。
ChoreTask task(int id,
        {int interval = 30,
        String anchor = '2026-06-01',
        bool archived = false,
        String name = 'ハブラシ交換',
        String emoji = '🪥'}) =>
    ChoreTask(
        id: id,
        name: name,
        emoji: emoji,
        intervalDays: interval,
        anchorDate: CivilDate.parse(anchor),
        archived: archived);

ChoreRecord rec(int id, int taskId, String date, {String memo = ''}) =>
    ChoreRecord(
        id: id,
        taskId: taskId,
        doneDate: CivilDate.parse(date),
        memo: memo,
        createdAt: DateTime(2026, 1, 1));

final today = CivilDate.parse('2026-07-15');

void main() {
  group('nextChoreDue（前回実施日基準）', () {
    test('記録なし→anchor+interval', () => expect(
        nextChoreDue(task(1, anchor: '2026-07-01'), []),
        CivilDate.parse('2026-07-31')));
    test('記録1件→記録日+interval', () => expect(
        nextChoreDue(task(1), [rec(1, 1, '2026-07-10')]),
        CivilDate.parse('2026-08-09')));
    test('複数記録→最新基準（並び順に依存しない）', () => expect(
        nextChoreDue(task(1), [rec(2, 1, '2026-07-10'), rec(1, 1, '2026-06-01')]),
        CivilDate.parse('2026-08-09')));
    test('遅れて実施→次回もその分ズレる', () {
      // 期日7/1(anchor6/1+30日)に対し7/5に実施→次回は8/4（7/1+30ではない）
      expect(nextChoreDue(task(1, anchor: '2026-06-01'), [rec(1, 1, '2026-07-05')]),
          CivilDate.parse('2026-08-04'));
    });
    test('過去日付の記録追加で期日が過去になる', () => expect(
        nextChoreDue(task(1), [rec(1, 1, '2026-05-01')]).isBefore(today), isTrue));
  });

  group('choreDaysLeft', () {
    test('当日=0/未来正/過去負', () {
      expect(choreDaysLeft(today, today), 0);
      expect(choreDaysLeft(today, CivilDate.parse('2026-07-20')), 5);
      expect(choreDaysLeft(today, CivilDate.parse('2026-07-12')), -3);
    });
  });

  group('buildChoreStatuses', () {
    test('超過→当日→未来の昇順・アーカイブ除外・同日はid昇順', () {
      final tasks = [
        task(1, anchor: '2026-07-01', interval: 30), // due 7/31
        task(2, anchor: '2026-06-01', interval: 30), // due 7/1 超過
        task(3, anchor: '2026-06-15', interval: 30), // due 7/15 今日
        task(4, anchor: '2026-06-01', interval: 5, archived: true),
        task(5, anchor: '2026-06-16', interval: 29), // due 7/15 今日(同日)
      ];
      final s = buildChoreStatuses(tasks, [], today);
      expect(s.map((e) => e.task.id).toList(), [2, 3, 5, 1]);
      expect(s.first.isOverdue, isTrue);
      expect(s[1].daysLeft, 0);
    });
  });

  group('choreMonthMarks', () {
    test('やった/期日/超過の振り分けと月境界', () {
      final tasks = [
        task(1, anchor: '2026-06-20', interval: 30), // due 7/20 未来期日
        task(2, anchor: '2026-06-01', interval: 30), // due 7/1 超過(今日7/15)
        task(3, anchor: '2026-07-02', interval: 30), // due 8/1 当月外
      ];
      final recs = [rec(1, 1, '2026-06-20'), rec(2, 2, '2026-07-06')];
      final m1 = choreMonthMarks(2026, 7, tasks, [rec(1, 1, '2026-06-20')], today);
      expect(m1[CivilDate.parse('2026-07-20')]!.dueTaskIds, [1]);
      expect(m1[CivilDate.parse('2026-07-01')]!.hasOverdue, isTrue); // task2超過
      expect(m1.containsKey(CivilDate.parse('2026-08-01')), isFalse); // 当月外
      final m2 = choreMonthMarks(2026, 7, tasks, recs, today);
      expect(m2[CivilDate.parse('2026-07-06')]!.doneTaskIds, [2]); // やった
      expect(m2.containsKey(CivilDate.parse('2026-07-01')), isFalse); // 記録で超過解消
    });
    test('同日に記録と期日が重なる', () {
      final t = [task(1, anchor: '2026-06-15', interval: 30)]; // due 7/15
      final r = [rec(1, 9, '2026-07-15')]; // 別項目(9)の記録
      final m =
          choreMonthMarks(2026, 7, [...t, task(9, anchor: '2026-07-10')], r, today);
      final marks = m[CivilDate.parse('2026-07-15')]!;
      expect(marks.dueTaskIds, [1]);
      expect(marks.doneTaskIds, [9]);
    });
    test('アーカイブ項目はやったも期日も出ない', () {
      final m = choreMonthMarks(
          2026, 7, [task(1, archived: true)], [rec(1, 1, '2026-07-10')], today);
      expect(m, isEmpty);
    });
  });

  group('buildChorePlans', () {
    test('未来期日のみ・昇順・当日含む・文言用フィールド', () {
      final tasks = [
        task(1, anchor: '2026-06-01', interval: 30), // due 7/1 過去→除外
        task(2, anchor: '2026-06-15', interval: 30), // due 7/15 当日→含む
        task(3, anchor: '2026-06-20', interval: 30,
            name: 'マットレス向き替え', emoji: '🛏️'), // due 7/20
      ];
      final p = buildChorePlans(tasks, [], today);
      expect(p.map((e) => e.taskId).toList(), [2, 3]);
      // 文言はChoreActionsがl10nで組み立てるため、素材だけを持つ
      expect(p[1].emoji, '🛏️');
      expect(p[1].name, 'マットレス向き替え');
      expect(p[1].intervalDays, 30);
    });
    test('badge=期日以前の件数（同日複数は同値で加算）', () {
      final tasks = [
        task(1, anchor: '2026-06-16', interval: 30), // due 7/16
        task(2, anchor: '2026-06-16', interval: 30), // due 7/16 同日
        task(3, anchor: '2026-06-21', interval: 30), // due 7/21
      ];
      final p = buildChorePlans(tasks, [], today);
      expect(p[0].badge, 2); // 7/16時点: due<=7/16 が2件
      expect(p[1].badge, 2);
      expect(p[2].badge, 3); // 7/21時点: 3件全部
    });
    test('badge=超過中の項目も加算（プラン対象外でも母数に入る）', () {
      final tasks = [
        task(1, anchor: '2026-06-01', interval: 30), // due 7/1 超過→プラン対象外
        task(2, anchor: '2026-06-20', interval: 30), // due 7/20
      ];
      final p = buildChorePlans(tasks, [], today);
      expect(p.single.taskId, 2);
      expect(p.single.badge, 2); // 7/20時点: 超過中のtask1＋自分
    });
    test('limit切りとアーカイブ除外', () {
      final tasks = [
        for (var i = 1; i <= 5; i++) task(i, anchor: '2026-07-0$i', interval: 30),
        task(99, anchor: '2026-07-01', archived: true),
      ];
      expect(buildChorePlans(tasks, [], today, limit: 3).length, 3);
      expect(buildChorePlans(tasks, [], today).any((e) => e.taskId == 99), isFalse);
    });
  });

  group('choreOverdueCount', () {
    test('0件と複数件', () {
      expect(choreOverdueCount([task(1, anchor: '2026-07-01')], [], today), 0);
      expect(
          choreOverdueCount([
            task(1, anchor: '2026-06-01'), // due 7/1 超過
            task(2, anchor: '2026-06-10'), // due 7/10 超過
            task(3, anchor: '2026-06-15'), // due 7/15 当日=超過でない
          ], [], today),
          2);
    });
  });
}
