import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/calendar/application/calendar_providers.dart';
import 'package:kakeibo_app/features/entry/application/entry_category_providers.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late int foodId;
  late int hobbyId;

  Future<void> addTx(int yen,
          {int day = 15, TxnType type = TxnType.expense, int? categoryId}) =>
      c.read(transactionRepositoryProvider).add(TransactionEntity(
            type: type,
            amountYen: yen,
            date: CivilDate(2026, 7, day),
            categoryId: categoryId ?? foodId,
            source: TxnSource.manual,
          ));

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
    hobbyId = cats.firstWhere((x) => x.name == '趣味・娯楽').id;
  });

  test('selectedDay/currentMonth の既定は固定時計に従う', () {
    expect(c.read(selectedDayProvider), const CivilDate(2026, 7, 15));
    expect(c.read(currentMonthProvider), (2026, 7));
  });

  test('currentMonth.next/prev は年を跨いでwrapする', () {
    final sub = c.listen(currentMonthProvider, (_, _) {});
    addTearDown(sub.close);
    final m = c.read(currentMonthProvider.notifier);
    m.set(2026, 12);
    m.next();
    expect(c.read(currentMonthProvider), (2027, 1));
    m.set(2026, 1);
    m.prev();
    expect(c.read(currentMonthProvider), (2025, 12));
  });

  test('dayTransactions は月streamから当日分だけ派生し、追加に反応する', () async {
    final sub =
        c.listen(dayTransactionsProvider(const CivilDate(2026, 7, 15)), (_, _) {});
    addTearDown(sub.close);
    await addTx(500);
    await addTx(999, day: 16);
    await pumpEventQueue();
    final list = sub.read().requireValue;
    expect(list.single.amountYen, 500);
  });

  test('monthToDateSummary: 当月は今日(7/15)まで実績のみ・未来の起票分は除外', () async {
    final sub = c.listen(monthToDateSummaryProvider((2026, 7)), (_, _) {});
    addTearDown(sub.close);
    await addTx(500, day: 14);
    await addTx(300, day: 15); // 当日は含む
    await addTx(72000, day: 27); // 分割払いの将来回相当（起票済み・未来日付）
    await addTx(270000, day: 25, type: TxnType.income); // 未来日付の収入も同様に除外
    await pumpEventQueue();
    final s = sub.read().requireValue;
    expect(s.expense, 800);
    expect(s.income, 0);
    expect(s.net, -800);
  });

  test('monthToDateSummary: 過去月・未来月はその月全体を合計する', () async {
    Future<void> at(CivilDate d, int yen) =>
        c.read(transactionRepositoryProvider).add(TransactionEntity(
              type: TxnType.expense,
              amountYen: yen,
              date: d,
              categoryId: foodId,
              source: TxnSource.manual,
            ));
    await at(const CivilDate(2026, 6, 30), 1000); // 過去月
    await at(const CivilDate(2026, 8, 20), 2000); // 未来月
    final past = c.listen(monthToDateSummaryProvider((2026, 6)), (_, _) {});
    final future = c.listen(monthToDateSummaryProvider((2026, 8)), (_, _) {});
    addTearDown(past.close);
    addTearDown(future.close);
    await pumpEventQueue();
    expect(past.read().requireValue.expense, 1000);
    expect(future.read().requireValue.expense, 2000);
  });

  test('見込み収支(月末)は未来の起票済み支出を含む（上部サマリとの役割分担）', () async {
    final sub = c.listen(monthForecastProvider((2026, 7)), (_, _) {});
    addTearDown(sub.close);
    await addTx(72000, day: 27);
    await pumpEventQueue();
    expect(sub.read()?.forecast, -72000);
  });

  test('dayExpenseTotals は支出のみを日別合計する', () async {
    final sub = c.listen(dayExpenseTotalsProvider((2026, 7)), (_, _) {});
    addTearDown(sub.close);
    await addTx(300);
    await addTx(200);
    await addTx(10000, type: TxnType.income);
    await pumpEventQueue();
    final totals = sub.read().requireValue;
    expect(totals[const CivilDate(2026, 7, 15)], 500);
  });

  test('entryCategories: type一致のみ・最終利用日降順→sortOrder順', () async {
    final sub = c.listen(entryCategoriesProvider(TxnType.expense), (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final before = sub.read().requireValue;
    expect(before.any((x) => x.isSystem), isFalse);
    expect(before.any((x) => x.type == CategoryType.income), isFalse);
    // 「趣味・娯楽」を最近使う → 先頭に来る
    await addTx(100, day: 14, categoryId: hobbyId);
    await pumpEventQueue();
    final after = sub.read().requireValue;
    expect(after.first.id, hobbyId);
  });

  test('entryCategories: アーカイブ済みは出ない', () async {
    // 食費はアクティブな内訳（外食）持ちでアーカイブガードに当たるため趣味・娯楽を使う
    await c.read(categoryRepositoryProvider).setArchived(hobbyId, true);
    final sub = c.listen(entryCategoriesProvider(TxnType.expense), (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(sub.read().requireValue.any((x) => x.id == hobbyId), isFalse);
  });
}
