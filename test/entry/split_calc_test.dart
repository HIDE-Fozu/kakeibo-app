import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/features/entry/application/split_calc.dart';

void main() {
  group('evalCalcExpr', () {
    test('ユーザー指定の両形式: +100+100 も 100+100 も 200', () {
      expect(evalCalcExpr('+100+100'), 200);
      expect(evalCalcExpr('100+100'), 200);
    });

    test('左から順に計算（×÷の優先なし・電卓式）', () {
      expect(evalCalcExpr('100+100×2'), 400); // (100+100)×2
      expect(evalCalcExpr('1000-100÷3'), 300); // (900)÷3
    });

    test('四則演算と切り捨て', () {
      expect(evalCalcExpr('398×2'), 796);
      expect(evalCalcExpr('1000÷3'), 333); // 切り捨て
      expect(evalCalcExpr('500-100'), 400);
    });

    test('末尾演算子は入力途中として無視', () {
      expect(evalCalcExpr('100+'), 100);
      expect(evalCalcExpr('100×'), 100);
    });

    test('無効: 空・0除算・0以下・不正文字・先頭×÷', () {
      expect(evalCalcExpr(''), isNull);
      expect(evalCalcExpr('100÷0'), isNull);
      expect(evalCalcExpr('100-100'), isNull); // 0円は無効
      expect(evalCalcExpr('100-200'), isNull); // 負は無効
      expect(evalCalcExpr('abc'), isNull);
      expect(evalCalcExpr('×100'), isNull);
      expect(evalCalcExpr('÷100'), isNull);
    });

    test('先頭の−は 0−n（結果が正になる式は無いので実質無効）', () {
      expect(evalCalcExpr('-100'), isNull);
    });
  });

  group('applyTax（外税・切り捨て）', () {
    test('確定仕様の例: 398円×8% → 429円（429.84の切り捨て）', () {
      expect(applyTax(398, 8), 429);
    });
    test('10%と内税(0)', () {
      expect(applyTax(398, 10), 437); // 437.8 → 437
      expect(applyTax(1000, 10), 1100);
      expect(applyTax(398, 0), 398);
    });
    test('整数演算で丸め誤差なし（大きめの額）', () {
      expect(applyTax(999999, 10), 1099998); // 1099998.9 → 切り捨て
    });
  });

  group('小数対応（decimals: minor unit 換算）', () {
    test('decimals=2: "12.50"→1250 cent', () {
      expect(evalCalcExpr('12.50', decimals: 2), 1250);
    });
    test('decimals=2: 二進誤差を吸収（0.29→29 / 0.07→7）', () {
      expect(evalCalcExpr('0.29', decimals: 2), 29);
      expect(evalCalcExpr('0.07', decimals: 2), 7);
    });
    test('decimals=2: 式も評価 "12.50+5"→1750', () {
      expect(evalCalcExpr('12.50+5', decimals: 2), 1750);
    });
    test('decimals=2: 最小単位未満は切り捨て "12.999"→1299', () {
      expect(evalCalcExpr('12.999', decimals: 2), 1299);
    });
    test('decimals=2: 0.005→null（1cent未満）', () {
      expect(evalCalcExpr('0.005', decimals: 2), isNull);
    });
    test('decimals=0(JPY): 従来通り整数・小数点は×1切り捨て', () {
      expect(evalCalcExpr('1250'), 1250);
      expect(evalCalcExpr('1250', decimals: 0), 1250);
      expect(evalCalcExpr('12.5', decimals: 0), 12);
    });
  });
}
