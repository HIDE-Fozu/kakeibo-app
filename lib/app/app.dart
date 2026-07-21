import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'home_shell.dart';
import 'theme.dart';

class KakeiboApp extends ConsumerWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 背景色・アクセント色は設定で変更可能（既定は kPaper / kPrimary）。
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // null = 端末のシステム言語に追従。設定で明示選択したらそれを優先。
      locale: settings.locale,
      theme: buildKakeiboTheme(
        background: settings.pageColor,
        accent: settings.accentColor,
      ),
      home: const HomeShell(),
    );
  }
}
