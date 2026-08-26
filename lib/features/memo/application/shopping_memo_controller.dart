import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/settings/shopping_memo_prefs.dart';

/// 買い物メモ（トップ画面のメモ帳）。家計簿の入力とは関係しない自由テキスト
/// （ユーザー要望 2026-08-23）。SharedPreferences に保存する。
class ShoppingMemo extends Notifier<String> {
  static const kShoppingMemo = kShoppingMemoPrefsKey;

  @override
  String build() =>
      ref.watch(sharedPreferencesProvider).getString(kShoppingMemo) ?? '';

  /// 入力のたびに保存する。小さな文字列なので十分軽い。
  Future<void> save(String text) async {
    state = text;
    await ref
        .read(sharedPreferencesProvider)
        .setString(kShoppingMemo, text);
  }
}

final shoppingMemoProvider =
    NotifierProvider<ShoppingMemo, String>(ShoppingMemo.new);

/// メモを編集中か（入力欄にフォーカスがあるか）。
///
/// 背景を落とす（スクリム）判断はこれを使う。キーボードの `viewInsets` で
/// 判断すると、0 になるのは**閉じるアニメーションが終わった後**なので、
/// 落としの解除が必ずアニメーション分だけ遅れ、カレンダーが白いまま
/// 待たされる（FB 2026-08-27「解除の動作を早めて」）。
/// フォーカスなら `unfocus()` と同じフレームで false になる＝即座に晴れる。
class ShoppingMemoFocused extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state != value) state = value;
  }
}

final shoppingMemoFocusedProvider =
    NotifierProvider.autoDispose<ShoppingMemoFocused, bool>(
        ShoppingMemoFocused.new);
