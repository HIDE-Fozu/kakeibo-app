import '../data/db/daos.dart' show CategorySpendRow;
import '../data/db/enums.dart';
import 'entities.dart';

abstract interface class TransactionRepository {
  Future<int> add(TransactionEntity tx);
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);
}

abstract interface class CategoryRepository {
  Future<List<CategoryEntity>> active();
  Future<void> archive(int categoryId);

  /// 取引が紐づく型変更は集計desyncを招くため [CategoryInUseError] を投げる。
  Future<void> changeType(int categoryId, CategoryType type);
}
