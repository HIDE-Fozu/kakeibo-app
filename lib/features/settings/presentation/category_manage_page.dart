import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリ管理'),
        actions: [
          IconButton(
            key: const Key('add-category'),
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '支出'), Tab(text: '収入')],
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

  /// category == null なら追加、非nullなら改名。
  Future<void> _showEditDialog({CategoryEntity? category}) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CategoryEditDialog(category: category),
    );
    if (result == null) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (category == null) {
      await repo.addCategory(
        name: result.$1,
        type: _currentType,
        icon: result.$2.trim().isEmpty ? null : result.$2.trim(),
      );
    } else {
      await repo.rename(category.id, result.$1);
    }
  }
}

/// controllerの寿命をダイアログ自身に閉じ込める（popアニメーション中のdispose事故防止）
class _CategoryEditDialog extends StatefulWidget {
  final CategoryEntity? category;
  const _CategoryEditDialog({required this.category});

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
    final isNew = widget.category == null;
    return AlertDialog(
      title: Text(isNew ? 'カテゴリを追加' : 'カテゴリを改名'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('category-name-field'),
            controller: _name,
            decoration: const InputDecoration(labelText: '名前'),
          ),
          if (isNew)
            TextField(
              key: const Key('category-icon-field'),
              controller: _icon,
              decoration:
                  const InputDecoration(labelText: 'アイコン（絵文字・任意）'),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(context, (_name.text, _icon.text));
          },
          child: Text(isNew ? '追加' : '保存'),
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
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    // 暫定: 親のみ表示（reorderのスコープ検証対応）。内訳の└表示はPhase 4.5
    // カテゴリ管理タスクで全面書き換え時に実装する。
    final active = all
        .where((c) =>
            c.type == type && !c.isSystem && !c.isArchived && c.parentId == null)
        .toList();
    final archived = all
        .where((c) => c.type == type && !c.isSystem && c.isArchived)
        .toList();
    final repo = ref.read(categoryRepositoryProvider);
    final pageState =
        context.findAncestorStateOfType<_CategoryManagePageState>()!;

    return Column(
      children: [
        Expanded(
          child: ReorderableListView(
            // onReorderItem: newIndexは「除去後」の調整済みインデックス
            onReorderItem: (oldIndex, newIndex) async {
              final ids = active.map((c) => c.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await repo.reorder(ids);
            },
            children: [
              for (final c in active)
                ListTile(
                  key: ValueKey('cat-${c.id}'),
                  leading:
                      Text(c.icon ?? '📁', style: const TextStyle(fontSize: 20)),
                  title: Text(c.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('rename-${c.id}'),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            pageState._showEditDialog(category: c),
                      ),
                      IconButton(
                        key: Key('archive-${c.id}'),
                        icon: const Icon(Icons.archive_outlined),
                        onPressed: () => repo.setArchived(c.id, true),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (archived.isNotEmpty)
          ExpansionTile(
            title: const Text('アーカイブ済み'),
            children: [
              for (final c in archived)
                ListTile(
                  leading:
                      Text(c.icon ?? '📁', style: const TextStyle(fontSize: 20)),
                  title: Text('${c.name}（アーカイブ）'),
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
