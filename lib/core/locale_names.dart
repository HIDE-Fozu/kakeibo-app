import 'dart:ui';

/// サポート言語のネイティブ表記。
/// 言語ピッカーは UI 言語に依らず各言語を自言語名で見せる（一般的な作法）。
String nativeLocaleName(Locale locale) {
  switch (locale.toLanguageTag()) {
    case 'ja':
      return '日本語';
    case 'en':
      return 'English';
    case 'zh':
      return '中文（简体）';
    case 'ko':
      return '한국어';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    case 'de':
      return 'Deutsch';
    case 'it':
      return 'Italiano';
    case 'pt':
      return 'Português';
    default:
      return locale.toLanguageTag();
  }
}
