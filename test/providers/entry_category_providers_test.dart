import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_category_providers.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
  });

  Future<int> idOf(String name) async {
    final cats = await waitForData(c, allCategoriesProvider);
    return cats.firstWhere((x) => x.name == name).id;
  }

  Future<void> spend(int catId, CivilDate date) =>
      c.read(transactionRepositoryProvider).add(TransactionEntity(
          type: TxnType.expense,
          amountYen: 100,
          date: date,
          categoryId: catId,
          source: TxnSource.manual));

  test('グリッドは親のみ（内訳の外食は出ない・食費は出る）', () async {
    final grid =
        await waitForData(c, entryCategoriesProvider(TxnType.expense));
    expect(grid.any((x) => x.name == '食費'), isTrue);
    expect(grid.any((x) => x.name == '外食'), isFalse);
    expect(grid.every((x) => x.parentId == null), isTrue);
  });

  test('内訳の利用実績は親の「最近使った」に効く', () async {
    final eatOut = await idOf('外食');
    final daily = await idOf('日用品');
    await spend(daily, const CivilDate(2026, 7, 1));
    await spend(eatOut, const CivilDate(2026, 7, 10)); // 内訳の方が新しい
    // autoDispose対策: 購読を保持し、watchエッジ経由で categoryLastUsedProvider を生かす。
    final sub = c.listen(entryCategoriesProvider(TxnType.expense), (_, _) {});
    addTearDown(sub.close);
    final lastUsed = await waitForData(c, categoryLastUsedProvider);
    expect(lastUsed[eatOut], const CivilDate(2026, 7, 10)); // 前提確認（空振り防止）
    final grid = c.read(entryCategoriesProvider(TxnType.expense)).value!;
    final foodIdx = grid.indexWhere((x) => x.name == '食費');
    final dailyIdx = grid.indexWhere((x) => x.name == '日用品');
    expect(foodIdx, lessThan(dailyIdx)); // 食費（外食経由7/10）が日用品（7/1）より先
  });

  test('entrySubcategoriesProvider: 親の内訳をsortOrder順・アーカイブ除外', () async {
    final food = await idOf('食費');
    final repo = c.read(categoryRepositoryProvider);
    final superId = await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: food);
    await repo.setArchived(superId, true);
    await pumpEventQueue(); // drift streamの再emitを待つ
    final subs = c.read(entrySubcategoriesProvider(food)).value!;
    expect(subs.map((s) => s.name).toList(), ['外食']); // アーカイブは出ない
  });
}
