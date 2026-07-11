import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import 'truth.dart';

/// spec §4-2 規則1〜4。戻り値は違反の説明（空=合格）。
List<String> validateTruth(TruthReceipt t) {
  final errors = <String>[];
  final itemsSum = t.items.fold(0, (a, i) => a + i.amountYen);
  final discountSum = t.discounts.fold(0, (a, d) => a + d.amountYen);
  final taxSum = t.taxLines.fold(0, (a, x) => a + x.taxYen);

  final expectedTotal =
      t.taxMode == 'inclusive' ? itemsSum - discountSum : itemsSum - discountSum + taxSum;
  if (t.totalYen != expectedTotal) {
    errors.add('rule1: totalYen=${t.totalYen} expected=$expectedTotal (${t.taxMode})');
  }
  for (final i in t.items) {
    if (i.amountYen != i.unitPriceYen * i.qty) {
      errors.add('rule2: ${i.name} amount=${i.amountYen} != ${i.unitPriceYen}x${i.qty}');
    }
  }
  if (t.tenderedYen != null && t.changeYen != null) {
    if (t.changeYen != t.tenderedYen! - t.totalYen) {
      errors.add('rule3: change=${t.changeYen} != ${t.tenderedYen}-${t.totalYen}');
    }
  }
  if (t.discounts.isNotEmpty && discountSum >= itemsSum) {
    errors.add('rule4: discounts=$discountSum >= itemsSum=$itemsSum');
  }
  return errors;
}

/// spec §4-2 規則5（L0のみ呼ぶ）: 合計金額文字列と日付行が本文に出現すること。
List<String> validateContainment(
    List<OcrBlock> blocks, String renderedTotalAmount, String? renderedDateLine) {
  final errors = <String>[];
  final texts = blocks.map((b) => b.text).toList();
  if (!texts.any((s) => s.contains(renderedTotalAmount))) {
    errors.add('rule5: total text "$renderedTotalAmount" not found');
  }
  if (renderedDateLine != null && !texts.any((s) => s.contains(renderedDateLine))) {
    errors.add('rule5: date line "$renderedDateLine" not found');
  }
  return errors;
}
