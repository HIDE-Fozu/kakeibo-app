import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/shopping_memo_controller.dart';

/// 日別カードの「メモ」タブの中身: 買い物メモ（家計簿の入力とは無関係）。
///
/// **その場で1タップで書ける**（別ページへ飛ばさない・タップで画面が動かない
/// ・FB 2026-08-27）。書き始めた拍子にせり上がると入力を取りこぼすので、
/// 広げるのはタブ行の上ドラッグに任せ、ここはタップ＝編集に徹する。
/// 入力欄は**1行から始まり**、書いた行数だけ伸びる。
class ShoppingMemoPad extends ConsumerStatefulWidget {
  const ShoppingMemoPad({super.key});

  @override
  ConsumerState<ShoppingMemoPad> createState() => _ShoppingMemoPadState();
}

class _ShoppingMemoPadState extends ConsumerState<ShoppingMemoPad> {
  late final TextEditingController _text =
      TextEditingController(text: ref.read(shoppingMemoProvider));
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 復元などで外から中身が変わったときだけ追従する（入力中のカーソルを守る）。
    ref.listen(shoppingMemoProvider, (_, next) {
      if (next != _text.text) _text.text = next;
    });
    return GestureDetector(
      // 1行しかないときでも、カードのどこを押しても書き始められる。
      key: const Key('shopping-memo-pad'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.requestFocus(),
      child: SingleChildScrollView(
        child: TextField(
          key: const Key('shopping-memo-field'),
          controller: _text,
          focusNode: _focus,
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 15, height: 1.6),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).shoppingMemoHint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          ),
          onChanged: (v) => ref.read(shoppingMemoProvider.notifier).save(v),
        ),
      ),
    );
  }
}
