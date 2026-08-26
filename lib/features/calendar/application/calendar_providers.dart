import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/daos.dart' show CategorySpendRow;
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/recurring_schedule.dart';
import '../../chores/application/chore_providers.dart';
import '../../payment/application/payment_providers.dart';
import '../../settings/application/settings_controller.dart';

class SelectedDay extends AutoDisposeNotifier<CivilDate> {
  @override
  CivilDate build() => ref.watch(clockProvider)();

  void select(CivilDate day) => state = day;
}

final selectedDayProvider =
    NotifierProvider.autoDispose<SelectedDay, CivilDate>(SelectedDay.new);

/// 日別カードのタブ。日付（取引リスト）/ つきいち / 買い物メモ。
enum DayTab { day, chores, memo }

/// 表示中のタブ。日を切り替えても維持する。
/// カード自体の高さ（daySheetExpandedProvider）とは独立に持つ：
/// 「メモと同じタブ列のつきいち・日付を押しても高さは変わらない」ため。
class DayTabState extends AutoDisposeNotifier<DayTab> {
  @override
  DayTab build() => DayTab.day;

  void select(DayTab tab) => state = tab;
}

final dayTabProvider =
    NotifierProvider.autoDispose<DayTabState, DayTab>(DayTabState.new);

/// 日別カードを上へせり上げているか（メモを書くための広い面）。
/// メモタブを開くと true。背景のカレンダーをタップすると false に戻る。
class DaySheetExpanded extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final daySheetExpandedProvider =
    NotifierProvider.autoDispose<DaySheetExpanded, bool>(DaySheetExpanded.new);

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

/// 月全体の起票済み合計（サマリタブ・見込み収支の入力用）。
/// 分割払いの将来回など未来日付の起票済み取引も含む。
/// カレンダー上部サマリはこれではなく monthToDateSummaryProvider を使う。
final monthSummaryProvider =
    StreamProvider.autoDispose.family<MonthlySummary, (int, int)>((ref, key) {
  final (year, month) = key;
  return ref.watch(transactionRepositoryProvider).watchSummary(year, month);
});

/// カレンダー上部サマリ用:「今日までの実績」合計（FB 2026-08-21「金額の計算が間違ってる」）。
///
/// 分割払いは登録時に将来回まで一括起票される一方、給料などの固定収入は
/// 期日到来時に起票される（それまではゴースト）。月全体を合計すると
/// 「未来の支出だけ差引に入る」非対称が上部サマリに露出するため、
/// 当月表示中は date <= today のみを合計する。過去月・未来月はその月全体。
/// 未来分の受け皿はセルの日別表示と見込み収支（月末）。
final monthToDateSummaryProvider = Provider.autoDispose
    .family<AsyncValue<MonthlySummary>, (int, int)>((ref, key) {
  final (year, month) = key;
  final today = ref.watch(choreTodayProvider);
  final bounded = year == today.year && month == today.month;
  // 現金主義（支払い区分モードON＋設定ON）のときだけ、カード購入を支出から
  // 外し、代わりにその月のカード引き落としを足す。二重計上を避けるため
  // 「購入か引き落としのどちらか一方」しか数えない。
  final cashBasis = ref.watch(appSettingsProvider).summaryUsesCashBasis;
  final cardTxIds = cashBasis
      ? ref.watch(cardPurchaseTxIdsOnMonthProvider(key))
      : const <int>{};
  final cardPayments =
      cashBasis ? ref.watch(cardPaymentsToDateProvider(key)) : 0;
  return ref.watch(monthTransactionsProvider(key)).whenData((txs) {
    var income = 0;
    var expense = 0;
    for (final t in txs) {
      if (bounded && t.date.isAfter(today)) continue;
      if (cashBasis && t.id != null && cardTxIds.contains(t.id)) {
        continue; // カードで買った分は引き落とし日に数える
      }
      switch (t.type) {
        case TxnType.income:
          income += t.amountYen;
        case TxnType.expense:
          expense += t.amountYen;
      }
    }
    return MonthlySummary(income: income, expense: expense + cardPayments);
  });
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
///
/// 現金主義のときは上部サマリと同じ定義に揃える: カードで買った日には
/// 金額を出さず（まだ現金は出ていない）、引き落とし日にカードの合計を出す。
/// セルと上部サマリで数字が食い違うと「計算が間違っている」に見えるため
/// （FB 2026-08-21）、定義は必ず一致させる。
final dayExpenseTotalsProvider = Provider.autoDispose
    .family<AsyncValue<Map<CivilDate, int>>, (int, int)>((ref, key) {
  final cashBasis = ref.watch(appSettingsProvider).summaryUsesCashBasis;
  final cardTxIds =
      cashBasis ? ref.watch(cardPurchaseTxIdsOnMonthProvider(key)) : const <int>{};
  final cardLines = cashBasis
      ? ref.watch(cardPaymentsProvider(key))
      : const <CardPaymentLine>[];
  return ref.watch(monthTransactionsProvider(key)).whenData((txs) {
    final map = <CivilDate, int>{};
    for (final t in txs) {
      if (t.type != TxnType.expense) continue;
      if (cashBasis && t.id != null && cardTxIds.contains(t.id)) continue;
      map[t.date] = (map[t.date] ?? 0) + t.amountYen;
    }
    for (final line in cardLines) {
      map[line.date] = (map[line.date] ?? 0) + line.amountMinor;
    }
    return map;
  });
});

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

/// 見込みの土台になる「月全体の差引」（today打ち切りなし）。
/// 現金主義ならカード購入を外し、その月の引き落としを入れる（上部サマリと同じ定義）。
final monthNetWholeProvider =
    Provider.autoDispose.family<int?, (int, int)>((ref, key) {
  final cashBasis = ref.watch(appSettingsProvider).summaryUsesCashBasis;
  if (!cashBasis) return ref.watch(monthSummaryProvider(key)).valueOrNull?.net;
  final txs = ref.watch(monthTransactionsProvider(key)).valueOrNull;
  if (txs == null) return null;
  final cardTxIds = ref.watch(cardPurchaseTxIdsOnMonthProvider(key));
  var net = 0;
  for (final t in txs) {
    if (t.id != null && cardTxIds.contains(t.id)) continue;
    net += t.type == TxnType.income ? t.amountYen : -t.amountYen;
  }
  for (final line in ref.watch(cardPaymentsProvider(key))) {
    net -= line.amountMinor;
  }
  return net;
});

/// 見込み収支（月全体の差引 + 月末までの未起票予定）。過去月は null（非表示）。
/// 月全体なので、分割払いの将来回など起票済みの未来分もここには含まれ、
/// 未起票の固定費・収入はゴースト側から足される。
/// 現金主義のときはカードの引き落としベース（monthNetWholeProvider）に揃える。
final monthForecastProvider = Provider.autoDispose.family<
    ({int forecast, CivilDate anchor, bool anchorIsMonthEnd})?,
    (int, int)>((ref, key) {
  final net = ref.watch(monthNetWholeProvider(key));
  if (net == null) return null; // 読込中は出さない（ちらつき防止）
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];
  return monthForecast(
    year: key.$1,
    month: key.$2,
    actualNet: net,
    rules: rules,
    today: ref.watch(choreTodayProvider),
    anchorDay: 0, // 常に月末（基準日切り替えは「不要」FB 2026-08-20で撤去）
  );
});
