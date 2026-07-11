import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../../tool/receipt_eval/src/scorer.dart';
import 'truth_codec_test.dart' show sampleTruthFixture;

const _today = CivilDate(2026, 7, 11);

ParsedReceipt _parse(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (var i = 0; i < lines.length; i++) {
    blocks.add(OcrBlock(
        text: lines[i],
        rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
        confidence: 0.95));
  }
  return ReceiptParser(today: () => _today).parse(blocks);
}

void main() {
  test('correct total and date', () {
    final parsed = _parse(['2026年6月30日(火) 18:45', '合計 ¥3,850']);
    final o = scoreOne(sampleTruthFixture(), parsed, _today);
    expect(o.totalCorrect, isTrue);
    expect(o.dateCorrect, isTrue);
    expect(o.candidateHit, isTrue);
    expect(o.dateAbsentHandled, isNull);
  });

  test('wrong total, right date', () {
    final parsed = _parse(['2026年6月30日(火) 18:45', '合計 ¥9,999']);
    final o = scoreOne(sampleTruthFixture(), parsed, _today);
    expect(o.totalCorrect, isFalse);
    expect(o.dateCorrect, isTrue);
  });

  test('date-absent receipt: excluded and fallback-today asserted', () {
    final parsed = _parse(['合計 ¥3,850']);
    final o = scoreOne(sampleTruthFixture(date: null), parsed, _today);
    expect(o.dateCorrect, isNull);
    expect(o.dateAbsentHandled, isTrue);
  });

  test('aggregate math and failures list', () {
    final agg = EvalAggregate();
    agg.add('a', 0, 'supermarket',
        const ReceiptOutcome(totalCorrect: true, dateCorrect: true, candidateHit: true, dateAbsentHandled: null));
    agg.add('b', 0, 'supermarket',
        const ReceiptOutcome(totalCorrect: false, dateCorrect: null, candidateHit: false, dateAbsentHandled: true));
    final j = agg.toJson();
    final l0 = j['l0'] as Map<String, dynamic>;
    expect((l0['total'] as Map)['scored'], 2);
    expect((l0['total'] as Map)['correct'], 1);
    expect((l0['total'] as Map)['accuracy'], 0.5);
    expect((l0['date'] as Map)['scored'], 1);
    expect((l0['date'] as Map)['accuracy'], 1.0);
    expect(agg.failures, ['b']);
    expect((j['dateAbsent'] as Map)['l0'], {'seen': 1, 'handled': 1});
  });
}
