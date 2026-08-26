import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payment_schedule.dart';

/// カード払いの支払日・支払い月の決定。
void main() {
  group('支払日（営業日調整）', () {
    test('平日の27日はそのまま', () {
      // 2026-08-27 は木曜
      expect(paymentDateIn(ym: 202608, payDay: 27),
          const CivilDate(2026, 8, 27));
    });

    test('日曜の27日は翌営業日（月曜）へ送られる', () {
      // 2026-09-27 は日曜 → 9/28（月・祝日でない）
      expect(paymentDateIn(ym: 202609, payDay: 27),
          const CivilDate(2026, 9, 28));
    });

    test('土曜の27日は月曜へ送られる', () {
      // 2026-06-27 は土曜 → 6/29（月）
      expect(paymentDateIn(ym: 202606, payDay: 27),
          const CivilDate(2026, 6, 29));
    });

    test('祝日（振替休日）も飛ばす', () {
      // 2026-05-06 は憲法記念日の振替休日（水）→ 5/7（木）
      expect(paymentDateIn(ym: 202605, payDay: 6), const CivilDate(2026, 5, 7));
      // 祝日を見ない設定（日本以外）なら 5/6 のまま
      expect(
        paymentDateIn(ym: 202605, payDay: 6, japaneseHolidays: false),
        const CivilDate(2026, 5, 6),
      );
    });

    test('連休をまたいで営業日まで送る', () {
      // 2026-05-03（日・憲法記念日）→ 5/4 5/5 5/6 も休み → 5/7（木）
      expect(paymentDateIn(ym: 202605, payDay: 3), const CivilDate(2026, 5, 7));
    });

    test('前営業日ルールは手前へ戻す', () {
      // 2026-09-27（日）→ 9/25（金）
      expect(
        paymentDateIn(
            ym: 202609, payDay: 27, rule: BusinessDayRule.previous),
        const CivilDate(2026, 9, 25),
      );
    });

    test('調整なしルールは休業日でもその日', () {
      expect(
        paymentDateIn(ym: 202609, payDay: 27, rule: BusinessDayRule.none),
        const CivilDate(2026, 9, 27),
      );
    });

    test('短い月は末日に丸めてから調整する', () {
      // 31日指定 → 2026年2月は28日（土）→ 3/2（月）
      expect(nominalPaymentDate(202602, 31), const CivilDate(2026, 2, 28));
      expect(paymentDateIn(ym: 202602, payDay: 31),
          const CivilDate(2026, 3, 2));
    });

    test('年末年始をまたいでも営業日に着地する', () {
      // 2027-01-01（金・元日）→ 1/2 1/3 は土日 → 1/4（月）
      expect(paymentDateIn(ym: 202701, payDay: 1), const CivilDate(2027, 1, 4));
    });
  });

  group('支払い月', () {
    test('既定は月末締め・翌月払い', () {
      expect(defaultPaymentYm(const CivilDate(2026, 8, 10)), 202609);
      expect(defaultPaymentYm(const CivilDate(2026, 8, 31)), 202609);
      expect(defaultPaymentYm(const CivilDate(2026, 9, 1)), 202610);
    });

    test('年をまたぐ', () {
      expect(defaultPaymentYm(const CivilDate(2026, 12, 5)), 202701);
    });

    test('締め日までは翌月払い・過ぎたら翌々月払い', () {
      // 27日締め（楽天市場）: 8/27までは9月払い、8/28以降は10月払い
      expect(defaultPaymentYm(const CivilDate(2026, 8, 27), closingDay: 27),
          202609);
      expect(defaultPaymentYm(const CivilDate(2026, 8, 28), closingDay: 27),
          202610);
      // 15日締め（セゾン等）
      expect(defaultPaymentYm(const CivilDate(2026, 8, 15), closingDay: 15),
          202609);
      expect(defaultPaymentYm(const CivilDate(2026, 8, 16), closingDay: 15),
          202610);
    });

    test('締め日が月末日より大きい月は末日に丸める', () {
      // 2月に30日締め → 実質28日締め。2/28は3月払い（翌々月にはならない）
      expect(defaultPaymentYm(const CivilDate(2026, 2, 28), closingDay: 30),
          202603);
    });

    test('締め日が年をまたぐ場合', () {
      // 12/28（27日締め）→ 12月の締めに乗らず2月払い
      expect(defaultPaymentYm(const CivilDate(2026, 12, 28), closingDay: 27),
          202702);
    });

    test('monthsBetweenYm は月数を返す', () {
      expect(monthsBetweenYm(202608, 202609), 1);
      expect(monthsBetweenYm(202608, 202610), 2);
      expect(monthsBetweenYm(202612, 202701), 1);
      expect(monthsBetweenYm(202609, 202608), -1);
    });

    test('分割の支払い月は開始月から連続する', () {
      expect(paymentYmsFrom(202611, 4), [202611, 202612, 202701, 202702]);
      expect(paymentYmsFrom(202609, 1), [202609]);
      expect(paymentYmsFrom(202609, 10).last, 202706);
    });
  });

  group('スケジュールの整合（合計＝総額の機械判定）', () {
    List<PayableInstallment> sched(int start, List<int> amounts) => [
          for (final (i, a) in amounts.indexed)
            PayableInstallment(ym: paymentYmsFrom(start, amounts.length)[i],
                amountMinor: a),
        ];

    test('合計が一致すれば妥当', () {
      expect(
        validateSchedule(sched(202609, [3334, 3333, 3333]),
            expectedTotalMinor: 10000),
        isNull,
      );
    });

    test('合計がずれたら理由を返す', () {
      final why = validateSchedule(sched(202609, [3334, 3333, 3000]),
          expectedTotalMinor: 10000);
      expect(why, isNotNull);
      expect(why, contains('一致しません'));
    });

    test('空・負の額・月の重複を弾く', () {
      expect(validateSchedule(const [], expectedTotalMinor: 0), isNotNull);
      expect(
        validateSchedule(
            [const PayableInstallment(ym: 202609, amountMinor: -1)],
            expectedTotalMinor: -1),
        isNotNull,
      );
      expect(
        validateSchedule(const [
          PayableInstallment(ym: 202609, amountMinor: 500),
          PayableInstallment(ym: 202609, amountMinor: 500),
        ], expectedTotalMinor: 1000),
        contains('重複'),
      );
    });

    test('scheduleTotalMinor は合計を返す', () {
      expect(scheduleTotalMinor(sched(202609, [100, 200, 300])), 600);
    });
  });
}
