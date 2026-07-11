import 'dart:math';

import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'truth.dart';
import 'vocab.dart';

const List<String> dateFormats = ['kanji', 'slash', 'dotShort', 'warekiShort', 'warekiKanji'];
const List<String> totalKeywords = ['合計', 'お買上げ計', '合　計', '総合計', 'お会計'];
const List<String> currencyMarks = ['yen', 'fullwidthYen', 'none', 'enSuffix'];

/// 評価時の固定today（spec §7）。日付サンプル範囲の基準でもある。
const CivilDate baseDate = CivilDate(2026, 7, 11);

T _pick<T>(Random rng, List<T> list) => list[rng.nextInt(list.length)];

String _sampleTaxMode(Random rng, String storeType) {
  final p = rng.nextInt(10);
  return switch (storeType) {
    'supermarket' || 'convenience' || 'drugstore' => p < 8 ? 'inclusive' : 'exclusive',
    'restaurant' || 'cafe' => p < 7 ? 'inclusive' : 'exclusive',
    _ => p < 6 ? 'inclusive' : 'exclusive',
  };
}

TruthReceipt sampleTruth(Random rng, Vocab vocab, int noiseLevel) {
  final storeType = _pick(rng, storeTypes);
  final storeName = _pick(rng, vocab.storeNames[storeType]!);

  CivilDate? date;
  if (rng.nextInt(100) >= 5) {
    final dt = DateTime.utc(baseDate.year, baseDate.month, baseDate.day)
        .subtract(Duration(days: rng.nextInt(365)));
    date = CivilDate(dt.year, dt.month, dt.day);
  }

  final taxMode = _sampleTaxMode(rng, storeType);
  final mixed = taxMode == 'inclusive' &&
      (storeType == 'supermarket' || storeType == 'drugstore') &&
      rng.nextInt(2) == 0;

  final n = rng.nextInt(3) < 2 ? 1 + rng.nextInt(8) : 9 + rng.nextInt(17);
  final items = <TruthItem>[];
  for (var i = 0; i < n; i++) {
    final name = _pick(rng, vocab.items[storeType]!);
    final unit = 8 + rng.nextInt(9973); // 8..9980
    final qty =
        (storeType == 'supermarket' && rng.nextInt(10) == 0) ? 2 + rng.nextInt(2) : 1;
    final rate = mixed ? (rng.nextInt(10) < 6 ? 8 : 10) : 10;
    items.add(TruthItem(
        name: name, unitPriceYen: unit, qty: qty, amountYen: unit * qty, taxRate: rate));
  }
  final itemsSum = items.fold(0, (a, i) => a + i.amountYen);

  final discounts = <TruthDiscount>[];
  if (rng.nextInt(5) == 0) {
    final minD = itemsSum * 5 ~/ 100;
    final maxD = itemsSum * 30 ~/ 100;
    var d = maxD > minD ? minD + rng.nextInt(maxD - minD + 1) : minD;
    if (d >= itemsSum) d = itemsSum - 1;
    if (d > 0) discounts.add(TruthDiscount(label: '割引', amountYen: d));
  }
  final discountSum = discounts.fold(0, (a, d) => a + d.amountYen);

  final rates = items.map((i) => i.taxRate).toSet().toList()..sort();
  final taxLines = <TruthTaxLine>[];
  for (final r in rates) {
    final base =
        items.where((i) => i.taxRate == r).fold(0, (a, i) => a + i.amountYen);
    taxLines.add(TruthTaxLine(
        rate: r,
        taxYen: taxMode == 'inclusive' ? base * r ~/ (100 + r) : base * r ~/ 100));
  }
  final taxSum = taxLines.fold(0, (a, t) => a + t.taxYen);
  final total =
      taxMode == 'inclusive' ? itemsSum - discountSum : itemsSum - discountSum + taxSum;

  int? tendered;
  int? change;
  if (rng.nextInt(2) == 0) {
    tendered = (total + 999) ~/ 1000 * 1000;
    change = tendered - total;
  }

  return TruthReceipt(
    storeName: storeName,
    storeType: storeType,
    date: date,
    items: items,
    discounts: discounts,
    taxMode: taxMode,
    taxLines: taxLines,
    totalYen: total,
    tenderedYen: tendered,
    changeYen: change,
    style: ReceiptStyle(
      dateFormat: _pick(rng, dateFormats),
      totalKeyword: _pick(rng, totalKeywords),
      currencyMark: _pick(rng, currencyMarks),
    ),
    noiseLevel: noiseLevel,
  );
}
