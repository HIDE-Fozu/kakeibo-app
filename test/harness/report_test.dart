import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_eval/src/report.dart';
import '../../tool/receipt_eval/src/scorer.dart';

EvalAggregate _agg() {
  final agg = EvalAggregate();
  for (var i = 0; i < 10; i++) {
    agg.add('syn-l0-${i.toString().padLeft(4, '0')}', 0, 'supermarket',
        ReceiptOutcome(totalCorrect: i < 9, dateCorrect: i < 8, candidateHit: true, dateAbsentHandled: null));
  }
  return agg;
}

void main() {
  test('json has 6 cells and corpusCount', () {
    final j = jsonDecode(buildReportJson(_agg(), corpusCount: 10)) as Map<String, dynamic>;
    for (final l in ['l0', 'l1', 'l2']) {
      expect((j[l] as Map).containsKey('total'), isTrue);
      expect((j[l] as Map).containsKey('date'), isTrue);
    }
    expect(((j['l0'] as Map)['total'] as Map)['accuracy'], 0.9);
    expect(j['corpusCount'], 10);
  });

  test('md contains accuracy table with 1-decimal percent', () {
    final md = buildReportMd(_agg(), corpusCount: 10);
    expect(md, contains('90.0%'));
    expect(md, contains('80.0%'));
    expect(md, contains('| L0 |'));
    expect(md, contains('syn-l0-0008')); // date外し → failures
  });

  test('failures truncated to 20 in md by default', () {
    final agg = EvalAggregate();
    for (var i = 0; i < 30; i++) {
      agg.add('f$i', 1, 'cafe',
          const ReceiptOutcome(totalCorrect: false, dateCorrect: false, candidateHit: false, dateAbsentHandled: null));
    }
    final md = buildReportMd(agg, corpusCount: 30);
    expect(md, contains('f19'));
    expect(md, isNot(contains('f20\n')));
    expect(md, contains('他10件'));
  });
}
