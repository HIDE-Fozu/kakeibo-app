/// カテゴリのイラストアイコン（assets/category_icons/*.png）。
///
/// 2026-08-11 に採用したデザインシート「ナチュラル＆やさしいデザイン」から
/// 円1個ぶんを切り出したもの。1枚120x120pxで、円の下地(#F5F8F5)まで含む。
/// 描画側は円形にクリップして使う（[CategoryIcon]）。
///
/// slug 単位なので表示名が多言語でも壊れない。ユーザーが作ったカテゴリや
/// カテゴリ管理で絵文字を設定したものはここに載らず、絵文字表示にフォールバック
/// する（[categoryEmoji]）。
library;

const String kCategoryIconDir = 'assets/category_icons';

/// slug → アセットのファイル名（拡張子なし）。
///
/// シートは支出カテゴリ向けに描かれており収入用の絵柄が無い。給与/賞与/副収入は
/// シートの余りから意味の近いものを充てている（がま口/プレゼント/貯金箱）。
/// 差し替えるならこの3行だけ直せばよい。
const Map<String, String> _assetBySlug = {
  // 支出
  'food': 'food',
  'dining': 'dining',
  'dailyGoods': 'dailyGoods',
  'utilities': 'utilities',
  'comm': 'comm',
  'transport': 'transport',
  'social': 'social',
  'hobby': 'hobby',
  'clothing': 'clothing',
  'medical': 'medical',
  'housing': 'housing',
  'education': 'education',
  'special': 'special',
  'otherExpense': 'other',
  // 収入（シートに専用の絵柄が無いぶん、余りから割り当て）
  'salary': 'cash',
  'bonus': 'gift',
  'sideIncome': 'savings',
  'otherIncome': 'other',
  // システム
  'uncategorized': 'uncategorized',
};

/// シートに含まれるが現行カテゴリでは未使用の絵柄。カテゴリを増やすときの在庫。
/// （車・ガソリン / クレジットカード / 書籍・雑誌 / 買い物 / 旅行・レジャー /
/// 子ども関連 / ペット関連 / 税金 / 冠婚葬祭 / サブスク）
const List<String> kSpareCategoryIcons = [
  'car',
  'creditCard',
  'books',
  'shopping',
  'travel',
  'kids',
  'pet',
  'tax',
  'ceremony',
  'subscription',
];

/// slug に対応するイラストのアセットパス。無ければ null（＝絵文字で描く）。
String? categoryIconAsset(String? slug) {
  final name = slug == null ? null : _assetBySlug[slug];
  return name == null ? null : '$kCategoryIconDir/$name.png';
}
