import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/amounts.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

ReceiptRow rowOf(String text, {double y = 0.5}) => groupRows([
      OcrBlock(text: text, rect: OcrRect(0.05, y, 0.9, 0.03), confidence: 0.9),
    ]).single;

List<int> yensOf(String text) =>
    extractAmounts(rowOf(text)).where((t) => !t.negative).map((t) => t.yen).toList();

void main() {
  group('tiers', () {
    test('currency-anchored: ¥ prefix, 円 suffix, backslash misread, starred', () {
      expect(yensOf('¥3,850'), [3850]);
      expect(yensOf(r'\3,850'), [3850]); // ¥の\誤読
      expect(yensOf('3850円'), [3850]);
      expect(yensOf('*¥3,850*'), [3850]);
      final t = extractAmounts(rowOf('¥3,850')).single;
      expect(t.tier, AmountTier.currency);
    });

    test('comma-grouped bare number is tier B', () {
      final t = extractAmounts(rowOf('3,850')).single;
      expect(t.yen, 3850);
      expect(t.tier, AmountTier.comma);
    });

    test('bare integer is tier C', () {
      final t = extractAmounts(rowOf('合計 3850')).single;
      expect(t.yen, 3850);
      expect(t.tier, AmountTier.bare);
    });

    test('negative markers produce negative tokens (discounts)', () {
      final t = extractAmounts(rowOf('値引 ▲100')).single;
      expect(t.yen, 100);
      expect(t.negative, isTrue);
      expect(yensOf('値引 -100'), isEmpty); // 非負のみ返すヘルパでは空
    });
  });

  group('guards: these must NOT be amounts', () {
    test('phone numbers', () {
      expect(yensOf('TEL 03-1234-5678'), isEmpty);
      expect(yensOf('電話 0312345678'), isEmpty);
    });

    test('postal codes', () {
      expect(yensOf('〒123-4567 東京都'), isEmpty);
    });

    test('invoice registration number T+13', () {
      expect(yensOf('登録番号 T1234567890123'), isEmpty);
    });

    test('dates and times', () {
      expect(yensOf('2024/01/15 14:30'), isEmpty);
      expect(yensOf('2024年1月15日'), isEmpty);
    });

    test('quantity and unit price markers', () {
      expect(yensOf('数量 3'), isEmpty);
      expect(yensOf('＠150 ×2'), isEmpty);
    });

    test('tax rate percent', () {
      expect(yensOf('10%'), isEmpty);
      expect(yensOf('消費税(10%)'), isEmpty); // %はマスク、税額は別行
    });

    test('register/transaction ids (long bare digit runs on id rows)', () {
      expect(yensOf('レジNo 123456'), isEmpty);
      expect(yensOf('取引 20240115001'), isEmpty);
    });

    test('implausible magnitude', () {
      expect(yensOf('99999999円'), isEmpty); // > 9,999,999
    });

    test('digit-confusion repair inside amounts', () {
      expect(yensOf('¥1,O80'), [1080]);
    });
  });

  test('multiple amounts in one block: all extracted, order preserved', () {
    expect(yensOf('小計 3,500 外税 350'), [3500, 350]);
  });
}
