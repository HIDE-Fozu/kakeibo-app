import '../db/enums.dart';
import 'backup_data.dart';

/// 取引の閲覧用CSV（エクスポート専用）。復元には使わない。
/// - 先頭BOM(U+FEFF): 日本語Excelでの文字化け回避
/// - CRLF: RFC-4180 準拠
/// - カンマ/引用符/改行を含むフィールドはクオートし、" は "" にエスケープ
String buildTransactionsCsv(BackupPayload payload) {
  final byId = {for (final c in payload.categories) c.id: c};
  final sb = StringBuffer('\uFEFF');
  sb.write('日付,種別,金額,カテゴリ,内訳,支払方法,メモ\r\n');
  for (final t in payload.transactions) {
    final cat = byId[t.categoryId];
    final parent = cat?.parentId == null ? null : byId[cat!.parentId];
    final fields = [
      t.date.toIso(),
      t.type == TxnType.expense ? '支出' : '収入',
      t.amount.toString(),
      // 内訳取引はカテゴリ列=親名・内訳列=自名。親直接は内訳列空
      parent?.name ?? cat?.name ?? '',
      parent == null ? '' : (cat?.name ?? ''),
      _paymentLabel(t.paymentMethod),
      t.memo ?? '',
    ];
    sb.write(fields.map(_escape).join(','));
    sb.write('\r\n');
  }
  return sb.toString();
}

String _paymentLabel(PaymentMethod? m) => switch (m) {
      null => '',
      PaymentMethod.cash => '現金',
      PaymentMethod.creditCard => 'クレジットカード',
      PaymentMethod.eMoney => '電子マネー',
      PaymentMethod.bankDraft => '口座引落',
      PaymentMethod.other => 'その他',
    };

String _escape(String v) {
  if (v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}