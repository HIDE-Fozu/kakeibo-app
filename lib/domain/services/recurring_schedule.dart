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
