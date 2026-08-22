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
