import 'package:flutter/material.dart';

import 'home_shell.dart';

class KakeiboApp extends StatelessWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '家計簿',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D6B),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      );
}
