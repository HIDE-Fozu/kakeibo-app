import '../ocr/ocr_types.dart';
import 'amounts.dart';
import 'rows.dart';

/// レシートの品目1行。UIは text ではなく rect による**写真の行切り抜き**を
/// 主表示にする（品名は半角カタカナ略称が多くOCRテキストは判読に不向き）。
class ReceiptItem {
  final String text; // 正規化済み行テキスト（補助・デバッグ用）
  final int yen; // 行の金額（税処理前の紙面の額）
  final OcrRect rect; // 行全体のbbox（正準空間0..1・写真切り抜き用）
  final bool reducedTaxMark; // ※（軽減税率8%）マーク付き行
  const ReceiptItem({
    required this.text,
    required this.yen,
    required this.rect,
    required this.reducedTaxMark,
  });
}

// 品目ではない行の語彙（合計系・支払系・値引・店メタ）。
final _reNotItem = RegExp(
    r'合計|小計|現計|お会計|御会計|ご請求|お支払|領収|税込|税抜|総額|消費税|外税|内税|'
    r'課税|非課税|対象|預り|預か|お預|現金|キャッシュ|釣|つり|返金|お返し|'
    r'ポイント|残高|クレジット|クレカ|カード|電子マネー|チャージ|差引|利用額|'
    r'値引|割引|クーポン|買上|点数|合計点|お買物|レジ|担当|責任者|会員|No\.');

final _reReducedMark = RegExp(r'[※×]|軽減');
// 品名は文字を含む（かな/カナ/半角カナ/漢字/ラテン）。裸数字だけの行は
// バーコード・点数等のノイズ（実フィクスチャで確認）。
final _reHasLetter = RegExp(r'[ぁ-んァ-ヶｦ-ﾟ一-龠a-zA-Z]');
final _reDateTime =
    RegExp(r'\d{2,4}\s*[/\-.年]\s*\d{1,2}\s*[/\-.月]\s*\d{1,2}|\d{1,2}\s*[:時]\s*\d{2}');

/// 品目行の抽出。
/// ゾーン: **日付/時刻行（上半分にあるもの）の次**から、最初の「小計/合計」系
/// 行の手前まで。店ヘッダ（電話・No.等）と支払・釣り銭ゾーンを構造的に外す。
/// 条件: 正の金額トークン＋文字（品名）を持ち、除外語彙に当たらない行。
/// 値引き行（負トークンのみ）は含めない＝差額行がその分を吸収する（v1）。
List<ReceiptItem> extractItemLines(List<ReceiptRow> rows) {
  var start = 0;
  for (final (i, row) in rows.indexed) {
    if (row.centerY >= 0.5) break;
    if (_reDateTime.hasMatch(row.text)) {
      start = i + 1;
      break;
    }
  }
  var end = rows.length;
  final reTotalStart = RegExp(r'小計|合計|現計|お会計|御会計|ご請求');
  for (final (i, row) in rows.indexed) {
    if (i >= start && reTotalStart.hasMatch(row.text)) {
      end = i;
      break;
    }
  }

  final items = <ReceiptItem>[];
  for (final row in rows.skip(start).take(end - start)) {
    final text = row.text;
    if (_reNotItem.hasMatch(text)) continue;
    if (!_reHasLetter.hasMatch(text)) continue;
    final tokens = extractAmounts(row);
    final positives = tokens.where((t) => !t.negative).toList();
    if (positives.isEmpty) continue;
    final yen = positives.last.yen; // 行内最右の額=価格（数量×単価の単価を避ける）
    if (yen <= 0) continue;

    // 行bbox（全ブロックの外接矩形）
    var x = double.infinity, right = -double.infinity;
    for (final b in row.blocks) {
      if (b.rect.x < x) x = b.rect.x;
      if (b.rect.right > right) right = b.rect.right;
    }
    items.add(ReceiptItem(
      text: text,
      yen: yen,
      rect: OcrRect(x, row.top, right - x, row.bottom - row.top),
      reducedTaxMark: _reReducedMark.hasMatch(text),
    ));
  }
  return items;
}
