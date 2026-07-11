import 'dart:math';

import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

import 'truth.dart';

List<OcrBlock> _mapText(List<OcrBlock> blocks, String Function(String) f) => [
      for (final b in blocks)
        OcrBlock(text: f(b.text), rect: b.rect, confidence: b.confidence),
    ];

/// 各物理行を1ブロックへ結合（test/support/receipt_fixtures.dart のmergeRowBlocksと同等。
/// toolはtest/に依存できないためlibのgroupRowsで再実装）。
List<OcrBlock> _mergeRows(List<OcrBlock> blocks) {
  final rows = groupRows(blocks);
  return [
    for (final row in rows)
      OcrBlock(
        text: row.blocks.map((b) => b.text).join(' '),
        rect: OcrRect(
          row.blocks.first.rect.x,
          row.top,
          row.blocks.last.rect.right - row.blocks.first.rect.x,
          row.bottom - row.top,
        ),
        confidence: row.blocks.map((b) => b.confidence).reduce((a, c) => a + c) /
            row.blocks.length,
      ),
  ];
}

const _subs = {'0': 'O', '1': 'I', 'ー': '一'};

List<OcrBlock> applyNoise(List<OcrBlock> blocks, TruthReceipt t, Random rng) {
  final level = t.noiseLevel;
  if (level == 0) return blocks;

  var out = blocks;

  // ① ¥落ち（レシート単位）
  if (rng.nextInt(100) < (level == 1 ? 10 : 25)) {
    out = _mapText(out, (s) => s.replaceAll(RegExp('[¥￥]'), ''));
  }
  // ② 合計キーワード落ち（L2のみ・レシート単位）
  if (level == 2 && rng.nextInt(100) < 10) {
    out = _mapText(out, (s) => s.replaceAll(t.style.totalKeyword, ''));
  }
  // ③ 行結合（L2のみ・レシート単位）
  if (level == 2 && rng.nextInt(100) < 30) {
    out = _mergeRows(out);
  }
  // ④ ブロック分割
  final pSplit = level == 1 ? 3 : 8;
  final split = <OcrBlock>[];
  for (final b in out) {
    if (b.text.length >= 2 && rng.nextInt(100) < pSplit) {
      final cut = 1 + rng.nextInt(b.text.length - 1);
      final r = b.rect;
      final w1 = r.w * cut / b.text.length;
      split.add(OcrBlock(
          text: b.text.substring(0, cut),
          rect: OcrRect(r.x, r.y, w1, r.h),
          confidence: b.confidence));
      split.add(OcrBlock(
          text: b.text.substring(cut),
          rect: OcrRect(r.x + w1, r.y, r.w - w1, r.h),
          confidence: b.confidence));
    } else {
      split.add(b);
    }
  }
  out = split;
  // ⑤ 文字置換
  final pSub = level == 1 ? 2 : 5;
  out = [
    for (final b in out)
      OcrBlock(
        text: b.text
            .split('')
            .map((c) =>
                _subs.containsKey(c) && rng.nextInt(100) < pSub ? _subs[c]! : c)
            .join(),
        rect: b.rect,
        confidence: b.confidence,
      ),
  ];
  // ⑥ 空ブロック除去
  return [
    for (final b in out)
      if (b.text.trim().isNotEmpty) b,
  ];
}
