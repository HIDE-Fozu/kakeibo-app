import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/recurring_schedule.dart';

RecurringRuleEntity rule({
  int? id,
  TxnType type = TxnType.expense,
  int amount = 85000,
  int day = 27,
  bool active = true,
  int startYm = 202601,
  int? endYm,
  int? lastYm,
}) =>
    RecurringRuleEntity(
      id: id,
      type: type,
      amountMinor: amount,
      categoryId: 1,
      dayOfMonth: day,
      isActive: active,
      startYm: startYm,
      endYm: endYm,
      lastGeneratedYm: lastYm,
    );

void main() {
  test('ymOf / nextYm: 年またぎを正しく進める', () {
    expect(ymOf(const CivilDate(2026, 8, 3)), 202608);
    expect(nextYm(202608), 202609);
    expect(nextYm(202612), 202701);
  });

  test('dueDateIn: 短い月は末日に丸める', () {
    expect(dueDateIn(202608, 31), const CivilDate(2026, 8, 31));
    expect(dueDateIn(202602, 31), const CivilDate(2026, 2, 28));
    expect(dueDateIn(202802, 31), const CivilDate(2028, 2, 29)); // 閏年
    expect(dueDateIn(202609, 31), const CivilDate(2026, 9, 30));
    expect(dueDateIn(202609, 15), const CivilDate(2026, 9, 15));
  });

  test('未起票ルール: 開始月から今日まで（期日到来分のみ）', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, [const CivilDate(2026, 8, 1)]);
    expect(p.newLastYm, 202608);
  });

  test('当月の期日がまだ来ていなければ起票しない', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 25,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, isEmpty);
    expect(p.newLastYm, isNull);
  });

  test('数か月ぶりに開くと未起票分をさかのぼって起票（キャッチアップ）', () {
    final p = pendingOccurrences(
      startYm: 202605,
      endYm: null,
      lastGeneratedYm: 202605,
      dayOfMonth: 10,
      today: const CivilDate(2026, 8, 3), // 8/10はまだ
    );
    expect(p.due, [const CivilDate(2026, 6, 10), const CivilDate(2026, 7, 10)]);
    expect(p.newLastYm, 202607);
  });

  test('年またぎキャッチアップ＋2月の末日丸め', () {
    final p = pendingOccurrences(
      startYm: 202512,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 31,
      today: const CivilDate(2026, 3, 31),
    );
    expect(p.due, [
      const CivilDate(2025, 12, 31),
      const CivilDate(2026, 1, 31),
      const CivilDate(2026, 2, 28),
      const CivilDate(2026, 3, 31),
    ]);
    expect(p.newLastYm, 202603);
  });

  test('endYm（両端含む）以降は起票しない', () {
    final p = pendingOccurrences(
      startYm: 202605,
      endYm: 202606,
      lastGeneratedYm: null,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, [const CivilDate(2026, 5, 1), const CivilDate(2026, 6, 1)]);
    expect(p.newLastYm, 202606);
  });

  test('開始月が未来なら何もしない', () {
    final p = pendingOccurrences(
      startYm: 202609,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, isEmpty);
    expect(p.newLastYm, isNull);
  });

  test('lastGeneratedYm が startYm より前でも startYm より前は起票しない', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: 202601, // 再開時の前進などで過去を指すケース
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, [const CivilDate(2026, 8, 1)]);
    expect(p.newLastYm, 202608);
  });

  test('起票済みの月は二重起票しない（冪等）', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: 202608,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, isEmpty);
    expect(p.newLastYm, 202608);
  });

  test('prevYm / maxYm: 年またぎと大小', () {
    expect(prevYm(202701), 202612);
    expect(prevYm(202608), 202607);
    expect(maxYm(202607, 202608), 202608);
    expect(maxYm(202608, 202607), 202608);
  });

  group('upcomingOccurrencesInMonth（ゴースト表示）', () {
    const today = CivilDate(2026, 8, 4);

    test('当月: 期日が今日以降の未起票分だけ・日付昇順', () {
      final list = upcomingOccurrencesInMonth(
        rules: [
          rule(id: 1, day: 27),                 // 8/27 未来 → 出る
          rule(id: 2, day: 25, type: TxnType.income, amount: 280000), // 8/25 → 出る
          rule(id: 3, day: 1, lastYm: 202608),  // 8/1 起票済み → 出ない
          rule(id: 4, day: 2),                  // 8/2 過去・未起票 → applyDueの領分で出ない
          rule(id: 5, day: 10, active: false),  // 停止中 → 出ない
        ],
        ym: 202608,
        today: today,
      );
      expect(list.map((o) => o.rule.id).toList(), [2, 1]);
      expect(list.first.date, const CivilDate(2026, 8, 25));
    });

    test('期日が今日ちょうどでも出す（>= today。applyDue が起票すると watermark で消える）', () {
      final list = upcomingOccurrencesInMonth(
        rules: [rule(id: 1, day: 4)],
        ym: 202608,
        today: today,
      );
      expect(list.single.date, const CivilDate(2026, 8, 4));
    });

    test('startYm前・endYm後・月末丸め', () {
      expect(
        upcomingOccurrencesInMonth(
            rules: [rule(startYm: 202609)], ym: 202608, today: today),
        isEmpty,
      );
      expect(
        upcomingOccurrencesInMonth(
            rules: [rule(endYm: 202607)], ym: 202608, today: today),
        isEmpty,
      );
      final feb = upcomingOccurrencesInMonth(
          rules: [rule(day: 31)], ym: 202702, today: today);
      expect(feb.single.date, const CivilDate(2027, 2, 28));
    });
  });

  group('monthForecast（見込み収支）', () {
    const today = CivilDate(2026, 8, 4);
    // 家賃 -85,000（27日）・給料 +280,000（25日）・起票済みサブスク（1日）
    final rules = [
      rule(id: 1, day: 27),
      rule(id: 2, day: 25, type: TxnType.income, amount: 280000),
      rule(id: 3, day: 1, amount: 1480, lastYm: 202608),
    ];

    test('当月・月末基準: 実績 + 未起票予定の全部', () {
      final f = monthForecast(
        year: 2026, month: 8, actualNet: -11620,
        rules: rules, today: today, anchorDay: 0,
      )!;
      expect(f.forecast, -11620 + 280000 - 85000); // 183,380
      expect(f.anchor, const CivilDate(2026, 8, 31));
      expect(f.anchorIsMonthEnd, isTrue);
    });

    test('当月・毎月25日基準: 25日より後の予定（家賃27日）は入らない', () {
      final f = monthForecast(
        year: 2026, month: 8, actualNet: -11620,
        rules: rules, today: today, anchorDay: 25,
      )!;
      expect(f.forecast, -11620 + 280000); // 268,380
      expect(f.anchor, const CivilDate(2026, 8, 25));
      expect(f.anchorIsMonthEnd, isFalse);
    });

    test('当月・基準日を過ぎている場合は月末へフォールバック', () {
      final f = monthForecast(
        year: 2026, month: 8, actualNet: -11620,
        rules: rules, today: today, anchorDay: 2, // 8/2 は過ぎた
      )!;
      expect(f.anchor, const CivilDate(2026, 8, 31));
      expect(f.anchorIsMonthEnd, isTrue);
      expect(f.forecast, -11620 + 280000 - 85000);
    });

    test('過去月は非表示（null）・未来月はその月の予定で計算', () {
      expect(
        monthForecast(
            year: 2026, month: 7, actualNet: 0,
            rules: rules, today: today, anchorDay: 0),
        isNull,
      );
      final f = monthForecast(
        year: 2026, month: 9, actualNet: 0,
        rules: rules, today: today, anchorDay: 25,
      )!;
      // 9月はサブスク(1日・lastYm=202608なので9月分は未起票)も入る
      expect(f.forecast, -1480 + 280000);
      expect(f.anchor, const CivilDate(2026, 9, 25));
    });

    test('短い月の基準日はdueDateInと同じ末日丸め（ラベル用anchorも丸め後）', () {
      final f = monthForecast(
        year: 2027, month: 2, actualNet: 0,
        rules: [rule(id: 1, day: 31)], today: today, anchorDay: 30,
      )!;
      expect(f.anchor, const CivilDate(2027, 2, 28));
      expect(f.forecast, -85000); // 2/28期日 <= anchor 2/28
    });
  });
}
