import 'package:kakeibo_app/domain/money/civil_date.dart';

String comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String formatAmount(int yen, String currencyMark) => switch (currencyMark) {
      'yen' => '¥${comma(yen)}',
      'fullwidthYen' => '￥${comma(yen)}',
      'none' => comma(yen),
      'enSuffix' => '${comma(yen)}円',
      _ => throw ArgumentError('unknown currencyMark: $currencyMark'),
    };

const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

String formatDateLine(CivilDate d, String dateFormat, String timeHHmm) {
  final w = _weekdays[DateTime.utc(d.year, d.month, d.day).weekday - 1];
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final r = d.year - 2018; // 令和N年
  return switch (dateFormat) {
    'kanji' => '${d.year}年${d.month}月${d.day}日($w) $timeHHmm',
    'slash' => '${d.year}/$mm/$dd $timeHHmm',
    'dotShort' => '${d.year % 100}.$mm.$dd $timeHHmm',
    'warekiShort' => 'R$r.$mm.$dd $timeHHmm',
    'warekiKanji' => '令和$r年${d.month}月${d.day}日 $timeHHmm',
    _ => throw ArgumentError('unknown dateFormat: $dateFormat'),
  };
}
