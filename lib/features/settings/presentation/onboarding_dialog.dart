import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';

/// 初回起動時の軽量オンボーディング（spec §5.5）。
class OnboardingDialog extends ConsumerWidget {
  const OnboardingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.onboardingTitle),
      content: Text(l.onboardingBody),
      actions: [
        FilledButton(
          onPressed: () {
            ref.read(appSettingsProvider.notifier).markOnboardingDone();
            Navigator.pop(context);
          },
          child: Text(l.onboardingStartButton),
        ),
      ],
    );
  }
}
