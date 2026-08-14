import 'package:flutter/material.dart';

// デザイントークン（2026-08-14 にデザインシート「落ち着き × 親しみやすさ 改善案」
// のパレットへ差し替え）。
//
// 方針: ウォームアイボリーの地に白いカードを置き、主役はメイングリーン。
// アクセント（アプリコット／コーラル）は面ではなく点（アイコン・状態）に使う。
//
// 役割分担: 指定の Main Green(#6FB6A3) は白背景の文字だと 2.4:1 で読めない。
// そこで「塗り・CTA・選択状態」は Main Green、「文字・枠・小さいグリフ」は
// 同系を締めた Primary Dark(#2F7A6A, 白地 5.1:1) に割り当てている。

const kPaper = Color(0xFFFAF8F4); // ウォームアイボリー（全体背景）
const kCard = Color(0xFFFFFFFF); // ホワイト（カード・入力面）
const kInk = Color(0xFF2F3A3D); // メインテキスト
const kMuted = Color(0xFF748089); // セカンダリテキスト
const kLine = Color(0xFFD9E3DF); // ボーダー／区切り線

/// メイングリーン（塗り・CTA・選択状態）。白地の文字色には使わない。
const kMint = Color(0xFF6FB6A3);

/// ソフトミント（背景・ハイライト）。選択タイル・チップの下地。
const kPrimarySoft = Color(0xFFDCEFE8);

/// Primary Dark。`scheme.primary` に入る実質の主色で、文字・枠・アイコン用。
/// シートに無い派生値（メイングリーンと同色相を白地 5.1:1 まで締めたもの）。
const kPrimary = Color(0xFF2F7A6A);

/// ウォームアプリコット（アクセント・強調）。
const kApricot = Color(0xFFF2B885);

/// ミューテッドコーラル（支出・注意喚起のアクセント）。
const kCoral = Color(0xFFE58D7C);

/// 注意（状態）。期日ドットなど「面・点」に使う。文字には kConfidenceMedium。
const kAttention = Color(0xFFD3A857);

/// 情報（状態）。お知らせ・情報。
const kInfo = Color(0xFF7A98C4);

/// クローム面（バックアップ帯・電卓下の帯・レシート確認パネル等）。
/// ベース背景よりわずかに沈ませた同系のアイボリー。
const kChrome = Color(0xFFF4F2ED);

/// 下部タブのラベル色（未選択）。仕様の Text Secondary。
/// NavigationBar の仕様上ラベルはタブ別に色を変えられないため共通。
const kNavIdle = kMuted;

/// 下部タブのアイコン色（タブごと）。シートのモックに合わせて
/// カレンダー=グリーン / 毎月=アプリコット / サマリ=コーラル / 設定=グレー。
const kNavMint = kMint;
const kNavAmber = kApricot;
const kNavCoral = kCoral;
const kNavBlue = kMuted;

const kExpense = Color(0xFFD97C6C); // 支出（状態）
const kExpenseSoft = Color(0xFFF7E4DF);
const kIncome = Color(0xFF59A98A); // 収入（状態）

/// Income の淡色は指定に無いため Expense Light と同じ明度感で作った派生。
const kIncomeSoft = Color(0xFFE2F0E9);

/// 常時表示される「未入力・未選択」の注意喚起に使う色。Expense(#D97C6C)は
/// 白地で 3.0:1 と文字には薄いので、同色相で締めた派生（3.9:1）。
const kWarnMuted = Color(0xFFC4685A);

/// カテゴリアイコンの円の下地。イラストアセット（assets/category_icons）が
/// 内包している色そのもので、絵文字フォールバック側の円をこれに合わせている。
/// （PNG側の色なのでパレット差し替えでは動かせない）
const kIconCircle = Color(0xFFF5F8F5);

const kConfidenceHighSoft = kPrimarySoft;

/// 注意(#D3A857)は白地 2.2:1 で文字に薄いため、同色相を締めた派生。
const kConfidenceMedium = Color(0xFFA87F32);
const kConfidenceMediumSoft = Color(0xFFFBF1DC);

/// カレンダーの曜日ヘッダ配色（日曜=支出系 / 土曜=情報系）。
/// どちらも指定色そのままだと文字に薄いので、色相を保って締めてある。
const kSunday = kWarnMuted;
const kSaturday = Color(0xFF5F80AE);

/// カードの影（シート指定: 0 6px 18px rgba(47,58,61,0.08)）。
const kCardShadow = BoxShadow(
  color: Color(0x142F3A3D),
  blurRadius: 18,
  offset: Offset(0, 6),
);

/// カードの角丸（シート指定: 16px）とベーススペーシング（8px）。
const kRadius = 16.0;
const kSpace = 8.0;

/// サマリ積み上げバーのグリーン濃淡（5色循環）
const kSubScale = <Color>[
  kPrimary,
  Color(0xFF4E9B87),
  kMint,
  Color(0xFFA7D3C6),
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
    // CTA（保存など）はメイングリーン塗り＋白文字（シートのモックどおり）。
    // scheme.primary は文字用の Primary Dark なので、塗りはここで差し替える。
    // 既定アクセントのときだけ（設定で色を変えている人は従来どおり seed 由来）。
    filledButtonTheme: isDefaultAccent
        ? FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: kMint,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kLine,
              disabledForegroundColor: kMuted,
            ),
          )
        : const FilledButtonThemeData(),
    // FAB「金額を入力する」も同じCTA言語に揃える。
    floatingActionButtonTheme: isDefaultAccent
        ? const FloatingActionButtonThemeData(
            backgroundColor: kMint,
            foregroundColor: Colors.white,
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
    // カードはシート指定の角丸16px。影はトークン（kCardShadow）を使う箇所で
    // 個別に付けるので、Card自体は影なし。
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
    ),
    extensions: const [KakeiboColors.standard],
  );
}
