import 'package:flutter/material.dart';

import '../core/category_emoji.dart';
import '../core/category_icon_assets.dart';
import 'theme.dart';

/// カテゴリのアイコン1個ぶん（円形）。
///
/// 優先順位は「ユーザーがカテゴリ管理で設定した絵文字 → シードslugのイラスト →
/// 既定の絵文字」。イラストはアセットに円の下地まで入っているので円形に
/// クリップし、絵文字側は同じ色の円を敷いて、並べたときに粒が揃うようにする。
class CategoryIcon extends StatelessWidget {
  /// カテゴリの icon 列（ユーザー設定の絵文字）。null ならイラストを使う。
  final String? icon;
  final String? slug;
  final double size;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.slug,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final asset = icon == null ? categoryIconAsset(slug) : null;
    if (asset != null) {
      return ClipOval(
        child: Image.asset(
          asset,
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
          // アセット欠けでレイアウトを壊さない（絵文字に落とす）
          errorBuilder: (context, _, _) => _emoji(),
        ),
      );
    }
    return _emoji();
  }

  Widget _emoji() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: kIconCircle,
        ),
        child: Text(
          categoryEmoji(icon, slug),
          style: TextStyle(fontSize: size * 0.62),
        ),
      );
}
