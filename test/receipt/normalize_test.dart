import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';

void main() {
  group('normalizeOcrText', () {
    test('full-width digits and letters to ASCII', () {
      expect(normalizeOcrText('１２３４５'), '12345');
      expect(normalizeOcrText('Ｒ６年'), 'R6年');
    });

    test('full-width punctuation to ASCII', () {
      expect(normalizeOcrText('￥３，８５０'), '¥3,850');
      expect(normalizeOcrText('１４：３０'), '14:30');
      expect(normalizeOcrText('２０２４／０１／１５'), '2024/01/15');
      expect(normalizeOcrText('１０％'), '10%');
    });

    test('all dash variants unify to hyphen', () {
      // FF0D, 2010, 2013, 2014, 30FC(長音), 2212(minus)
      expect(normalizeOcrText('０３－１２３４'), '03-1234');
      expect(normalizeOcrText('03‐1234'), '03-1234');
      expect(normalizeOcrText('03–1234'), '03-1234');
      expect(normalizeOcrText('03—1234'), '03-1234');
      expect(normalizeOcrText('03ー1234'), '03-1234');
      expect(normalizeOcrText('03−1234'), '03-1234');
    });

    test('keeps ▲ and △ (negative markers)', () {
      expect(normalizeOcrText('▲１００'), '▲100');
      expect(normalizeOcrText('△100'), '△100');
    });

    test('collapses spaces inside number tokens', () {
      expect(normalizeOcrText('¥ 1, 234'), '¥1,234');
      expect(normalizeOcrText('合計 ¥ 3,850'), '合計 ¥3,850'); // ラベル境界の空白は保持
    });

    test('does not glue date and time together', () {
      expect(normalizeOcrText('12/28 18:05'), '12/28 18:05');
    });

    test('full-width space becomes normal space', () {
      expect(normalizeOcrText('合計　３８５０'), '合計 3850');
    });
  });

  group('repairDigitConfusions', () {
    test('repairs O/l/I/B/S adjacent to digits', () {
      expect(repairDigitConfusions('¥1,O80'), '¥1,080');
      expect(repairDigitConfusions('l,200'), '1,200');
      expect(repairDigitConfusions('12B'), '128');
      expect(repairDigitConfusions('5S0'), '550');
    });

    test('does not touch letters outside numeric context', () {
      expect(repairDigitConfusions('BOOK Store'), 'BOOK Store');
      expect(repairDigitConfusions('POINT'), 'POINT');
    });
  });
}
