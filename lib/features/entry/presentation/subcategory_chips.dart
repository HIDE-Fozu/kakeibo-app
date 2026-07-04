import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

/// 内訳チップ列（押したタイルの真上に出るオーバーレイの中身）。
/// 横スクロール1行＋右端固定の「＋」（この場で内訳を追加→そのまま選択）。
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
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    CategoryEntity? parent;
    for (final c in all) {
      if (c.id == parentId) {
        parent = c;
        break;
      }
    }
    final parentCat = parent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in subs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      // 長押しで内訳を編集（名前変更・削除）
                      child: GestureDetector(
                        onLongPress: () => _showEditSheet(context, ref, s),
                        child: ChoiceChip(
                          key: Key('sub-chip-${s.id}'),
                          label: Text(s.name),
                          selected: s.id == selectedId,
                          // 選択時は塗りを変えず、緑のチェックマークだけで表す
                          showCheckmark: true,
                          checkmarkColor: const Color(0xFF1E6B5A),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white,
                          onSelected: (_) => onToggle(s.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (parentCat != null)
            TextButton.icon(
              key: const Key('add-sub-inline'),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('追加'),
              onPressed: () => _showAddDialog(context, ref, parentCat),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, WidgetRef ref, CategoryEntity parent) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _AddSubDialog(parent: parent),
    );
    if (result == null) return;
    final id = await ref.read(categoryRepositoryProvider).addCategory(
          name: result.$1,
          type: parent.type,
          icon: result.$2.trim().isEmpty ? null : result.$2.trim(),
          parentId: parent.id,
        );
    // 追加した内訳をそのまま選択（チップ列は格納され、すぐ金額入力に戻れる）
    onToggle(id);
  }

  /// 内訳チップの長押し: 名前変更・削除。
  Future<void> _showEditSheet(
      BuildContext context, WidgetRef ref, CategoryEntity sub) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(sub.name,
                  style: Theme.of(ctx).textTheme.titleMedium),
              dense: true,
            ),
            ListTile(
              key: const Key('sub-rename'),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('名前を変更'),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              key: const Key('sub-delete'),
              leading: const Icon(Icons.delete_outline),
              title: const Text('削除'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (action == 'rename') {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _RenameSubDialog(initial: sub.name),
      );
      if (name != null && name.trim().isNotEmpty) {
        await repo.rename(sub.id, name.trim());
      }
    } else if (action == 'delete') {
      // 管理画面と同じくアーカイブで消す（取引があってもFK RESTRICTで壊れない）
      await repo.setArchived(sub.id, true);
      // 選択中の内訳を消したら親へ戻す
      if (selectedId == sub.id) onToggle(sub.id);
    }
  }
}

/// 内訳の名前変更ダイアログ（controllerの寿命をダイアログ内に閉じ込める）。
class _RenameSubDialog extends StatefulWidget {
  final String initial;
  const _RenameSubDialog({required this.initial});

  @override
  State<_RenameSubDialog> createState() => _RenameSubDialogState();
}

class _RenameSubDialogState extends State<_RenameSubDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('内訳を改名'),
      content: TextField(
        key: const Key('sub-rename-field'),
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(labelText: '名前'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('sub-rename-save'),
          onPressed: () => Navigator.pop(context, _name.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 内訳の追加ダイアログ。下部の折りたたみ「既存の内容を編集」から既存内訳の
/// 名前変更・削除もできる（追加は従来どおりpopで返して呼び出し側が選択）。
class _AddSubDialog extends ConsumerStatefulWidget {
  final CategoryEntity parent;
  const _AddSubDialog({required this.parent});

  @override
  ConsumerState<_AddSubDialog> createState() => _AddSubDialogState();
}

class _AddSubDialogState extends ConsumerState<_AddSubDialog> {
  final _name = TextEditingController();
  final _icon = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _renameSub(CategoryEntity sub) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameSubDialog(initial: sub.name),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(categoryRepositoryProvider).rename(sub.id, name.trim());
    }
  }

  // 管理画面と同じくアーカイブで消す（取引があってもFK RESTRICTで壊れない）
  Future<void> _deleteSub(CategoryEntity sub) =>
      ref.read(categoryRepositoryProvider).setArchived(sub.id, true);

  @override
  Widget build(BuildContext context) {
    final subs =
        ref.watch(entrySubcategoriesProvider(widget.parent.id)).valueOrNull ??
            const <CategoryEntity>[];
    return AlertDialog(
      title: const Text('内訳を追加'),
      // ボタンを本文内に入れ、「既存の内容を編集」を追加ボタンの下に置く
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('category-name-field'),
                controller: _name,
                decoration: const InputDecoration(labelText: '名前'),
              ),
              TextField(
                key: const Key('category-icon-field'),
                controller: _icon,
                decoration:
                    const InputDecoration(labelText: 'アイコン（絵文字・任意）'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_name.text.trim().isEmpty) return;
                      Navigator.pop(context, (_name.text, _icon.text));
                    },
                    child: const Text('追加'),
                  ),
                ],
              ),
              if (subs.isNotEmpty) ...[
                const Divider(),
                Theme(
                  // ExpansionTileの上下線を消して素朴に
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: const Key('edit-existing-subs'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: const Text('既存の内容を編集'),
                    children: [
                      for (final s in subs)
                        ListTile(
                          key: Key('edit-sub-${s.id}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('edit-sub-rename-${s.id}'),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: '名前を変更',
                                onPressed: () => _renameSub(s),
                              ),
                              IconButton(
                                key: Key('edit-sub-delete-${s.id}'),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: '削除',
                                onPressed: () => _deleteSub(s),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
