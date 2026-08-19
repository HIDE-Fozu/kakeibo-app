import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/locale_names.dart';
import '../../../core/money.dart';
import '../../../data/ocr/ocr_fixture_recorder.dart';
import '../../../data/ocr/ocr_fixture_share.dart';
import '../../../l10n/app_localizations.dart';
import '../application/backup_controller.dart';
import '../application/settings_controller.dart';
import '../../chores/presentation/chore_notification_settings_page.dart';
import '../../recurring/presentation/recurring_rules_page.dart';
import 'category_manage_page.dart';
import 'theme_color_sheet.dart';
import 'restore_picker_page.dart';
import 'trash_page.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final last = ref.watch(lastBackupProvider);
    final now = ref.watch(utcNowProvider)();
    final settings = ref.watch(appSettingsProvider);
    final currency = ref.watch(currencyProvider);
    // 取引が1件でもあれば通貨変更ロック（best-effort表示。確定判定はタップ時に再確認）。
    final currencyLocked = (ref.watch(transactionCountProvider).valueOrNull ?? 0) > 0;
    final generations =
        ref.watch(autoBackupStoreProvider).listGenerations().length;

    return SafeArea(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(backupAgeLabel(l, last, now)),
            subtitle: Text(l.settingsAutoBackupSubtitle(generations)),
          ),
          ListTile(
            key: const Key('backup-now'),
            leading: const Icon(Icons.save_alt),
            title: Text(l.settingsBackupNowTitle),
            onTap: () => _backupNow(context, ref),
          ),
          ListTile(
            key: const Key('export-json'),
            leading: const Icon(Icons.upload_file),
            title: Text(l.settingsExportJsonTitle),
            subtitle: Text(l.settingsExportJsonSubtitle),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            key: const Key('export-csv'),
            leading: const Icon(Icons.table_view),
            title: Text(l.settingsExportCsvTitle),
            subtitle: Text(l.settingsExportCsvSubtitle),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            key: const Key('restore-tile'),
            leading: const Icon(Icons.settings_backup_restore),
            title: Text(l.settingsRestoreTitle),
            subtitle: Text(l.settingsRestoreSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RestorePickerPage()),
            ),
          ),
          ListTile(
            key: const Key('trash-tile'),
            leading: const Icon(Icons.delete_outline),
            title: Text(l.trashTitle),
            subtitle: Text(l.settingsTrashSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrashPage()),
            ),
          ),
          // テスト期間限定: 収集済みOCRデータ（JSON+写真）の送信まわり。
          // 自動送信はオプトイン（既定OFF）。一般公開前にフラグごと撤去する
          if (kCollectReceiptPhotosDuringTest) ...[
            SwitchListTile(
              key: const Key('auto-upload-switch'),
              title: Text(l.settingsTestUploadTitle),
              subtitle: Text(l.settingsTestUploadSubtitle),
              value: settings.autoUploadTestData,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setAutoUploadTestData(v),
            ),
            ListTile(
              key: const Key('share-test-data'),
              leading: const Icon(Icons.outbox_outlined),
              title: Text(l.settingsShareTestDataTitle),
              subtitle: Text(l.settingsShareTestDataSubtitle),
              onTap: () => _shareTestData(context, ref),
            ),
            ListTile(
              key: const Key('fetch-collected'),
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(l.settingsFetchCollectedTitle),
              subtitle: Text(l.settingsFetchCollectedSubtitle),
              onTap: () => _fetchCollected(context, ref),
            ),
          ],
          const Divider(),
          ListTile(
            key: const Key('recurring-tile'),
            leading: const Icon(Icons.event_repeat),
            title: Text(l.recurringPageTitle),
            subtitle: Text(l.settingsRecurringSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecurringRulesPage()),
            ),
          ),
          ListTile(
            key: const Key('chores-tile'),
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l.settingsChoresTitle),
            subtitle: Text(l.settingsChoresSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ChoreNotificationSettingsPage()),
            ),
          ),
          SwitchListTile(
            key: const Key('retain-images-switch'),
            title: Text(l.settingsRetainImagesTitle),
            subtitle: Text(l.settingsRetainImagesSubtitle),
            value: settings.retainReceiptImages,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setRetainReceiptImages(v),
          ),
          ListTile(
            key: const Key('category-manage-tile'),
            leading: const Icon(Icons.category_outlined),
            title: Text(l.settingsCategoryManageTitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryManagePage()),
            ),
          ),
          SwitchListTile(
            key: const Key('category-order-switch'),
            secondary: const Icon(Icons.sort),
            title: Text(l.settingsCategoryOrderTitle),
            subtitle: Text(l.settingsCategoryOrderSubtitle),
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
            key: const Key('language-tile'),
            leading: const Icon(Icons.language),
            title: Text(l.settingsLanguage),
            subtitle: Text(settings.locale == null
                ? l.languageSystemDefault
                : nativeLocaleName(settings.locale!)),
            onTap: () => _pickLanguage(context, ref, settings),
          ),
          ListTile(
            key: const Key('currency-tile'),
            leading: const Icon(Icons.payments_outlined),
            title: Text(l.settingsCurrency),
            subtitle: Text(currencyLocked
                ? l.currencyLockedSubtitle
                : '${currency.code}  ${currency.symbol}'),
            trailing: currencyLocked ? const Icon(Icons.lock_outline) : null,
            onTap: () => _pickCurrency(context, ref, currency),
          ),
          const Divider(),
          ListTile(
            key: const Key('theme-color-tile'),
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.settingsColorTitle),
            subtitle: Text(l.settingsColorSubtitle),
            trailing: _swatch(settings.themeColor ?? kPrimaryFill),
            onTap: () => showThemeColorSheet(context, ref),
          ),
          const Divider(),
          ListTile(
            key: const Key('about-data-tile'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.settingsDataPolicyTitle),
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

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final l = AppLocalizations.of(context);
    final options = <Locale?>[null, ...AppLocalizations.supportedLocales];
    final currentTag = settings.locale?.toLanguageTag();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.settingsLanguage),
        children: [
          for (var i = 0; i < options.length; i++)
            _choiceRow(
              ctx,
              label: options[i] == null
                  ? l.languageSystemDefault
                  : nativeLocaleName(options[i]!),
              selected: options[i]?.toLanguageTag() == currentTag,
              onTap: () => Navigator.pop(ctx, i),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(appSettingsProvider.notifier).setLocale(options[picked]);
  }

  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    Currency current,
  ) async {
    final l = AppLocalizations.of(context);
    // タップ時に最新件数で確定判定（表示側の best-effort ロックの取りこぼしを防ぐ）。
    final count = await ref.read(transactionRepositoryProvider).count();
    if (!context.mounted) return;
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.currencyLockedTitle),
          content: Text(l.currencyLockedBody),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.commonClose)),
          ],
        ),
      );
      return;
    }
    final picked = await showDialog<Currency>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.settingsCurrency),
        children: [
          for (final c in kSupportedCurrencies)
            _choiceRow(
              ctx,
              label: '${c.code}  ${c.symbol}',
              secondary: c.englishName,
              selected: c.code == current.code,
              onTap: () => Navigator.pop(ctx, c),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(appSettingsProvider.notifier).setCurrency(picked.code);
  }

  /// 言語/通貨ピッカー共通の選択行（選択中はチェックを表示）。
  Widget _choiceRow(
    BuildContext context, {
    required String label,
    String? secondary,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      ListTile(
        title: Text(label),
        subtitle: secondary == null ? null : Text(secondary),
        trailing: selected
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: onTap,
      );

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupControllerProvider.notifier).backupNow();
      messenger.showSnackBar(
          SnackBar(content: Text(l.settingsBackupSuccessSnackbar)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.settingsBackupFailedSnackbar('$e'))));
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
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
      messenger.showSnackBar(SnackBar(
          content: Text(l.settingsExportSavedSnackbar(
              file.uri.pathSegments.last))));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.settingsExportFailedSnackbar('$e'))));
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref.read(backupControllerProvider.notifier).exportCsv();
      messenger.showSnackBar(SnackBar(
          content: Text(l.settingsExportSavedSnackbar(
              file.uri.pathSegments.last))));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.settingsExportFailedSnackbar('$e'))));
    }
  }

  /// 開発者用: CloudKitに集まった全端末分を exports/ocr-collected へ取り込む。
  Future<void> _fetchCollected(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final out = Directory(
          '${ref.read(exportsDirProvider).path}${Platform.pathSeparator}ocr-collected');
      final count =
          await ref.read(cloudFixtureUploaderProvider).fetchAllTo(out);
      messenger.showSnackBar(SnackBar(
          content:
              Text(l.settingsFetchCollectedSuccessSnackbar(count))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.settingsFetchCollectedFailedSnackbar('$e'))));
    }
  }

  /// テスト期間限定: 収集済みOCRデータ（JSON+写真）をzipして共有シートへ。
  Future<void> _shareTestData(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = ref.read(ocrFixtureRecorderProvider).dir;
      final count = countOcrFixtures(dir);
      if (count == 0) {
        messenger.showSnackBar(
            SnackBar(content: Text(l.settingsNoScanRecordsSnackbar)));
        return;
      }
      final zipPath = zipOcrFixtures(dir, Directory.systemTemp);
      if (zipPath == null) return;
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: l.settingsShareTestDataSubject(count),
        // iPad等では共有シートがポップオーバーで出るため、アンカー矩形(非ゼロ・
        // source view内)が必須。未指定だと端末により PlatformException
        // (sharePositionOrigin ...) で落ちる（iPhoneのシート経路では無視される）。
        sharePositionOrigin: _shareOrigin(context),
      );
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.settingsShareTestDataFailedSnackbar('$e'))));
    }
  }

  /// 共有ポップオーバーのアンカー。source view内の非ゼロ矩形（画面中央の小矩形）。
  Rect _shareOrigin(BuildContext context) {
    final size = context.size ?? MediaQuery.of(context).size;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }
}

/// オンボーディングと共通の説明（Task 13 で初回起動ダイアログからも使う）
Future<void> showDataPolicyDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l.settingsDataPolicyTitle),
          content: Text(l.settingsDataPolicyBody),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.commonClose)),
          ],
        );
      },
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.settingsExportJsonTitle),
      content: TextField(
        key: const Key('passphrase-field'),
        controller: _controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: l.settingsPassphraseFieldLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l.settingsSaveAsIs)),
        FilledButton(
            onPressed: () {
              final t = _controller.text;
              if (t.isNotEmpty) Navigator.pop(context, t);
            },
            child: Text(l.settingsSaveEncrypted)),
      ],
    );
  }
}
