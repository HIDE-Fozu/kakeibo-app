import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/domain/services/receipt/total.dart'
    show ExtractionConfidence;
import 'package:kakeibo_app/domain/money/civil_date.dart';

const fixedToday = CivilDate(2026, 7, 3);

ReceiptParser parser() => ReceiptParser(today: () => fixedToday);

/// 1行=1ブロックの合成レシート（正規化はparserがやる＝生テキストで渡す）
List<OcrBlock> lines(List<String> texts) => [
      for (final (i, t) in texts.indexed)
        OcrBlock(
          text: t,
          rect: OcrRect(0.05, 0.05 + i * 0.045, 0.9, 0.03),
          confidence: 0.9,
        ),
    ];

void main() {
  test('supermarket receipt end-to-end (raw full-width input)', () {
    final r = parser().parse(lines([
      'スーパーマルエツ 渋谷店',
      '〒150-0002 東京都渋谷区',
      'TEL 03-1234-5678',
      '２０２６年６月３０日(火) １８：４５',
      'レジ001 No.0123 責任者012',
      'ネギ ＠98 ×2 196',
      '牛乳 258',
      '小計 ３，５００',
      '消費税(10%) ３５０',
      '合計 ￥３，８５０',
      'お預り ￥５，０００',
      'お釣り ￥１，１５０',
      'ポイント残高 12,340P',
      '登録番号 T1234567890123',
    ]));
    expect(r.total!.yen, 3850);
    expect(r.total!.confidence, ExtractionConfidence.high);
    expect(r.date.date, const CivilDate(2026, 6, 30));
    expect(r.date.confidence, ExtractionConfidence.high);
  });

  test('convenience store with wareki thermal date', () {
    final r = parser().parse(lines([
      'セブン-イレブン',
      'R8.6.30 09:12 レジ2',
      'おにぎり 150円',
      'お茶 130円',
      '合計 ¥280',
      '現金 ¥300',
      'おつり ¥20',
    ]));
    expect(r.total!.yen, 280);
    expect(r.date.date, const CivilDate(2026, 6, 30));
  });

  test('drugstore with points and campaign dates', () {
    final r = parser().parse(lines([
      'マツモトキヨシ',
      '2026/06/28 20:01',
      'シャンプー 880',
      '合計 ¥880',
      'ポイント有効期限 2027/03/31',
      'ポイント残高 5,000',
    ]));
    expect(r.total!.yen, 880);
    expect(r.date.date, const CivilDate(2026, 6, 28));
  });

  test('OCR dropped the 合計 keyword -> fallback still lands on the total', () {
    final r = parser().parse(lines([
      '2026/07/01 12:00',
      'コーヒー 480',
      'ケーキ 520',
      '1,100', // 合計ラベルがOCR落ち（税込1100）
      'お預り 2,000',
      'おつり 900',
    ]));
    expect(r.total!.yen, 1100);
    expect(r.total!.confidence, ExtractionConfidence.medium);
    expect(r.date.date, const CivilDate(2026, 7, 1));
  });

  test('label and amount as separate blocks on the same physical row', () {
    final blocks = [
      const OcrBlock(text: '合計', rect: OcrRect(0.05, 0.60, 0.2, 0.03), confidence: 0.95),
      const OcrBlock(text: '¥3,850', rect: OcrRect(0.65, 0.601, 0.3, 0.03), confidence: 0.95),
      const OcrBlock(text: '2026/07/01', rect: OcrRect(0.05, 0.10, 0.4, 0.03), confidence: 0.95),
    ];
    final r = parser().parse(blocks);
    expect(r.total!.yen, 3850);
  });

  test('empty input -> null total, today default date, empty candidates', () {
    final r = parser().parse(const []);
    expect(r.total, isNull);
    expect(r.totalCandidates, isEmpty);
    expect(r.date.date, fixedToday);
    expect(r.date.reason, 'default-today');
  });

  test('candidates are exposed for the confirm-screen switch UI', () {
    final r = parser().parse(lines(['小計 3,500', '合計 3,850']));
    expect(r.totalCandidates.first.yen, 3850);
    expect(r.totalCandidates.length, greaterThanOrEqualTo(1));
  });
}
