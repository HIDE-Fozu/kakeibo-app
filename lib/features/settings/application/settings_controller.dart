import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/settings/budget_prefs.dart';
import '../../../data/settings/installment_cards.dart';
import '../../../data/settings/payment_mode_prefs.dart';

export '../../../data/settings/installment_cards.dart' show InstallmentCard;

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

  /// 分割払いの登録済みカード（名称順不同・名前で一意）。
  final List<InstallmentCard> installmentCards;

  /// 毎月の予算（毎月共通の1金額・2026-08-23要望）。
  /// オンならカレンダー上部サマリに「予算の残り」を表示する。
  final bool budgetEnabled;

  /// 予算額（最小単位）。未設定は0。
  final int monthlyBudgetMinor;

  /// 支払い区分モード（2026-08-26要望）。オフなら未払金の仕組みは動かない。
  final bool paymentModeEnabled;

  /// 上部サマリの数え方。true=現金主義（引き落とし日・見出しは「支払い」）/
  /// false=発生主義（買った日・見出しは「支出」）。
  /// モードがオフのときは [summaryUsesCashBasis] が常に false を返す。
  final bool summaryBasisCash;
  const SettingsState({
    required this.onboardingDone,
    required this.retainReceiptImages,
    this.autoUploadTestData = false,
    this.themeColor,
    required this.categoryOrder,
    this.locale,
    this.currencyCode = 'JPY',
    this.installmentCards = const [],
    this.budgetEnabled = false,
    this.monthlyBudgetMinor = 0,
    this.paymentModeEnabled = false,
    this.summaryBasisCash = true,
  });

  /// 実際に現金主義で数えるか。支払い区分モードがオフなら未払金が存在せず、
  /// 「支払い」と呼ぶ意味もないので従来どおり（発生主義・見出しは「支出」）。
  bool get summaryUsesCashBasis => paymentModeEnabled && summaryBasisCash;
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
  // 分割払いカード。形式は data/settings/installment_cards.dart（バックアップと共用）。
  static const kInstallmentCards = kInstallmentCardsPrefsKey;
  // 毎月の予算。キーは data/settings/budget_prefs.dart（バックアップと共用）。
  static const kBudgetEnabled = kBudgetEnabledPrefsKey;
  static const kMonthlyBudgetMinor = kMonthlyBudgetMinorPrefsKey;
  // 支払い区分。キーは data/settings/payment_mode_prefs.dart（バックアップと共用）。
  static const kPaymentModeEnabled = kPaymentModeEnabledPrefsKey;
  static const kSummaryBasisCash = kSummaryBasisCashPrefsKey;

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
      installmentCards:
          decodeInstallmentCardPrefs(p.getStringList(kInstallmentCards)),
      budgetEnabled: p.getBool(kBudgetEnabled) ?? false,
      monthlyBudgetMinor: p.getInt(kMonthlyBudgetMinor) ?? 0,
      paymentModeEnabled: p.getBool(kPaymentModeEnabled) ?? false,
      summaryBasisCash: p.getBool(kSummaryBasisCash) ?? true,
    );
  }

  Future<void> setBudgetEnabled(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(kBudgetEnabled, value);
    ref.invalidateSelf();
  }

  Future<void> setMonthlyBudget(int minor) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kMonthlyBudgetMinor, minor);
    ref.invalidateSelf();
  }

  Future<void> setPaymentModeEnabled(bool value) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kPaymentModeEnabled, value);
    ref.invalidateSelf();
  }

  Future<void> setSummaryBasisCash(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(kSummaryBasisCash, value);
    ref.invalidateSelf();
  }

  /// 分割払いカードを保存（同名は上書き）。
  Future<void> saveInstallmentCard(String name, double ratePercent) async {
    final p = ref.read(sharedPreferencesProvider);
    final cards = [
      for (final c in state.installmentCards)
        if (c.name != name) c,
      InstallmentCard(name: name, annualRatePercent: ratePercent),
    ];
    await p.setStringList(
        kInstallmentCards, encodeInstallmentCardPrefs(cards));
    ref.invalidateSelf();
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
}

final appSettingsProvider =
    NotifierProvider<AppSettings, SettingsState>(AppSettings.new);
