import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../../tool/receipt_gen/src/sampler.dart';
import '../../tool/receipt_gen/src/validate.dart';
import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  final vocab = loadVocab('test/harness/fixtures/test_vocab.json');

  test('1,000 samples all pass validateTruth (spec 9-1)', () {
    final rng = Random(20260711);
    for (var i = 0; i < 1000; i++) {
      final t = sampleTruth(rng, vocab, i % 3);
      final errors = validateTruth(t);
      expect(errors, isEmpty, reason: 'sample #$i: $errors\n${t.toJson()}');
    }
  });

  test('distribution constraints hold over 1,000 samples', () {
    final rng = Random(1);
    var dateAbsent = 0;
    for (var i = 0; i < 1000; i++) {
      final t = sampleTruth(rng, vocab, 0);
      expect(t.items.length, inInclusiveRange(1, 25));
      for (final it in t.items) {
        expect(it.unitPriceYen, inInclusiveRange(8, 9980));
        if (it.qty > 1) expect(t.storeType, 'supermarket', reason: 'qty>1 is supermarket-only');
        expect(it.qty, inInclusiveRange(1, 3));
      }
      if (t.date == null) {
        dateAbsent++;
      } else {
        expect(t.date!.compareTo(const CivilDate(2025, 7, 12)) >= 0, isTrue);
        expect(t.date!.compareTo(const CivilDate(2026, 7, 11)) <= 0, isTrue);
      }
      if (t.taxLines.length > 1) {
        expect(['supermarket', 'drugstore'].contains(t.storeType), isTrue,
            reason: '混在税率はスーパー/ドラッグのみ');
      }
      if (t.tenderedYen != null) {
        expect(t.tenderedYen! >= t.totalYen, isTrue);
        expect(t.tenderedYen! % 1000, 0);
      }
      expect(t.totalYen > 0, isTrue);
    }
    expect(dateAbsent, inInclusiveRange(20, 90), reason: '日付なし≈5%');
  });

  test('same seed same sequence', () {
    final a = sampleTruth(Random(42), vocab, 1);
    final b = sampleTruth(Random(42), vocab, 1);
    expect(a.toJson(), b.toJson());
  });
}
