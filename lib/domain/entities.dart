import 'money/civil_date.dart';
import '../data/db/enums.dart';

class TransactionEntity {
  final int? id;
  final TxnType type;
  final int amountYen; // 非負
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? memo;
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
    this.memo,
    required this.source,
    this.imagePath,
    this.splitGroupId,
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
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    this.parentId,
  });
}
