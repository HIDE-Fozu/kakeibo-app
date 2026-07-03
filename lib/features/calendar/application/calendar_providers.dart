import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/daos.dart' show CategorySpendRow;
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';

class SelectedDay extends AutoDisposeNotifier<CivilDate> {
  @override
  CivilDate build() => ref.watch(clockProvider)();

  void select(CivilDate day) => state = day;
}

final selectedDayProvider =
    NotifierProvider.autoDispose<SelectedDay, CivilDate>(SelectedDay.new);

class CurrentMonth extends AutoDisposeNotifier<(int, int)> {
  @override
  (int, int) build() {
    final today = ref.watch(clockProvider)();
    return (today.year, today.month);
  }

  void set(int year, int month) => state = (year, month);

  void next() {
    final (y, m) = state;
    state = m == 12 ? (y + 1, 1) : (y, m + 1);
  }

  void prev() {
    final (y, m) = state;
    state = m == 1 ? (y - 1, 12) : (y, m - 1);
  }
}

final currentMonthProvider =
    NotifierProvider.autoDispose<CurrentMonth, (int, int)>(CurrentMonth.new);

/// 月キー=(year, month)レコードのstream family。DB購読の唯一の入口
/// （日別・セル合計はここからの派生。42セル×familyの乱造をしない）。
final monthTransactionsProvider = StreamProvider.autoDispose
    .family<List<TransactionEntity>, (int, int)>((ref, key) {
  final (year, month) = key;
  return ref.watch(transactionRepositoryProvider).watchMonth(year, month);
});

final monthSummaryProvider =
    StreamProvider.autoDispose.family<MonthlySummary, (int, int)>((ref, key) {
  final (year, month) = key;
  return ref.watch(transactionRepositoryProvider).watchSummary(year, month);
});

final monthSpendingProvider = StreamProvider.autoDispose
    .family<List<CategorySpendRow>, (int, int)>((ref, key) {
  final (year, month) = key;
  return ref
      .watch(transactionRepositoryProvider)
      .watchSpendingByCategory(year, month);
});

/// 選択日の取引リスト（月streamからの派生）。
final dayTransactionsProvider = Provider.autoDispose
    .family<AsyncValue<List<TransactionEntity>>, CivilDate>(
  (ref, day) => ref
      .watch(monthTransactionsProvider((day.year, day.month)))
      .whenData((txs) => txs.where((t) => t.date == day).toList()),
);

/// カレンダーセル用: 日別の支出合計（支出のみ、月streamからの派生）。
final dayExpenseTotalsProvider = Provider.autoDispose
    .family<AsyncValue<Map<CivilDate, int>>, (int, int)>(
  (ref, key) => ref.watch(monthTransactionsProvider(key)).whenData((txs) {
    final map = <CivilDate, int>{};
    for (final t in txs) {
      if (t.type != TxnType.expense) continue;
      map[t.date] = (map[t.date] ?? 0) + t.amountYen;
    }
    return map;
  }),
);
