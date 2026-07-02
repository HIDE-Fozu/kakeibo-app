import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

void main() {
  test('toIso zero-pads month and day', () {
    expect(const CivilDate(2026, 7, 3).toIso(), '2026-07-03');
    expect(const CivilDate(2026, 12, 31).toIso(), '2026-12-31');
  });

  test('parse round-trips a valid ISO date', () {
    final d = CivilDate.parse('2026-07-03');
    expect(d, const CivilDate(2026, 7, 3));
    expect(d.toIso(), '2026-07-03');
  });

  test('parse rejects malformed or impossible dates', () {
    expect(() => CivilDate.parse('2026-7-3'), throwsFormatException);
    expect(() => CivilDate.parse('2026-02-30'), throwsFormatException);
    expect(() => CivilDate.parse('not-a-date'), throwsFormatException);
  });

  test('fromDateTime takes the local calendar day only', () {
    final d = CivilDate.fromDateTime(DateTime(2026, 7, 3, 23, 59));
    expect(d, const CivilDate(2026, 7, 3));
  });

  test('equality and comparison', () {
    expect(const CivilDate(2026, 7, 3), const CivilDate(2026, 7, 3));
    expect(const CivilDate(2026, 7, 3).compareTo(const CivilDate(2026, 7, 4)), lessThan(0));
    expect(const CivilDate(2026, 8, 1).compareTo(const CivilDate(2026, 7, 31)), greaterThan(0));
  });

  test('lexicographic ISO order equals chronological order', () {
    final list = [
      CivilDate.parse('2026-12-31'),
      CivilDate.parse('2026-01-05'),
      CivilDate.parse('2026-07-03'),
    ]..sort();
    expect(list.map((d) => d.toIso()).toList(),
        ['2026-01-05', '2026-07-03', '2026-12-31']);
  });

  test('month range helpers (December wraps to next January)', () {
    expect(CivilDate.firstOfMonthIso(2026, 7), '2026-07-01');
    expect(CivilDate.firstOfNextMonthIso(2026, 7), '2026-08-01');
    expect(CivilDate.firstOfNextMonthIso(2026, 12), '2027-01-01');
  });
}
