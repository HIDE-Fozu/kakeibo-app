/// 支払い区分（カード払い）の日付計算。DBに触れない純関数群。
///
/// 用語:
/// - **未払金**: 買った時点では現金が動かない負債。カードの支払日にまとめて
///   引き落とされる（会計でいう未払金）。
/// - **支払い月**: その未払金がどの月の引き落としに乗るか（YYYYMM）。
///   既定は「月末締め・翌月払い」＝購入月の翌月。カード会社や加盟店で
///   締めが違う（例: 楽天市場は27日締め）ため、**未払金ごとに変更できる**
///   前提の設計にしてある（この関数は既定値を出すだけ）。
library;

import '../money/civil_date.dart';
import 'jp_holidays.dart';
import 'recurring_schedule.dart' show daysInMonth, nextYm, ymOf;

/// 支払日が休業日に当たったときの寄せ方。日本のカードは「翌営業日」が主流。
enum BusinessDayRule {
  /// 休業日でもその日のまま（自動振替でない支払い等）。
  none,

  /// 翌営業日へ送る（楽天カードなど大半のカード）。
  next,

  /// 前営業日へ戻す（一部のカード・口座振替）。
  previous,
}

/// ym 月の payDay を暦日にする。短い月は末日に丸める（31日指定→2月は28/29日）。
/// 営業日調整は行わない素の期日。
CivilDate nominalPaymentDate(int ym, int payDay) {
  final y = ym ~/ 100, m = ym % 100;
  final last = daysInMonth(y, m);
  return CivilDate(y, m, payDay > last ? last : payDay);
}

/// 実際に引き落とされる日。nominalPaymentDate を営業日調整したもの。
///
/// [japaneseHolidays] が false なら土日だけを休業日とみなす（日本以外で
/// 使うとき、日本の祝日で日付がずれるのを防ぐ）。
CivilDate paymentDateIn({
  required int ym,
  required int payDay,
  BusinessDayRule rule = BusinessDayRule.next,
  bool japaneseHolidays = true,
}) =>
    adjustToBusinessDay(
      nominalPaymentDate(ym, payDay),
      rule: rule,
      japaneseHolidays: japaneseHolidays,
    );

/// 休業日なら rule の向きへ営業日まで送る（既に営業日ならそのまま）。
CivilDate adjustToBusinessDay(
  CivilDate date, {
  BusinessDayRule rule = BusinessDayRule.next,
  bool japaneseHolidays = true,
}) {
  if (rule == BusinessDayRule.none) return date;
  final step = rule == BusinessDayRule.next ? 1 : -1;
  var d = date;
  // 年末年始でも高々10日程度。無限ループ防止に上限を置く。
  for (var i = 0; i < 30; i++) {
    if (!isBankHoliday(d, japaneseHolidays: japaneseHolidays)) return d;
    d = d.addDays(step);
  }
  return d;
}

/// 購入日から決まる既定の支払い月（月末締め・翌月払い）。
/// 締めが月末でないカード/加盟店は、未払金ごとにこの値を上書きして使う。
int defaultPaymentYm(CivilDate purchaseDate) => nextYm(ymOf(purchaseDate));

/// 分割の支払い月の並び。startYm から count ヶ月ぶん連続。
List<int> paymentYmsFrom(int startYm, int count) {
  assert(count >= 1);
  final out = <int>[startYm];
  for (var i = 1; i < count; i++) {
    out.add(nextYm(out.last));
  }
  return out;
}

/// 未払金の支払い予定1回分（何月にいくら払うか）。
class PayableInstallment {
  final int ym; // 支払い月（YYYYMM）
  final int amountMinor; // その月の支払額（minor unit・非負）
  const PayableInstallment({required this.ym, required this.amountMinor});

  @override
  bool operator ==(Object other) =>
      other is PayableInstallment &&
      other.ym == ym &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(ym, amountMinor);

  @override
  String toString() => 'PayableInstallment($ym, $amountMinor)';
}

/// スケジュールの整合性。**合計が総額と一致するか**を常に機械判定するための門番
/// （「この月は1万円・この月は2万円」と個別に触れるようにしたときの安全網）。
/// null = 妥当。非nullは人間向けの理由。
String? validateSchedule(
  List<PayableInstallment> schedule, {
  required int expectedTotalMinor,
}) {
  if (schedule.isEmpty) return 'スケジュールが空です';
  var sum = 0;
  final seen = <int>{};
  for (final s in schedule) {
    if (s.amountMinor < 0) return '支払額が負です: ${s.ym} / ${s.amountMinor}';
    if (!seen.add(s.ym)) return '支払い月が重複しています: ${s.ym}';
    sum += s.amountMinor;
  }
  if (sum != expectedTotalMinor) {
    return '支払いの合計 $sum が総額 $expectedTotalMinor と一致しません';
  }
  return null;
}

/// スケジュールの合計。
int scheduleTotalMinor(List<PayableInstallment> schedule) =>
    schedule.fold(0, (a, s) => a + s.amountMinor);
