import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/installment_calc.dart';

void main() {
  test('33,000円・10回・17%: 総額35,625・手数料2,625・端数は初回', () {
    final p = computeInstallment(
        principalMinor: 33000, count: 10, annualRatePercent: 17.0);
    expect(p.totalMinor, 35625);
    expect(p.feeMinor, 2625);
    expect(p.payments, hasLength(10));
    expect(p.firstMinor, 3567);
    expect(p.monthlyMinor, 3562);
    expect(p.payments.skip(1).toSet(), {3562});
    expect(p.payments.fold(0, (a, v) => a + v), 35625);
  });

  test('カード表との整合: 15%・10回 → 手数料7.0円/100円', () {
    final p = computeInstallment(
        principalMinor: 10000, count: 10, annualRatePercent: 15.0);
    expect(p.feeMinor, 700);
  });

  test('率0%は手数料なし・均等割り', () {
    final p = computeInstallment(
        principalMinor: 30000, count: 10, annualRatePercent: 0);
    expect(p.totalMinor, 30000);
    expect(p.feeMinor, 0);
    expect(p.payments.toSet(), {3000});
  });

  test('割り切れない場合の端数は初回に乗る', () {
    final p = computeInstallment(
        principalMinor: 100000, count: 3, annualRatePercent: 12.0);
    expect(p.totalMinor, 102007);
    expect(p.firstMinor, 34003);
    expect(p.monthlyMinor, 34002);
  });

  test('1回払いは手数料なし', () {
    final p = computeInstallment(
        principalMinor: 5000, count: 1, annualRatePercent: 17.0);
    expect(p.totalMinor, 5000);
    expect(p.payments, [5000]);
  });

  test('回数の選択肢: 2..60は1刻み・以降は段階刻みで420回（35年）まで', () {
    expect(kInstallmentCountChoices.first, 2);
    expect(kInstallmentCountChoices.last, 420);
    // FB 2026-08-18: 48回やそれ以上（ショッピングクレジット〜住宅ローン基準）
    expect(kInstallmentCountChoices, containsAll([36, 48, 60, 66, 120, 180, 360, 420]));
    expect(kInstallmentCountChoices.contains(61), isFalse); // 60超は間引き
    // 昇順・重複なし（ドロップダウンの前提）
    final sorted = [...kInstallmentCountChoices]..sort();
    expect(kInstallmentCountChoices, sorted);
    expect(kInstallmentCountChoices.toSet().length, kInstallmentCountChoices.length);
  });
}
