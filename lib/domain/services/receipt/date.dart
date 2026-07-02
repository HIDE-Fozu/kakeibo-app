import '../../money/civil_date.dart';
import 'rows.dart';
import 'total.dart' show ExtractionConfidence;

class DateCandidate {
  final CivilDate date;
  final ExtractionConfidence confidence;
  final String sourceText;
  final String reason;
  const DateCandidate({
    required this.date,
    required this.confidence,
    required this.sourceText,
    required this.reason,
  });
}

class DateExtraction {
  final DateCandidate? best;
  final List<DateCandidate> candidates;
  const DateExtraction({required this.best, required this.candidates});
}

final _reGregorian = RegExp(
    r'(?<y>\d{4})\s*[/\-.年]\s*(?<m>\d{1,2})\s*[/\-.月]\s*(?<d>\d{1,2})\s*日?');
final _reWareki = RegExp(
    r'(?<era>令和|平成|昭和|[RHS])\s*(?<ey>元|\d{1,2})\s*[年.\-/]\s*'
    r'(?<m>\d{1,2})\s*[月.\-/]\s*(?<d>\d{1,2})\s*日?');
final _reShortYear = RegExp(
    r'(?<![\d/\-.年])(?<y>\d{1,2})[/\-.](?<m>\d{1,2})[/\-.](?<d>\d{1,2})(?![\d/\-.])');
final _reMonthDay = RegExp(
    r'(?<![\d/\-.年月])(?<m>\d{1,2})[/月](?<d>\d{1,2})日?(?![\d/\-.日])');
final _reTime = RegExp(r'\d{1,2}\s*[:時]\s*\d{2}');
final _reExpiry = RegExp(r'期限|有効|まで|~');
final _reIssueCue = RegExp(r'発行|取引|ご利用|日時|レジ');
final _rePhoneGuard = RegExp(r'TEL|電話|FAX|〒', caseSensitive: false);

int _warekiYear(String era, String ey) {
  final n = (ey == '元') ? 1 : int.parse(ey);
  return switch (era) {
    '令和' || 'R' => 2018 + n,
    '平成' || 'H' => 1988 + n,
    '昭和' || 'S' => 1925 + n,
    _ => -1,
  };
}

CivilDate? _valid(int y, int m, int d) {
  final c = CivilDate(y, m, d);
  return c.isValid ? c : null;
}

/// today+1日 を返す（tzスラック）
CivilDate _tomorrow(CivilDate today) {
  final dt = DateTime.utc(today.year, today.month, today.day)
      .add(const Duration(days: 1));
  return CivilDate(dt.year, dt.month, dt.day);
}

int _daysFromToday(CivilDate d, CivilDate today) {
  final a = DateTime.utc(d.year, d.month, d.day);
  final b = DateTime.utc(today.year, today.month, today.day);
  return a.difference(b).inDays;
}

class _Raw {
  final CivilDate date;
  final ExtractionConfidence confidence;
  final String reason;
  _Raw(this.date, this.confidence, this.reason);
}

DateExtraction extractDate(List<ReceiptRow> rows, CivilDate today) {
  final tomorrow = _tomorrow(today);
  final found = <(double score, int order, DateCandidate cand)>[];
  var order = 0;

  bool acceptable(CivilDate d) => d.year >= 2000 && d.compareTo(tomorrow) <= 0;

  for (final row in rows) {
    final text = row.text;
    if (_rePhoneGuard.hasMatch(text)) continue; // TEL/〒行の数値は日付にしない
    if (_reExpiry.hasMatch(text)) continue; // 有効期限・キャンペーン行
    final hasTime = _reTime.hasMatch(text);

    final raws = <_Raw>[];

    for (final m in _reWareki.allMatches(text)) {
      final y = _warekiYear(m.namedGroup('era')!, m.namedGroup('ey')!);
      final d =
          _valid(y, int.parse(m.namedGroup('m')!), int.parse(m.namedGroup('d')!));
      if (d != null) raws.add(_Raw(d, ExtractionConfidence.high, 'wareki'));
    }

    for (final m in _reGregorian.allMatches(text)) {
      final d = _valid(int.parse(m.namedGroup('y')!),
          int.parse(m.namedGroup('m')!), int.parse(m.namedGroup('d')!));
      if (d != null) raws.add(_Raw(d, ExtractionConfidence.high, 'gregorian'));
    }

    // 短年: 2桁→西暦20YYと和暦2018+YYの両解釈、1桁→和暦のみ。
    // 双方validなら「未来でなく今日に近い方」。
    if (raws.isEmpty) {
      for (final m in _reShortYear.allMatches(text)) {
        final yTok = m.namedGroup('y')!;
        final mo = int.parse(m.namedGroup('m')!);
        final da = int.parse(m.namedGroup('d')!);
        final interp = <CivilDate>[];
        if (yTok.length == 2) {
          final g = _valid(2000 + int.parse(yTok), mo, da);
          if (g != null) interp.add(g);
        }
        final w = _valid(2018 + int.parse(yTok), mo, da);
        if (w != null) interp.add(w);
        final ok = interp.where(acceptable).toList();
        if (ok.isEmpty) continue;
        ok.sort((a, b) =>
            _daysFromToday(b, today).compareTo(_daysFromToday(a, today)));
        // 今日に最も近い（過去方向で最大の daysFromToday）
        raws.add(_Raw(ok.first, ExtractionConfidence.medium, 'short-year'));
      }
    }

    // MM/DDのみ: 同一行に時刻がある場合だけ。年は今日を超えない直近年。
    if (raws.isEmpty && hasTime) {
      for (final m in _reMonthDay.allMatches(text)) {
        final mo = int.parse(m.namedGroup('m')!);
        final da = int.parse(m.namedGroup('d')!);
        var d = _valid(today.year, mo, da);
        if (d != null && d.compareTo(tomorrow) > 0) {
          d = _valid(today.year - 1, mo, da);
        }
        if (d != null && acceptable(d)) {
          raws.add(_Raw(d, ExtractionConfidence.low, 'month-day'));
        }
      }
    }

    for (final raw in raws) {
      if (!acceptable(raw.date)) continue;
      var score = 0.0;
      if (hasTime) score += 50;
      score += (1 - row.centerY) * 20;
      if (_reIssueCue.hasMatch(text)) score += 15;
      // フル日付でも時刻非同居なら medium に降格（時刻同居が最強の取引手がかり）
      final conf = (raw.confidence == ExtractionConfidence.high && !hasTime)
          ? ExtractionConfidence.medium
          : raw.confidence;
      found.add((
        score,
        order++,
        DateCandidate(
            date: raw.date, confidence: conf, sourceText: text, reason: raw.reason)
      ));
    }
  }

  found.sort((a, b) {
    final s = b.$1.compareTo(a.$1);
    return s != 0 ? s : a.$2.compareTo(b.$2);
  });

  final candidates = <DateCandidate>[];
  for (final f in found) {
    if (candidates.any((c) => c.date == f.$3.date)) continue;
    if (candidates.length >= 5) break;
    candidates.add(f.$3);
  }

  final best = candidates.isNotEmpty
      ? candidates.first
      : DateCandidate(
          date: today,
          confidence: ExtractionConfidence.low,
          sourceText: '',
          reason: 'default-today');

  return DateExtraction(best: best, candidates: candidates);
}
