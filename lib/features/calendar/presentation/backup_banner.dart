import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/application/backup_controller.dart';

/// spec §2.1-2: 「前回バックアップ: N日前」をホームに常時表示（通知の代替）。
/// 2026-08-20 モック: 全幅のクローム帯をやめ、右上のさりげない表示に。
class BackupBanner extends ConsumerWidget {
  const BackupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final last = ref.watch(lastBackupProvider);
    final now = ref.watch(utcNowProvider)();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 14, 0),
      child: Row(
        children: [
          const Spacer(),
          const Icon(Icons.backup_outlined, size: 13, color: kMuted),
          const SizedBox(width: 4),
          Text(
            backupAgeLabel(l, last, now),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
