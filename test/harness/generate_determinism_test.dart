import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/generate.dart';

void main() {
  const vocabPath = 'test/harness/fixtures/test_vocab.json';

  test('smoke: 5 per level -> 15 files with correct names; rerun wipes', () async {
    final dir = Directory.systemTemp.createTempSync('gen_smoke');
    try {
      await runGenerate(
          seed: 20260711, outDir: dir.path, vocabPath: vocabPath, countPerLevel: 5);
      final names = dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();
      expect(names.length, 15);
      expect(names.first, 'syn-l0-0001.json');
      expect(names.last, 'syn-l2-0005.json');

      // 異物を置いて再実行→消えている（全削除→再生成）
      File('${dir.path}/garbage.txt').writeAsStringSync('x');
      await runGenerate(
          seed: 20260711, outDir: dir.path, vocabPath: vocabPath, countPerLevel: 5);
      expect(File('${dir.path}/garbage.txt').existsSync(), isFalse);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('same seed -> byte-identical corpus (spec 9-3, 20 files)', () async {
    final d1 = Directory.systemTemp.createTempSync('gen_a');
    final d2 = Directory.systemTemp.createTempSync('gen_b');
    try {
      await runGenerate(seed: 1, outDir: d1.path, vocabPath: vocabPath, countPerLevel: 7);
      await runGenerate(seed: 1, outDir: d2.path, vocabPath: vocabPath, countPerLevel: 7);
      final files1 = d1.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f1 in files1) {
        final f2 = File('${d2.path}/${f1.uri.pathSegments.last}');
        expect(f2.readAsBytesSync(), f1.readAsBytesSync(),
            reason: f1.uri.pathSegments.last);
      }
    } finally {
      d1.deleteSync(recursive: true);
      d2.deleteSync(recursive: true);
    }
  });

  test('different seed -> different corpus', () async {
    final d1 = Directory.systemTemp.createTempSync('gen_c');
    final d2 = Directory.systemTemp.createTempSync('gen_d');
    try {
      await runGenerate(seed: 1, outDir: d1.path, vocabPath: vocabPath, countPerLevel: 3);
      await runGenerate(seed: 2, outDir: d2.path, vocabPath: vocabPath, countPerLevel: 3);
      final a = File('${d1.path}/syn-l0-0001.json').readAsStringSync();
      final b = File('${d2.path}/syn-l0-0001.json').readAsStringSync();
      expect(a == b, isFalse);
    } finally {
      d1.deleteSync(recursive: true);
      d2.deleteSync(recursive: true);
    }
  });
}
