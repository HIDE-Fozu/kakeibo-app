import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/src/renderer.dart';
import '../../tool/receipt_gen/src/sampler.dart';
import '../../tool/receipt_gen/src/validate.dart';
import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  final vocab = loadVocab('test/harness/fixtures/test_vocab.json');

  test('containment holds for 200 sampled truths (spec 9-2)', () {
    final rng = Random(20260711);
    for (var i = 0; i < 200; i++) {
      final t = sampleTruth(rng, vocab, 0);
      final r = renderReceipt(t, rng);
      final errors =
          validateContainment(r.blocks, r.renderedTotalAmount, r.renderedDateLine);
      expect(errors, isEmpty, reason: '#$i: $errors');
      expect(r.renderedDateLine == null, t.date == null);
    }
  });

  test('geometry: rects in 0..1, rows ordered, label left of amount', () {
    final rng = Random(7);
    for (var i = 0; i < 100; i++) {
      final t = sampleTruth(rng, vocab, 0);
      final r = renderReceipt(t, rng);
      double prevY = -1;
      for (final b in r.blocks) {
        expect(b.rect.x >= 0 && b.rect.right <= 1.0, isTrue, reason: b.text);
        expect(b.rect.y >= 0 && b.rect.bottom <= 1.0, isTrue, reason: b.text);
        expect(b.confidence, inInclusiveRange(0.90, 0.98));
        expect(b.rect.y >= prevY, isTrue, reason: 'y must be non-decreasing');
        prevY = b.rect.y;
      }
      // 合計行: キーワードブロックの右に金額ブロック
      final kwIdx = r.blocks.indexWhere((b) => b.text == t.style.totalKeyword);
      expect(kwIdx, greaterThanOrEqualTo(0));
      final amount = r.blocks[kwIdx + 1];
      expect(amount.text, r.renderedTotalAmount);
      expect(amount.rect.x > r.blocks[kwIdx].rect.right, isTrue);
    }
  });

  test('deterministic for same rng seed', () {
    final t = sampleTruth(Random(5), vocab, 0);
    final a = renderReceipt(t, Random(9));
    final b = renderReceipt(t, Random(9));
    expect(a.blocks.length, b.blocks.length);
    for (var i = 0; i < a.blocks.length; i++) {
      expect(a.blocks[i].text, b.blocks[i].text);
      expect(a.blocks[i].rect.y, b.blocks[i].rect.y);
      expect(a.blocks[i].confidence, b.blocks[i].confidence);
    }
  });
}
