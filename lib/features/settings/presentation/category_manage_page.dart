import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_emoji.dart';
import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../l10n/app_localizations.dart';

class CategoryManagePage extends ConsumerStatefulWidget {
  const CategoryManagePage({super.key});

  @override
  ConsumerState<CategoryManagePage> createState() =>
      _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  CategoryType get _currentType =>
      _tab.index == 0 ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.categoryManageTitle),
        actions: [
          IconButton(
            key: const Key('add-category'),
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [Tab(text: l.categoryTabExpense), Tab(text: l.categoryTabIncome)],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CategoryTypeList(type: CategoryType.expense),
          _CategoryTypeList(type: CategoryType.income),
        ],
      ),
    );
  }

  /// category == null なら追加（parentId非nullなら内訳追加）、非nullなら改名。
  Future<void> _showEditDialog({CategoryEntity? category, int? parentId}) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) =>
          _CategoryEditDialog(category: category, isSub: parentId != null),
    );
    if (result == null) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (category == null) {
      await repo.addCategory(
        name: result.$1,
        type: _currentType,
        icon: result.$2.trim().isEmpty ? null : result.$2.trim(),
        parentId: parentId,
      );
    } else {
      await repo.rename(category.id, result.$1);
    }
  }
}

/// カテゴリ追加ダイアログの共通入口。
/// 管理画面以外（入力グリッド/内訳帯/一括ピッカー）の「カテゴリを追加」からも呼ぶ。
Future<void> showCategoryAddDialog(
  BuildContext context,
  WidgetRef ref, {
  required CategoryType type,
}) async {
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (_) => const _CategoryEditDialog(category: null),
  );
  if (result == null) return;
  await ref.read(categoryRepositoryProvider).addCategory(
        name: result.$1,
        type: type,
        icon: result.$2.trim().isEmpty ? null : result.$2.trim(),
        parentId: null,
      );
}

/// controllerの寿命をダイアログ自身に閉じ込める（popアニメーション中のdispose事故防止）
class _CategoryEditDialog extends StatefulWidget {
  final CategoryEntity? category;
  final bool isSub;
  const _CategoryEditDialog({required this.category, this.isSub = false});

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _icon = TextEditingController(text: widget.category?.icon ?? '');

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isNew = widget.category == null;
    return AlertDialog(
      title: Text(isNew
          ? (widget.isSub ? l.categorySubAddTitle : l.categoryAddTitle)
          : (widget.category!.parentId != null
              ? l.categorySubRenameTitle
              : l.categoryRenameTitle)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('category-name-field'),
            controller: _name,
            decoration: InputDecoration(labelText: l.categoryNameFieldLabel),
          ),
          if (isNew)
            TextField(
              key: const Key('category-icon-field'),
              controller: _icon,
              decoration:
                  InputDecoration(labelText: l.categoryIconFieldLabel),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(context, (_name.text, _icon.text));
          },
          child: Text(isNew ? l.commonAdd : l.commonSave),
        ),
      ],
    );
  }
}

class _CategoryTypeList extends ConsumerWidget {
  final CategoryType type;
  const _CategoryTypeList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final ofType = all.where((c) => c.type == type && !c.isSystem).toList();
    final parents =
        ofType.where((c) => c.parentId == null && !c.isArchived).toList();
    final childrenByParent = <int, List<CategoryEntity>>{};
    for (final c in ofType.where((c) => c.parentId != null && !c.isArchived)) {
      childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
    }
    final archived = ofType.where((c) => c.isArchived).toList();
    final repo = ref.read(categoryRepositoryProvider);
    final pageState =
        context.findAncestorStateOfType<_CategoryManagePageState>()!;

    return Column(
      children: [
        Expanded(
          child: ReorderableListView(
            // 親ブロック（親行＋その内訳）ごと動かす。並べ替えは親スコープのみ。
            // onReorderItem: newIndexは「除去後」の調整済みインデックス
            onReorderItem: (oldIndex, newIndex) async {
              final ids = parents.map((c) => c.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await repo.reorder(ids);
            },
            children: [
              for (final p in parents)
                Column(
                  key: ValueKey('cat-${p.id}'),
                  children: [
                    ListTile(
                      leading: Text(categoryEmoji(p.icon, p.slug),
                          style: const TextStyle(fontSize: 20)),
                      title: Text(p.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('add-sub-${p.id}'),
                            icon: const Icon(Icons.playlist_add),
                            tooltip: l.categorySubAddTooltip,
                            onPressed: () =>
                                pageState._showEditDialog(parentId: p.id),
                          ),
                          IconButton(
                            key: Key('rename-${p.id}'),
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                pageState._showEditDialog(category: p),
                          ),
                          IconButton(
                            key: Key('archive-${p.id}'),
                            icon: const Icon(Icons.archive_outlined),
                            onPressed: () {
                              // アクティブな内訳が残る親は不可（リポジトリのガードと
                              // 二重化。ここで弾かないと非同期例外がUIに漏れる）
                              if ((childrenByParent[p.id] ?? const [])
                                  .isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            l.categoryArchiveBlockedSnackbar)));
                                return;
                              }
                              repo.setArchived(p.id, true);
                            },
                          ),
                        ],
                      ),
                    ),
                    _SubList(
                      subs: childrenByParent[p.id] ?? const [],
                      onRename: (c) => pageState._showEditDialog(category: c),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (archived.isNotEmpty)
          ExpansionTile(
            title: Text(l.categoryArchivedSectionTitle),
            children: [
              for (final c in archived)
                ListTile(
                  leading: Text(
                      c.parentId != null
                          ? '└ ${categoryEmoji(c.icon, c.slug)}'
                          : categoryEmoji(c.icon, c.slug),
                      style: const TextStyle(fontSize: 16)),
                  title: Text(l.categoryArchivedItemLabel(c.name)),
                  trailing: IconButton(
                    key: Key('unarchive-${c.id}'),
                    icon: const Icon(Icons.unarchive_outlined),
                    onPressed: () => repo.setArchived(c.id, false),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 親の下にネスト表示する内訳リスト。並べ替えは同じ親の中だけ
/// （明示ハンドルで外側のブロック並べ替えと干渉させない）。
class _SubList extends ConsumerWidget {
  final List<CategoryEntity> subs;
  final void Function(CategoryEntity) onRename;
  const _SubList({required this.subs, required this.onRename});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subs.isEmpty) return const SizedBox.shrink();
    final repo = ref.read(categoryRepositoryProvider);
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) async {
        final ids = subs.map((c) => c.id).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        await repo.reorder(ids);
      },
      children: [
        for (final (i, s) in subs.indexed)
          ListTile(
            key: ValueKey('sub-${s.id}'),
            dense: true,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: Text('└ ${categoryEmoji(s.icon, s.slug)}',
                style: const TextStyle(fontSize: 16)),
            title: Text(s.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('rename-${s.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onRename(s),
                ),
                IconButton(
                  key: Key('archive-${s.id}'),
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () => repo.setArchived(s.id, true),
                ),
                ReorderableDragStartListener(
                  key: Key('sub-drag-${s.id}'),
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
