import '../../data/db/enums.dart';
import '../entities.dart';
import '../money/civil_date.dart';

/// 定期起票（毎月の固定費・収入）の期日計算。DBに触れない純関数群。
///
/// 月は YYYY*100+MM の整数（例: 2026年8月=202608）で持ち、大小比較が
/// そのまま時系列比較になる。

/// CivilDate → YYYY*100+MM。
int ymOf(CivilDate d) => d.year * 100 + d.month;

/// 次の月（202612 → 202701）。
int nextYm(int ym) {
  final m = ym % 100;
  return m == 12 ? ym + 100 - 11 : ym + 1;
}

/// 前の月（202701 → 202612）。
int prevYm(int ym) {
  final m = ym % 100;
  return m == 1 ? ym - 100 + 11 : ym - 1;
}

/// 2つの YYYYMM の大きい方。
int maxYm(int a, int b) => a >= b ? a : b;

/// その月の日数。DateTime.utc の day=0 正規化（前月末日）を利用する。
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// ym 月の起票日。短い月は末日に丸める（31日指定→2月は28/29日）。
CivilDate dueDateIn(int ym, int dayOfMonth) {
  final y = ym ~/ 100, m = ym % 100;
  final last = daysInMonth(y, m);
  return CivilDate(y, m, dayOfMonth > last ? last : dayOfMonth);
}

/// today までに起票すべき期日一覧と、起票後の lastGeneratedYm を返す。
///
/// 走査は「lastGeneratedYm の次の月」（未起票なら startYm）から today の月まで。
/// 当月は期日が today 以前のときだけ含む（期日前に開くと何もしない）。
/// endYm（両端含む）を超える月は起票しない。
({List<CivilDate> due, int? newLastYm}) pendingOccurrences({
  required int startYm,
  required int? endYm,
  required int? lastGeneratedYm,
  required int dayOfMonth,
  required CivilDate today,
}) {
  final todayYm = ymOf(today);
  var ym = lastGeneratedYm == null ? startYm : nextYm(lastGeneratedYm);
  // 再開時の lastGeneratedYm 前進などで startYm より前に戻らないよう下駄を履かせる
  // （開始月が未来のルールは開始月まで起票しない）。
  if (ym < startYm) ym = startYm;
  final due = <CivilDate>[];
  var last = lastGeneratedYm;
  while (ym <= todayYm && (endYm == null || ym <= endYm)) {
    final d = dueDateIn(ym, dayOfMonth);
    if (d.compareTo(today) > 0) break; // 当月でまだ期日前
    due.add(d);
    last = ym;
    ym = nextYm(ym);
  }
  return (due: due, newLastYm: last);
}

/// ym 月内の「まだ起票されていない予定」（カレンダーのゴースト表示・見込み計算用）。
///
/// 重複排除は lastGeneratedYm（起票の watermark）だけで行い、実取引との
/// 突き合わせはしない（起票済み取引をユーザーが編集しても壊れない）。
/// 期日は `>= today` で含める: `>` にすると日付が変わった瞬間から次の
/// applyDue（起動/復帰）までの間、当日分が画面から消えてしまう。
/// applyDue が起票すると同一トランザクションで watermark が進み、ゴーストは消える。
List<({CivilDate date, RecurringRuleEntity rule})> upcomingOccurrencesInMonth({
  required List<RecurringRuleEntity> rules,
  required int ym,
  required CivilDate today,
}) {
  final out = <({CivilDate date, RecurringRuleEntity rule})>[];
  for (final r in rules) {
    if (!r.isActive) continue;
    if (ym < r.startYm) continue;
    if (r.endYm != null && ym > r.endYm!) continue;
    if (ym <= (r.lastGeneratedYm ?? 0)) continue; // 起票済みの月
    final d = dueDateIn(ym, r.dayOfMonth);
    if (d.compareTo(today) < 0) continue; // 過去分は applyDue の領分
    out.add((date: d, rule: r));
  }
  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : (a.rule.id ?? 0).compareTo(b.rule.id ?? 0);
  });
  return out;
}

/// 見込み収支: 表示中の月 (year, month) の実績差引 + 基準日までの固定費予定。
///
/// [anchorDay] は 0=月末、1..31=毎月N日（短い月は dueDateIn と同じ末日丸め）。
/// 過去月は null（予定が常に空で差引の重複表示になるだけのため非表示）。
/// 当月で基準日をすでに過ぎている場合は月末へフォールバックする
/// （「25日時点」の数字が25日以降も動き続けると誤解を招くため）。
/// [anchorIsMonthEnd] はラベル出し分け用（true=（月末）/ false=（M/D時点））。
({int forecast, CivilDate anchor, bool anchorIsMonthEnd})? monthForecast({
  required int year,
  required int month,
  required int actualNet,
  required List<RecurringRuleEntity> rules,
  required CivilDate today,
  required int anchorDay,
}) {
  final ym = year * 100 + month;
  final todayYm = ymOf(today);
  if (ym < todayYm) return null;

  var monthEnd = anchorDay == 0;
  var anchor = dueDateIn(ym, monthEnd ? 31 : anchorDay);
  if (ym == todayYm && anchor.compareTo(today) < 0) {
    anchor = dueDateIn(ym, 31);
    monthEnd = true;
  }

  var sum = 0;
  for (final o
      in upcomingOccurrencesInMonth(rules: rules, ym: ym, today: today)) {
    if (o.date.compareTo(anchor) > 0) continue;
    sum += o.rule.type == TxnType.income ? o.rule.amountMinor : -o.rule.amountMinor;
  }
  return (forecast: actualNet + sum, anchor: anchor, anchorIsMonthEnd: monthEnd);
}
