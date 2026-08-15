import 'package:flutter/material.dart';

// デザイントークン（2026-08-14 デザインシート「落ち着き × 親しみやすさ 改善案」
// のパレットを土台に、2026-08-15 主色を締まったブルーへ変更。4案を実ビルドで
// 比較してユーザーが②を選定）。
//
// 方針: ウォームアイボリーの地に白いカードを置き、主役はブルー。
// アクセント（アプリコット／コーラル）は面ではなく点（アイコン・状態）に使う。
// 支出=コーラル／収入=グリーンの意味色と背景はシートのまま据え置き。
//
// 役割分担: 「塗り・CTA・選択状態」は Primary Fill(#4A7FB5・白文字 4.2:1)、
// 「文字・枠・小さいグリフ」は同系を締めた Primary Dark(#2F5C8A・白地 7.0:1)。

const kPaper = Color(0xFFFAF8F4); // ウォームアイボリー（全体背景）
const kCard = Color(0xFFFFFFFF); // ホワイト（カード・入力面）
const kInk = Color(0xFF2F3A3D); // メインテキスト
const kMuted = Color(0xFF748089); // セカンダリテキスト
const kLine = Color(0xFFD9E1EA); // ボーダー／区切り線（青寄りに調整）

/// Primary Fill（塗り・CTA・選択状態のブルー）。白地の文字色には使わない。
const kPrimaryFill = Color(0xFF4A7FB5);

/// ソフトブルー（背景・ハイライト）。選択タイル・チップの下地。
const kPrimarySoft = Color(0xFFDDE8F4);

/// Primary Dark。`scheme.primary` に入る実質の主色で、文字・枠・アイコン用。
/// Primary Fill と同色相を白地 7.0:1 まで締めた派生値。
const kPrimary = Color(0xFF2F5C8A);

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

/// 下部タブのアイコン色（タブごと）。
/// カレンダー=主色（パレット追従のため home_shell 側で取得）/
/// 毎月=アプリコット / サマリ=コーラル / 設定=グレー。
const kNavMonthly = kApricot;
const kNavSummary = kCoral;
const kNavSettings = kMuted;

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
/// 主色がブルーになったため土曜と同系になるが、慣習（土曜=青）を優先して残す。
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

/// サマリ積み上げバーのブルー濃淡（5色循環）
const kSubScale = <Color>[
  kPrimary,
  Color(0xFF3F6FA0),
  kPrimaryFill,
  Color(0xFFA3C0DC),
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

/// テーマ1色から導出した実効パレット。ウィジェットが `kPrimaryFill` 等の
/// 定数を直接使うとカスタム色に追従できないため、主色まわりは必ず
/// `context.kakeiboPalette` 経由で読む。既定テーマでは各値が
/// kPaper/kPrimaryFill/kPrimary/kPrimarySoft/kLine/kChrome とバイト一致する。
@immutable
class KakeiboPalette extends ThemeExtension<KakeiboPalette> {
  final Color fill; // 塗り・CTA・選択状態
  final Color dark; // 文字・枠（= scheme.primary）
  final Color soft; // 選択タイル・チップの下地
  final Color line; // ボーダー
  final Color bg; // ページ背景
  final Color chrome; // バックアップ帯などの沈んだ面
  const KakeiboPalette({
    required this.fill,
    required this.dark,
    required this.soft,
    required this.line,
    required this.bg,
    required this.chrome,
  });

  static const standard = KakeiboPalette(
    fill: kPrimaryFill,
    dark: kPrimary,
    soft: kPrimarySoft,
    line: kLine,
    bg: kPaper,
    chrome: kChrome,
  );

  @override
  KakeiboPalette copyWith({
    Color? fill,
    Color? dark,
    Color? soft,
    Color? line,
    Color? bg,
    Color? chrome,
  }) =>
      KakeiboPalette(
        fill: fill ?? this.fill,
        dark: dark ?? this.dark,
        soft: soft ?? this.soft,
        line: line ?? this.line,
        bg: bg ?? this.bg,
        chrome: chrome ?? this.chrome,
      );

  @override
  KakeiboPalette lerp(KakeiboPalette? other, double t) {
    if (other == null) return this;
    return KakeiboPalette(
      fill: Color.lerp(fill, other.fill, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      line: Color.lerp(line, other.line, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      chrome: Color.lerp(chrome, other.chrome, t)!,
    );
  }
}

extension KakeiboPaletteX on BuildContext {
  KakeiboPalette get kakeiboPalette =>
      Theme.of(this).extension<KakeiboPalette>()!;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// テーマ1色 → 全パレット導出（設定の「色」機能の中核。モックのJSと同じ規則）。
/// - 塗り: 白文字が読める濃さ（3.5:1）まで明度を下げる
/// - 文字・枠: 同色相を白地4.5:1まで締める
/// - 選択面/背景/罫線/クローム: 同色相の薄いティント
KakeiboPalette derivePalette(Color seed) {
  final hsl = HSLColor.fromColor(seed);
  final h = hsl.hue;
  final sat = hsl.saturation;
  Color at(double s1, double l1) =>
      HSLColor.fromAHSL(1, h, s1.clamp(0.0, 1.0), l1.clamp(0.0, 1.0))
          .toColor();

  var fl = hsl.lightness;
  var fill = at(sat, fl);
  while (fl > 0.20 && _contrast(Colors.white, fill) < 3.5) {
    fl -= 0.01;
    fill = at(sat, fl);
  }

  final ds = (sat + 0.08).clamp(0.0, 1.0);
  var dl = fl < 0.50 ? fl : 0.50;
  var dark = at(ds, dl);
  while (dl > 0.10 && _contrast(dark, Colors.white) < 4.5) {
    dl -= 0.01;
    dark = at(ds, dl);
  }

  double atLeast(double v, double min) => v < min ? min : v;
  return KakeiboPalette(
    fill: fill,
    dark: dark,
    soft: at(atLeast(sat * 0.45, 0.08), 0.92),
    line: at(atLeast(sat * 0.22, 0.04), 0.87),
    bg: at(atLeast(sat * 0.35, 0.06), 0.97),
    chrome: at(atLeast(sat * 0.30, 0.05), 0.94),
  );
}

/// [themeColor] は設定の「色」。null = 既定（現行トークンとバイト一致）。
/// 1色から導出したパレットが scheme・CTA・タブ・カード等に一括で入る。
ThemeData buildKakeiboTheme({Color? themeColor}) {
  final p =
      themeColor == null ? KakeiboPalette.standard : derivePalette(themeColor);
  final scheme = ColorScheme.fromSeed(seedColor: p.dark).copyWith(
    primary: p.dark,
    primaryContainer: p.soft,
    onPrimaryContainer: kInk,
    surface: kCard,
    onSurface: kInk,
    onSurfaceVariant: kMuted,
    outline: p.line,
    outlineVariant: p.line,
    error: kExpense,
    errorContainer: kExpenseSoft,
    onErrorContainer: kInk,
    surfaceContainerHighest: p.chrome,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    dividerColor: p.line,
    // 文字を入力できる場所は白で塗る（ページ背景に同化して入力欄と
    // 分からない、というFB・2026-08-09）。白ピル・カードと同じ kCard。
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: kCard,
    ),
    appBarTheme: AppBarTheme(backgroundColor: p.bg, foregroundColor: kInk),
    // CTA（保存など）は塗り＋白文字。scheme.primary は文字用の濃色なので、
    // 塗りはここで導出パレットの fill に差し替える。
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.fill,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.line,
        disabledForegroundColor: kMuted,
      ),
    ),
    // FAB「金額を入力する」も同じCTA言語に揃える。
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.fill,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCard,
      indicatorColor: p.soft,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.dark : kNavIdle,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? p.dark : kNavIdle,
          )),
    ),
    // カードはシート指定の角丸16px。影はトークン（kCardShadow）を使う箇所で
    // 個別に付けるので、Card自体は影なし。
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
    ),
    extensions: [KakeiboColors.standard, p],
  );
}
