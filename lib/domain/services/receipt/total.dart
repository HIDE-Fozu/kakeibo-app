import 'amounts.dart';
import 'rows.dart';

enum ExtractionConfidence { high, medium, low }

class AmountCandidate {
  final int yen;
  final ExtractionConfidence confidence;
  final String sourceText;
  final String reason;
  const AmountCandidate({
    required this.yen,
    required this.confidence,
    required this.sourceText,
    required this.reason,
  });
}

class TotalExtraction {
  final AmountCandidate? best;
  final List<AmountCandidate> candidates;
  const TotalExtraction({required this.best, required this.candidates});
}

// --- キーワード語彙 ---
final _reP1 = RegExp(r'合計|お会計|御会計|ご請求|お支払|領収');
final _reP2 = RegExp(r'税込|内税込|総額|総合計|総計');
final _reP3 = RegExp(r'お買上げ|お買い上げ|お買上|買上|お買物');
final _reP4 = RegExp(r'(?<![小中抜外合会総課])計');
final _reTaxExcluded = RegExp(r'税抜|本体|外税対象');
final _reExclusion = RegExp(
    r'預り|預か|お預|現金|キャッシュ|釣|つり|返金|お返し|'
    r'ポイント|残高|クレジット|カード|電子マネー|チャージ|差引|利用額|'
    r'値引|割引|クーポン|非課税|課税対象額');
final _reSubtotal = RegExp(r'小計');
final _reTax = RegExp(r'消費税|外税|内税(?!込)');
final _reTendered = RegExp(r'預');
final _reChange = RegExp(r'釣|つり');

class _RowInfo {
  final ReceiptRow row;
  final int index;
  final List<AmountToken> tokens;
  _RowInfo(this.row, this.index, this.tokens);
}

/// 行の右端（最右トークン）の非負金額。無ければnull。
int? _rowAmount(List<AmountToken> tokens) {
  final positives = tokens.where((t) => !t.negative).toList();
  if (positives.isEmpty) return null;
  return positives.last.yen; // 行内で最後（最右/最終出現）
}

TotalExtraction extractTotal(List<ReceiptRow> rows) {
  final infos = <_RowInfo>[];
  for (final (i, row) in rows.indexed) {
    infos.add(_RowInfo(row, i, extractAmounts(row)));
  }

  // --- 現金恒等式の素材 ---
  int? tendered;
  int? change;
  for (final info in infos) {
    final text = info.row.text;
    final amount = _rowAmount(info.tokens);
    if (amount == null) continue;
    if (_reTendered.hasMatch(text)) tendered ??= amount;
    if (_reChange.hasMatch(text) && !_reTendered.hasMatch(text)) change ??= amount;
  }
  final cashIdentity =
      (tendered != null && change != null) ? tendered - change : null;

  // --- キーワード候補のスコアリング ---
  final scored = <(int score, int rowIndex, AmountCandidate cand)>[];
  for (final info in infos) {
    final text = info.row.text;
    if (_reExclusion.hasMatch(text)) continue;

    int tier = 0;
    if (_reP2.hasMatch(text)) {
      tier = 110;
    } else if (_reP1.hasMatch(text)) {
      tier = 100;
    } else if (_reP3.hasMatch(text)) {
      tier = 80;
    } else if (_reP4.hasMatch(text) && !_reSubtotal.hasMatch(text)) {
      tier = 30;
    }
    if (tier == 0) continue;

    final amount = _rowAmount(info.tokens);
    if (amount == null || amount <= 0) continue;

    var score = tier;
    if (_reTaxExcluded.hasMatch(text)) score -= 1000;
    if (RegExp(r'税込|内税').hasMatch(text)) score += 25;
    if (info.row.centerY > 0.5) score += 10;
    final token = info.tokens.lastWhere((t) => !t.negative && t.yen == amount);
    if (token.tier != AmountTier.bare) score += 10;
    if (cashIdentity != null && amount == cashIdentity) score += 40;

    if (score <= 0) continue; // 税抜降格は候補から外す（合成パスで扱う）
    scored.add((
      score,
      info.index,
      AmountCandidate(
        yen: amount,
        // キーワード行でも金額が裸数字（通貨手がかりなし）なら low
        confidence: token.tier == AmountTier.bare
            ? ExtractionConfidence.low
            : ExtractionConfidence.high,
        sourceText: text,
        reason: 'keyword(score=$score)',
      )
    ));
  }

  // 同点はより下の行（index大）を優先 → score desc, index desc
  scored.sort((a, b) {
    final s = b.$1.compareTo(a.$1);
    return s != 0 ? s : b.$2.compareTo(a.$2);
  });

  final candidates = <AmountCandidate>[];
  void addCandidate(AmountCandidate c) {
    if (candidates.any((e) => e.yen == c.yen)) return;
    if (candidates.length >= 5) return;
    candidates.add(c);
  }

  for (final s in scored) {
    addCandidate(s.$3);
  }

  AmountCandidate? best = candidates.isNotEmpty ? candidates.first : null;

  // --- 税抜合計 + 消費税 の合成（税込系候補ゼロのとき） ---
  if (best == null) {
    int? taxExcludedTotal;
    var taxSum = 0;
    for (final info in infos) {
      final text = info.row.text;
      final amount = _rowAmount(info.tokens);
      if (amount == null) continue;
      if (_reTaxExcluded.hasMatch(text) && RegExp(r'合計|計').hasMatch(text)) {
        taxExcludedTotal ??= amount;
      } else if (_reTax.hasMatch(text) && !_reExclusion.hasMatch(text)) {
        taxSum += amount;
      }
    }
    if (taxExcludedTotal != null && taxSum > 0) {
      best = AmountCandidate(
        yen: taxExcludedTotal + taxSum,
        confidence: ExtractionConfidence.medium,
        sourceText: '税抜合計+消費税',
        reason: 'synthesized(taxExcluded+tax)',
      );
      addCandidate(best);
    }
  }

  // --- フォールバック: 除外行以外の Tier A/B 最大値 ---
  if (best == null) {
    final pool = <AmountToken>[];
    int? subtotal;
    var taxSum = 0;
    for (final info in infos) {
      final text = info.row.text;
      final amount = _rowAmount(info.tokens);
      if (_reSubtotal.hasMatch(text) && amount != null) subtotal ??= amount;
      if (_reTax.hasMatch(text) && amount != null) taxSum += amount;
      if (_reExclusion.hasMatch(text)) continue;
      pool.addAll(
          info.tokens.where((t) => !t.negative && t.tier != AmountTier.bare));
    }
    if (pool.isNotEmpty) {
      AmountToken pick;
      if (subtotal != null && taxSum > 0) {
        final target = subtotal + taxSum;
        pick = pool.reduce(
            (a, c) => (c.yen - target).abs() < (a.yen - target).abs() ? c : a);
      } else {
        pick = pool.reduce((a, c) => c.yen > a.yen ? c : a);
      }
      best = AmountCandidate(
        yen: pick.yen,
        confidence: ExtractionConfidence.medium,
        sourceText: pick.raw,
        reason: 'fallback(max-plausible)',
      );
      addCandidate(best);
    }
  }

  // --- 現金恒等式によるrecovery ---
  if (best == null && cashIdentity != null && cashIdentity > 0) {
    best = AmountCandidate(
      yen: cashIdentity,
      confidence: ExtractionConfidence.medium,
      sourceText: 'お預り-お釣り',
      reason: 'cash-identity',
    );
    addCandidate(best);
  }

  return TotalExtraction(best: best, candidates: candidates);
}
