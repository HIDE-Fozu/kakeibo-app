import 'dart:math';

import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import 'formats.dart';
import 'truth.dart';

class RenderResult {
  final List<OcrBlock> blocks;
  final String renderedTotalAmount;
  final String? renderedDateLine;
  const RenderResult({
    required this.blocks,
    required this.renderedTotalAmount,
    required this.renderedDateLine,
  });
}

class _Line {
  final String label;
  final String? amount;
  const _Line.single(this.label) : amount = null;
  const _Line.pair(this.label, String this.amount);
}

double _w(String s) => (0.02 * s.length).clamp(0.05, 0.55);

String _digits(Random rng, int n) =>
    List.generate(n, (_) => rng.nextInt(10).toString()).join();

RenderResult renderReceipt(TruthReceipt t, Random rng) {
  final mark = t.style.currencyMark;
  final lines = <_Line>[];

  lines.add(_Line.single(t.storeName));
  if (rng.nextInt(10) < 6) {
    lines.add(_Line.single('TEL 0${rng.nextInt(9) + 1}-${_digits(rng, 4)}-${_digits(rng, 4)}'));
  }

  String? dateLine;
  if (t.date != null) {
    final hh = 8 + rng.nextInt(15); // 8..22
    final mi = rng.nextInt(60);
    dateLine = formatDateLine(
        t.date!, t.style.dateFormat, '$hh:${mi.toString().padLeft(2, '0')}');
    lines.add(_Line.single(dateLine));
  }

  final mixedMark = t.taxLines.length > 1 &&
      (t.storeType == 'supermarket' || t.storeType == 'drugstore');
  for (final it in t.items) {
    final name = (mixedMark && it.taxRate == 8) ? '${it.name}※' : it.name;
    if (it.qty > 1) {
      lines.add(_Line.single(name));
      lines.add(_Line.pair('${it.qty}コX${it.unitPriceYen}', formatAmount(it.amountYen, mark)));
    } else {
      lines.add(_Line.pair(name, formatAmount(it.amountYen, mark)));
    }
  }

  final itemsSum = t.items.fold(0, (a, i) => a + i.amountYen);
  lines.add(_Line.pair('小計', formatAmount(itemsSum, mark)));
  for (final d in t.discounts) {
    lines.add(_Line.pair(d.label, '-${formatAmount(d.amountYen, mark)}'));
  }
  for (final tx in t.taxLines) {
    if (t.taxMode == 'inclusive') {
      lines.add(_Line.single('（内消費税等 ${tx.rate}% ${formatAmount(tx.taxYen, mark)}）'));
    } else {
      lines.add(_Line.pair('消費税(${tx.rate}%)', formatAmount(tx.taxYen, mark)));
    }
  }

  final totalText = formatAmount(t.totalYen, mark);
  lines.add(_Line.pair(t.style.totalKeyword, totalText));

  if (t.tenderedYen != null) {
    lines.add(_Line.pair('お預り', formatAmount(t.tenderedYen!, mark)));
    lines.add(_Line.pair('お釣り', formatAmount(t.changeYen!, mark)));
  }
  if (rng.nextInt(10) < 3) {
    lines.add(_Line.single('ポイント残高 ${comma(100 + rng.nextInt(99900))}P'));
  }
  if (rng.nextInt(10) < 4) {
    lines.add(_Line.single('登録番号 T${_digits(rng, 13)}'));
  }

  // レイアウト: y_i = 0.03 + i*step, step = 0.94/行数, h = 0.8*step（spec §5）
  final step = 0.94 / lines.length;
  final h = step * 0.8;
  final blocks = <OcrBlock>[];
  for (var i = 0; i < lines.length; i++) {
    final y = 0.03 + i * step;
    final l = lines[i];
    blocks.add(OcrBlock(
      text: l.label,
      rect: OcrRect(0.05, y, _w(l.label), h),
      confidence: 0.90 + rng.nextDouble() * 0.08,
    ));
    if (l.amount != null) {
      final aw = _w(l.amount!);
      blocks.add(OcrBlock(
        text: l.amount!,
        rect: OcrRect(0.95 - aw, y, aw, h),
        confidence: 0.90 + rng.nextDouble() * 0.08,
      ));
    }
  }
  return RenderResult(
      blocks: blocks, renderedTotalAmount: totalText, renderedDateLine: dateLine);
}
