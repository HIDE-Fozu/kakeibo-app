import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

/// 内訳チップ列（カテゴリグリッドの直上に出る・モック確定）。
/// 選択中チップの再タップは onToggle 側で親選択へ戻す。
class SubcategoryChips extends ConsumerWidget {
  final int parentId;
  final int? selectedId;
  final void Function(int subId) onToggle;

  const SubcategoryChips({
    super.key,
    required this.parentId,
    required this.selectedId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(entrySubcategoriesProvider(parentId)).valueOrNull ??
        const <CategoryEntity>[];
    if (subs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final s in subs)
            ChoiceChip(
              key: Key('sub-chip-${s.id}'),
              label: Text(s.name),
              selected: s.id == selectedId,
              onSelected: (_) => onToggle(s.id),
            ),
        ],
      ),
    );
  }
}
