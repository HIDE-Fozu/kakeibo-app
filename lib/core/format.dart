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

/// カレンダーセル用の万表記（モック確定: 980 / 0.3万 / 1.2万 / 28.5万 / 124万）。
/// <1000: 生数字（¥なし）／<100万: 万単位・小数1桁に四捨五入（.0はトリム）／
/// ≥100万: 整数万に四捨五入。0以下は空文字（セル非表示）。
String manYen(int yen) {
  if (yen <= 0) return '';
  if (yen < 1000) return '$yen';
  if (yen < 1000000) {
    final tenths = (yen / 1000).round(); // 0.1万（千円）単位に四捨五入
    final s = (tenths / 10).toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}万';
  }
  return '${(yen / 10000).round()}万';
}

String backupAgeLabel(DateTime? lastUtc, DateTime nowUtc) {
  if (lastUtc == null) return 'バックアップ未作成';
  final days = nowUtc.difference(lastUtc).inDays;
  if (days <= 0) return '前回バックアップ: 今日';
  return '前回バックアップ: $days日前';
}
