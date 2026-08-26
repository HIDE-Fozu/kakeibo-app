import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/shopping_memo_controller.dart';

/// 日別カードの「メモ」タブの中身: 買い物メモ（家計簿の入力とは無関係）。
///
/// **その場で直接書ける**（別ページへ飛ばさない・FB 2026-08-27）。
/// タブを押した時点では位置は変わらず、**メモ欄をタップして書き始めたときに**
/// カードが上へせり上がって広い面になる（同 FB）。
/// 入力のたびに保存するので「保存」操作は要らない。
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
  void initState() {
    super.initState();
    // 書き始めた時だけ広げる（タブを押しただけでは動かさない）。
    _focus.addListener(() {
      if (_focus.hasFocus) {
        ref.read(daySheetExpandedProvider.notifier).set(true);
      }
    });
  }

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
    return TextField(
      key: const Key('shopping-memo-field'),
      controller: _text,
      focusNode: _focus,
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
