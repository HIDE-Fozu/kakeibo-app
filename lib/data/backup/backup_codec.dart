import 'dart:convert';
import 'backup_data.dart';

/// バックアップJSONの直列化と厳格検証。復元の唯一の門番。
class BackupCodec {
  /// バックアップ形式のバージョン。DBのschemaVersionとは独立に管理する。
  static const int formatVersion = 1;

  const BackupCodec();

  String encode(BackupPayload p) {
    final root = <String, dynamic>{
      'formatVersion': p.formatVersion,
      'exportedAt': p.exportedAt?.toUtc().toIso8601String(),
      'categories': [
        for (final c in p.categories)
          {
            'id': c.id,
            'name': c.name,
            'type': c.type.name,
            'icon': c.icon,
            'sortOrder': c.sortOrder,
            'isArchived': c.isArchived,
            'isSystem': c.isSystem,
          },
      ],
      'transactions': [
        for (final t in p.transactions)
          {
            'id': t.id,
            'type': t.type.name,
            'amount': t.amount,
            'date': t.date.toIso(),
            'categoryId': t.categoryId,
            'paymentMethod': t.paymentMethod?.name,
            'memo': t.memo,
            'source': t.source.name,
            'imagePath': t.imagePath,
            'createdAt': t.createdAt.toUtc().toIso8601String(),
            'updatedAt': t.updatedAt.toUtc().toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }
}
