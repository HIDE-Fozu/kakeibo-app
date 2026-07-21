import '../data/db/category_seeds.dart';

/// カテゴリの絵文字を返す。
/// ユーザーがカテゴリ管理で設定した icon（絵文字）を最優先し、無ければ
/// slug からプリセット絵文字を引く。どちらも無ければ既定（📁）。
/// slug は表示名から独立しているので、多言語化しても絵文字が壊れない。
String categoryEmoji(String? icon, String? slug) =>
    icon ?? (slug == null ? null : seedEmojiBySlug[slug]) ?? '📁';
