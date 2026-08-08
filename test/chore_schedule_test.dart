import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/chore_schedule.dart';

/// routine-reminder の due_logic_test.dart を移植（DateOnly→CivilDate・
/// Task→ChoreTask・buildPlans は文言レスの PlannedChore に変更）。
/// v2.2.0で「毎月N日」方式に変更: 次回期日 = 記録が無ければ anchor 以降で
/// 最初の毎月N日、あれば最後にやった月の翌月のN日（月末丸め）。
ChoreTask task(int id,
        {int day = 1,
        String anchor = '2026-06-01',
        bool archived = false,
        String name = 'ハブラシ交換',
        String emoji = '🪥'}) =>
    ChoreTask(
        id: id,
        name: name,
        emoji: emoji,
        dayOfMonth: day,
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
  group('nextChoreDue（毎月N日・月末丸め）', () {
    test('記録なし・作成月に予定日が残っていればその日', () => expect(
        nextChoreDue(task(1, anchor: '2026-07-01', day: 31), []),
        CivilDate.parse('2026-07-31')));
    test('記録なし・作成日当日が予定日なら当日', () => expect(
        nextChoreDue(task(1, anchor: '2026-07-15', day: 15), []),
        CivilDate.parse('2026-07-15')));
    test('記録なし・作成月の予定日を過ぎていれば翌月', () => expect(
        nextChoreDue(task(1, anchor: '2026-07-10', day: 5), []),
        CivilDate.parse('2026-08-05')));
    test('記録1件→記録月の翌月N日', () => expect(
        nextChoreDue(task(1, day: 10), [rec(1, 1, '2026-07-10')]),
        CivilDate.parse('2026-08-10')));
    test('複数記録→最新基準（並び順に依存しない）', () => expect(
        nextChoreDue(task(1, day: 10),
            [rec(2, 1, '2026-07-10'), rec(1, 1, '2026-06-01')]),
        CivilDate.parse('2026-08-10')));
    test('月内に早めに実施してもその月は済み扱い（翌月N日）', () => expect(
        nextChoreDue(task(1, day: 25), [rec(1, 1, '2026-07-02')]),
        CivilDate.parse('2026-08-25')));
    test('短い月は月末に丸める（31日→2月28日）', () => expect(
        nextChoreDue(task(1, day: 31), [rec(1, 1, '2026-01-15')]),
        CivilDate.parse('2026-02-28')));
    test('12月の記録→翌年1月へ繰越', () => expect(
        nextChoreDue(task(1, day: 5), [rec(1, 1, '2026-12-20')]),
        CivilDate.parse('2027-01-05')));
    test('過去日付の記録追加で期日が過去になる', () => expect(
        nextChoreDue(task(1, day: 1), [rec(1, 1, '2026-05-01')])
            .isBefore(today),
        isTrue));
  });

  group('choreDueAfterDone（スナックバー近似表示）', () {
    test('記録月の翌月N日・月末丸め', () {
      expect(choreDueAfterDone(task(1, day: 10), CivilDate.parse('2026-07-08')),
          CivilDate.parse('2026-08-10'));
      expect(choreDueAfterDone(task(1, day: 31), CivilDate.parse('2026-01-20')),
          CivilDate.parse('2026-02-28'));
    });
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
        task(1, anchor: '2026-07-01', day: 31), // due 7/31
        task(2, anchor: '2026-06-20', day: 25), // due 6/25 超過
        task(3, anchor: '2026-07-01', day: 15), // due 7/15 今日
        task(4, anchor: '2026-06-01', day: 5, archived: true),
        task(5, anchor: '2026-07-10', day: 15), // due 7/15 今日(同日)
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
        task(1, anchor: '2026-06-01', day: 20), // 6/20実施→due 7/20 未来期日
        task(2, anchor: '2026-07-01', day: 1), // due 7/1 超過(今日7/15)
        task(3, anchor: '2026-07-02', day: 1), // due 8/1 当月外
      ];
      final recs = [rec(1, 1, '2026-06-20'), rec(2, 2, '2026-07-06')];
      final m1 =
          choreMonthMarks(2026, 7, tasks, [rec(1, 1, '2026-06-20')], today);
      expect(m1[CivilDate.parse('2026-07-20')]!.dueTaskIds, [1]);
      expect(m1[CivilDate.parse('2026-07-01')]!.hasOverdue, isTrue); // task2超過
      expect(m1.containsKey(CivilDate.parse('2026-08-01')), isFalse); // 当月外
      final m2 = choreMonthMarks(2026, 7, tasks, recs, today);
      expect(m2[CivilDate.parse('2026-07-06')]!.doneTaskIds, [2]); // やった
      expect(m2.containsKey(CivilDate.parse('2026-07-01')), isFalse); // 記録で超過解消
    });
    test('同日に記録と期日が重なる', () {
      final t = [task(1, anchor: '2026-07-01', day: 15)]; // due 7/15
      final r = [rec(1, 9, '2026-07-15')]; // 別項目(9)の記録
      final m = choreMonthMarks(
          2026, 7, [...t, task(9, anchor: '2026-07-10', day: 1)], r, today);
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
        task(1, anchor: '2026-07-01', day: 1), // due 7/1 過去→除外
        task(2, anchor: '2026-07-01', day: 15), // due 7/15 当日→含む
        task(3, anchor: '2026-07-01', day: 20,
            name: 'マットレス向き替え', emoji: '🛏️'), // due 7/20
      ];
      final p = buildChorePlans(tasks, [], today);
      expect(p.map((e) => e.taskId).toList(), [2, 3]);
      // 文言はChoreActionsがl10nで組み立てるため、素材だけを持つ
      expect(p[1].emoji, '🛏️');
      expect(p[1].name, 'マットレス向き替え');
      expect(p[1].dayOfMonth, 20);
    });
    test('badge=期日以前の件数（同日複数は同値で加算）', () {
      final tasks = [
        task(1, anchor: '2026-07-01', day: 16), // due 7/16
        task(2, anchor: '2026-07-01', day: 16), // due 7/16 同日
        task(3, anchor: '2026-07-01', day: 21), // due 7/21
      ];
      final p = buildChorePlans(tasks, [], today);
      expect(p[0].badge, 2); // 7/16時点: due<=7/16 が2件
      expect(p[1].badge, 2);
      expect(p[2].badge, 3); // 7/21時点: 3件全部
    });
    test('badge=超過中の項目も加算（プラン対象外でも母数に入る）', () {
      final tasks = [
        task(1, anchor: '2026-07-01', day: 1), // due 7/1 超過→プラン対象外
        task(2, anchor: '2026-07-01', day: 20), // due 7/20
      ];
      final p = buildChorePlans(tasks, [], today);
      expect(p.single.taskId, 2);
      expect(p.single.badge, 2); // 7/20時点: 超過中のtask1＋自分
    });
    test('limit切りとアーカイブ除外', () {
      final tasks = [
        for (var i = 1; i <= 5; i++)
          task(i, anchor: '2026-07-01', day: 15 + i), // due 7/16..7/20
        task(99, anchor: '2026-07-01', day: 16, archived: true),
      ];
      expect(buildChorePlans(tasks, [], today, limit: 3).length, 3);
      expect(
          buildChorePlans(tasks, [], today).any((e) => e.taskId == 99), isFalse);
    });
  });

  group('choreOverdueCount', () {
    test('0件と複数件', () {
      expect(
          choreOverdueCount(
              [task(1, anchor: '2026-07-01', day: 31)], [], today),
          0);
      expect(
          choreOverdueCount([
            task(1, anchor: '2026-07-01', day: 1), // due 7/1 超過
            task(2, anchor: '2026-07-01', day: 10), // due 7/10 超過
            task(3, anchor: '2026-07-01', day: 15), // due 7/15 当日=超過でない
          ], [], today),
          2);
    });
  });
}
