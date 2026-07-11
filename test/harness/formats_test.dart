import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../../tool/receipt_gen/src/formats.dart';

void main() {
  test('comma', () {
    expect(comma(8), '8');
    expect(comma(3850), '3,850');
    expect(comma(1234567), '1,234,567');
  });

  test('formatAmount 4 marks', () {
    expect(formatAmount(3850, 'yen'), '¥3,850');
    expect(formatAmount(3850, 'fullwidthYen'), '￥3,850');
    expect(formatAmount(3850, 'none'), '3,850');
    expect(formatAmount(3850, 'enSuffix'), '3,850円');
    expect(() => formatAmount(1, 'unknown'), throwsArgumentError);
  });

  test('formatDateLine 5 formats (2026-06-30 is Tuesday, R8)', () {
    const d = CivilDate(2026, 6, 30);
    expect(formatDateLine(d, 'kanji', '18:45'), '2026年6月30日(火) 18:45');
    expect(formatDateLine(d, 'slash', '18:45'), '2026/06/30 18:45');
    expect(formatDateLine(d, 'dotShort', '08:05'), '26.06.30 08:05');
    expect(formatDateLine(d, 'warekiShort', '18:45'), 'R8.06.30 18:45');
    expect(formatDateLine(d, 'warekiKanji', '18:45'), '令和8年6月30日 18:45');
  });
}
