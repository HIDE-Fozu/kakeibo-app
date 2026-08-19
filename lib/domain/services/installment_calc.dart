import 'dart:math';

/// 分割払い（実質年率・元利均等）の支払い計画。
///
/// 方式（確定仕様・FB 2026-08-16「33,000円を分割10回払い、金利17%」）:
/// - 月利 r = 実質年率/12。毎月の支払額 = P・r / (1 − (1+r)^−n)（元利均等）。
///   カード各社の「100円あたりの分割払手数料」表とほぼ同じ水準になる
///   （例: 15%・10回 → 手数料7.0円/100円）。厳密な手数料額はカードごとに
///   異なるので、明細と合わせたい場合は率の方を調整してもらう。
/// - 総額 = 月額×回数を円に丸め、月々は均等割り・**端数は初回に上乗せ**
///   （2回目以降を揃えるカードの慣行に合わせた）。
/// - 率0%は総額=元金（手数料なし）。
class InstallmentPlan {
  final int principalMinor; // 購入金額（元金・minor unit）
  final int count; // 支払い回数（>=1）
  final double annualRatePercent; // 実質年率（%）
  final int totalMinor; // 支払い総額（元金＋手数料）
  final int feeMinor; // 手数料（利息）合計
  final List<int> payments; // 長さ count。[0]=初回（端数調整込み）

  const InstallmentPlan({
    required this.principalMinor,
    required this.count,
    required this.annualRatePercent,
    required this.totalMinor,
    required this.feeMinor,
    required this.payments,
  });

  /// 2回目以降の均等額（1回払いなら初回と同じ）。
  int get monthlyMinor => payments.length > 1 ? payments[1] : payments[0];
  int get firstMinor => payments[0];
}

/// 回数ドロップダウンの選択肢（FB 2026-08-18: 48回やそれ以上が欲しい。
/// 主体はショッピングクレジットとして期間を増やし、住宅ローン基準も含める）。
/// 全列挙はメニューが破綻するため密→疎の段階刻み:
/// 2..60回は1刻み → 66/72/84/96/108/120回（5〜10年） → 年単位 180..420回（35年）。
/// 計算（computeInstallment）は任意の回数で動くので刻みはUIだけの都合。
final kInstallmentCountChoices = List<int>.unmodifiable([
  for (var n = 2; n <= 60; n++) n,
  66, 72, 84, 96, 108, 120,
  180, 240, 300, 360, 420,
]);

InstallmentPlan computeInstallment({
  required int principalMinor,
  required int count,
  required double annualRatePercent,
}) {
  assert(principalMinor > 0);
  assert(count >= 1);
  final int total;
  if (annualRatePercent <= 0 || count == 1) {
    // 率0% または1回払いは手数料なし（1回払いは日本のカード慣行どおり無手数料）。
    total = principalMinor;
  } else {
    final r = annualRatePercent / 100 / 12;
    final payment = principalMinor * r / (1 - pow(1 + r, -count));
    total = (payment * count).round();
  }
  final base = total ~/ count;
  final first = total - base * (count - 1);
  return InstallmentPlan(
    principalMinor: principalMinor,
    count: count,
    annualRatePercent: annualRatePercent,
    totalMinor: total,
    feeMinor: total - principalMinor,
    payments: [first, for (var i = 1; i < count; i++) base],
  );
}
