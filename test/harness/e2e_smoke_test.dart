import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../../tool/receipt_eval/evaluate.dart';
import '../../tool/receipt_gen/generate.dart';
import '../support/receipt_fixtures.dart';

void main() {
  test('E2E: generate 20/level -> evaluate -> reports exist and parse (spec 9-6)', () async {
    final corpus = Directory.systemTemp.createTempSync('e2e_corpus');
    final out = Directory.systemTemp.createTempSync('e2e_out');
    try {
      await runGenerate(
          seed: 20260711,
          outDir: corpus.path,
          vocabPath: 'test/harness/fixtures/test_vocab.json',
          countPerLevel: 20);
      final code = await runEvaluate(corpusDir: corpus.path, outDir: out.path);
      expect(code, 0);
      final json = jsonDecode(File('${out.path}/report.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(json['corpusCount'], 60);
      for (final l in ['l0', 'l1', 'l2']) {
        expect(((json[l] as Map)['total'] as Map)['scored'], greaterThan(0));
      }
      expect(File('${out.path}/report.md').existsSync(), isTrue);
    } finally {
      corpus.deleteSync(recursive: true);
      out.deleteSync(recursive: true);
    }
  });

  test('sanity anchor: sample_supermarket.json still parses to 3850 / 2026-06-30 (spec 9-7)', () {
    final fx = loadFixture('test/fixtures/receipts/sample_supermarket.json');
    final parsed =
        ReceiptParser(today: () => const CivilDate(2026, 7, 11)).parse(fx.blocks);
    expect(parsed.total?.yen, 3850);
    expect(parsed.date.date, const CivilDate(2026, 6, 30));
  });

  test('missing golden dir does not crash', () async {
    final corpus = Directory.systemTemp.createTempSync('e2e_c2');
    final out = Directory.systemTemp.createTempSync('e2e_o2');
    try {
      await runGenerate(
          seed: 1,
          outDir: corpus.path,
          vocabPath: 'test/harness/fixtures/test_vocab.json',
          countPerLevel: 2);
      final code = await runEvaluate(
          corpusDir: corpus.path, outDir: out.path, goldenDir: '/no/such/dir');
      expect(code, 0);
    } finally {
      corpus.deleteSync(recursive: true);
      out.deleteSync(recursive: true);
    }
  });
}
