import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/ocr/ocr_fixture_recorder.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../support/receipt_fixtures.dart';

void main() {
  test('保存したJSONは loadFixture でそのまま読める（往復）', () {
    final dir = Directory.systemTemp.createTempSync('ocr-fixtures');
    addTearDown(() => dir.deleteSync(recursive: true));
    final recorder =
        OcrFixtureRecorder(dir, now: () => DateTime.utc(2026, 7, 6, 12));

    const blocks = [
      OcrBlock(
          text: '合計 ¥1,080',
          rect: OcrRect(0.1, 0.5, 0.8, 0.03),
          confidence: 0.99),
      OcrBlock(
          text: 'スーパーA', rect: OcrRect(0.1, 0.05, 0.5, 0.03), confidence: 0.9),
    ];
    final path = recorder.record(blocks);

    final fixture = loadFixture(path);
    expect(fixture.name, startsWith('receipt-2026-07-06'));
    expect(fixture.blocks.length, 2);
    expect(fixture.blocks.first.text, '合計 ¥1,080');
    expect(fixture.blocks.first.rect.y, closeTo(0.5, 1e-9));
    expect(fixture.blocks.first.confidence, closeTo(0.99, 1e-9));
    expect(fixture.expectedTotalYen, isNull); // expected は収集後に手で書く
  });
}
