import '../data/db/enums.dart';

String formatYen(int yen) {
  final digits = yen.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${yen < 0 ? '-' : ''}¥$buf';
}

String signedYen(TxnType type, int amountYen) =>
    (type == TxnType.expense ? '-' : '+') + formatYen(amountYen);

/// カレンダーセル用の略記（45px幅で潰れないように）。実機での最終調整はspec §13の宿題。
String compactYen(int yen) {
  if (yen <= 0) return '';
  if (yen < 1000) return '¥$yen';
  if (yen < 10000) return '¥${_oneDecimal(yen / 1000)}k';
  if (yen < 1000000) return '¥${yen ~/ 1000}k';
  return '¥${_oneDecimal(yen / 1000000)}M';
}

String _oneDecimal(double v) {
  final s = ((v * 10).floor() / 10).toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String backupAgeLabel(DateTime? lastUtc, DateTime nowUtc) {
  if (lastUtc == null) return 'バックアップ未作成';
  final days = nowUtc.difference(lastUtc).inDays;
  if (days <= 0) return '前回バックアップ: 今日';
  return '前回バックアップ: $days日前';
}
