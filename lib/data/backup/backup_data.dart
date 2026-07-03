import '../db/enums.dart';
import '../../domain/money/civil_date.dart';

/// バックアップ関連の例外の基底。message は人間向け（UI表示は後続フェーズ）。
abstract class BackupException implements Exception {
  String get message;
  @override
  String toString() => '$runtimeType: $message';
}

/// JSONとして壊れている／型が違う（構造の問題）。
class BackupFormatError extends BackupException {
  @override
  final String message;
  BackupFormatError(this.message);
}

/// formatVersion が欠落・不正・アプリより新しい。
class BackupVersionError extends BackupException {
  @override
  final String message;
  final bool newerThanApp;
  BackupVersionError(this.message, {this.newerThanApp = false});
}

/// 構造は正しいが内容が制約違反（負の金額・未知enum・FK不解決など）。
class BackupValidationError extends BackupException {
  @override
  final String message;
  BackupValidationError(this.message);
}

/// 取引ゼロのバックアップを（明示許可なしに）復元しようとした。
class EmptyBackupError extends BackupException {
  @override
  final String message;
  EmptyBackupError(this.message);
}

/// 復元前の自動退避の書き込み/検証に失敗（復元は中止される）。
class AutoBackupWriteError extends BackupException {
  @override
  final String message;
  AutoBackupWriteError(this.message);
}

/// パスフレーズ誤り・データ改ざん・暗号化バックアップでないファイル。
class BackupDecryptionError extends BackupException {
  @override
  final String message;
  BackupDecryptionError(this.message);
}

/// 行と1:1のバックアップ用カテゴリ。
class BackupCategory {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;
  final int? parentId; // 非null=内訳（formatVersion 2で追加）
  const BackupCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    required this.parentId,
  });
}

/// 行と1:1のバックアップ用取引。
class BackupTxn {
  final int id;
  final TxnType type;
  final int amount;
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? memo;
  final TxnSource source;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BackupTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.paymentMethod,
    required this.memo,
    required this.source,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
}

class BackupPayload {
  final int formatVersion;
  final DateTime? exportedAt;
  final List<BackupCategory> categories;
  final List<BackupTxn> transactions;
  const BackupPayload({
    required this.formatVersion,
    required this.exportedAt,
    required this.categories,
    required this.transactions,
  });
}
