import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/converters.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

void main() {
  const conv = CivilDateConverter();

  test('toSql serializes to YYYY-MM-DD', () {
    expect(conv.toSql(const CivilDate(2026, 7, 3)), '2026-07-03');
  });

  test('fromSql parses YYYY-MM-DD back to CivilDate', () {
    expect(conv.fromSql('2026-12-31'), const CivilDate(2026, 12, 31));
  });

  test('round-trip preserves the exact civil date (no tz drift)', () {
    for (final iso in ['2026-01-01', '2026-07-03', '2026-12-31']) {
      expect(conv.toSql(conv.fromSql(iso)), iso);
    }
  });
}
