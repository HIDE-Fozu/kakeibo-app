/// 未払金の組み立て。「カードで買った」→ 支払い予定を作る／作り直す。
/// DBに触れない純関数で、金額の計算は installment_calc.dart を再利用する。
library;

import '../entities.dart';
import '../money/civil_date.dart';
import 'installment_calc.dart';
import 'payment_schedule.dart';

/// 一括払いの未払金を作る。支払い月は既定（月末締め・翌月払い）だが、
/// [paymentYm] を渡せば「これは9月分じゃなく10月分」と上書きできる。
PayableEntity buildSinglePayable({
  int? id,
  required int transactionId,
  required int cardId,
  required int amountMinor,
  required CivilDate purchaseDate,
  int? paymentYm,
}) {
  final ym = paymentYm ?? defaultPaymentYm(purchaseDate);
  return PayableEntity(
    id: id,
    transactionId: transactionId,
    cardId: cardId,
    installmentCount: 1,
    annualRatePercent: 0, // 1回払いは日本のカード慣行どおり手数料なし
    totalMinor: amountMinor,
    schedule: [PayableInstallment(ym: ym, amountMinor: amountMinor)],
  );
}

/// 「あとから分割」。元本を count 回に割り、[startYm] からの各月に載せる。
/// 手数料込みの総額と月々の額は既存の分割払い計算（元利均等・端数は初回）と同じ。
///
/// 再分割（10回→3回）も同じ関数でよい。元本 [principalMinor] は購入額のままで、
/// 手数料だけが回数と率で変わる。
PayableEntity buildInstallmentPayable({
  int? id,
  required int transactionId,
  required int cardId,
  required int principalMinor,
  required int count,
  required double annualRatePercent,
  required int startYm,
}) {
  final plan = computeInstallment(
    principalMinor: principalMinor,
    count: count,
    annualRatePercent: annualRatePercent,
  );
  final yms = paymentYmsFrom(startYm, count);
  return PayableEntity(
    id: id,
    transactionId: transactionId,
    cardId: cardId,
    installmentCount: count,
    annualRatePercent: annualRatePercent,
    totalMinor: plan.totalMinor,
    schedule: [
      for (final (i, ym) in yms.indexed)
        PayableInstallment(ym: ym, amountMinor: plan.payments[i]),
    ],
  );
}

/// 支払い月をまるごとずらす（一括の「9月分→10月分」変更）。
/// 分割にも使える（開始月をずらすと以降が連動する）。
PayableEntity shiftPaymentYm(PayableEntity p, int newStartYm) {
  final yms = paymentYmsFrom(newStartYm, p.schedule.length);
  return PayableEntity(
    id: p.id,
    transactionId: p.transactionId,
    cardId: p.cardId,
    installmentCount: p.installmentCount,
    annualRatePercent: p.annualRatePercent,
    totalMinor: p.totalMinor,
    schedule: [
      for (final (i, s) in p.schedule.indexed)
        PayableInstallment(ym: yms[i], amountMinor: s.amountMinor),
    ],
  );
}

/// その月にこの未払金からいくら引き落とされるか（無ければ0）。
int amountDueIn(PayableEntity p, int ym) {
  for (final s in p.schedule) {
    if (s.ym == ym) return s.amountMinor;
  }
  return 0;
}

/// カードの ym 月の引き落とし合計。
int cardTotalDueIn(Iterable<PayableEntity> payables, int cardId, int ym) {
  var sum = 0;
  for (final p in payables) {
    if (p.cardId == cardId) sum += amountDueIn(p, ym);
  }
  return sum;
}
