import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import 'home_shell.dart';
import 'theme.dart';

class KakeiboApp extends ConsumerWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 背景色・アクセント色は設定で変更可能（既定は kPaper / kPrimary）。
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      title: '家計簿',
      theme: buildKakeiboTheme(
        background: settings.pageColor,
        accent: settings.accentColor,
      ),
      home: const HomeShell(),
    );
  }
}
