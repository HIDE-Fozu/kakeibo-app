import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

void main() {
  test('OcrRect exposes derived edges in canonical space', () {
    const r = OcrRect(0.1, 0.2, 0.3, 0.05);
    expect(r.centerY, closeTo(0.225, 1e-9));
    expect(r.right, closeTo(0.4, 1e-9));
    expect(r.bottom, closeTo(0.25, 1e-9));
  });

  test('FakeOcrService returns the injected blocks for any path', () async {
    const blocks = [
      OcrBlock(text: '合計 ¥1,080', rect: OcrRect(0.1, 0.5, 0.8, 0.03), confidence: 0.99),
    ];
    final fake = FakeOcrService(blocks);
    expect(await fake.recognize('whatever.jpg'), blocks);
  });

  group('groupRows', () {
    OcrBlock b(String t, double x, double y, {double w = 0.3, double h = 0.03}) =>
        OcrBlock(text: t, rect: OcrRect(x, y, w, h), confidence: 0.9);

    test('label and amount as separate blocks on one physical row cluster together',
        () {
      final rows = groupRows([
        b('合計', 0.05, 0.600),
        b('¥3,850', 0.65, 0.602), // わずかにずれた同一行
        b('お預り', 0.05, 0.650),
        b('¥5,000', 0.65, 0.649),
      ]);
      expect(rows.length, 2);
      expect(rows[0].text, '合計 ¥3,850');
      expect(rows[0].rightmost.text, '¥3,850');
      expect(rows[1].text, 'お預り ¥5,000');
    });

    test('slight skew within 0.6*lineH tolerance stays one row', () {
      final rows = groupRows([
        b('ラベル', 0.05, 0.500, h: 0.030),
        b('999', 0.70, 0.514, h: 0.030), // centerY差 0.014 < 0.6*0.03
      ]);
      expect(rows.length, 1);
    });

    test('distinct lines split into separate rows', () {
      final rows = groupRows([
        b('1行目', 0.05, 0.10),
        b('2行目', 0.05, 0.15),
        b('3行目', 0.05, 0.20),
      ]);
      expect(rows.length, 3);
      expect(rows.map((r) => r.text).toList(), ['1行目', '2行目', '3行目']);
    });

    test('rows are ordered top-to-bottom, blocks left-to-right', () {
      final rows = groupRows([
        b('右', 0.60, 0.30),
        b('左', 0.05, 0.30),
        b('上', 0.05, 0.10),
      ]);
      expect(rows.first.text, '上');
      expect(rows.last.text, '左 右');
    });

    test('empty input -> empty rows', () {
      expect(groupRows(const []), isEmpty);
    });
  });
}
