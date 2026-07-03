import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/spending_rollup.dart';
import '../../calendar/application/calendar_providers.dart';

/// 月次のカテゴリ別支出を親カテゴリへロールアップ（内訳込み・降順）。
final monthSpendingRollupProvider = Provider.autoDispose
    .family<AsyncValue<List<CategorySpendGroup>>, (int, int)>((ref, key) {
  final List<CategoryEntity>? cats =
      ref.watch(allCategoriesProvider).valueOrNull;
  if (cats == null) {
    return const AsyncValue<List<CategorySpendGroup>>.loading();
  }
  return ref
      .watch(monthSpendingProvider(key))
      .whenData((rows) => rollupSpending(rows, cats));
});
