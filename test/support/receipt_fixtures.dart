import 'dart:convert';
import 'dart:io';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

/// Mac実機ブリッジ（後続Phase）が吐くのと同一のJSON形式のフィクスチャ。
class ReceiptFixture {
  final String name;
  final List<OcrBlock> blocks;
  final int? expectedTotalYen;
  final CivilDate? expectedDate;
  const ReceiptFixture({
    required this.name,
    required this.blocks,
    required this.expectedTotalYen,
    required this.expectedDate,
  });
}

ReceiptFixture loadFixture(String path) {
  final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final blocksRaw = root['blocks'] as List<dynamic>;
  final expected = root['expected'] as Map<String, dynamic>?;
  return ReceiptFixture(
    name: root['name'] as String,
    blocks: [
      for (final b in blocksRaw.cast<Map<String, dynamic>>())
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
    expectedTotalYen: expected?['totalYen'] as int?,
    expectedDate: expected?['date'] == null
        ? null
        : CivilDate.parse(expected!['date'] as String),
  );
}

// --- 決定的摂動（乱数なし） ---

List<OcrBlock> _mapText(List<OcrBlock> blocks, String Function(String) f) => [
      for (final b in blocks)
        OcrBlock(text: f(b.text), rect: b.rect, confidence: b.confidence),
    ];

/// ¥/￥ を全て落とす（OCRが通貨記号を拾えなかったケース）
List<OcrBlock> dropCurrencyMarks(List<OcrBlock> blocks) =>
    _mapText(blocks, (t) => t.replaceAll(RegExp('[¥￥]'), ''));

/// 「合計」キーワードを落とす（太字大フォントのOCR落ち）
List<OcrBlock> dropTotalKeyword(List<OcrBlock> blocks) =>
    _mapText(blocks, (t) => t.replaceAll('合計', ''));

/// 金額中の 0 を O に誤読させる
List<OcrBlock> confuseZeros(List<OcrBlock> blocks) =>
    _mapText(blocks,
        (t) => t.replaceAllMapped(RegExp(r'(?<=\d)0|0(?=\d)'), (m) => 'O'));

/// 各物理行の複数ブロックを1ブロックに結合（結合レイアウト）
List<OcrBlock> mergeRowBlocks(List<OcrBlock> blocks) {
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
        confidence:
            row.blocks.map((b) => b.confidence).reduce((a, c) => a + c) /
                row.blocks.length,
      ),
  ];
}
