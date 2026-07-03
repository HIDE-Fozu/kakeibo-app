import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';

/// 初回起動時の軽量オンボーディング（spec §5.5）。
class OnboardingDialog extends ConsumerWidget {
  const OnboardingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
        title: const Text('データの取り扱いについて'),
        content: const Text(
          '・記録は端末の中だけに保存されます。自動で外部に送信されることはありません。\n'
          '・端末内で自動バックアップを取りますが、機種変更や端末の故障に備えて、'
          '設定からエクスポートを保存してください。',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).markOnboardingDone();
              Navigator.pop(context);
            },
            child: const Text('はじめる'),
          ),
        ],
      );
}
