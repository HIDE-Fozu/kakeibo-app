import 'package:flutter/foundation.dart';

/// 消費税の扱いプロファイル。8%/10% は日本固有なので、通貨/地域で切り替える。
@immutable
class TaxProfile {
  /// 税UI（内税/外税トグル・8/10%・個別ダイアログ）を表示するか。
  final bool enabled;

  /// 外税で選べる税率。
  final List<int> rates;

  /// 既定税率。
  final int defaultRate;

  /// 軽減税率（食費8%・外食10%等）の自動適用をするか。
  final bool reducedRateSupported;

  const TaxProfile({
    required this.enabled,
    required this.rates,
    required this.defaultRate,
    required this.reducedRateSupported,
  });
}

/// 日本の消費税（軽減8% / 標準10%）。従来挙動と完全一致。
const kJapanTax = TaxProfile(
  enabled: true,
  rates: [8, 10],
  defaultRate: 10,
  reducedRateSupported: true,
);

/// 税UIなし（非JP）。入力額はそのまま（税込相当）として扱う。
const kNoTax = TaxProfile(
  enabled: false,
  rates: [],
  defaultRate: 0,
  reducedRateSupported: false,
);
