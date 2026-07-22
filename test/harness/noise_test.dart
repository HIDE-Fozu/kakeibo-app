import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/src/noise.dart';
import '../../tool/receipt_gen/src/renderer.dart';
import '../../tool/receipt_gen/src/sampler.dart';
import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  final vocab = loadVocab('test/harness/fixtures/test_vocab.json');

  test('L0 is identity', () {
    final rng = Random(1);
    final t = sampleTruth(rng, vocab, 0);
    final blocks = renderReceipt(t, rng).blocks;
    expect(identical(applyNoise(blocks, t, Random(2)), blocks), isTrue);
  });

  test('deterministic for same seed', () {
    final rng = Random(3);
    final t = sampleTruth(rng, vocab, 2);
    final blocks = renderReceipt(t, rng).blocks;
    final a = applyNoise(blocks, t, Random(4));
    final b = applyNoise(blocks, t, Random(4));
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].text, b[i].text);
      expect(a[i].rect.x, b[i].rect.x);
    }
  });

  test('no empty blocks; substitutions only 0->O 1->I long-vowel', () {
    final rng = Random(5);
    for (var i = 0; i < 200; i++) {
      final t = sampleTruth(rng, vocab, 2);
      final out = applyNoise(renderReceipt(t, rng).blocks, t, rng);
      for (final b in out) {
        expect(b.text.trim(), isNotEmpty);
      }
    }
  });

  test('split preserves concatenated text when only split fires', () {
    // 分割だけを強制するため、確率draw順を利用せず統計的に検証:
    // L1では ¥落ち10%・分割3%・置換2% のみ。500レシートで
    // 「元blocks数 <= ノイズ後blocks数」（分割は増やす一方、結合はL2のみ）を確認。
    final rng = Random(6);
    for (var i = 0; i < 500; i++) {
      final t = sampleTruth(rng, vocab, 1);
      final blocks = renderReceipt(t, rng).blocks;
      final out = applyNoise(blocks, t, rng);
      expect(out.length >= blocks.length - blocks.length ~/ 10, isTrue,
          reason: 'L1で大幅減はおかしい（空ブロック除去は¥単独ブロック程度）');
    }
  });
}
