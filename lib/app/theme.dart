import 'package:flutter/material.dart';

// デザイントークン（docs/phase45-handoff.md「デザイントークン」の正）
const kPaper = Color(0xFFF6F5F0);
const kCard = Color(0xFFFFFFFF);
const kInk = Color(0xFF20241F);
const kMuted = Color(0xFF6F756A);
const kLine = Color(0xFFE3E2D8);
const kPrimary = Color(0xFF1E6B5A);
const kPrimarySoft = Color(0xFFE4EFE9);
const kExpense = Color(0xFFB8433A);
const kExpenseSoft = Color(0xFFF7E9E7);
const kIncome = Color(0xFF2E6E93);
const kIncomeSoft = Color(0xFFE7EFF5);
const kConfidenceHighSoft = Color(0xFFE2F0E6);
const kConfidenceMedium = Color(0xFFA8741A);
const kConfidenceMediumSoft = Color(0xFFF6EDDC);

/// サマリ積み上げバーの深緑濃淡（5色循環）
const kSubScale = <Color>[
  Color(0xFF1E6B5A),
  Color(0xFF4E937E),
  Color(0xFF7BB3A0),
  Color(0xFFA8CFC0),
  Color(0xFFCFE4DB),
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

ThemeData buildKakeiboTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
    primary: kPrimary,
    primaryContainer: kPrimarySoft,
    onPrimaryContainer: kInk,
    surface: kCard,
    onSurface: kInk,
    onSurfaceVariant: kMuted,
    outline: kLine,
    outlineVariant: kLine,
    error: kExpense,
    errorContainer: kExpenseSoft,
    onErrorContainer: kInk,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kPaper,
    dividerColor: kLine,
    appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk),
    cardTheme: const CardThemeData(color: kCard),
    extensions: const [KakeiboColors.standard],
  );
}
