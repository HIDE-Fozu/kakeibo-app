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
  final int? installmentPlanId; // 分割払いの計画id。null=分割払い由来ではない（v10）

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
    this.installmentPlanId,
  });
}

/// 分割払いの計画（FB 2026-08-16）。保存時に count ヶ月分の支出取引が
/// installmentPlanId で紐づいて起票される（計算は installment_calc.dart・
/// 端数は初回）。編集=取引の作り直し・削除=取引ごと削除。
class InstallmentPlanEntity {
  final int? id;
  final int principalMinor; // 購入金額（元金）
  final int count; // 支払い回数 >=1
  final double annualRatePercent; // 実質年率（%）
  final int categoryId;
  final int dayOfMonth; // 支払日 1..31（短い月は末日に丸め）
  final int startYm; // 初回の月（YYYY*100+MM）
  final String? cardName;

  const InstallmentPlanEntity({
    this.id,
    required this.principalMinor,
    required this.count,
    required this.annualRatePercent,
    required this.categoryId,
    required this.dayOfMonth,
    required this.startYm,
    this.cardName,
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
/// 次回期日は [repeatUnit] で決まる（chore_schedule.dart の nextChoreDue）:
/// monthlyDay=最後にやった月の翌月のN日 / everyDays=最後にやった日＋間隔。
class ChoreTask {
  final int id;
  final String name;
  final String emoji;
  final ChoreRepeatUnit repeatUnit;
  final int dayOfMonth; // 毎月の予定日 1..31（monthlyDay時・短い月は月末丸め）
  final int intervalDays; // 間隔 1..999（everyDays時）
  final CivilDate anchorDate; // 作成日。記録が無い間の初回期日の基準
  final bool archived;

  const ChoreTask({
    required this.id,
    required this.name,
    required this.emoji,
    this.repeatUnit = ChoreRepeatUnit.monthlyDay,
    required this.dayOfMonth,
    this.intervalDays = 30,
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

/// ごみ箱の1件（最近削除した取引）。tx.id は null（復元時に新規採番される）。
/// v11で追加（FB 2026-08-16: SnackBarのUndo撤去→設定から復元）。
class TrashEntry {
  final int id; // ごみ箱行のid（deleted_transactions.id）
  final DateTime deletedAt; // UTC
  final TransactionEntity tx;

  const TrashEntry({
    required this.id,
    required this.deletedAt,
    required this.tx,
  });
}
