import '../../data/db/daos.dart' show CategorySpendRow;
import '../entities.dart';

/// サマリ用: 内訳ごとの支出。
class SubSpend {
  final int categoryId;
  final String name;
  final bool isArchived;
  final int total;
  const SubSpend({
    required this.categoryId,
    required this.name,
    required this.isArchived,
    required this.total,
  });
}

/// サマリ用: 親カテゴリ単位のロールアップ結果。
class CategorySpendGroup {
  final int categoryId;
  final String name;
  final bool isArchived;
  final int total; // directTotal + 内訳合計
  final int directTotal; // 親カテゴリへの直接計上分（UIでは「（内訳なし）」）
  final List<SubSpend> subs; // 金額降順
  const CategorySpendGroup({
    required this.categoryId,
    required this.name,
    required this.isArchived,
    required this.total,
    required this.directTotal,
    required this.subs,
  });
  bool get hasSubs => subs.isNotEmpty;
}

/// カテゴリ別支出行（parentId付き）を親カテゴリ単位にまとめる。
/// - グループは合計の降順、subsも降順
/// - 直接計上のない親（内訳にだけ支出がある）もグループとして現れる。
///   その名前/isArchivedは categories から引く
/// - 防御: parentIdがcategoriesに解決できない行は自分自身を親として扱う
List<CategorySpendGroup> rollupSpending(
    List<CategorySpendRow> rows, List<CategoryEntity> categories) {
  final catById = {for (final c in categories) c.id: c};
  final direct = <int, int>{};
  final subRows = <int, List<CategorySpendRow>>{};
  for (final r in rows) {
    final p = r.parentId;
    if (p == null || !catById.containsKey(p)) {
      direct[r.categoryId] = (direct[r.categoryId] ?? 0) + r.total;
    } else {
      subRows.putIfAbsent(p, () => []).add(r);
    }
  }
  final selfRowById = {for (final r in rows) r.categoryId: r};
  final groups = <CategorySpendGroup>[];
  for (final id in {...direct.keys, ...subRows.keys}) {
    final subs = [
      for (final r in subRows[id] ?? const <CategorySpendRow>[])
        SubSpend(
          categoryId: r.categoryId,
          name: r.categoryName,
          isArchived: r.isArchived,
          total: r.total,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    final subTotal = subs.fold<int>(0, (a, s) => a + s.total);
    final d = direct[id] ?? 0;
    final cat = catById[id];
    final selfRow = selfRowById[id];
    groups.add(CategorySpendGroup(
      categoryId: id,
      name: cat?.name ?? selfRow?.categoryName ?? '不明',
      isArchived: cat?.isArchived ?? selfRow?.isArchived ?? false,
      total: d + subTotal,
      directTotal: d,
      subs: subs,
    ));
  }
  groups.sort((a, b) => b.total.compareTo(a.total));
  return groups;
}
