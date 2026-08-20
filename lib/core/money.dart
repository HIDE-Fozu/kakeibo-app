import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

import '../data/db/enums.dart';
import 'format.dart';

/// 通貨（ISO 4217）モデル。
///
/// [decimals] は小数桁（JPY/KRW=0、多くの通貨=2）。金額はDB上「その通貨の
/// 整数 minor unit」で保持する（円なら円、ドルならセント）。JPYは0桁なので
/// 既存データ（整数円）はそのまま minor unit として解釈でき、移行不要。
///
/// [symbol] はピッカー表示用の目安。実際の金額整形（Phase 3 の MoneyFormatter）は
/// intl の NumberFormat.simpleCurrency がロケールに応じた記号・桁区切りを出す。
class Currency {
  final String code;
  final int decimals;
  final String symbol;
  final String englishName;
  const Currency({
    required this.code,
    required this.decimals,
    required this.symbol,
    required this.englishName,
  });

  /// 1単位あたりの最小単位数（10^decimals）。円=1、ドル=100。
  int get minorPerUnit {
    var m = 1;
    for (var i = 0; i < decimals; i++) {
      m *= 10;
    }
    return m;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

const kDefaultCurrency = Currency(
  code: 'JPY',
  decimals: 0,
  symbol: '¥',
  englishName: 'Japanese Yen',
);

/// ピッカーに出す通貨の厳選リスト（対象9ロケール＋主要通貨）。
/// 0桁通貨は JPY / KRW のみ。それ以外は2桁。
const kSupportedCurrencies = <Currency>[
  kDefaultCurrency,
  Currency(code: 'USD', decimals: 2, symbol: r'$', englishName: 'US Dollar'),
  Currency(code: 'EUR', decimals: 2, symbol: '€', englishName: 'Euro'),
  Currency(code: 'GBP', decimals: 2, symbol: '£', englishName: 'British Pound'),
  Currency(code: 'CNY', decimals: 2, symbol: '¥', englishName: 'Chinese Yuan'),
  Currency(code: 'KRW', decimals: 0, symbol: '₩', englishName: 'South Korean Won'),
  Currency(code: 'TWD', decimals: 2, symbol: r'NT$', englishName: 'New Taiwan Dollar'),
  Currency(code: 'HKD', decimals: 2, symbol: r'HK$', englishName: 'Hong Kong Dollar'),
  Currency(code: 'SGD', decimals: 2, symbol: r'S$', englishName: 'Singapore Dollar'),
  Currency(code: 'AUD', decimals: 2, symbol: r'A$', englishName: 'Australian Dollar'),
  Currency(code: 'CAD', decimals: 2, symbol: r'C$', englishName: 'Canadian Dollar'),
  Currency(code: 'CHF', decimals: 2, symbol: 'CHF', englishName: 'Swiss Franc'),
  Currency(code: 'THB', decimals: 2, symbol: '฿', englishName: 'Thai Baht'),
  Currency(code: 'INR', decimals: 2, symbol: '₹', englishName: 'Indian Rupee'),
  Currency(code: 'BRL', decimals: 2, symbol: r'R$', englishName: 'Brazilian Real'),
  Currency(code: 'MXN', decimals: 2, symbol: r'$', englishName: 'Mexican Peso'),
];

/// コードから通貨を引く。未知コードは既定（JPY）。
Currency currencyForCode(String code) => kSupportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => kDefaultCurrency,
    );

/// テキスト入力（定期ルールの金額欄など）→ 整数minor unit。
/// 数字＋小数点（. か , どちらでも）のみ許容。通貨の小数桁を超える・
/// 数値でない・空 は null。例: JPY "1500"→1500 / EUR "12,5"→1250。
int? parseAmountMinor(String text, Currency currency) {
  final m = RegExp(r'^(\d+)(?:[.,](\d*))?$').firstMatch(text.trim());
  if (m == null) return null;
  final frac = m[2] ?? '';
  if (frac.length > currency.decimals) return null;
  final units = int.tryParse(m[1]!);
  if (units == null) return null;
  final fracPadded = frac.padRight(currency.decimals, '0');
  final fracMinor = currency.decimals == 0 ? 0 : int.parse('0$fracPadded');
  return units * currency.minorPerUnit + fracMinor;
}

/// 整数minor unit → 金額欄の初期テキスト（記号・桁区切りなしの素の数）。
String amountMinorToText(int minor, Currency currency) =>
    currency.decimals == 0
        ? '$minor'
        : (minor / currency.minorPerUnit).toStringAsFixed(currency.decimals);

/// 金額（整数 minor unit）を、ロケール＋通貨に応じて整形する。
///
/// JPY は既存の [formatYen]/[signedYen]/[manYen] にそのまま委譲し、従来の表示
/// （¥・「万」）をバイト等価で維持する。他通貨は intl の NumberFormat が記号・
/// 桁区切り・小数桁をロケールから決める。
class MoneyFormatter {
  final String localeTag;
  final Currency currency;
  const MoneyFormatter._(this.localeTag, this.currency);
  factory MoneyFormatter(Locale locale, Currency currency) =>
      MoneyFormatter._(locale.toLanguageTag(), currency);

  bool get _isJpy => currency.code == 'JPY';
  num _major(int minor) =>
      currency.decimals == 0 ? minor : minor / currency.minorPerUnit;

  /// minor unit をロケール準拠で整形（例: JPY→¥1,250 / USD→$12.50）。
  String format(int minor) {
    if (_isJpy) return formatYen(minor);
    return NumberFormat.simpleCurrency(locale: localeTag, name: currency.code)
        .format(_major(minor));
  }

  /// 符号つき（支出=− / 収入=＋）。
  String signed(TxnType type, int minor) {
    if (_isJpy) return signedYen(type, minor);
    final s = type == TxnType.expense ? '-' : '+';
    return '$s${format(minor)}';
  }

  /// 差引・見込みの符号つき表示。正のみ＋を付け、0は符号なし・負は format の−。
  /// （0円に＋が付くのは変「差し引き0なのに+」FB 2026-08-21）
  String net(int minor) => minor > 0 ? '+${format(minor)}' : format(minor);

  /// カレンダーセル用のコンパクト表記。JPYは「万」表記を維持、他はintlのcompact。
  /// 0以下は空文字（セル非表示）。
  String compact(int minor) {
    if (_isJpy) return manYen(minor);
    if (minor <= 0) return '';
    return NumberFormat.compactSimpleCurrency(
            locale: localeTag, name: currency.code)
        .format(_major(minor));
  }
}
