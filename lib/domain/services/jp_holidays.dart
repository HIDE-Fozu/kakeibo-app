/// 日本の国民の祝日。カードの引き落とし日を「土日祝なら翌営業日」に
/// ずらすために使う（銀行の休業日判定）。DBにも通信にも触れない純関数。
///
/// 対象は **2023年以降の現行法**（天皇誕生日=2/23・スポーツの日=10月第2月曜・
/// 山の日=8/11 が定着した形）。2020〜2022年の五輪特例（海の日・山の日・
/// スポーツの日の移動）と2018年以前の12/23天皇誕生日は**再現しない**。
/// 引き落とし日は基本的に「これから来る日」なので実害はないが、
/// 過去日を判定させないこと。
///
/// 春分・秋分は天文計算の近似式（1980〜2099年で実際の暦と一致する）。
library;

import '../money/civil_date.dart';

/// 月曜=1 ... 日曜=7（DateTime と同じ）。
int weekdayOf(CivilDate d) => DateTime.utc(d.year, d.month, d.day).weekday;

bool isWeekend(CivilDate d) {
  final w = weekdayOf(d);
  return w == DateTime.saturday || w == DateTime.sunday;
}

/// 春分の日（3月）。近似式は 1980〜2099 年で有効。
int vernalEquinoxDay(int year) =>
    (20.8431 + 0.242194 * (year - 1980) - (year - 1980) ~/ 4).floor();

/// 秋分の日（9月）。近似式は 1980〜2099 年で有効。
int autumnalEquinoxDay(int year) =>
    (23.2488 + 0.242194 * (year - 1980) - (year - 1980) ~/ 4).floor();

/// その月の第 n 月曜（ハッピーマンデー）。
int nthMondayDay(int year, int month, int n) {
  final firstWeekday = DateTime.utc(year, month, 1).weekday;
  // 1日が月曜なら1日が第1月曜。以降は (8 - 曜日) 日目が第1月曜。
  final firstMonday = firstWeekday == DateTime.monday
      ? 1
      : 1 + (DateTime.monday + 7 - firstWeekday) % 7;
  return firstMonday + (n - 1) * 7;
}

/// 法律で日付が決まっている祝日（振替休日・国民の休日を含まない素の祝日）。
bool _isStatutoryHoliday(CivilDate d) {
  switch (d.month) {
    case 1:
      return d.day == 1 || d.day == nthMondayDay(d.year, 1, 2); // 元日・成人の日
    case 2:
      return d.day == 11 || d.day == 23; // 建国記念の日・天皇誕生日
    case 3:
      return d.day == vernalEquinoxDay(d.year); // 春分の日
    case 4:
      return d.day == 29; // 昭和の日
    case 5:
      return d.day == 3 || d.day == 4 || d.day == 5; // 憲法記念日・みどり・こども
    case 7:
      return d.day == nthMondayDay(d.year, 7, 3); // 海の日
    case 8:
      return d.day == 11; // 山の日
    case 9:
      return d.day == nthMondayDay(d.year, 9, 3) || // 敬老の日
          d.day == autumnalEquinoxDay(d.year); // 秋分の日
    case 10:
      return d.day == nthMondayDay(d.year, 10, 2); // スポーツの日
    case 11:
      return d.day == 3 || d.day == 23; // 文化の日・勤労感謝の日
    default:
      return false;
  }
}

/// 国民の祝日（振替休日・国民の休日を含む）か。
bool isJapaneseHoliday(CivilDate d) {
  if (_isStatutoryHoliday(d)) return true;

  // 振替休日: 祝日が日曜のとき、その後の最も近い「祝日でない日」を休日にする。
  // 連休の途中も飛ばすので、遡って祝日が続く限り辿り、その先頭が日曜かで判定。
  var back = d.addDays(-1);
  while (_isStatutoryHoliday(back)) {
    if (weekdayOf(back) == DateTime.sunday) return true;
    back = back.addDays(-1);
  }

  // 国民の休日: 前日と翌日がともに祝日である平日（例: 敬老の日と秋分の日に挟まれた日）。
  return _isStatutoryHoliday(d.addDays(-1)) && _isStatutoryHoliday(d.addDays(1));
}

/// 銀行の休業日か（土日、または（判定するなら）日本の祝日）。
bool isBankHoliday(CivilDate d, {required bool japaneseHolidays}) =>
    isWeekend(d) || (japaneseHolidays && isJapaneseHoliday(d));
