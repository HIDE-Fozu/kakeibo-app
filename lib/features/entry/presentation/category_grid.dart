import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/enums.dart';
import '../application/entry_category_providers.dart';

class CategoryGrid extends ConsumerWidget {
  final TxnType type;
  final int? selectedId;
  final void Function(int categoryId) onSelect;

  const CategoryGrid({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(entryCategoriesProvider(type)).valueOrNull ?? const [];
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
          InkWell(
            onTap: () => onSelect(c.id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: c.id == selectedId
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                border: c.id == selectedId
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.icon ?? '📁', style: const TextStyle(fontSize: 18)),
                  Text(c.name,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
