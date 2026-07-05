import 'package:flutter_riverpod/flutter_riverpod.dart';

/// IndexedStack の表示index。0=カレンダー 1=入力 2=サマリ 3=設定。
/// keepAlive（状態を保持）。入力(1)はボトムタブに出さず、カレンダーのFABから開く。
/// 入力画面の戻る/保存でカレンダー(0)へ戻る。
class HomeTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

final homeTabIndexProvider =
    NotifierProvider<HomeTabIndex, int>(HomeTabIndex.new);

const kInputTabIndex = 1;
