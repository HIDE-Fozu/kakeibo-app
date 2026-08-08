import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

/// routine-reminder の date_only_test.dart を CivilDate へ移植
/// （つきいち合体で追加した addDays / differenceInDays / isBefore / isAfter）。
void main() {
  test('addDays: 月またぎ・年またぎ・閏年', () {
    expect(const CivilDate(2026, 7, 31).addDays(1), const CivilDate(2026, 8, 1));
    expect(const CivilDate(2026, 12, 31).addDays(1), const CivilDate(2027, 1, 1));
    expect(const CivilDate(2028, 2, 28).addDays(1), const CivilDate(2028, 2, 29)); // 閏年
    expect(const CivilDate(2026, 2, 28).addDays(1), const CivilDate(2026, 3, 1));
    expect(const CivilDate(2026, 7, 15).addDays(30), const CivilDate(2026, 8, 14));
    expect(const CivilDate(2026, 7, 15).addDays(-15), const CivilDate(2026, 6, 30));
  });

  test('differenceInDays: this - other（未来が正）', () {
    const a = CivilDate(2026, 7, 15);
    expect(const CivilDate(2026, 7, 20).differenceInDays(a), 5);
    expect(const CivilDate(2026, 7, 12).differenceInDays(a), -3);
    expect(a.differenceInDays(a), 0);
    // 年またぎ
    expect(const CivilDate(2027, 1, 1).differenceInDays(const CivilDate(2026, 12, 31)), 1);
  });

  test('isBefore / isAfter は compareTo と整合', () {
    const a = CivilDate(2026, 7, 15);
    const b = CivilDate(2026, 7, 16);
    expect(a.isBefore(b), isTrue);
    expect(b.isAfter(a), isTrue);
    expect(a.isBefore(a), isFalse);
    expect(a.isAfter(a), isFalse);
  });

  test('toIso は年も4桁ゼロ埋め・parse と往復一致', () {
    expect(const CivilDate(800, 1, 5).toIso(), '0800-01-05');
    const d = CivilDate(2026, 8, 4);
    expect(CivilDate.parse(d.toIso()), d);
  });
}
