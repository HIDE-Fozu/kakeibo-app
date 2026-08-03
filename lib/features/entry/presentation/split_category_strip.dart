import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/category_emoji.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/category_manage_page.dart';
import '../application/entry_category_providers.dart';
import '../application/entry_form_controller.dart';
import 'category_grid.dart';

/// 分割中のカテゴリ帯（通常グリッドと同じ位置・同じタイルサイズの1行横スクロール）。
/// 分割中は常設で、タップはアクティブ行（編集中の行）への割当になる。
/// 親（内訳あり）をタップ→親を割当てつつ帯が内訳タイルに切り替わり、
/// leaf/内訳タイルの確定で親一覧表示に戻る（expandedParentId=null）。
class SplitCategoryStrip extends ConsumerWidget {
  const SplitCategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryFormControllerProvider);
    if (state == null || state.splits == null) {
      return const SizedBox.shrink();
    }
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final line = state.splits![state.activeSplitIndex];
    final parentId = state.expandedParentId;

    // グリッドと同じ「選択中グループ」表示: 内訳選択中は親タイルを点灯し
    // ラベルを内訳名に置き換える（食費→外食）。
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final byId = {for (final c in all) c.id: c};
    final selected = line.categoryId == null ? null : byId[line.categoryId];
    final selectedGroupId = selected?.parentId ?? selected?.id;

    final List<Widget> tiles;
    if (parentId != null) {
      // 内訳タイル表示（親を選んだ直後）。「‹」で親一覧へ戻れる。
      final subs =
          ref.watch(entrySubcategoriesProvider(parentId)).valueOrNull ??
          const <CategoryEntity>[];
      tiles = [
        _actionTile(
          scheme,
          key: const Key('strip-back'),
          width: 36,
          onTap: ctrl.collapseSplitSubcategories,
          child: Icon(
            Icons.chevron_left,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ),
        for (final s in subs)
          _catTile(
            key: Key('strip-cat-${s.id}'),
            emoji: categoryEmoji(s.icon, s.slug),
            label: s.name,
            selected: line.categoryId == s.id,
            hasSubs: false,
            onTap: () => ctrl.toggleSubcategory(s.id),
          ),
      ];
    } else {
      final cats =
          ref.watch(entryCategoriesProvider(state.type)).valueOrNull ??
          const <CategoryEntity>[];
      tiles = [
        for (final c in cats)
          _catTile(
            key: Key('strip-cat-${c.id}'),
            emoji: categoryEmoji(c.icon, c.slug),
            label: (c.id == selectedGroupId && selected?.parentId != null)
                ? selected!.name
                : c.name,
            selected: c.id == selectedGroupId,
            hasSubs:
                (ref.watch(entrySubcategoriesProvider(c.id)).valueOrNull ??
                        const <CategoryEntity>[])
                    .isNotEmpty,
            onTap: () {
              final subs =
                  ref.read(entrySubcategoriesProvider(c.id)).valueOrNull ??
                  const <CategoryEntity>[];
              ctrl.tapCategory(
                categoryId: c.id,
                hasSubs: subs.isNotEmpty,
                isSameGroup: false,
              );
            },
          ),
        // 末尾に「カテゴリを追加」（グリッドの追加タイルと同じ見た目）。
        _actionTile(
          scheme,
          key: const Key('strip-add-category'),
          onTap: () => showCategoryAddDialog(
            context,
            ref,
            type: categoryTypeOf(state.type),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: scheme.onSurfaceVariant),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  AppLocalizations.of(context).categoryAddTitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // タイル幅は通常グリッドと同じ計算（4つ見え＋続きが覗く）。高さも同じ56。
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileW = CatGridMetrics.fit(constraints.maxWidth).tileW;
          return SizedBox(
            height: kCatTileH,
            child: SingleChildScrollView(
              key: const Key('split-cat-strip'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in tiles)
                    Padding(
                      padding: const EdgeInsets.only(right: kCatGap),
                      child: SizedBox(
                        // 戻るタイルだけ幅指定（狭い）。他はグリッドと同じ幅。
                        width: (t is _SizedAction ? t.width : null) ?? tileW,
                        height: kCatTileH,
                        child: t,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _catTile({
    required Key key,
    required String emoji,
    required String label,
    required bool selected,
    required bool hasSubs,
    required VoidCallback onTap,
  }) => InkWell(
    key: key,
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: CategoryTileBox(
      emoji: emoji,
      label: label,
      selected: selected,
      hasSubs: hasSubs,
    ),
  );

  /// 枠線だけのアクションタイル（‹戻る／カテゴリを追加）。
  Widget _actionTile(
    ColorScheme scheme, {
    required Key key,
    required VoidCallback onTap,
    required Widget child,
    double? width,
  }) => _SizedAction(
    width: width,
    child: InkWell(
      key: key,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Center(child: child),
      ),
    ),
  );
}

/// アクションタイルの幅指定を親のRowへ伝えるための薄いラッパ。
class _SizedAction extends StatelessWidget {
  final double? width;
  final Widget child;
  const _SizedAction({required this.width, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
