import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/daos.dart' show CategorySpendRow;
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/recurring_schedule.dart';
import '../../chores/application/chore_providers.dart';

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

/// カレンダーセル用: 日別の収入合計（収入のみ、月streamからの派生）。
/// セルは支出だけの仕様だったが、モック（+27万の緑）に合わせて収入も出す
/// （FB 2026-08-21「収入が反映されてない」）。
final dayIncomeTotalsProvider = Provider.autoDispose
    .family<AsyncValue<Map<CivilDate, int>>, (int, int)>(
  (ref, key) => ref.watch(monthTransactionsProvider(key)).whenData((txs) {
    final map = <CivilDate, int>{};
    for (final t in txs) {
      if (t.type != TxnType.income) continue;
      map[t.date] = (map[t.date] ?? 0) + t.amountYen;
    }
    return map;
  }),
);

/// (year, month) 月内の「まだ起票されていない固定費・収入の予定」（ゴースト）。
/// 実取引と混ざらない別レーン。カレンダー・日パネル・毎月タブで共用する。
final monthGhostsProvider = Provider.autoDispose
    .family<List<({CivilDate date, RecurringRuleEntity rule})>, (int, int)>(
        (ref, key) {
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];
  final today = ref.watch(choreTodayProvider);
  return upcomingOccurrencesInMonth(
    rules: rules,
    ym: key.$1 * 100 + key.$2,
    today: today,
  );
});

/// カレンダーセル用: 日別のゴースト（予定）金額の符号付き合計。
/// 支出はマイナス・収入はプラス（実績の dayExpenseTotals とはレーンを分ける）。
final dayGhostTotalsProvider =
    Provider.autoDispose.family<Map<CivilDate, int>, (int, int)>((ref, key) {
  final ghosts = ref.watch(monthGhostsProvider(key));
  final map = <CivilDate, int>{};
  for (final g in ghosts) {
    final signed = g.rule.type == TxnType.income
        ? g.rule.amountMinor
        : -g.rule.amountMinor;
    map[g.date] = (map[g.date] ?? 0) + signed;
  }
  return map;
});

/// 見込み収支（実績差引 + 基準日までの予定）。過去月は null（非表示）。
final monthForecastProvider = Provider.autoDispose.family<
    ({int forecast, CivilDate anchor, bool anchorIsMonthEnd})?,
    (int, int)>((ref, key) {
  final summary = ref.watch(monthSummaryProvider(key)).valueOrNull;
  if (summary == null) return null; // 読込中は出さない（ちらつき防止）
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];
  return monthForecast(
    year: key.$1,
    month: key.$2,
    actualNet: summary.net,
    rules: rules,
    today: ref.watch(choreTodayProvider),
    anchorDay: 0, // 常に月末（基準日切り替えは「不要」FB 2026-08-20で撤去）
  );
});
