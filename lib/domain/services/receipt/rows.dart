import '../ocr/ocr_types.dart';

/// 物理行（ラベル左・金額右の2カラムを1行に束ねる）。blocksはx昇順。
class ReceiptRow {
  final List<OcrBlock> blocks;
  ReceiptRow(this.blocks);

  String get text => blocks.map((b) => b.text).join(' ');
  double get centerY =>
      blocks.map((b) => b.rect.centerY).reduce((a, c) => a + c) / blocks.length;
  double get top => blocks.map((b) => b.rect.y).reduce((a, c) => a < c ? a : c);
  double get bottom =>
      blocks.map((b) => b.rect.bottom).reduce((a, c) => a > c ? a : c);
  OcrBlock get rightmost =>
      blocks.reduce((a, c) => c.rect.right >= a.rect.right ? c : a);
}

/// bounding box から物理行を復元する。
/// 行高中央値 lineH、tolerance τ = 0.6 * lineH。
/// 同一行 = |centerY差| ≤ τ かつ 垂直重なり > 0。
List<ReceiptRow> groupRows(List<OcrBlock> blocks) {
  if (blocks.isEmpty) return const [];

  final hs = blocks.map((b) => b.rect.h).toList()..sort();
  final lineH = hs[hs.length ~/ 2];
  final tau = 0.6 * lineH;

  final sorted = [...blocks]..sort((a, b) => a.rect.centerY.compareTo(b.rect.centerY));
  final rows = <ReceiptRow>[];

  for (final block in sorted) {
    ReceiptRow? home;
    for (final row in rows) {
      final dy = (block.rect.centerY - row.centerY).abs();
      final overlap =
          _min(block.rect.bottom, row.bottom) - _max(block.rect.y, row.top);
      if (dy <= tau && overlap > 0) {
        home = row;
        break;
      }
    }
    if (home != null) {
      home.blocks.add(block);
    } else {
      rows.add(ReceiptRow([block]));
    }
  }

  for (final row in rows) {
    row.blocks.sort((a, b) => a.rect.x.compareTo(b.rect.x));
  }
  rows.sort((a, b) => a.centerY.compareTo(b.centerY));
  return rows;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;
