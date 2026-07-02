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

  const TransactionEntity({
    this.id,
    required this.type,
    required this.amountYen,
    required this.date,
    required this.categoryId,
    this.paymentMethod,
    this.memo,
    required this.source,
  });
}

class MonthlySummary {
  final int income;
  final int expense;
  const MonthlySummary({required this.income, required this.expense});
  int get net => income - expense;
}
