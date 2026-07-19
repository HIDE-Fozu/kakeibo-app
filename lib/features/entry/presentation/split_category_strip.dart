import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_emoji.dart';
import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';
import '../application/entry_form_controller.dart';

/// 分割中のカテゴリ帯（電卓の上・1行・絵文字チップ横スクロール）。
/// 常設せず、行の「カテゴリを追加」/選択済みチップを押した時だけ出す。
/// 親（内訳あり）をタップ→親を割当てつつ帯が内訳チップに切り替わる。
/// leaf/内訳チップの確定でcontrollerが帯を閉じる（splitCatPickerOpen=false）。
class SplitCategoryStrip extends ConsumerWidget {
  const SplitCategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryFormControllerProvider);
    if (state == null || state.splits == null || !state.splitCatPickerOpen) {
      return const SizedBox.shrink();
    }
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final line = state.splits![state.activeSplitIndex];
    final parentId = state.expandedParentId;

    Widget chip(String label, bool selected, VoidCallback onTap, {Key? key}) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.2)
                  : scheme.surface,
              border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? scheme.primary : scheme.onSurface)),
          ),
        ),
      );
    }

    final List<Widget> chips;
    if (parentId != null) {
      // 内訳チップ表示（親を選んだ直後）。「‹」で親一覧へ戻れる。
      final subs = ref.watch(entrySubcategoriesProvider(parentId)).valueOrNull ??
          const <CategoryEntity>[];
      chips = [
        chip('‹', false, ctrl.collapseSplitSubcategories,
            key: const Key('strip-back')),
        for (final s in subs)
          chip('${categoryEmoji(s.icon, s.name)} ${s.name}',
              line.categoryId == s.id, () => ctrl.toggleSubcategory(s.id),
              key: Key('strip-cat-${s.id}')),
      ];
    } else {
      final cats = ref.watch(entryCategoriesProvider(state.type)).valueOrNull ??
          const <CategoryEntity>[];
      chips = [
        for (final c in cats)
          chip(
            '${categoryEmoji(c.icon, c.name)} ${c.name}',
            line.categoryId == c.id,
            () {
              final subs = ref
                      .read(entrySubcategoriesProvider(c.id))
                      .valueOrNull ??
                  const <CategoryEntity>[];
              ctrl.tapCategory(
                categoryId: c.id,
                hasSubs: subs.isNotEmpty,
                isSameGroup: false,
              );
            },
            key: Key('strip-cat-${c.id}'),
          ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        key: const Key('split-cat-strip'),
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),
          InkWell(
            key: const Key('strip-close'),
            onTap: ctrl.closeSplitCatPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 17, color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
