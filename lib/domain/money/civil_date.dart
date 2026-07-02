/// タイムゾーン・時刻を持たない暦日（civil date）。
/// 取引日はこの型で表し、DateTime の時刻/タイムゾーンに起因する日ズレを構造的に排除する。
class CivilDate implements Comparable<CivilDate> {
  final int year;
  final int month;
  final int day;

  const CivilDate(this.year, this.month, this.day);

  factory CivilDate.parse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) {
      throw FormatException('Not a YYYY-MM-DD date: $iso');
    }
    final d = CivilDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (!d.isValid) {
      throw FormatException('Not a valid calendar date: $iso');
    }
    return d;
  }

  factory CivilDate.fromDateTime(DateTime dt) =>
      CivilDate(dt.year, dt.month, dt.day);

  /// カレンダー上妥当か（例: 2026-02-30 は false）。
  bool get isValid {
    if (month < 1 || month > 12 || day < 1) return false;
    // DateTime.utc で正規化し、往復して一致するかで妥当性を判定。
    final normalized = DateTime.utc(year, month, day);
    return normalized.year == year &&
        normalized.month == month &&
        normalized.day == day;
  }

  String toIso() {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  static String firstOfMonthIso(int year, int month) =>
      CivilDate(year, month, 1).toIso();

  static String firstOfNextMonthIso(int year, int month) => month == 12
      ? CivilDate(year + 1, 1, 1).toIso()
      : CivilDate(year, month + 1, 1).toIso();

  @override
  int compareTo(CivilDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'CivilDate(${toIso()})';
}
