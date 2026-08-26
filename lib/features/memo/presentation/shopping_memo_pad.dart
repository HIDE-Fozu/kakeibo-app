import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/shopping_memo_controller.dart';

/// 日別カードの「メモ」タブの中身: 買い物メモ（家計簿の入力とは無関係）。
///
/// **その場で直接書ける**（別ページへ飛ばさない・FB 2026-08-27）。
/// メモタブを開くとカード自体が上へせり上がるので、その広い面がそのまま
/// 書き込み面になる。入力のたびに保存するので「保存」操作は要らない。
class ShoppingMemoPad extends ConsumerStatefulWidget {
  const ShoppingMemoPad({super.key});

  @override
  ConsumerState<ShoppingMemoPad> createState() => _ShoppingMemoPadState();
}

class _ShoppingMemoPadState extends ConsumerState<ShoppingMemoPad> {
  late final TextEditingController _text =
      TextEditingController(text: ref.read(shoppingMemoProvider));

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 復元などで外から中身が変わったときだけ追従する（入力中のカーソルを守る）。
    ref.listen(shoppingMemoProvider, (_, next) {
      if (next != _text.text) _text.text = next;
    });
    return TextField(
      key: const Key('shopping-memo-field'),
      controller: _text,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 15, height: 1.6),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).shoppingMemoHint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      ),
      onChanged: (v) => ref.read(shoppingMemoProvider.notifier).save(v),
    );
  }
}
