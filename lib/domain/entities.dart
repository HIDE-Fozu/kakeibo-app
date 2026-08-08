import 'money/civil_date.dart';
import '../data/db/enums.dart';

class TransactionEntity {
  final int? id;
  final TxnType type;
  final int amountYen; // 非負
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? storeName; // 店舗名。v4でmemoから分離。null=未設定
  final String? memo; // 自由記述の詳細メモ（店名は含めない）
  final TxnSource source;
  final String? imagePath; // §14-C: 保持設定ON時のみ非null
  final String? splitGroupId; // 同じレシート（詳細入力）由来の取引を束ねる。null=単独

  const TransactionEntity({
    this.id,
    required this.type,
    required this.amountYen,
    required this.date,
    required this.categoryId,
    this.paymentMethod,
    this.storeName,
    this.memo,
    required this.source,
    this.imagePath,
    this.splitGroupId,
  });
}

/// 毎月の固定費・収入のルール。期日が来ると通常の取引として起票される。
/// 月（startYm/endYm/lastGeneratedYm）は YYYY*100+MM の整数
/// （recurring_schedule.dart の ymOf と同形式）。
class RecurringRuleEntity {
  final int? id;
  final TxnType type;
  final int amountMinor; // 整数minor unit・非負
  final int categoryId;
  final int dayOfMonth; // 1..31（短い月は末日に丸めて起票）
  final String? storeName;
  final String? memo;
  final bool isActive; // false=一時停止（起票しない）
  final int startYm;
  final int? endYm; // 両端含む。null=無期限
  final int? lastGeneratedYm; // null=未起票

  const RecurringRuleEntity({
    this.id,
    required this.type,
    required this.amountMinor,
    required this.categoryId,
    required this.dayOfMonth,
    this.storeName,
    this.memo,
    this.isActive = true,
    required this.startYm,
    this.endYm,
    this.lastGeneratedYm,
  });
}

/// つきいちタスク（低頻度の家事。ハブラシ交換・マットレス干し等）。
/// 次回期日 = 最後にやった月の翌月の毎月N日（記録が無ければ anchorDate 以降で最初のN日）。
class ChoreTask {
  final int id;
  final String name;
  final String emoji;
  final int dayOfMonth; // 毎月の予定日 1..31（フォームで保証・短い月は月末丸め）
  final CivilDate anchorDate; // 作成日。記録が無い間の初回期日の基準
  final bool archived;

  const ChoreTask({
    required this.id,
    required this.name,
    required this.emoji,
    required this.dayOfMonth,
    required this.anchorDate,
    required this.archived,
  });
}

/// つきいちタスクの「やった」記録1件。
class ChoreRecord {
  final int id;
  final int taskId;
  final CivilDate doneDate;
  final String memo;
  final DateTime createdAt;

  const ChoreRecord({
    required this.id,
    required this.taskId,
    required this.doneDate,
    required this.memo,
    required this.createdAt,
  });
}

/// ある基準日時点でのタスクの期日状況。
class ChoreStatus {
  final ChoreTask task;
  final CivilDate due;
  final int daysLeft;

  const ChoreStatus({
    required this.task,
    required this.due,
    required this.daysLeft,
  });

  /// 残り日数が負＝期日超過。
  bool get isOverdue => daysLeft < 0;
}

/// 月カレンダー1日分の家事ドット情報。
class ChoreDayMarks {
  final List<int> doneTaskIds;
  final List<int> dueTaskIds;
  final bool hasOverdue;

  const ChoreDayMarks({
    required this.doneTaskIds,
    required this.dueTaskIds,
    required this.hasOverdue,
  });
}

class MonthlySummary {
  final int income;
  final int expense;
  const MonthlySummary({required this.income, required this.expense});
  int get net => income - expense;
}

class CategoryEntity {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;
  final int? parentId; // 非null=内訳（階層は2段まで）

  /// 安定キー（シードカテゴリのみ非null）。絵文字・自動税率の結び付け先。
  final String? slug;
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    this.parentId,
    this.slug,
  });
}
