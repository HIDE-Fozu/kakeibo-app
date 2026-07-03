import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'theme.dart';

class KakeiboApp extends StatelessWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '家計簿',
        theme: buildKakeiboTheme(),
        home: const HomeShell(),
      );
}
