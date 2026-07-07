import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/items.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

/// 1行1ブロックの合成レシート。yは行順で自動採番（total_testと同形）。
List<ReceiptRow> receipt(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (final (i, line) in lines.indexed) {
    blocks.add(OcrBlock(
      text: normalizeOcrText(line),
      rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
      confidence: 0.9,
    ));
  }
  return groupRows(blocks);
}

void main() {
  test('品目行だけを抽出（メタ行・合計ゾーンは除外）', () {
    final items = extractItemLines(receipt([
      'サミット みなみ台店',
      '2026/06/21 18:05',
      'ﾒｸﾞﾐﾙｸ ｷﾞｭｳﾆｭｳ ※198',
      'ｻｸｯﾄﾊﾟﾝ 6ﾏｲ ※298',
      'JOY ｼｮｸｾﾝ 398',
      '小計 894',
      '外税(10%) 39',
      '合計 933',
      'クレジット ¥933',
    ]));
    expect(items.map((i) => i.yen), [198, 298, 398]);
    expect(items[0].reducedTaxMark, isTrue); // ※=軽減税率
    expect(items[2].reducedTaxMark, isFalse);
  });

  test('数量×単価の行は最右の額（行合計）を採る', () {
    final items = extractItemLines(receipt([
      'ﾀﾏｺﾞ 10P ＠128 ×2 256',
      '小計 256',
    ]));
    expect(items.single.yen, 256);
  });

  test('値引き行（負トークンのみ）は品目にしない', () {
    final items = extractItemLines(receipt([
      'ﾊﾟﾝ 298',
      '値引 ▲50',
      '小計 248',
    ]));
    expect(items.map((i) => i.yen), [298]);
  });

  test('bboxは行のブロックを覆う', () {
    final rows = groupRows(const [
      OcrBlock(text: 'ﾊﾟﾝ', rect: OcrRect(0.05, 0.2, 0.3, 0.03), confidence: 0.9),
      OcrBlock(text: '¥298', rect: OcrRect(0.7, 0.2, 0.2, 0.03), confidence: 0.9),
      OcrBlock(text: '小計 ¥298', rect: OcrRect(0.05, 0.3, 0.5, 0.03), confidence: 0.9),
    ]);
    final item = extractItemLines(rows).single;
    expect(item.rect.x, closeTo(0.05, 1e-9));
    expect(item.rect.right, closeTo(0.9, 1e-9));
    expect(item.rect.y, closeTo(0.2, 1e-9));
  });

  test('品目ゼロ（手書きレシート等）は空リスト', () {
    expect(extractItemLines(receipt(['合計 3,850'])), isEmpty);
  });
}
