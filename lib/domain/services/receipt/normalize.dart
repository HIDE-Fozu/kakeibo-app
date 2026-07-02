/// OCRテキストの正規化。Dartの \d はASCIIのみ＝全角はここで潰してからregexへ。
/// ▲/△ は負値マーカーとして意図的に保持する。
String normalizeOcrText(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xFF10 && r <= 0xFF19) {
      sb.writeCharCode(r - 0xFEE0); // 全角数字
      continue;
    }
    if (r >= 0xFF21 && r <= 0xFF5A) {
      sb.writeCharCode(r - 0xFEE0); // 全角英字（Ａ-Ｚａ-ｚ、間の記号も同オフセットで無害）
      continue;
    }
    switch (r) {
      case 0xFF0C: sb.write(','); break; // ，
      case 0xFF0E: sb.write('.'); break; // ．
      case 0xFF1A: sb.write(':'); break; // ：
      case 0xFF0F: sb.write('/'); break; // ／
      case 0xFFE5: sb.write('¥'); break; // ￥
      case 0x3000: sb.write(' '); break; // 全角スペース
      case 0xFF05: sb.write('%'); break; // ％
      case 0xFF0D: // －
      case 0x2010: // ‐
      case 0x2011: // ‑
      case 0x2013: // –
      case 0x2014: // —
      case 0x30FC: // ー(長音。サーマルはダッシュと混用)
      case 0x2212: // −
        sb.write('-');
        break;
      default:
        sb.writeCharCode(r);
    }
  }
  // 数トークン内の空白を潰す: 「¥ 1, 234」→「¥1,234」
  // （カンマ/¥ の直後の空白列で、次が数字/カンマのもの。
  //  左辺に \d を入れると「12/28 18:05」の日付-時刻間まで接着して
  //  日付抽出を壊すため、¥ と , のみ）
  var out = sb.toString();
  out = out.replaceAllMapped(
    _numGap,
    (m) => m.group(1)!,
  );
  return out;
}

final _numGap = RegExp(r'([¥,])[ \t]+(?=[\d,])');

/// 数字文脈のOCR誤読修復（O→0, l/I→1, B→8, S→5）。
/// 数字に隣接する1文字だけを直し、単語中の文字は触らない。
String repairDigitConfusions(String s) {
  var out = s;
  // 数字の直後にある誤読文字
  out = out.replaceAllMapped(_confAfterDigit, (m) => _mapConfusion(m.group(1)!));
  // 数字(またはカンマ)の直前にある誤読文字
  out = out.replaceAllMapped(_confBeforeDigit, (m) => _mapConfusion(m.group(1)!));
  return out;
}

final _confAfterDigit = RegExp(r'(?<=\d)([OolIBS])(?![A-Za-z])');
final _confBeforeDigit = RegExp(r'(?<![A-Za-z])([OolIBS])(?=[\d,]*\d)');

String _mapConfusion(String c) => switch (c) {
      'O' || 'o' => '0',
      'l' || 'I' => '1',
      'B' => '8',
      'S' => '5',
      _ => c,
    };
