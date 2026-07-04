import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ボトムタブの選択index。0=カレンダー 1=入力 2=サマリ 3=設定。
/// keepAlive（タブ状態を保持）。FABや「この日に追加」からも入力タブへ遷移する。
class HomeTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

final homeTabIndexProvider =
    NotifierProvider<HomeTabIndex, int>(HomeTabIndex.new);

const kInputTabIndex = 1;
