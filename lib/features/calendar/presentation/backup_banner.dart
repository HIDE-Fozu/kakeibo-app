import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/application/backup_controller.dart';

/// spec §2.1-2: 「前回バックアップ: N日前」をホームに常時表示（通知の代替）。
class BackupBanner extends ConsumerWidget {
  const BackupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final last = ref.watch(lastBackupProvider);
    final now = ref.watch(utcNowProvider)();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.backup_outlined, size: 14),
          const SizedBox(width: 6),
          Text(backupAgeLabel(l, last, now),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
