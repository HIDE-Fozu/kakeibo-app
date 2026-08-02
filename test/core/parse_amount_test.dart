import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/money.dart';

void main() {
  final jpy = currencyForCode('JPY');
  final eur = currencyForCode('EUR');

  test('JPY: 整数のみ・小数は不正', () {
    expect(parseAmountMinor('1500', jpy), 1500);
    expect(parseAmountMinor(' 80000 ', jpy), 80000);
    expect(parseAmountMinor('12.5', jpy), isNull); // 0桁通貨に小数は不可
    expect(parseAmountMinor('', jpy), isNull);
    expect(parseAmountMinor('abc', jpy), isNull);
    expect(parseAmountMinor('-100', jpy), isNull);
  });

  test('EUR: 小数点は . と , の両方を受ける・2桁まで', () {
    expect(parseAmountMinor('12.50', eur), 1250);
    expect(parseAmountMinor('12,5', eur), 1250); // 欧州式カンマ・1桁は0埋め
    expect(parseAmountMinor('12', eur), 1200);
    expect(parseAmountMinor('12.', eur), 1200); // 小数点で終わってもOK
    expect(parseAmountMinor('12.345', eur), isNull); // 3桁は不正
    expect(parseAmountMinor('1.2.3', eur), isNull);
  });

  test('amountMinorToText: 編集初期値の往復', () {
    expect(amountMinorToText(80000, jpy), '80000');
    expect(amountMinorToText(1250, eur), '12.50');
    expect(parseAmountMinor(amountMinorToText(1250, eur), eur), 1250);
  });
}
