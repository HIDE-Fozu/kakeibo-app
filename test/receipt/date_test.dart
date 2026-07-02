import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/date.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/services/receipt/total.dart'
    show ExtractionConfidence;
import 'package:kakeibo_app/domain/money/civil_date.dart';

const today = CivilDate(2026, 7, 3);

DateExtraction run(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (final (i, line) in lines.indexed) {
    blocks.add(OcrBlock(
      text: normalizeOcrText(line),
      rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
      confidence: 0.9,
    ));
  }
  return extractDate(groupRows(blocks), today);
}

void main() {
  test('gregorian with 年月日 and time -> high confidence', () {
    final r = run(['2026年1月15日 14:30']);
    expect(r.best!.date, const CivilDate(2026, 1, 15));
    expect(r.best!.confidence, ExtractionConfidence.high);
  });

  test('gregorian slash/dash variants', () {
    expect(run(['2026/01/15']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['2026-1-5']).best!.date, const CivilDate(2026, 1, 5));
  });

  test('two-digit year resolves to 20YY when plausible', () {
    expect(run(['26.01.15']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['26/1/5']).best!.date, const CivilDate(2026, 1, 5));
  });

  test('wareki full and abbreviated', () {
    expect(run(['令和8年1月15日']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['R8.1.15']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['令和元年5月1日']).best!.date, const CivilDate(2019, 5, 1));
    expect(run(['H31.4.20']).best!.date, const CivilDate(2019, 4, 20));
  });

  test('bare single-digit year is inferred as 令和 (8.07.03 -> 2026)', () {
    final r = run(['8.07.03']);
    expect(r.best!.date, const CivilDate(2026, 7, 3));
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('two-digit ambiguity prefers the interpretation closest to today', () {
    // 06.07.03: 西暦2006(20年前) vs 令和6=2024(2年前) -> 2024
    final r = run(['06.07.03']);
    expect(r.best!.date, const CivilDate(2024, 7, 3));
  });

  test('future dates (point expiry) are rejected in favor of the issue date', () {
    final r = run(['2026/01/15 10:00', 'ポイント有効期限 2027/03/31']);
    expect(r.best!.date, const CivilDate(2026, 1, 15));
  });

  test('期限/有効/まで rows are excluded even without a better date', () {
    final r = run(['お支払い期限 2026/06/30']);
    expect(r.best!.reason, 'default-today'); // 期限行しか無ければ今日既定
  });

  test('topmost date preferred over campaign date below', () {
    final r = run(['2026/07/01', 'セール開催 2026/06/20']);
    expect(r.best!.date, const CivilDate(2026, 7, 1));
  });

  test('invalid calendar dates rejected', () {
    final r = run(['2026/02/30']);
    expect(r.best!.reason, 'default-today');
  });

  test('too-old years rejected', () {
    final r = run(['1999/01/15']);
    expect(r.best!.reason, 'default-today');
  });

  test('MM/DD only requires an adjacent time; year rolls back across new year',
      () {
    // today=2026-07-03: 「12/28 18:05」→ 2025-12-28（未来にしない）
    final r = run(['12/28 18:05']);
    expect(r.best!.date, const CivilDate(2025, 12, 28));
    expect(r.best!.confidence, ExtractionConfidence.low);
  });

  test('no date at all -> today as low-confidence default', () {
    final r = run(['ありがとうございました']);
    expect(r.best!.date, today);
    expect(r.best!.confidence, ExtractionConfidence.low);
    expect(r.best!.reason, 'default-today');
  });

  test('phone numbers are not misread as dates', () {
    final r = run(['TEL 03-1234-5678']);
    expect(r.best!.reason, 'default-today');
  });
}
