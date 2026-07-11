import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../../tool/receipt_gen/src/truth.dart';

TruthReceipt sampleTruthFixture({CivilDate? date = const CivilDate(2026, 6, 30)}) {
  return TruthReceipt(
    storeName: 'フレッシュたなか青果',
    storeType: 'supermarket',
    date: date,
    items: const [
      TruthItem(name: '国産豚小間切れ', unitPriceYen: 1950, qty: 2, amountYen: 3900, taxRate: 8),
    ],
    discounts: const [TruthDiscount(label: '割引', amountYen: 50)],
    taxMode: 'inclusive',
    taxLines: const [TruthTaxLine(rate: 8, taxYen: 285)],
    totalYen: 3850,
    tenderedYen: 5000,
    changeYen: 1150,
    style: const ReceiptStyle(dateFormat: 'kanji', totalKeyword: '合計', currencyMark: 'yen'),
    noiseLevel: 1,
  );
}

void main() {
  test('TruthReceipt round-trips through JSON', () {
    final t = sampleTruthFixture();
    final back = TruthReceipt.fromJson(t.toJson());
    expect(back.toJson(), t.toJson());
    expect(back.date, const CivilDate(2026, 6, 30));
    expect(back.items.single.amountYen, 3900);
  });

  test('date=null round-trips', () {
    final t = sampleTruthFixture(date: null);
    expect(TruthReceipt.fromJson(t.toJson()).date, isNull);
  });

  test('SynthFixture derives expected from truth', () {
    final f = SynthFixture(
      name: 'syn-l1-0001',
      blocks: const [
        OcrBlock(text: '合計', rect: OcrRect(0.05, 0.5, 0.1, 0.03), confidence: 0.95),
      ],
      truth: sampleTruthFixture(),
    );
    final json = f.toJson();
    expect((json['expected'] as Map)['totalYen'], 3850);
    expect((json['expected'] as Map)['date'], '2026-06-30');
    final noDate = SynthFixture(name: 'x', blocks: const [], truth: sampleTruthFixture(date: null));
    expect((noDate.toJson()['expected'] as Map)['date'], isNull);
  });

  test('encodeFixture ends with LF and is stable', () {
    final f = SynthFixture(name: 'x', blocks: const [], truth: sampleTruthFixture());
    final s = encodeFixture(f);
    expect(s.endsWith('\n'), isTrue);
    expect(encodeFixture(f), s);
  });
}
