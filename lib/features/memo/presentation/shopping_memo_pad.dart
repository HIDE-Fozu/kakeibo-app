import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/shopping_memo_controller.dart';

/// 日別カードの「メモ」タブの中身: 買い物メモ（家計簿の入力とは無関係）。
/// タブ内は表示専用で、タップすると全画面の編集ページを開く。
/// （カレンダー画面は固定レイアウトのため、この画面上でキーボードを開くと
/// 縦に溢れる。不透過ルートなら背後はレイアウトされないので安全。）
class ShoppingMemoPad extends ConsumerWidget {
  const ShoppingMemoPad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = ref.watch(shoppingMemoProvider);
    final l = AppLocalizations.of(context);
    return InkWell(
      key: const Key('shopping-memo-pad'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ShoppingMemoEditorPage())),
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Text(
            memo.isEmpty ? l.shoppingMemoHint : memo,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: memo.isEmpty ? kMuted : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 全画面のメモ編集ページ。入力のたびに保存するので、どの閉じ方でも内容は残る。
class ShoppingMemoEditorPage extends ConsumerStatefulWidget {
  const ShoppingMemoEditorPage({super.key});

  @override
  ConsumerState<ShoppingMemoEditorPage> createState() =>
      _ShoppingMemoEditorPageState();
}

class _ShoppingMemoEditorPageState
    extends ConsumerState<ShoppingMemoEditorPage> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: ref.read(shoppingMemoProvider));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.calendarMemoTab),
        actions: [
          TextButton(
            key: const Key('shopping-memo-done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.commonDone),
          ),
        ],
      ),
      body: SafeArea(
        child: TextField(
          key: const Key('shopping-memo-field'),
          controller: _text,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 15, height: 1.6),
          decoration: InputDecoration(
            hintText: l.shoppingMemoHint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          ),
          onChanged: (v) => ref.read(shoppingMemoProvider.notifier).save(v),
        ),
      ),
    );
  }
}
