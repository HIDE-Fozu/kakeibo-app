import 'dart:io';
import 'backup_codec.dart';
import 'backup_data.dart';

/// 復元前スナップショット等の「サイレント自動退避」置き場。
/// - 共有シート不要（アプリ専用ディレクトリへの直接書き込み）
/// - 上書きしないローリング世代（タイムスタンプ名・辞書順＝時系列順）
/// - 書き込み後に読み戻し＋decode検証してから成功とみなす
///
/// Directoryは注入（テスト=一時Dir、アプリ=UIフェーズでpath_provider配線）。
class AutoBackupStore {
  final Directory dir;
  final BackupCodec _codec;
  final DateTime Function() _now;
  final int maxGenerations;

  AutoBackupStore(
    this.dir, {
    this._codec = const BackupCodec(),
    this._now = DateTime.now,
    this.maxGenerations = 10,
  });

  static final _nameRe = RegExp(r'^backup-(\d{19})\.json$');

  Future<File> writeVerified(String json) async {
    dir.createSync(recursive: true);
    final micros = _now().toUtc().microsecondsSinceEpoch;
    final name = 'backup-${micros.toString().padLeft(19, '0')}.json';
    final file = File('${dir.path}${Platform.pathSeparator}$name');

    try {
      file.writeAsStringSync(json, flush: true);
      // 読み戻して完全検証。ここを通らない退避は「無い」のと同じなので失敗扱い。
      final readBack = file.readAsStringSync();
      _codec.decode(readBack);
    } catch (e) {
      if (file.existsSync()) file.deleteSync();
      throw AutoBackupWriteError('自動退避の書き込み/検証に失敗しました: $e');
    }

    _prune();
    return file;
  }

  List<File> listGenerations() {
    if (!dir.existsSync()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _nameRe.hasMatch(_basename(f)))
        .toList()
      ..sort((a, b) => _basename(b).compareTo(_basename(a))); // 新しい順
    return files;
  }

  File? latest() {
    final gens = listGenerations();
    return gens.isEmpty ? null : gens.first;
  }

  DateTime? latestTimestamp() {
    final f = latest();
    if (f == null) return null;
    final micros = int.parse(_nameRe.firstMatch(_basename(f))!.group(1)!);
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }

  void _prune() {
    final gens = listGenerations();
    for (final f in gens.skip(maxGenerations)) {
      f.deleteSync();
    }
  }

  String _basename(File f) => f.uri.pathSegments.last;
}
