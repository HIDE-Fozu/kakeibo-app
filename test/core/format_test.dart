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

  test('manYen: セル万表記（モック確定・四捨五入）', () {
    expect(manYen(0), '');
    expect(manYen(-100), '');
    expect(manYen(980), '980'); // <1000は生数字・¥なし
    expect(manYen(999), '999');
    expect(manYen(1000), '0.1万');
    expect(manYen(3449), '0.3万'); // 四捨五入（モックのMath.round準拠）
    expect(manYen(3500), '0.4万');
    expect(manYen(9999), '1万'); // 四捨五入で1.0万→.0トリム
    expect(manYen(10000), '1万');
    expect(manYen(12345), '1.2万');
    expect(manYen(285000), '28.5万');
    expect(manYen(999449), '99.9万');
    expect(manYen(999500), '100万'); // 繰り上がり境界（丸め単位=0.05万）
    expect(manYen(1000000), '100万'); // ≥100万は整数万
    expect(manYen(1235000), '124万'); // 整数万も四捨五入
    expect(manYen(9999999), '1000万'); // 入力上限相当
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
