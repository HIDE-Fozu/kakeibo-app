import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// 入力グリッドのカテゴリ並び順。
/// recentlyUsed=最近使った順（既定）/ manual=自分で決めた固定順（sortOrder）。
enum CategoryOrderMode { recentlyUsed, manual }

class SettingsState {
  final bool onboardingDone;
  final bool retainReceiptImages;

  /// 【テスト期間限定】収集データをCloudKitへ自動送信（オプトイン・既定OFF）。
  final bool autoUploadTestData;

  /// ページ背景色・アクセント（テーマ）色。未設定なら既定（kPaper / kPrimary）。
  final Color? themeColor;
  final CategoryOrderMode categoryOrder;

  /// 表示言語。null = 端末のシステム言語に追従。
  final Locale? locale;

  /// 通貨（ISO 4217）。既定 JPY。取引が1件でもあると変更ロック（Phase 2でUI制御）。
  final String currencyCode;

  /// 見込み収支の基準日。0=月末（既定）、1..31=毎月N日
  /// （短い月は起票日と同じ末日丸め）。カレンダーの見込み行タップで変更。
  final int forecastAnchorDay;
  const SettingsState({
    required this.onboardingDone,
    required this.retainReceiptImages,
    this.autoUploadTestData = false,
    this.themeColor,
    required this.categoryOrder,
    this.locale,
    this.currencyCode = 'JPY',
    this.forecastAnchorDay = 0,
  });
}

/// SharedPreferences 由来のアプリ設定。書き込み後は invalidateSelf で再読込。
class AppSettings extends Notifier<SettingsState> {
  static const kOnboardingDone = 'onboardingDone';
  static const kRetainReceiptImages = 'retainReceiptImages';
  static const kAutoUploadTestData = 'autoUploadTestData';
  static const kThemeColor = 'themeColor';
  // 旧キー（〜build 44 の背景色/テーマ色2本立て）。読み込まず、起動時に削除する。
  static const kLegacyPageColor = 'pageColor';
  static const kLegacyAccentColor = 'accentColor';
  static const kCategoryOrder = 'categoryOrder';
  static const kLocale = 'locale';
  static const kCurrency = 'currency';
  static const kForecastAnchorDay = 'forecastAnchorDay';

  @override
  SettingsState build() {
    final p = ref.watch(sharedPreferencesProvider);
    // 旧2本立ての色設定は無条件に破棄（色設定を使った既存ユーザーは
    // いないことをユーザーが確認済み・2026-08-15）。以後は themeColor 1本。
    if (p.containsKey(kLegacyPageColor)) p.remove(kLegacyPageColor);
    if (p.containsKey(kLegacyAccentColor)) p.remove(kLegacyAccentColor);
    final theme = p.getInt(kThemeColor);
    return SettingsState(
      onboardingDone: p.getBool(kOnboardingDone) ?? false,
      retainReceiptImages: p.getBool(kRetainReceiptImages) ?? false,
      autoUploadTestData: p.getBool(kAutoUploadTestData) ?? false,
      themeColor: theme == null ? null : Color(theme),
      categoryOrder: p.getString(kCategoryOrder) == 'manual'
          ? CategoryOrderMode.manual
          : CategoryOrderMode.recentlyUsed,
      locale: parseLocale(p.getString(kLocale)),
      currencyCode: p.getString(kCurrency) ?? 'JPY',
      forecastAnchorDay: p.getInt(kForecastAnchorDay) ?? 0,
    );
  }

  /// BCP-47 タグ（例: "ja" / "zh" / "pt-BR"）→ Locale。null/空 = システム追従。
  static Locale? parseLocale(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final parts = tag.split('-');
    if (parts.length == 1) return Locale(parts[0]);
    // 2番目が4文字（例: Hans）ならスクリプト、それ以外は国コード扱い。
    final second = parts[1];
    if (second.length == 4) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: second);
    }
    return Locale(parts[0], second);
  }

  Future<void> markOnboardingDone() async {
    await ref.read(sharedPreferencesProvider).setBool(kOnboardingDone, true);
    ref.invalidateSelf();
  }

  Future<void> setRetainReceiptImages(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(kRetainReceiptImages, value);
    ref.invalidateSelf();
  }

  Future<void> setAutoUploadTestData(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(kAutoUploadTestData, value);
    ref.invalidateSelf();
  }

  /// null = 既定（キー削除）。値を焼き込まないので、パレット更新に常に追従する。
  Future<void> setThemeColor(Color? value) async {
    final p = ref.read(sharedPreferencesProvider);
    if (value == null) {
      await p.remove(kThemeColor);
    } else {
      await p.setInt(kThemeColor, value.toARGB32());
    }
    ref.invalidateSelf();
  }


  Future<void> setCategoryOrder(CategoryOrderMode value) async {
    await ref.read(sharedPreferencesProvider).setString(
        kCategoryOrder,
        value == CategoryOrderMode.manual ? 'manual' : 'recent');
    ref.invalidateSelf();
  }

  /// 表示言語を設定。null = システム追従（キーを削除）。
  Future<void> setLocale(Locale? value) async {
    final p = ref.read(sharedPreferencesProvider);
    if (value == null) {
      await p.remove(kLocale);
    } else {
      await p.setString(kLocale, value.toLanguageTag());
    }
    ref.invalidateSelf();
  }

  /// 通貨（ISO 4217）を設定。取引ロックの判定は呼び出し側（設定画面）で行う。
  Future<void> setCurrency(String code) async {
    await ref.read(sharedPreferencesProvider).setString(kCurrency, code);
    ref.invalidateSelf();
  }

  /// 見込み収支の基準日を設定（0=月末、1..31=毎月N日）。
  Future<void> setForecastAnchorDay(int day) async {
    assert(day >= 0 && day <= 31);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kForecastAnchorDay, day);
    ref.invalidateSelf();
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettings, SettingsState>(AppSettings.new);
