import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';

final categoryLastUsedProvider = StreamProvider.autoDispose<Map<int, CivilDate>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchLastUsedByCategory(),
);

/// 高速入力のカテゴリグリッド: 親カテゴリのみ・最近使った順 → sortOrder順（spec §5.2）。
/// 内訳の利用実績は親の「最近使った」に取り込む（自身と内訳のmax）。
final entryCategoriesProvider = Provider.autoDispose
    .family<AsyncValue<List<CategoryEntity>>, TxnType>((ref, type) {
  final lastUsed =
      ref.watch(categoryLastUsedProvider).valueOrNull ?? const <int, CivilDate>{};
  return ref.watch(allCategoriesProvider).whenData((all) {
    final wanted = categoryTypeOf(type);
    final childToParent = {
      for (final c in all)
        if (c.parentId != null) c.id: c.parentId!,
    };
    final effectiveLastUsed = <int, CivilDate>{};
    lastUsed.forEach((id, date) {
      final target = childToParent[id] ?? id;
      final cur = effectiveLastUsed[target];
      if (cur == null || date.compareTo(cur) > 0) {
        effectiveLastUsed[target] = date;
      }
    });
    final list = all
        .where((c) =>
            c.parentId == null &&
            !c.isArchived &&
            !c.isSystem &&
            c.type == wanted)
        .toList();
    list.sort((a, b) {
      final ua = effectiveLastUsed[a.id];
      final ub = effectiveLastUsed[b.id];
      if (ua != null || ub != null) {
        if (ua == null) return 1;
        if (ub == null) return -1;
        final cmp = ub.compareTo(ua);
        if (cmp != 0) return cmp;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  });
});

/// 指定親のアクティブな内訳（sortOrder順）。チップ列とグリッドの▾判定に使う。
final entrySubcategoriesProvider = Provider.autoDispose
    .family<AsyncValue<List<CategoryEntity>>, int>((ref, parentId) =>
        ref.watch(allCategoriesProvider).whenData((all) => all
            .where((c) => c.parentId == parentId && !c.isArchived)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))));
