/// 分割払いで使うカード（名称＋実質年率）。端末ローカル（SharedPreferences）。
/// 「カード名称を登録すれば次から選択で金利入力を省略できる」FB 2026-08-16。
///
/// モデルとprefs直列化をここ（data層）に置くのは、設定画面（AppSettings）と
/// バックアップ（BackupService/Codec, 形式v9）の両方が同じ形式を読み書きするため。
library;

/// SharedPreferences のキー。1件 = "名称\t実質年率"（タブ区切り）の StringList。
const String kInstallmentCardsPrefsKey = 'installmentCards';

class InstallmentCard {
  final String name;
  final double annualRatePercent;
  const InstallmentCard({required this.name, required this.annualRatePercent});
}

/// prefs の StringList → カード一覧。不正行（タブ無し・率が数値でない）は捨てる。
List<InstallmentCard> decodeInstallmentCardPrefs(List<String>? raw) => [
      for (final e in raw ?? const [])
        if (e.contains('\t') &&
            double.tryParse(e.substring(e.indexOf('\t') + 1)) != null)
          InstallmentCard(
            name: e.substring(0, e.indexOf('\t')),
            annualRatePercent: double.parse(e.substring(e.indexOf('\t') + 1)),
          ),
    ];

/// カード一覧 → prefs の StringList。
List<String> encodeInstallmentCardPrefs(List<InstallmentCard> cards) =>
    [for (final c in cards) '${c.name}\t${c.annualRatePercent}'];
