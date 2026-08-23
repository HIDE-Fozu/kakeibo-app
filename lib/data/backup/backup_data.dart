import '../db/enums.dart';
import '../settings/installment_cards.dart';
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
  final String? slug; // 安定キー（formatVersion 3で追加。旧バックアップはnull復元）
  const BackupCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    required this.parentId,
    this.slug,
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
  final String? storeName; // v4列。旧バックアップには無い（memoから移行して復元）
  final String? memo;
  final TxnSource source;
  final String? imagePath;
  final String? splitGroupId; // v3列。旧バックアップには無い（null復元）
  final int? installmentPlanId; // v8列。旧バックアップには無い（null復元）
  final DateTime createdAt;
  final DateTime updatedAt;
  const BackupTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.paymentMethod,
    this.storeName,
    required this.memo,
    required this.source,
    required this.imagePath,
    this.splitGroupId,
    this.installmentPlanId,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// 行と1:1のバックアップ用分割払い計画（formatVersion 8で追加）。
class BackupInstallmentPlan {
  final int id;
  final int principal;
  final int count;
  final double annualRatePercent;
  final int categoryId;
  final int dayOfMonth;
  final int startYm;
  final String? cardName;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BackupInstallmentPlan({
    required this.id,
    required this.principal,
    required this.count,
    required this.annualRatePercent,
    required this.categoryId,
    required this.dayOfMonth,
    required this.startYm,
    required this.cardName,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// 行と1:1のバックアップ用定期ルール（formatVersion 4で追加）。
class BackupRecurringRule {
  final int id;
  final TxnType type;
  final int amount;
  final int categoryId;
  final int dayOfMonth;
  final String? storeName;
  final String? memo;
  final bool isActive;
  final int startYm;
  final int? endYm;
  final int? lastGeneratedYm;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BackupRecurringRule({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.dayOfMonth,
    required this.storeName,
    required this.memo,
    required this.isActive,
    required this.startYm,
    required this.endYm,
    required this.lastGeneratedYm,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// 行と1:1のバックアップ用つきいちタスク（formatVersion 5で追加・
/// v6で dayOfMonth を追加・v7で repeatUnit と intervalDays を追加）。
class BackupChoreTask {
  final int id;
  final String name;
  final String emoji;
  final ChoreRepeatUnit repeatUnit;
  final int dayOfMonth;
  final int intervalDays;
  final CivilDate anchorDate;
  final bool archived;
  final DateTime createdAt;
  const BackupChoreTask({
    required this.id,
    required this.name,
    required this.emoji,
    required this.repeatUnit,
    required this.dayOfMonth,
    required this.intervalDays,
    required this.anchorDate,
    required this.archived,
    required this.createdAt,
  });
}

/// 行と1:1のバックアップ用つきいち実施記録（formatVersion 5で追加）。
class BackupChoreRecord {
  final int id;
  final int taskId;
  final CivilDate doneDate;
  final String memo;
  final DateTime createdAt;
  const BackupChoreRecord({
    required this.id,
    required this.taskId,
    required this.doneDate,
    required this.memo,
    required this.createdAt,
  });
}

/// 毎月の予算（オンオフ＋金額・最小単位）。formatVersion 9で追加。
class BackupBudget {
  final bool enabled;
  final int amountMinor;
  const BackupBudget({required this.enabled, required this.amountMinor});
}

class BackupPayload {
  final int formatVersion;
  final DateTime? exportedAt;
  final List<BackupCategory> categories;
  final List<BackupTxn> transactions;

  /// 定期ルール（formatVersion 4で追加。旧バックアップは空で復元）。
  final List<BackupRecurringRule> recurringRules;

  /// つきいちタスクと実施記録（formatVersion 5で追加。旧バックアップは空で復元）。
  final List<BackupChoreTask> choreTasks;
  final List<BackupChoreRecord> choreRecords;

  /// 分割払いの計画（formatVersion 8で追加。旧バックアップは空で復元）。
  final List<BackupInstallmentPlan> installmentPlans;

  /// 分割払いカードのプリセット（formatVersion 9で追加。SharedPreferences由来）。
  /// null = v8以前のバックアップで「未収録」。復元時は端末の登録カードを変更しない。
  /// 非null（空含む）= 収録済み。復元時はその内容で置換する。
  final List<InstallmentCard>? installmentCards;

  /// 買い物メモ（formatVersion 9で追加。SharedPreferences由来）。
  /// null = 未収録（v8以前）。復元時は端末のメモを変更しない。
  final String? shoppingMemo;

  /// 毎月の予算（formatVersion 9で追加。SharedPreferences由来）。
  /// null = 未収録（v8以前）。復元時は端末の予算設定を変更しない。
  final BackupBudget? budget;
  const BackupPayload({
    required this.formatVersion,
    required this.exportedAt,
    required this.categories,
    required this.transactions,
    this.recurringRules = const [],
    this.choreTasks = const [],
    this.choreRecords = const [],
    this.installmentPlans = const [],
    this.installmentCards,
    this.shoppingMemo,
    this.budget,
  });
}
