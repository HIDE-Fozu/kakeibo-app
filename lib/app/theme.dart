import 'package:flutter/material.dart';

// デザイントークン（2026-08-13 にユーザー指定のパレットへ全面差し替え）。
//
// 方針（ユーザー指定）: パステル調だが全体を低彩度にはしない。背景・Surfaceは
// 高明度・低彩度、CTA・アイコン・選択状態は中〜高彩度。くすみカラーを多用せず、
// 白背景に明るいパステルが映えるポップな家計簿UIにする。
//
// 役割分担: 指定の Primary(#6EDCC7) は明るく、**白背景の上の文字としては
// 1.6:1 で読めない**。そこで同じく指定された Primary Dark を「文字・枠・
// 小さいグリフ」に、Primary を「塗り・CTA・選択状態」に割り当てている。
// CTAは Primary 塗り＋Text Primary 文字で 7.0:1 と、明るさと可読性が両立する。

const kPaper = Color(0xFFFFFCF7); // ベース背景
const kCard = Color(0xFFFFFFFF); // Surface
const kInk = Color(0xFF343A3A); // Text Primary
const kMuted = Color(0xFF8B918F); // Text Secondary
const kLine = Color(0xFFE9E6E1); // Border

/// Primary（塗り・CTA・選択状態に使う明るいミント）。文字色には使わない。
const kMint = Color(0xFF6EDCC7);

/// Primary Light。選択タイル・チップの下地。
const kPrimarySoft = Color(0xFFDDF7F0);

/// Primary Dark。`scheme.primary` に入る実質の主色で、文字・枠・アイコン用。
const kPrimary = Color(0xFF287F73);

/// クローム面（バックアップ帯・電卓下の帯・レシート確認パネル等）。
/// ベース背景よりわずかに沈ませた同系のクリーム。
const kChrome = Color(0xFFFBF7F0);

/// 下部タブのラベル色（未選択）。仕様の Text Secondary。
/// NavigationBar の仕様上ラベルはタブ別に色を変えられないため共通。
const kNavIdle = kMuted;

/// 下部タブのアイコン色（タブごと）。仕様の Accent 4色をそのまま使う。
const kNavMint = kMint;
const kNavAmber = Color(0xFFF4C95D); // Accent Yellow
const kNavCoral = Color(0xFFF4B557); // Accent Orange
const kNavBlue = Color(0xFF65AFE0); // Accent Blue

/// Accent Purple（現状カレンダー等では未使用。サマリの系列色などに使える）
const kAccentPurple = Color(0xFF8B82E8);

const kExpense = Color(0xFFF07878);
const kExpenseSoft = Color(0xFFFFE5E3);
const kIncome = Color(0xFF54C69A);

/// Income の淡色は指定に無いため Expense Light と同じ明度感で作った派生。
const kIncomeSoft = Color(0xFFE4F6ED);

/// 常時表示される「未入力・未選択」の注意喚起に使う色。Expense(#F07878)は
/// 背景の上で 2.7:1 と文字には薄いので、同系で締めた値（3.9:1）。
const kWarnMuted = Color(0xFFC7605C);

/// カテゴリアイコンの円の下地。イラストアセット（assets/category_icons）が
/// 内包している色そのもので、絵文字フォールバック側の円をこれに合わせている。
const kIconCircle = Color(0xFFF5F8F5);

const kConfidenceHighSoft = kPrimarySoft;
const kConfidenceMedium = Color(0xFFB8862B); // Accent Yellow を文字用に締めた値
const kConfidenceMediumSoft = Color(0xFFFDF3DC);

/// カレンダーの曜日ヘッダ配色（日曜=Expense系 / 土曜=Accent Blue系）。
/// どちらも指定色そのままだと文字に薄いので、色相を保って締めてある。
const kSunday = Color(0xFFD9605C);
const kSaturday = Color(0xFF4E93C4);

/// サマリ積み上げバーの深緑濃淡（5色循環）
const kSubScale = <Color>[
  kPrimary,
  Color(0xFF3FA595),
  kMint,
  Color(0xFFA9E9DB),
  kPrimarySoft,
];

/// 金額表示は等幅数字（桁が揃う）
const kTabularFigures = <FontFeature>[FontFeature.tabularFigures()];

/// 支出/収入などアプリ固有のセマンティック色。
@immutable
class KakeiboColors extends ThemeExtension<KakeiboColors> {
  final Color expense;
  final Color expenseSoft;
  final Color income;
  final Color incomeSoft;
  const KakeiboColors({
    required this.expense,
    required this.expenseSoft,
    required this.income,
    required this.incomeSoft,
  });

  static const standard = KakeiboColors(
    expense: kExpense,
    expenseSoft: kExpenseSoft,
    income: kIncome,
    incomeSoft: kIncomeSoft,
  );

  @override
  KakeiboColors copyWith({
    Color? expense,
    Color? expenseSoft,
    Color? income,
    Color? incomeSoft,
  }) =>
      KakeiboColors(
        expense: expense ?? this.expense,
        expenseSoft: expenseSoft ?? this.expenseSoft,
        income: income ?? this.income,
        incomeSoft: incomeSoft ?? this.incomeSoft,
      );

  @override
  KakeiboColors lerp(KakeiboColors? other, double t) {
    if (other == null) return this;
    return KakeiboColors(
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
    );
  }
}

extension KakeiboColorsX on BuildContext {
  KakeiboColors get kakeiboColors => Theme.of(this).extension<KakeiboColors>()!;
}

/// [background]（ページ背景）と [accent]（テーマ色）は設定で上書き可能。
/// 無指定＝既定（kPaper / kPrimary）。既定アクセント時は従来の見た目を厳密に維持し、
/// カスタム時のみ container 系を seed から派生させる。
ThemeData buildKakeiboTheme({Color? background, Color? accent}) {
  final bg = background ?? kPaper;
  final ac = accent ?? kPrimary;
  final seeded = ColorScheme.fromSeed(seedColor: ac);
  final isDefaultAccent = ac.toARGB32() == kPrimary.toARGB32();
  final scheme = seeded.copyWith(
    primary: ac,
    primaryContainer: isDefaultAccent ? kPrimarySoft : seeded.primaryContainer,
    onPrimaryContainer: isDefaultAccent ? kInk : seeded.onPrimaryContainer,
    surface: kCard,
    onSurface: kInk,
    onSurfaceVariant: kMuted,
    outline: kLine,
    outlineVariant: kLine,
    error: kExpense,
    errorContainer: kExpenseSoft,
    onErrorContainer: kInk,
    surfaceContainerHighest: kChrome,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    dividerColor: kLine,
    // 文字を入力できる場所は白で塗る（ページ背景＝bgに同化して入力欄と
    // 分からない、というFB・2026-08-09）。白ピル・カードと同じ kCard。
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: kCard,
    ),
    appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: kInk),
    // CTA（保存など）は明るい Primary 塗り＋濃い文字。scheme.primary は文字用の
    // Primary Dark なので、塗りだけここで明るいミントに差し替えている。
    // 既定アクセントのときだけ（設定で色を変えている人は従来どおり seed 由来）。
    filledButtonTheme: isDefaultAccent
        ? FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: kMint,
              foregroundColor: kInk,
              disabledBackgroundColor: kLine,
              disabledForegroundColor: kMuted,
            ),
          )
        : const FilledButtonThemeData(),
    // FAB「金額を入力する」も同じCTA言語に揃える。
    floatingActionButtonTheme: isDefaultAccent
        ? const FloatingActionButtonThemeData(
            backgroundColor: kMint,
            foregroundColor: kInk,
          )
        : const FloatingActionButtonThemeData(),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCard,
      indicatorColor: kPrimarySoft,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? kPrimary : kNavIdle,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? kPrimary : kNavIdle,
          )),
    ),
    cardTheme: const CardThemeData(color: kCard),
    extensions: const [KakeiboColors.standard],
  );
}
