import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/services/receipt/store.dart';

/// 1行1ブロックの合成レシート。yは行順で自動採番。
/// 店名抽出は**生テキスト**を食う（正規化は判定用に内部で行う）ため
/// total_test と違い normalizeOcrText を通さない。
List<ReceiptRow> receipt(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (final (i, line) in lines.indexed) {
    blocks.add(OcrBlock(
      text: line,
      rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
      confidence: 0.9,
    ));
  }
  return groupRows(blocks);
}

void main() {
  test('最上部の店名行を抽出する', () {
    final name = extractStoreName(receipt([
      'サミットストア みどり駅前店',
      '東京都みなみ区みどり3-1-1',
      'TEL 03-1234-5678',
      '2026/07/14 12:34',
    ]));
    expect(name, 'サミットストア みどり駅前店');
  });

  test('電話・住所・日付・レジ行は店名にしない', () {
    final name = extractStoreName(receipt([
      '領収書',
      '東京都みなみ区みどり3-1-1',
      'TEL 03-1234-5678',
      'スーパーB',
      '2026/07/14 12:34',
    ]));
    expect(name, 'スーパーB');
  });

  test('金額・数字混じりの商品行は店名にしない', () {
    final name = extractStoreName(receipt([
      '2026/07/14 12:34',
      '牛乳 ¥258',
      '食パン 298',
    ]));
    expect(name, isNull);
  });

  test('上部に文字行が無ければ null（→UIは店名不明）', () {
    expect(extractStoreName(receipt(['T1234567890123'])), isNull);
    expect(extractStoreName(const []), isNull);
  });

  test('OK型: 店名が0.35より下でも日付行より上なら候補に入る', () {
    // 実レシート(OKストア): スローガンが長く、店名は y≈0.36-0.43 に来る
    final cands = extractStoreCandidates(receipt([
      '高品質・Everyday Low Price', // y=0.05
      'オーククラブ会員で現金払に限り、食料品は', // 会員→除外
      '単品毎に本体価格の3/10（3%相当）を割引', // 数字→除外
      '事業者番号 6010801001974', // 除外
      'オーケー', // y=0.25
      'あおば店', // y=0.30
      '03-3378-3921', // y=0.35 電話→除外
      '営業時間8:30～21:30', // y=0.40 除外
      '2026年04月19日（日）20:32', // y=0.45 日付行=ゾーン終端
      'レジ0804', // 日付より下→対象外
    ]));
    expect(cands, contains('オーケー'));
    expect(cands, contains('あおば店'));
    expect(cands.first, '高品質・Everyday Low Price');
  });

  test('候補は上から複数返す（URL・番号行は除外）: 実レシートのサミット型', () {
    final cands = extractStoreCandidates(receipt([
      'サミット',
      'みなみ台店',
      'https://www.summitstore.co jp/',
      '登録番号',
      'T3011301002747',
    ]));
    expect(cands, ['サミット', 'みなみ台店']);
  });

  test('レシート下部の文字行は店名にしない（centerY >= 0.35）', () {
    // 先頭7行をブラックリスト行で埋め、文字行を下部に置く
    final name = extractStoreName(receipt([
      '2026/07/14',
      'TEL 03-0000-0000',
      '領収書',
      'レジ 001',
      'No. 1234',
      '2026/07/14 12:34',
      'T1234567890123',
      'ようこそフーズマート', // index7 → y=0.40 > 0.35
    ]));
    expect(name, isNull);
  });
}
