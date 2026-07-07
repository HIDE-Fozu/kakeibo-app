import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';

/// 入力グリッドのカテゴリ並び順。
/// recentlyUsed=最近使った順（既定）/ manual=自分で決めた固定順（sortOrder）。
enum CategoryOrderMode { recentlyUsed, manual }

class SettingsState {
  final bool onboardingDone;
  final bool retainReceiptImages;

  /// 【テスト期間限定】収集データをCloudKitへ自動送信（オプトイン・既定OFF）。
  final bool autoUploadTestData;

  /// ページ背景色・アクセント（テーマ）色。未設定なら既定（kPaper / kPrimary）。
  final Color pageColor;
  final Color accentColor;
  final CategoryOrderMode categoryOrder;
  const SettingsState({
    required this.onboardingDone,
    required this.retainReceiptImages,
    this.autoUploadTestData = false,
    required this.pageColor,
    required this.accentColor,
    required this.categoryOrder,
  });
}

/// SharedPreferences 由来のアプリ設定。書き込み後は invalidateSelf で再読込。
class AppSettings extends Notifier<SettingsState> {
  static const kOnboardingDone = 'onboardingDone';
  static const kRetainReceiptImages = 'retainReceiptImages';
  static const kAutoUploadTestData = 'autoUploadTestData';
  static const kPageColor = 'pageColor';
  static const kAccentColor = 'accentColor';
  static const kCategoryOrder = 'categoryOrder';

  @override
  SettingsState build() {
    final p = ref.watch(sharedPreferencesProvider);
    final page = p.getInt(kPageColor);
    final accent = p.getInt(kAccentColor);
    return SettingsState(
      onboardingDone: p.getBool(kOnboardingDone) ?? false,
      retainReceiptImages: p.getBool(kRetainReceiptImages) ?? false,
      autoUploadTestData: p.getBool(kAutoUploadTestData) ?? false,
      pageColor: page == null ? kPaper : Color(page),
      accentColor: accent == null ? kPrimary : Color(accent),
      categoryOrder: p.getString(kCategoryOrder) == 'manual'
          ? CategoryOrderMode.manual
          : CategoryOrderMode.recentlyUsed,
    );
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

  Future<void> setPageColor(Color value) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kPageColor, value.toARGB32());
    ref.invalidateSelf();
  }

  Future<void> setAccentColor(Color value) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kAccentColor, value.toARGB32());
    ref.invalidateSelf();
  }

  Future<void> setCategoryOrder(CategoryOrderMode value) async {
    await ref.read(sharedPreferencesProvider).setString(
        kCategoryOrder,
        value == CategoryOrderMode.manual ? 'manual' : 'recent');
    ref.invalidateSelf();
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettings, SettingsState>(AppSettings.new);
