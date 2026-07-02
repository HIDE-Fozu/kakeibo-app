import 'package:drift/drift.dart';
import '../db/database.dart';
import 'backup_codec.dart';
import 'backup_data.dart';

/// バックアップ／復元のオーケストレーション。
/// 検証は BackupCodec に集約されており、本クラスはDBとの読み書きに徹する。
class BackupService {
  final AppDatabase _db;
  final BackupCodec _codec;

  BackupService(this._db, {BackupCodec codec = const BackupCodec()})
      : _codec = codec;

  Future<BackupPayload> exportPayload() async {
    final cats = await (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.id)]))
        .get();
    final txs = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.now().toUtc(),
      categories: [
        for (final c in cats)
          BackupCategory(
            id: c.id,
            name: c.name,
            type: c.type,
            icon: c.icon,
            sortOrder: c.sortOrder,
            isArchived: c.isArchived,
            isSystem: c.isSystem,
          ),
      ],
      transactions: [
        for (final t in txs)
          BackupTxn(
            id: t.id,
            type: t.type,
            amount: t.amount,
            date: t.date,
            categoryId: t.categoryId,
            paymentMethod: t.paymentMethod,
            memo: t.memo,
            source: t.source,
            imagePath: t.imagePath,
            createdAt: t.createdAt.toUtc(),
            updatedAt: t.updatedAt.toUtc(),
          ),
      ],
    );
  }

  Future<String> exportJson() async => _codec.encode(await exportPayload());
}
