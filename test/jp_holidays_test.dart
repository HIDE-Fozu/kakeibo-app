import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/jp_holidays.dart';

/// 日本の祝日判定。期待値は実際の暦（内閣府「国民の祝日」）と突き合わせた実日付。
void main() {
  bool hol(int y, int m, int d) => isJapaneseHoliday(CivilDate(y, m, d));

  test('2026年の祝日を実際の暦どおりに判定する', () {
    // 内閣府の2026年カレンダー
    const expected = <(int, int)>[
      (1, 1), // 元日（木）
      (1, 12), // 成人の日（第2月曜）
      (2, 11), // 建国記念の日（水）
      (2, 23), // 天皇誕生日（月）
      (3, 20), // 春分の日（金）
      (4, 29), // 昭和の日（水）
      (5, 3), // 憲法記念日（日）
      (5, 4), // みどりの日（月）
      (5, 5), // こどもの日（火）
      (5, 6), // 振替休日（憲法記念日が日曜 → 連休明けの水）
      (7, 20), // 海の日（第3月曜）
      (8, 11), // 山の日（火）
      (9, 21), // 敬老の日（第3月曜）
      (9, 22), // 国民の休日（敬老の日と秋分の日に挟まれた火）
      (9, 23), // 秋分の日（水）
      (10, 12), // スポーツの日（第2月曜）
      (11, 3), // 文化の日（火）
      (11, 23), // 勤労感謝の日（月）
    ];
    for (final (m, d) in expected) {
      expect(hol(2026, m, d), isTrue, reason: '2026-$m-$d は祝日のはず');
    }

    // 年間の祝日はこの18日だけ（取りこぼしも過剰判定も出さない）
    final found = <String>[];
    for (var m = 1; m <= 12; m++) {
      for (var d = 1; d <= 31; d++) {
        final date = CivilDate(2026, m, d);
        if (date.isValid && isJapaneseHoliday(date)) found.add('$m/$d');
      }
    }
    expect(found, hasLength(expected.length));
  });

  test('春分・秋分は年によって日が動く', () {
    expect(vernalEquinoxDay(2026), 20);
    expect(autumnalEquinoxDay(2026), 23);
    expect(vernalEquinoxDay(2027), 21);
    expect(autumnalEquinoxDay(2027), 23);
    expect(vernalEquinoxDay(2024), 20);
    expect(autumnalEquinoxDay(2024), 22);
  });

  test('ハッピーマンデーは第N月曜', () {
    expect(nthMondayDay(2026, 1, 2), 12); // 成人の日
    expect(nthMondayDay(2026, 7, 3), 20); // 海の日
    expect(nthMondayDay(2026, 10, 2), 12); // スポーツの日
    // 1日が月曜の月（2026年6月）は1日が第1月曜
    expect(nthMondayDay(2026, 6, 1), 1);
    expect(nthMondayDay(2026, 6, 3), 15);
  });

  test('振替休日: 祝日が日曜なら次の平日へ送られる', () {
    // 2026-05-03（憲法記念日）が日曜 → 5/4・5/5 も祝日なので 5/6（水）が振替
    expect(hol(2026, 5, 3), isTrue);
    expect(hol(2026, 5, 6), isTrue);
    expect(hol(2026, 5, 7), isFalse);
    // 2027-01-01（金）は日曜でないので 1/2 は振替にならない
    expect(hol(2027, 1, 2), isFalse);
  });

  test('国民の休日: 前後を祝日に挟まれた平日', () {
    // 2026: 敬老の日 9/21（月）・秋分の日 9/23（水）→ 9/22（火）が休日
    expect(hol(2026, 9, 22), isTrue);
    // 2025 は敬老 9/15・秋分 9/23 で離れているため挟まれた日はない
    expect(hol(2025, 9, 16), isFalse);
  });

  test('平日は祝日ではない', () {
    expect(hol(2026, 8, 12), isFalse);
    expect(hol(2026, 9, 24), isFalse);
    expect(hol(2026, 12, 25), isFalse); // クリスマスは祝日ではない
  });

  test('isBankHoliday: 土日は常に休業、祝日は判定を切れる', () {
    final sat = CivilDate(2026, 8, 22);
    final sun = CivilDate(2026, 8, 23);
    final holiday = CivilDate(2026, 8, 11); // 山の日（火）
    expect(isBankHoliday(sat, japaneseHolidays: false), isTrue);
    expect(isBankHoliday(sun, japaneseHolidays: false), isTrue);
    expect(isBankHoliday(holiday, japaneseHolidays: true), isTrue);
    expect(isBankHoliday(holiday, japaneseHolidays: false), isFalse);
  });
}
