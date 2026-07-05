import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../application/backup_controller.dart';
import '../application/settings_controller.dart';
import 'category_manage_page.dart';
import 'color_picker_dialog.dart';
import 'restore_picker_page.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastBackupProvider);
    final now = ref.watch(utcNowProvider)();
    final settings = ref.watch(appSettingsProvider);
    final generations =
        ref.watch(autoBackupStoreProvider).listGenerations().length;

    return SafeArea(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(backupAgeLabel(last, now)),
            subtitle: Text('自動バックアップ $generations世代（端末内）'),
          ),
          ListTile(
            key: const Key('backup-now'),
            leading: const Icon(Icons.save_alt),
            title: const Text('今すぐバックアップ'),
            onTap: () => _backupNow(context, ref),
          ),
          ListTile(
            key: const Key('export-json'),
            leading: const Icon(Icons.upload_file),
            title: const Text('JSONエクスポート'),
            subtitle: const Text('任意でパスフレーズ暗号化（復元に使えます）'),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            key: const Key('export-csv'),
            leading: const Icon(Icons.table_view),
            title: const Text('CSVエクスポート'),
            subtitle: const Text('閲覧用（復元には使えません）'),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            key: const Key('restore-tile'),
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('復元'),
            subtitle: const Text('全データを置き換えます'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RestorePickerPage()),
            ),
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('retain-images-switch'),
            title: const Text('レシート画像をローカル保持'),
            subtitle: const Text('既定では保存後に破棄します'),
            value: settings.retainReceiptImages,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setRetainReceiptImages(v),
          ),
          ListTile(
            key: const Key('category-manage-tile'),
            leading: const Icon(Icons.category_outlined),
            title: const Text('カテゴリ管理'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryManagePage()),
            ),
          ),
          SwitchListTile(
            key: const Key('category-order-switch'),
            secondary: const Icon(Icons.sort),
            title: const Text('カテゴリを自分の順で並べる'),
            subtitle: const Text('オフ=最近使った順 / オン=固定順（入力画面でタイル長押し→並べ替え）'),
            value: settings.categoryOrder == CategoryOrderMode.manual,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setCategoryOrder(
                      v
                          ? CategoryOrderMode.manual
                          : CategoryOrderMode.recentlyUsed,
                    ),
          ),
          const Divider(),
          ListTile(
            key: const Key('page-color-tile'),
            leading: const Icon(Icons.palette_outlined),
            title: const Text('ページの色（背景）'),
            trailing: _swatch(settings.pageColor),
            onTap: () => _pickColor(
              context,
              ref,
              title: 'ページの色（背景）',
              current: settings.pageColor,
              defaultColor: kPaper,
              onPicked: (c) =>
                  ref.read(appSettingsProvider.notifier).setPageColor(c),
            ),
          ),
          ListTile(
            key: const Key('accent-color-tile'),
            leading: const Icon(Icons.format_color_fill),
            title: const Text('アクセント色'),
            subtitle: const Text('ボタンや選択の色'),
            trailing: _swatch(settings.accentColor),
            onTap: () => _pickColor(
              context,
              ref,
              title: 'アクセント色',
              current: settings.accentColor,
              defaultColor: kPrimary,
              onPicked: (c) =>
                  ref.read(appSettingsProvider.notifier).setAccentColor(c),
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('about-data-tile'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('データの取り扱いについて'),
            onTap: () => showDataPolicyDialog(context),
          ),
        ],
      ),
    );
  }

  /// 現在色を示す小さな見本。
  Widget _swatch(Color color) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: kLine),
        ),
      );

  Future<void> _pickColor(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Color current,
    required Color defaultColor,
    required void Function(Color) onPicked,
  }) async {
    final picked = await showColorPickerDialog(
      context,
      initial: current,
      title: title,
      defaultColor: defaultColor,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupControllerProvider.notifier).backupNow();
      messenger
          .showSnackBar(const SnackBar(content: Text('バックアップを作成しました')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('バックアップに失敗しました: $e')));
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => const _ExportPassphraseDialog(),
    );
    if (choice == null) return; // キャンセル
    try {
      final file = await ref
          .read(backupControllerProvider.notifier)
          .exportJson(passphrase: choice.isEmpty ? null : choice);
      messenger.showSnackBar(
          SnackBar(content: Text('保存しました: ${file.uri.pathSegments.last}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref.read(backupControllerProvider.notifier).exportCsv();
      messenger.showSnackBar(
          SnackBar(content: Text('保存しました: ${file.uri.pathSegments.last}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    }
  }
}

/// オンボーディングと共通の説明（Task 13 で初回起動ダイアログからも使う）
Future<void> showDataPolicyDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('データの取り扱いについて'),
        content: const Text(
          '・記録は端末の中だけに保存されます。自動で外部に送信されることはありません。\n'
          '・端末内で自動バックアップを取りますが、機種変更や端末の故障に備えて、'
          '設定からエクスポートを保存してください。',
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
        ],
      ),
    );

class _ExportPassphraseDialog extends StatefulWidget {
  const _ExportPassphraseDialog();

  @override
  State<_ExportPassphraseDialog> createState() =>
      _ExportPassphraseDialogState();
}

class _ExportPassphraseDialogState extends State<_ExportPassphraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('JSONエクスポート'),
        content: TextField(
          key: const Key('passphrase-field'),
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'パスフレーズ（暗号化する場合）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('そのまま保存')),
          FilledButton(
              onPressed: () {
                final t = _controller.text;
                if (t.isNotEmpty) Navigator.pop(context, t);
              },
              child: const Text('暗号化して保存')),
        ],
      );
}
