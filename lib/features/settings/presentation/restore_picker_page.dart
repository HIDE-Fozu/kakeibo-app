import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/backup/backup_data.dart';
import '../../../l10n/app_localizations.dart';
import '../application/backup_controller.dart';

class RestorePickerPage extends ConsumerStatefulWidget {
  const RestorePickerPage({super.key});

  @override
  ConsumerState<RestorePickerPage> createState() => _RestorePickerPageState();
}

class _RestorePickerPageState extends ConsumerState<RestorePickerPage> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sources = ref
        .read(backupControllerProvider.notifier)
        .listRestoreSources();
    return Scaffold(
      appBar: AppBar(title: Text(l.restorePageTitle)),
      body: sources.isEmpty
          ? Center(child: Text(l.restoreEmptyMessage))
          : ListView(
              children: [
                for (final s in sources)
                  ListTile(
                    leading: Icon(
                      s.isAutoBackup ? Icons.history : Icons.file_present,
                    ),
                    title: Text(s.label),
                    trailing: s.encrypted ? const Icon(Icons.lock) : null,
                    onTap: () => _restore(s),
                  ),
              ],
            ),
    );
  }

  Future<void> _restore(RestoreSource src) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restoreConfirmTitle),
        content: Text(l.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-restore'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.restoreButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    String? pass;
    if (src.encrypted) {
      pass = await _askPassphrase();
      if (pass == null || !mounted) return;
    }

    final ctrl = ref.read(backupControllerProvider.notifier);
    try {
      await ctrl.restoreFrom(src, passphrase: pass);
    } on EmptyBackupError {
      if (!mounted) return;
      final okEmpty = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.restoreEmptyBackupTitle),
          content: Text(l.restoreEmptyBackupMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              key: const Key('confirm-empty-restore'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.restoreEmptyBackupConfirmButton),
            ),
          ],
        ),
      );
      if (okEmpty != true || !mounted) return;
      try {
        await ctrl.restoreFrom(src, passphrase: pass, allowEmpty: true);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.restoreFailedMessage('$e'))),
        );
        return;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.restoreFailedMessage('$e'))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l.restoreSuccessMessage)));
  }

  Future<String?> _askPassphrase() => showDialog<String>(
    context: context,
    builder: (_) => const _RestorePassphraseDialog(),
  );
}

/// controllerの寿命をダイアログ自身に閉じ込める（popアニメーション中のdispose事故防止）
class _RestorePassphraseDialog extends StatefulWidget {
  const _RestorePassphraseDialog();

  @override
  State<_RestorePassphraseDialog> createState() =>
      _RestorePassphraseDialogState();
}

class _RestorePassphraseDialogState extends State<_RestorePassphraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.restorePassphraseTitle),
      content: TextField(
        key: const Key('restore-passphrase-field'),
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: Text(l.restoreButton),
        ),
      ],
    );
  }
}
