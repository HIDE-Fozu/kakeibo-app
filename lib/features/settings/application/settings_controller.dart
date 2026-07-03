import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class SettingsState {
  final bool onboardingDone;
  final bool retainReceiptImages;
  const SettingsState({
    required this.onboardingDone,
    required this.retainReceiptImages,
  });
}

/// SharedPreferences 由来のアプリ設定。書き込み後は invalidateSelf で再読込。
class AppSettings extends Notifier<SettingsState> {
  static const kOnboardingDone = 'onboardingDone';
  static const kRetainReceiptImages = 'retainReceiptImages';

  @override
  SettingsState build() {
    final p = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      onboardingDone: p.getBool(kOnboardingDone) ?? false,
      retainReceiptImages: p.getBool(kRetainReceiptImages) ?? false,
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
}

final appSettingsProvider =
    NotifierProvider<AppSettings, SettingsState>(AppSettings.new);
