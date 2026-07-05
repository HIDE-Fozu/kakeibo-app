import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/services/receipt/total.dart';

/// 1行1ブロックの合成レシート。yは行順で自動採番。
List<ReceiptRow> receipt(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (final (i, line) in lines.indexed) {
    blocks.add(OcrBlock(
      text: normalizeOcrText(line),
      rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
      confidence: 0.9,
    ));
  }
  return groupRows(blocks);
}

void main() {
  test('picks 合計 over 小計 (tax-inclusive over subtotal)', () {
    final r = extractTotal(receipt(['小計 3,500', '消費税(10%) 350', '合計 3,850']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.high);
  });

  test('tendered/change rows never win; cash identity boosts the total', () {
    final r = extractTotal(receipt(['合計 3,850', 'お預り 10,000', 'お釣り 6,150']));
    expect(r.best!.yen, 3850);
  });

  test('points balance trap: 残高 must not be chosen', () {
    final r = extractTotal(receipt(['ポイント 385', 'ポイント残高 12,340', '合計 3,850']));
    expect(r.best!.yen, 3850);
  });

  test('credit line does not shadow the total', () {
    final r = extractTotal(receipt(['合計 3,850', 'クレジット 3,850', 'カード ****1234']));
    expect(r.best!.yen, 3850);
  });

  test('picks 税込合計 over 税抜合計', () {
    final r = extractTotal(receipt(['税抜合計 3,500', '税込合計 3,850']));
    expect(r.best!.yen, 3850);
  });

  test('内税 note does not confuse: 合計 wins', () {
    final r = extractTotal(receipt(['合計 3,850', '(内消費税 350)']));
    expect(r.best!.yen, 3850);
  });

  test('fallback: no keyword -> max plausible excluding tendered/change', () {
    final r = extractTotal(receipt(['ネギ 128', '牛乳 258', '3,850', 'お預り 5,000']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('¥ misread as backslash still anchors', () {
    final r = extractTotal(receipt([r'合計 \3,850']));
    expect(r.best!.yen, 3850);
  });

  test('full-width text works end-to-end', () {
    final r = extractTotal(receipt(['合計　￥３，８５０']));
    expect(r.best!.yen, 3850);
  });

  test('discount rows are never the total', () {
    final r = extractTotal(receipt(['小計 3,950', '値引 ▲100', '合計 3,850']));
    expect(r.best!.yen, 3850);
  });

  test('starred grand total', () {
    final r = extractTotal(receipt(['お買上げ *¥3,850*']));
    expect(r.best!.yen, 3850);
  });

  test('reduced tax rate receipt: 8%/10% breakdown rows do not win', () {
    final r = extractTotal(receipt([
      '8%対象 1,080',
      '10%対象 2,770',
      '合計 3,850',
    ]));
    expect(r.best!.yen, 3850);
  });

  test('税抜合計+消費税 synthesis when no tax-inclusive total printed', () {
    final r = extractTotal(receipt(['税抜合計 3,500', '消費税 350']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('cash identity recovers total when 合計 row is unreadable', () {
    final r = extractTotal(receipt(['お預り 10,000', 'お釣り 6,150']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('candidates are exposed for UI switching, best first, deduped', () {
    final r = extractTotal(receipt(['小計 3,500', '合計 3,850']));
    expect(r.candidates.first.yen, 3850);
    expect(r.candidates.map((c) => c.yen).toSet().length, r.candidates.length);
  });

  test('no amounts at all -> best is null', () {
    final r = extractTotal(receipt(['ありがとうございました']));
    expect(r.best, isNull);
    expect(r.candidates, isEmpty);
  });

  // --- 合計ラベル欠落（サミット型: 小計→税→クレジット） ---

  test('サミット型: 小計+消費税=クレジットの相互検証 → high', () {
    final r = extractTotal(receipt(['小計 3,500', '消費税 350', 'クレジット ¥3,850']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.high);
    expect(r.best!.reason, 'derived=payment');
  });

  test('合計なし: 小計+外税の導出 → medium', () {
    final r = extractTotal(receipt(['小計 3,500', '消費税 350']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('合計なし・内税方式: 小計がそのまま税込合計', () {
    final r = extractTotal(receipt(['小計 3,850', '(内税 350)']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('合計なし・小計なし: クレジット行を合計とみなす → medium', () {
    final r = extractTotal(receipt(['牛乳 ¥258', 'クレジット ¥3,850']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
    expect(r.best!.reason, 'payment-line');
  });

  test('クレジット額は合計があっても候補チップに載る（額が違うケース）', () {
    final r = extractTotal(receipt(['合計 3,850', 'クレジット ¥3,700']));
    expect(r.best!.yen, 3850); // bestは合計のまま
    expect(r.candidates.map((c) => c.yen), contains(3700));
  });

  test('カード番号断片（裸数字）は支払額として拾わない', () {
    final r = extractTotal(receipt(['クレジットカード番号 ****1234']));
    expect(r.best, isNull);
  });
}
