import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/receipt_fixtures.dart';

const fixedToday = CivilDate(2026, 7, 3);
ReceiptParser parser() => ReceiptParser(today: () => fixedToday);

void main() {
  late ReceiptFixture fx;

  setUpAll(() {
    fx = loadFixture('test/fixtures/receipts/sample_supermarket.json');
  });

  test('pristine fixture parses to expected total and date', () {
    final r = parser().parse(fx.blocks);
    expect(r.total!.yen, fx.expectedTotalYen);
    expect(r.date.date, fx.expectedDate);
  });

  test('survives dropped currency marks (comma anchor takes over)', () {
    final r = parser().parse(dropCurrencyMarks(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
  });

  test('survives dropped 合計 keyword via fallback / cash identity', () {
    final r = parser().parse(dropTotalKeyword(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
  });

  test('survives 0->O digit confusion via repair', () {
    final r = parser().parse(confuseZeros(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
  });

  test('survives merged row blocks (label+amount in one block)', () {
    final r = parser().parse(mergeRowBlocks(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
    expect(r.date.date, fx.expectedDate);
  });
}
