import '../data/db/daos.dart' show CategorySpendRow;
import 'entities.dart';

abstract interface class TransactionRepository {
  Future<int> add(TransactionEntity tx);
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);
}
