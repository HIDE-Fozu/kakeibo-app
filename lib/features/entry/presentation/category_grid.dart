import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

class CategoryGrid extends ConsumerWidget {
  final TxnType type;
  final int? selectedId; // 保存されるid（親 or 内訳）
  final void Function({
    required int categoryId,
    required bool hasSubs,
    required bool isSameGroup,
  }) onTapCategory;

  const CategoryGrid({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(entryCategoriesProvider(type)).valueOrNull ?? const [];
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final byId = {for (final c in all) c.id: c};
    // 選択が内訳ならその親がグリッド上の「選択中」タイル
    final selected = selectedId == null ? null : byId[selectedId];
    final selectedGroupId = selected?.parentId ?? selected?.id;
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.4,
      children: [
        for (final c in cats)
          _tile(
            context,
            ref,
            c,
            scheme,
            isSelectedGroup: c.id == selectedGroupId,
            // 内訳選択中は親タイルのラベルが内訳名に変わる（食費→外食）
            selectedSubName: (c.id == selectedGroupId &&
                    selected != null &&
                    selected.parentId != null)
                ? selected.name
                : null,
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, CategoryEntity c,
      ColorScheme scheme,
      {required bool isSelectedGroup, required String? selectedSubName}) {
    final subs = ref.watch(entrySubcategoriesProvider(c.id)).valueOrNull ??
        const <CategoryEntity>[];
    final hasSubs = subs.isNotEmpty;
    final label = selectedSubName ?? c.name;
    return InkWell(
      key: Key('cat-tile-${c.id}'),
      onTap: () => onTapCategory(
          categoryId: c.id, hasSubs: hasSubs, isSameGroup: isSelectedGroup),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelectedGroup
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          border: isSelectedGroup
              ? Border.all(color: scheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(c.icon ?? '📁', style: const TextStyle(fontSize: 18)),
            Text(hasSubs ? '$label ▾' : label,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
