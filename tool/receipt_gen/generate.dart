import 'dart:io';
import 'dart:math';

import 'src/noise.dart';
import 'src/renderer.dart';
import 'src/sampler.dart';
import 'src/truth.dart';
import 'src/validate.dart';
import 'src/vocab.dart';

Future<void> runGenerate({
  required int seed,
  required String outDir,
  required String vocabPath,
  int countPerLevel = 400,
}) async {
  final vocab = loadVocab(vocabPath);
  final dir = Directory(outDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  final rng = Random(seed);
  for (var level = 0; level <= 2; level++) {
    for (var i = 1; i <= countPerLevel; i++) {
      final truth = sampleTruth(rng, vocab, level);
      final render = renderReceipt(truth, rng);
      final blocks = applyNoise(render.blocks, truth, rng);
      final name = 'syn-l$level-${i.toString().padLeft(4, '0')}';
      final errors = [
        ...validateTruth(truth),
        if (level == 0)
          ...validateContainment(
              render.blocks, render.renderedTotalAmount, render.renderedDateLine),
      ];
      if (errors.isNotEmpty) {
        throw StateError('$name failed validation: $errors');
      }
      final fixture = SynthFixture(name: name, blocks: blocks, truth: truth);
      File('${dir.path}/$name.json').writeAsStringSync(encodeFixture(fixture));
    }
  }
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final seed = int.tryParse(_arg(args, '--seed') ?? '');
  final out = _arg(args, '--out');
  if (seed == null || out == null) {
    stderr.writeln(
        'usage: dart run tool/receipt_gen/generate.dart --seed <int> --out <dir> [--vocab <path>] [--count-per-level <n>]');
    exit(2);
  }
  final vocabPath = _arg(args, '--vocab') ?? 'tool/receipt_gen/data/vocab.json';
  if (!File(vocabPath).existsSync()) {
    // spec §8: 自動でOllamaを叩かず、先に語彙生成を促して終了する
    stderr.writeln('vocab not found: $vocabPath — 先に dart run tool/receipt_vocab/generate_vocab.dart を実行してください');
    exit(1);
  }
  final count = int.tryParse(_arg(args, '--count-per-level') ?? '400') ?? 400;
  try {
    await runGenerate(
        seed: seed, outDir: out, vocabPath: vocabPath, countPerLevel: count);
    stdout.writeln('generated ${count * 3} fixtures in $out (seed=$seed)');
  } on Object catch (e) {
    stderr.writeln('generation failed: $e');
    exit(1);
  }
}
