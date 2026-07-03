import '../domain/money/civil_date.dart';

/// 時刻00:00のローカルDateTime（table_calendar連携用）。
DateTime dateTimeOfCivil(CivilDate d) => DateTime(d.year, d.month, d.day);

/// 時刻/タイムゾーンを捨てる正規化。family キーは必ずこれを通す。
CivilDate civilOfDateTime(DateTime dt) => CivilDate(dt.year, dt.month, dt.day);
