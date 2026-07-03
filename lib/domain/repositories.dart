import '../data/db/daos.dart' show CategorySpendRow;
import '../data/db/enums.dart';
import 'entities.dart';
import 'money/civil_date.dart';

abstract interface class TransactionRepository {
  Future<int> add(TransactionEntity tx);
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);

  /// 既存取引を更新する（tx.id 必須）。updatedAt は実装が更新し、source は不変。
  Future<void> update(TransactionEntity tx);

  Stream<List<TransactionEntity>> watchMonth(int year, int month);
  Stream<MonthlySummary> watchSummary(int year, int month);
  Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month);

  /// categoryId -> 最終利用日（取引date基準）。高速入力の「最近使った順」に使う。
  Stream<Map<int, CivilDate>> watchLastUsedByCategory();

  /// 冪等（存在しないIDでも例外を投げない）。
  Future<void> delete(int id);
}

abstract interface class CategoryRepository {
  Future<List<CategoryEntity>> active();
  Stream<List<CategoryEntity>> watchAll();
  Future<void> archive(int categoryId);

  /// 取引が紐づく型変更は集計desyncを招くため [CategoryInUseError] を投げる。
  Future<void> changeType(int categoryId, CategoryType type);

  /// 末尾sortOrderで追加。name.trim()が空なら [ArgumentError]。
  Future<int> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
  });

  /// isSystem行への操作は [SystemCategoryError]（rename/setArchived/reorder共通）。
  Future<void> rename(int categoryId, String name);
  Future<void> setArchived(int categoryId, bool archived);

  /// 渡した順に sortOrder = 0,1,2,... を振り直す（同一typeのアクティブ列を想定）。
  Future<void> reorder(List<int> orderedIds);
}
