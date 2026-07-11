import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../../tool/receipt_gen/src/truth.dart';
import '../../tool/receipt_gen/src/validate.dart';
import 'truth_codec_test.dart' show sampleTruthFixture;

TruthReceipt _mutate(TruthReceipt t, {int? totalYen, int? changeYen, List<TruthDiscount>? discounts, List<TruthItem>? items}) {
  return TruthReceipt(
    storeName: t.storeName,
    storeType: t.storeType,
    date: t.date,
    items: items ?? t.items,
    discounts: discounts ?? t.discounts,
    taxMode: t.taxMode,
    taxLines: t.taxLines,
    totalYen: totalYen ?? t.totalYen,
    tenderedYen: t.tenderedYen,
    changeYen: changeYen ?? t.changeYen,
    style: t.style,
    noiseLevel: t.noiseLevel,
  );
}

void main() {
  test('valid truth passes all rules', () {
    expect(validateTruth(sampleTruthFixture()), isEmpty);
  });

  test('rule 1: total mismatch detected', () {
    expect(validateTruth(_mutate(sampleTruthFixture(), totalYen: 9999)), isNotEmpty);
  });

  test('rule 2: item amount != unit*qty detected', () {
    final bad = _mutate(sampleTruthFixture(), totalYen: 3851, items: const [
      TruthItem(name: 'x', unitPriceYen: 1950, qty: 2, amountYen: 3901, taxRate: 8),
    ]);
    expect(validateTruth(bad), isNotEmpty);
  });

  test('rule 3: change identity violation detected', () {
    expect(validateTruth(_mutate(sampleTruthFixture(), changeYen: 1)), isNotEmpty);
  });

  test('rule 4: discounts >= items sum detected', () {
    final bad = _mutate(sampleTruthFixture(),
        totalYen: -100, discounts: const [TruthDiscount(label: 'x', amountYen: 4000)]);
    expect(validateTruth(bad), isNotEmpty);
  });

  test('rule 1 exclusive: total = items - discounts + tax', () {
    final t = sampleTruthFixture();
    final ex = TruthReceipt(
      storeName: t.storeName,
      storeType: t.storeType,
      date: t.date,
      items: t.items, // 3900
      discounts: t.discounts, // 50
      taxMode: 'exclusive',
      taxLines: const [TruthTaxLine(rate: 8, taxYen: 312)], // 3900*8~/100
      totalYen: 3900 - 50 + 312,
      tenderedYen: null,
      changeYen: null,
      style: t.style,
      noiseLevel: 0,
    );
    expect(validateTruth(ex), isEmpty);
  });

  test('rule 5: containment', () {
    const blocks = [
      OcrBlock(text: '合計', rect: OcrRect(0.05, 0.5, 0.1, 0.03), confidence: 0.95),
      OcrBlock(text: '¥3,850', rect: OcrRect(0.7, 0.5, 0.2, 0.03), confidence: 0.95),
      OcrBlock(text: '2026年6月30日(火) 18:45', rect: OcrRect(0.05, 0.1, 0.5, 0.03), confidence: 0.95),
    ];
    expect(validateContainment(blocks, '¥3,850', '2026年6月30日(火) 18:45'), isEmpty);
    expect(validateContainment(blocks, '¥9,999', null), isNotEmpty);
    expect(validateContainment(blocks, '¥3,850', '存在しない日付行'), isNotEmpty);
  });
}
