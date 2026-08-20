import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/money.dart';
import 'package:kakeibo_app/data/db/enums.dart';

void main() {
  test('Currency: 小数桁と minorPerUnit', () {
    expect(currencyForCode('JPY').decimals, 0);
    expect(currencyForCode('JPY').minorPerUnit, 1);
    expect(currencyForCode('USD').decimals, 2);
    expect(currencyForCode('USD').minorPerUnit, 100);
    expect(currencyForCode('KRW').decimals, 0);
    expect(currencyForCode('XXX'), kDefaultCurrency); // 未知はJPY
  });

  group('MoneyFormatter', () {
    test('net: 正のみ＋・0は符号なし・負は−（「差し引き0なのに+」FB 2026-08-21）', () {
      final mf = MoneyFormatter(const Locale('ja'), currencyForCode('JPY'));
      expect(mf.net(1500), '+¥1,500');
      expect(mf.net(0), '¥0');
      expect(mf.net(-72500), '-¥72,500');
    });

    test('JPY は formatYen 相当（¥・小数なし・「万」）', () {
      final mf = MoneyFormatter(const Locale('ja'), currencyForCode('JPY'));
      expect(mf.format(1250), '¥1,250');
      expect(mf.signed(TxnType.expense, 1234), '-¥1,234');
      expect(mf.signed(TxnType.income, 1234), '+¥1,234');
      expect(mf.compact(12345), '1.2万');
      expect(mf.compact(0), '');
    });

    test('USD は小数2桁・\$記号', () {
      final mf = MoneyFormatter(const Locale('en'), currencyForCode('USD'));
      expect(mf.format(1250), '\$12.50');
      expect(mf.format(5), '\$0.05');
      expect(mf.signed(TxnType.income, 1250), '+\$12.50');
      expect(mf.signed(TxnType.expense, 1250), '-\$12.50');
    });

    test('KRW は小数0桁（区切りあり）', () {
      final mf = MoneyFormatter(const Locale('ko'), currencyForCode('KRW'));
      expect(mf.format(1235), contains('1,235'));
    });
  });
}
