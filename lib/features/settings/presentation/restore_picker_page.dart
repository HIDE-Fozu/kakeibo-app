import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/backup/backup_data.dart';
import '../application/backup_controller.dart';

class RestorePickerPage extends ConsumerStatefulWidget {
  const RestorePickerPage({super.key});

  @override
  ConsumerState<RestorePickerPage> createState() => _RestorePickerPageState();
}

class _RestorePickerPageState extends ConsumerState<RestorePickerPage> {
  @override
  Widget build(BuildContext context) {
    final sources =
        ref.read(backupControllerProvider.notifier).listRestoreSources();
    return Scaffold(
      appBar: AppBar(title: const Text('復元')),
      body: sources.isEmpty
          ? const Center(child: Text('復元できるバックアップがありません'))
          : ListView(
              children: [
                for (final s in sources)
                  ListTile(
                    leading: Icon(
                        s.isAutoBackup ? Icons.history : Icons.file_present),
                    title: Text(s.label),
                    trailing: s.encrypted ? const Icon(Icons.lock) : null,
                    onTap: () => _restore(s),
                  ),
              ],
            ),
    );
  }

  Future<void> _restore(RestoreSource src) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('復元しますか？'),
        content: const Text('現在のデータはすべて置き換えられます。'
            '直前の状態は自動退避され、あとで取り出せます。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          FilledButton(
              key: const Key('confirm-restore'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('復元')),
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
          title: const Text('取引が0件のバックアップです'),
          content: const Text('復元するとすべての取引が消えます。それでも復元しますか？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('キャンセル')),
            FilledButton(
                key: const Key('confirm-empty-restore'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('復元する')),
          ],
        ),
      );
      if (okEmpty != true || !mounted) return;
      try {
        await ctrl.restoreFrom(src, passphrase: pass, allowEmpty: true);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('復元に失敗しました: $e')));
        return;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('復元に失敗しました: $e')));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('復元しました')));
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
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('パスフレーズを入力'),
        content: TextField(
          key: const Key('restore-passphrase-field'),
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  Navigator.pop(context, _controller.text);
                }
              },
              child: const Text('復元')),
        ],
      );
}
