import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/backup/backup_codec.dart';
import '../../chores/application/chore_providers.dart';

class RestoreSource {
  final File file;
  final String label;
  final bool encrypted;
  final bool isAutoBackup;
  const RestoreSource({
    required this.file,
    required this.label,
    required this.encrypted,
    required this.isAutoBackup,
  });
}

class PassphraseRequiredError implements Exception {
  const PassphraseRequiredError();
  @override
  String toString() => '暗号化バックアップにはパスフレーズが必要です';
}

class LastBackup extends AutoDisposeNotifier<DateTime?> {
  @override
  DateTime? build() => ref.watch(autoBackupStoreProvider).latestTimestamp();
}

final lastBackupProvider =
    NotifierProvider.autoDispose<LastBackup, DateTime?>(LastBackup.new);

/// バックアップ操作のUI向け窓口。DB反映はdrift streamで自動伝播する。
class BackupController extends Notifier<void> {
  static final _genRe = RegExp(r'^backup-(\d{19})\.json$');

  @override
  void build() {}

  Future<void> backupNow() async {
    final json = await ref.read(backupServiceProvider).exportJson();
    await ref.read(autoBackupStoreProvider).writeVerified(json);
    ref.invalidate(lastBackupProvider);
  }

  /// 起動時ポリシー（spec §2.1「定期」の実装）:
  /// 取引が1件以上あり、前回バックアップが無い/24時間超なら世代を書く。
  Future<bool> runStartupBackupIfStale() async {
    final service = ref.read(backupServiceProvider);
    final payload = await service.exportPayload();
    if (payload.transactions.isEmpty) return false;
    final store = ref.read(autoBackupStoreProvider);
    final last = store.latestTimestamp();
    final now = ref.read(utcNowProvider)();
    if (last != null && now.difference(last) < const Duration(hours: 24)) {
      return false;
    }
    await store.writeVerified(const BackupCodec().encode(payload));
    ref.invalidate(lastBackupProvider);
    return true;
  }

  // ファイルIOは同期API: 小ファイルであり、widgetテスト(FakeAsync)では
  // 非同期IOの完了イベントが配送されず永久に固まるため。
  Future<File> exportJson({String? passphrase}) async {
    final json = await ref.read(backupServiceProvider).exportJson();
    if (passphrase == null || passphrase.isEmpty) {
      return _writeExport('json', (f) => f.writeAsStringSync(json, flush: true));
    }
    final bytes =
        await ref.read(backupCryptoProvider).encrypt(json, passphrase);
    return _writeExport('kkbk', (f) => f.writeAsBytesSync(bytes, flush: true));
  }

  Future<File> exportCsv() async {
    final csv = await ref.read(backupServiceProvider).exportCsv();
    return _writeExport('csv', (f) => f.writeAsStringSync(csv, flush: true));
  }

  List<RestoreSource> listRestoreSources() {
    final sources = <RestoreSource>[];
    for (final f in ref.read(autoBackupStoreProvider).listGenerations()) {
      sources.add(RestoreSource(
        file: f,
        label: '自動バックアップ ${_genLabel(f)}',
        encrypted: false,
        isAutoBackup: true,
      ));
    }
    final dir = ref.read(exportsDirProvider);
    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') || f.path.endsWith('.kkbk'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final f in files) {
        sources.add(RestoreSource(
          file: f,
          label: f.uri.pathSegments.last,
          encrypted: f.path.endsWith('.kkbk'),
          isAutoBackup: false,
        ));
      }
    }
    return sources;
  }

  Future<void> restoreFrom(RestoreSource src,
      {String? passphrase, bool allowEmpty = false}) async {
    String json;
    if (src.encrypted) {
      if (passphrase == null || passphrase.isEmpty) {
        throw const PassphraseRequiredError();
      }
      json = await ref
          .read(backupCryptoProvider)
          .decrypt(src.file.readAsBytesSync(), passphrase);
    } else {
      json = src.file.readAsStringSync();
    }
    await ref
        .read(backupServiceProvider)
        .restoreFromJson(json, allowEmpty: allowEmpty);
    ref.invalidate(lastBackupProvider);
    // つきいちタスクも置換されたので、予約済み通知とバッジを復元後の内容へ
    // 同期し直す（消えたタスクの通知が残らないように）。失敗しても復元は成立。
    await ref
        .read(choreActionsProvider)
        .resync()
        .catchError((_) {});
  }

  File _writeExport(String ext, void Function(File) write) {
    final dir = ref.read(exportsDirProvider)..createSync(recursive: true);
    final now = ref.read(utcNowProvider)();
    final base =
        '${dir.path}${Platform.pathSeparator}kakeibo-export-${_stamp(now)}';
    var file = File('$base.$ext');
    for (var n = 2; file.existsSync(); n++) {
      file = File('$base-$n.$ext'); // 同秒内の連続エクスポートを上書きしない
    }
    write(file);
    return file;
  }

  String _stamp(DateTime utc) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        '-${two(utc.hour)}${two(utc.minute)}${two(utc.second)}';
  }

  String _genLabel(File f) {
    final m = _genRe.firstMatch(f.uri.pathSegments.last);
    if (m == null) return f.uri.pathSegments.last;
    final dt = DateTime.fromMicrosecondsSinceEpoch(int.parse(m.group(1)!),
            isUtc: true)
        .toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, void>(BackupController.new);
