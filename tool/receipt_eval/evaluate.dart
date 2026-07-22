import 'dart:convert';
import 'dart:io';

import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../receipt_gen/src/truth.dart';
import 'src/report.dart';
import 'src/scorer.dart';

const CivilDate evalToday = CivilDate(2026, 7, 11);

/// golden JSON（実機ブリッジ形式: blocks + expected）の読込。truthは持たない。
({List<OcrBlock> blocks, int? totalYen, CivilDate? date}) _loadGolden(String path) {
  final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final expected = root['expected'] as Map<String, dynamic>?;
  return (
    blocks: [
      for (final b in (root['blocks'] as List).cast<Map<String, dynamic>>())
        OcrBlock(
          text: b['text'] as String,
          rect: OcrRect(
            (b['x'] as num).toDouble(),
            (b['y'] as num).toDouble(),
            (b['w'] as num).toDouble(),
            (b['h'] as num).toDouble(),
          ),
          confidence: (b['confidence'] as num).toDouble(),
        ),
    ],
    totalYen: expected?['totalYen'] as int?,
    date: expected?['date'] == null ? null : CivilDate.parse(expected!['date'] as String),
  );
}

Future<int> runEvaluate({
  required String corpusDir,
  required String outDir,
  String goldenDir = 'test/fixtures/receipts/golden',
  double? minTotalAcc,
  double? minDateAcc,
  bool dumpFailures = false,
}) async {
  final parser = ReceiptParser(today: () => evalToday);
  final agg = EvalAggregate();

  final files = Directory(corpusDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('syn-'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final fx = loadSynthFixture(f.path);
    final parsed = parser.parse(fx.blocks);
    agg.add(fx.name, fx.truth.noiseLevel, fx.truth.storeType,
        scoreOne(fx.truth, parsed, evalToday));
  }

  Map<String, dynamic>? golden;
  final gDir = Directory(goldenDir);
  if (gDir.existsSync()) {
    var count = 0;
    var totalOk = 0;
    var dateOk = 0;
    for (final f in gDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final g = _loadGolden(f.path);
      final parsed = parser.parse(g.blocks);
      count++;
      if (g.totalYen != null && parsed.total?.yen == g.totalYen) totalOk++;
      if (g.date != null && parsed.date.date == g.date) dateOk++;
    }
    if (count > 0) golden = {'count': count, 'totalCorrect': totalOk, 'dateCorrect': dateOk};
  }

  final out = Directory(outDir)..createSync(recursive: true);
  File('${out.path}/report.json').writeAsStringSync(
      '${buildReportJson(agg, corpusCount: files.length, golden: golden)}\n');
  File('${out.path}/report.md').writeAsStringSync(buildReportMd(agg,
      corpusCount: files.length, golden: golden, dumpFailures: dumpFailures));

  var code = 0;
  if (minTotalAcc != null) {
    for (final l in [0, 1, 2]) {
      if (agg.totalByLevel[l]!.accuracy * 100 < minTotalAcc) code = 1;
    }
  }
  if (minDateAcc != null) {
    for (final l in [0, 1, 2]) {
      if (agg.dateByLevel[l]!.accuracy * 100 < minDateAcc) code = 1;
    }
  }
  return code;
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final corpus = _arg(args, '--corpus');
  final out = _arg(args, '--out');
  if (corpus == null || out == null) {
    stderr.writeln(
        'usage: dart run tool/receipt_eval/evaluate.dart --corpus <dir> --out <dir> [--min-total-acc N] [--min-date-acc N] [--dump-failures]');
    exit(2);
  }
  try {
    final code = await runEvaluate(
      corpusDir: corpus,
      outDir: out,
      minTotalAcc: double.tryParse(_arg(args, '--min-total-acc') ?? ''),
      minDateAcc: double.tryParse(_arg(args, '--min-date-acc') ?? ''),
      dumpFailures: args.contains('--dump-failures'),
    );
    stdout.writeln('report written to $out (exit=$code)');
    exit(code);
  } on Object catch (e) {
    stderr.writeln('evaluation failed: $e');
    exit(1);
  }
}
