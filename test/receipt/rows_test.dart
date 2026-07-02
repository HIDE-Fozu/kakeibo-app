import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

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
}
