import 'normalize.dart';
import 'rows.dart';

// --- 店名になり得ない行の語彙 ---
final _reBlacklist = RegExp(
    r'TEL|FAX|電話|〒|T\d{13}|登録番号|事業者番号|レジ|責任者|取引|伝票|会員|領収|レシート|明細|'
    r'ありがとう|毎度|お買上|営業時間|担当|'
    r'https?|www\.|\.co|\.jp|\.com', // URL行（実フィクスチャ: サミット）
    caseSensitive: false);
final _reDateLike = RegExp(r'\d{2,4}\s*[/\-.年]\s*\d{1,2}');
final _reTimeLike = RegExp(r'\d{1,2}\s*[:時]\s*\d{2}');
// 3桁以上の数字列・通貨記号を含む行は商品/金額行とみなす（店名の誤爆源）
final _reAmountLike = RegExp(r'\d{3,}|[¥￥\\]');
// 住所行（都道府県→市区町村郡の並び）
final _reAddressLike = RegExp(r'[都道府県].*[市区町村郡]');
// 文字（かな/カナ/漢字/ラテン）を1文字以上含むこと
final _reHasLetter = RegExp(r'[ぁ-んァ-ヶー一-龠a-zA-Zａ-ｚＡ-Ｚ]');

/// レシート上部から店名らしい行を抽出する。見つからなければ null。
///
/// ヒューリスティック: 上から順に、レシート上部（centerY < 0.35）にあり、
/// ブラックリスト（電話/登録番号/日付/時刻/金額/住所/挨拶）に当たらない
/// 最初の文字入り行を店名とみなす。ロゴ画像で店名がOCRに乗らないレシートでは
/// null（UI側は「店名不明」を表示）。
///
/// 入力は**正規化前の生ブロック**の行であること。normalizeOcrText は長音ーを
/// ダッシュに潰す（数字文脈用）ため、店名表示には使えない。
/// 判定だけ正規化後テキストで行い、返すのは生テキスト。
String? extractStoreName(List<ReceiptRow> rows) {
  final candidates = extractStoreCandidates(rows);
  return candidates.isEmpty ? null : candidates.first;
}

/// 店名候補を上から順に最大[max]件返す（確認UIのチップ切替用）。
/// 実レシートではロゴ断片・スローガン・モール名が1位に来ることがあり、
/// 1位の完全自動特定は原理的に不安定＝ユーザー選択で解決する。
List<String> extractStoreCandidates(List<ReceiptRow> rows, {int max = 4}) {
  final out = <String>[];
  for (final row in rows) {
    if (row.centerY >= 0.35) break; // 店名は上部にしか無い
    final raw = row.text.trim();
    final text = normalizeOcrText(raw);
    if (text.length < 2 || !_reHasLetter.hasMatch(text)) continue;
    if (_reBlacklist.hasMatch(text)) continue;
    if (_reDateLike.hasMatch(text) || _reTimeLike.hasMatch(text)) continue;
    if (_reAmountLike.hasMatch(text)) continue;
    if (_reAddressLike.hasMatch(text)) continue;
    if (!out.contains(raw)) out.add(raw);
    if (out.length >= max) break;
  }
  return out;
}
