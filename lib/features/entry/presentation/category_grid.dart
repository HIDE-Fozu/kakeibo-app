import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

/// プリセットカテゴリのMaterialアイコン（表示のみ。DBは触らない）。
/// ユーザーがカテゴリ管理でicon（絵文字）を設定していればそちらを優先する。
const _presetIcons = <String, IconData>{
  '食費': Icons.restaurant,
  '日用品': Icons.shopping_basket,
  '水道光熱費': Icons.lightbulb,
  '通信費': Icons.smartphone,
  '交通費': Icons.train,
  '交際費': Icons.local_bar,
  '趣味・娯楽': Icons.sports_esports,
  '衣服・美容': Icons.checkroom,
  '医療・健康': Icons.medical_services,
  '住居': Icons.home,
  '教育': Icons.school,
  '特別費': Icons.card_giftcard,
  'その他': Icons.more_horiz,
  '給与': Icons.payments,
  '賞与': Icons.celebration,
  '副収入': Icons.work,
  '未分類': Icons.help_outline,
};

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
    // 1画面に収めるため2段の横スクロール（タイルの見た目・大きさは従来のまま）
    return SizedBox(
      height: 132,
      child: GridView.count(
        scrollDirection: Axis.horizontal,
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        // 横グリッドでは cross(高さ64)/main(幅88) の比
        childAspectRatio: 64 / 88,
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
      ),
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
            if (c.icon != null)
              Text(c.icon!, style: const TextStyle(fontSize: 18))
            else
              Icon(_presetIcons[c.name] ?? Icons.category,
                  size: 20, color: scheme.onSurfaceVariant),
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
