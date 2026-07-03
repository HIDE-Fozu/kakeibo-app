import '../data/db/daos.dart' show CategorySpendRow;
import '../data/db/enums.dart';
import 'entities.dart';

abstract interface class TransactionRepository {
  Future<int> add(TransactionEntity tx);
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);

  /// 既存取引を更新する（tx.id 必須）。updatedAt は実装が更新し、source は不変。
  Future<void> update(TransactionEntity tx);
}

abstract interface class CategoryRepository {
  Future<List<CategoryEntity>> active();
  Stream<List<CategoryEntity>> watchAll();
  Future<void> archive(int categoryId);

  /// 取引が紐づく型変更は集計desyncを招くため [CategoryInUseError] を投げる。
  Future<void> changeType(int categoryId, CategoryType type);
}
