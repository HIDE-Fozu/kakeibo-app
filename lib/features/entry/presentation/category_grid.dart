import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/category_emoji.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

class CategoryGrid extends ConsumerStatefulWidget {
  final TxnType type;
  final int? selectedId; // 保存されるid（親 or 内訳）
  final void Function({
    required int categoryId,
    required bool hasSubs,
    required bool isSameGroup,
  })
  onTapCategory;

  const CategoryGrid({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onTapCategory,
  });

  @override
  ConsumerState<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends ConsumerState<CategoryGrid> {
  final _scroll = ScrollController();
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateCanScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateCanScroll() {
    if (!_scroll.hasClients) return;
    final can = _scroll.offset < _scroll.position.maxScrollExtent - 1;
    if (can != _canScrollRight) setState(() => _canScrollRight = can);
  }

  void _scrollRight() {
    if (!_scroll.hasClients) return;
    final page = _scroll.position.viewportDimension * 0.8;
    _scroll.animateTo(
      (_scroll.offset + page).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats =
        ref.watch(entryCategoriesProvider(widget.type)).valueOrNull ?? const [];
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final byId = {for (final c in all) c.id: c};
    // 選択が内訳ならその親がグリッド上の「選択中」タイル
    final selected = widget.selectedId == null ? null : byId[widget.selectedId];
    final selectedGroupId = selected?.parentId ?? selected?.id;
    final scheme = Theme.of(context).colorScheme;
    // レイアウト確定後に右送り可否を反映（型切替でカテゴリ数が変わるため毎build）
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanScroll());
    // 1画面に収めるため2段の横スクロール（タイルの見た目・大きさは従来のまま）。
    // 右端は「続きが右にある」ことを示す細身の右送りボタン（終端で無効化）
    return SizedBox(
      height: 132,
      child: Row(
        children: [
          Expanded(
            child: GridView.count(
              controller: _scroll,
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
                    c,
                    scheme,
                    isSelectedGroup: c.id == selectedGroupId,
                    // 内訳選択中は親タイルのラベルが内訳名に変わる（食費→外食）
                    selectedSubName:
                        (c.id == selectedGroupId &&
                            selected != null &&
                            selected.parentId != null)
                        ? selected.name
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            key: const Key('cat-scroll-right'),
            onTap: _canScrollRight ? _scrollRight : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: scheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: _canScrollRight
                    ? scheme.onSurfaceVariant
                    : scheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    CategoryEntity c,
    ColorScheme scheme, {
    required bool isSelectedGroup,
    required String? selectedSubName,
  }) {
    final subs =
        ref.watch(entrySubcategoriesProvider(c.id)).valueOrNull ??
        const <CategoryEntity>[];
    final hasSubs = subs.isNotEmpty;
    final label = selectedSubName ?? c.name;
    return InkWell(
      key: Key('cat-tile-${c.id}'),
      onTap: () => widget.onTapCategory(
        categoryId: c.id,
        hasSubs: hasSubs,
        isSameGroup: isSelectedGroup,
      ),
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
            Text(
              categoryEmoji(c.icon, c.name),
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              hasSubs ? '$label ▾' : label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
