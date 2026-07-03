import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';

final categoryLastUsedProvider = StreamProvider.autoDispose<Map<int, CivilDate>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchLastUsedByCategory(),
);

/// 高速入力のカテゴリグリッド: 最近使った順 → sortOrder順（spec §5.2）
final entryCategoriesProvider = Provider.autoDispose
    .family<AsyncValue<List<CategoryEntity>>, TxnType>((ref, type) {
  final lastUsed =
      ref.watch(categoryLastUsedProvider).valueOrNull ?? const <int, CivilDate>{};
  return ref.watch(allCategoriesProvider).whenData((all) {
    final wanted = categoryTypeOf(type);
    final list = all
        .where((c) => !c.isArchived && !c.isSystem && c.type == wanted)
        .toList();
    list.sort((a, b) {
      final ua = lastUsed[a.id];
      final ub = lastUsed[b.id];
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
