import 'dart:convert';

import 'scorer.dart';

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

String buildReportJson(EvalAggregate agg,
    {required int corpusCount, Map<String, dynamic>? golden}) {
  return jsonEncode({
    ...agg.toJson(),
    'corpusCount': corpusCount,
    'golden': ?golden,
  });
}

String buildReportMd(EvalAggregate agg,
    {required int corpusCount, Map<String, dynamic>? golden, bool dumpFailures = false}) {
  final b = StringBuffer()
    ..writeln('# レシートパーサ評価レポート')
    ..writeln()
    ..writeln('対象: $corpusCount 件')
    ..writeln()
    ..writeln('| レベル | total精度 | date精度 | 候補内正解 |')
    ..writeln('|---|---|---|---|');
  for (final l in [0, 1, 2]) {
    b.writeln('| L$l | ${_pct(agg.totalByLevel[l]!.accuracy)} '
        '(${agg.totalByLevel[l]!.correct}/${agg.totalByLevel[l]!.scored}) '
        '| ${_pct(agg.dateByLevel[l]!.accuracy)} '
        '(${agg.dateByLevel[l]!.correct}/${agg.dateByLevel[l]!.scored}) '
        '| ${_pct(agg.candidateByLevel[l]!.accuracy)} |');
  }
  b
    ..writeln()
    ..writeln('日付なしレシート処理: '
        '${[for (final l in [0, 1, 2]) 'L$l ${agg.dateAbsentHandled[l]}/${agg.dateAbsentSeen[l]}'].join(' / ')}')
    ..writeln()
    ..writeln('## 様式別 total精度 ワースト5')
    ..writeln();
  final worst = agg.totalByStoreType.entries.toList()
    ..sort((a, b2) => a.value.accuracy.compareTo(b2.value.accuracy));
  for (final e in worst.take(5)) {
    b.writeln('- ${e.key}: ${_pct(e.value.accuracy)} (${e.value.correct}/${e.value.scored})');
  }
  b
    ..writeln()
    ..writeln('## 失敗レシート（total/dateいずれか不一致）')
    ..writeln();
  final shown = dumpFailures ? agg.failures : agg.failures.take(20).toList();
  for (final f in shown) {
    b.writeln('- $f');
  }
  if (!dumpFailures && agg.failures.length > 20) {
    b.writeln('- …他${agg.failures.length - 20}件（--dump-failures で全件）');
  }
  if (golden != null) {
    b
      ..writeln()
      ..writeln('## Golden set（実レシート）')
      ..writeln()
      ..writeln('件数: ${golden['count']} / total一致: ${golden['totalCorrect']} / date一致: ${golden['dateCorrect']}');
  }
  return b.toString();
}
