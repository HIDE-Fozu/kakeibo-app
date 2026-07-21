import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/money.dart';
import '../core/tax_config.dart';
import '../features/settings/application/settings_controller.dart';
import '../l10n/app_localizations.dart';

/// 実効ロケール（非context用）。
/// 設定で明示選択があればそれ、無ければ端末の優先ロケール群を
/// supportedLocales に突き合わせて解決する。MaterialApp が内部で使うのと
/// 同じ [basicLocaleListResolution] を使い、UIとロジックのロケールを一致させる。
final effectiveLocaleProvider = Provider<Locale>((ref) {
  final settings = ref.watch(appSettingsProvider);
  if (settings.locale != null) return settings.locale!;
  final preferred = ui.PlatformDispatcher.instance.locales;
  return basicLocaleListResolution(
    preferred,
    AppLocalizations.supportedLocales,
  );
});

/// BuildContext を持たない層（controller / formatter）から
/// ローカライズ文字列を引くための provider。
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return lookupAppLocalizations(ref.watch(effectiveLocaleProvider));
});

/// 現在の通貨（設定 currencyCode から解決）。既定 JPY。
final currencyProvider = Provider<Currency>((ref) {
  return currencyForCode(ref.watch(appSettingsProvider).currencyCode);
});

/// 金額整形器（ロケール＋通貨）。表示側は formatYen 等の代わりにこれを使う。
final moneyFormatterProvider = Provider<MoneyFormatter>((ref) {
  return MoneyFormatter(
    ref.watch(effectiveLocaleProvider),
    ref.watch(currencyProvider),
  );
});

/// 消費税プロファイル。日本円=日本の8/10%、それ以外=税UIなし。
final taxProfileProvider = Provider<TaxProfile>((ref) {
  return ref.watch(currencyProvider).code == 'JPY' ? kJapanTax : kNoTax;
});
