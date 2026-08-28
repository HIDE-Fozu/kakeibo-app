import 'package:flutter/material.dart';

import 'theme.dart';

/// ボトムシートの選択肢1つ。**四辺を囲ったブロック**にする。
///
/// 上下だけの罫線だと左右が開いていて、どこからどこまでが押せる範囲なのか
/// 読めない（FB 2026-08-28「左右両端にも罫線が欲しい。ブロック型にしないと
/// 選択範囲だって直感的に認識できない」）。
///
/// 選んである方は枠を主色・太めにして、押した結果がどれなのかも枠で分かる
/// ようにする（チェックだけだと小さくて気づけない）。
class SheetOptionCell extends StatelessWidget {
  final Widget? leading;
  final String title;

  /// 見出しの下に置く一文（省略可）。
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SheetOptionCell({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        // 選んである方も**塗りは変えない**。薄い主色を敷くとシートの地色と
        // 混じって、かえってどれが選択中か読みづらい
        //（FB 2026-08-28「選択してる場所は青背景にしないで」）。
        // 選択は枠の色・太さと文字色だけで示す。
        color: kCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? scheme.primary : kLine,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: ListTile(
          leading: leading,
          title: Text(
            title,
            style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
          ),
          subtitle: subtitle == null ? null : Text(subtitle!),
          selected: selected,
          onTap: onTap,
        ),
      ),
    );
  }
}
