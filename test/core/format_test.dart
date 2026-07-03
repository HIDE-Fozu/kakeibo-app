import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/dates.dart';
import 'package:kakeibo_app/core/format.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

void main() {
  test('formatYen: 桁区切り', () {
    expect(formatYen(0), '¥0');
    expect(formatYen(999), '¥999');
    expect(formatYen(1000), '¥1,000');
    expect(formatYen(1234567), '¥1,234,567');
  });

  test('signedYen: typeで符号', () {
    expect(signedYen(TxnType.expense, 1234), '-¥1,234');
    expect(signedYen(TxnType.income, 1234), '+¥1,234');
  });

  test('compactYen: セル略記', () {
    expect(compactYen(0), '');
    expect(compactYen(980), '¥980');
    expect(compactYen(1000), '¥1k');
    expect(compactYen(9840), '¥9.8k');
    expect(compactYen(12345), '¥12k');
    expect(compactYen(999999), '¥999k');
    expect(compactYen(1200000), '¥1.2M');
  });

  test('backupAgeLabel', () {
    final now = DateTime.utc(2026, 7, 15, 3);
    expect(backupAgeLabel(null, now), 'バックアップ未作成');
    expect(backupAgeLabel(DateTime.utc(2026, 7, 15, 1), now), '前回バックアップ: 今日');
    expect(backupAgeLabel(DateTime.utc(2026, 7, 12, 1), now), '前回バックアップ: 3日前');
  });

  test('dates: CivilDate <-> DateTime 正規化', () {
    expect(dateTimeOfCivil(const CivilDate(2026, 7, 3)), DateTime(2026, 7, 3));
    expect(civilOfDateTime(DateTime(2026, 7, 3, 14, 5)), const CivilDate(2026, 7, 3));
  });

  test('categoryTypeOf', () {
    expect(categoryTypeOf(TxnType.expense), CategoryType.expense);
    expect(categoryTypeOf(TxnType.income), CategoryType.income);
  });
}
