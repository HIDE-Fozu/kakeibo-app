import '../ocr/ocr_types.dart';
import 'normalize.dart';
import 'rows.dart';

/// 金額トークンの確信度tier。
/// currency: ¥/円/星囲みアンカー / comma: 3,850形式 / bare: 裸数字（文脈必須）
enum AmountTier { currency, comma, bare }

class AmountToken {
  final int yen;
  final bool negative;
  final AmountTier tier;
  final String raw;
  final OcrBlock block;
  const AmountToken({
    required this.yen,
    required this.negative,
    required this.tier,
    required this.raw,
    required this.block,
  });
}

const int maxPlausibleYen = 9999999;

// --- マスク対象（金額として拾ってはならない数値文脈） ---
final _maskPatterns = <RegExp>[
  RegExp(r'T\d{13}'), // インボイス登録番号
  RegExp(r'〒\s*\d{3}-?\d{4}'), // 郵便番号
  RegExp(r'0\d{1,4}-\d{1,4}-\d{3,4}'), // 電話（ハイフン形式）
  RegExp(r'\d{4}\s*[/\-.年]\s*\d{1,2}\s*[/\-.月]\s*\d{1,2}\s*日?'), // 日付(4桁年)
  RegExp(r'(?<![\d/\-.])\d{1,2}[/\-.]\d{1,2}[/\-.]\d{1,2}(?![\d/\-.])'), // 日付(短)
  RegExp(r'\d{1,2}\s*[:時]\s*\d{2}'), // 時刻
  RegExp(r'[×xX＠@]\s*\d+'), // 数量・単価マーカー
  RegExp(r'\d+(?:\.\d+)?\s*%'), // 税率
];

// --- 金額regex（正規化済みテキスト前提） ---
const _grp = r'\d{1,3}(?:,\d{3})+'; // カンマ区切り必須
const _bare = r'\d{1,7}';

final _reYenPrefix = RegExp(r'[¥\\]\s*([-▲△]?(?:' + _grp + r'|' + _bare + r'))');
final _reYenSuffix =
    RegExp(r'(?<![\d,])([-▲△]?(?:' + _grp + r'|' + _bare + r'))\s*円');
final _reStarred = RegExp(r'\*\s*¥?\s*(' + _grp + r')\s*\*');
final _reComma = RegExp(r'(?<![\d,.¥\\])([-▲△]?' + _grp + r')(?![\d,])');
final _reBare = RegExp(r'(?<![\d,.\-¥\\])([-▲△]?' + _bare + r')(?![\d,%])');

final _reNeg = RegExp(r'^\s*[-▲△]');

// --- 行レベルガードの語彙 ---
final _rePhoneRow = RegExp(r'TEL|電話|FAX', caseSensitive: false);
final _reIdRow = RegExp(r'No|レジ|責|取引|伝票|会員', caseSensitive: false);
final _reQtyRow = RegExp(r'数量|単価|点数');
final _reLongBareDigits = RegExp(r'^\d{6,}$');
final _rePhoneLike = RegExp(r'^0\d{9,10}$');

int? _parseYen(String tok) {
  final digits = tok.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty || digits.length > 8) return null;
  final v = int.parse(digits);
  if (v < 1 || v > maxPlausibleYen) return null;
  return v;
}

String _mask(String text) {
  var out = text;
  for (final re in _maskPatterns) {
    out = out.replaceAllMapped(re, (m) => ' ' * (m.end - m.start));
  }
  return out;
}

/// 行から金額トークンを抽出する。呼び出し側は normalizeOcrText 適用済みテキストを前提。
/// tokensは「ブロックのx昇順 → tier走査順 → 同tier内は左→右」で自然に整列する
/// （List.sortは不安定なのでsortしない）。
List<AmountToken> extractAmounts(ReceiptRow row) {
  final rowText = row.text;
  final phoneRow = _rePhoneRow.hasMatch(rowText);
  final idRow = _reIdRow.hasMatch(rowText);
  final qtyRow = _reQtyRow.hasMatch(rowText);

  final tokens = <AmountToken>[];
  for (final block in row.blocks) {
    final repaired = repairDigitConfusions(block.text);
    final masked = _mask(repaired);

    // マッチ範囲の重複を避けるため tier 順に走査し、採用済み範囲はスキップ
    final taken = <(int, int)>[];
    bool overlaps(int s, int e) => taken.any((r) => s < r.$2 && e > r.$1);

    void scan(RegExp re, AmountTier tier) {
      for (final m in re.allMatches(masked)) {
        final s = m.start, e = m.end;
        if (overlaps(s, e)) continue;
        final raw = m.group(1) ?? m.group(0)!;
        final yen = _parseYen(raw);
        if (yen == null) continue;
        final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
        final hasComma = raw.contains(',');

        // 行レベルガード
        if (phoneRow && !hasComma && digits.length >= 6) continue;
        if (_rePhoneLike.hasMatch(digits)) continue;
        if (idRow && !hasComma && _reLongBareDigits.hasMatch(digits)) continue;
        if (qtyRow && tier == AmountTier.bare) continue;

        taken.add((s, e));
        tokens.add(AmountToken(
          yen: yen,
          negative: _reNeg.hasMatch(raw),
          tier: tier,
          raw: raw,
          block: block,
        ));
      }
    }

    scan(_reStarred, AmountTier.currency);
    scan(_reYenPrefix, AmountTier.currency);
    scan(_reYenSuffix, AmountTier.currency);
    scan(_reComma, AmountTier.comma);
    scan(_reBare, AmountTier.bare);
  }
  return tokens;
}
