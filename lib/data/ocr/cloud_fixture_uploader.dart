import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 【テスト期間限定・オプトイン】収集フィクスチャをCloudKit公開DBへ送る。
///
/// - 送信単位: JSON 1件（＋同名写真があれば添付）。recordName=ファイル名
///   なので再送は上書き＝保存確定ラベルの追記にそのまま追従できる。
/// - 送信済み管理: SharedPreferences のリスト。失敗分は次回の
///   [syncPending]（起動時・保存後に呼ばれる）で自然に再試行される。
/// - ネットワーク/チャネル失敗は握りつぶす（家計簿機能を一切妨げない）。
class CloudFixtureUploader {
  static const _channel = MethodChannel('kakeibo/cloud');
  static const kUploadedKey = 'uploadedFixtureNames';

  final MethodChannel channel;
  final Directory fixturesDir;
  final SharedPreferences prefs;

  CloudFixtureUploader(
    this.fixturesDir,
    this.prefs, {
    MethodChannel? channel,
  }) : channel = channel ?? _channel;

  /// 未送信のJSONを全て送る。成功数を返す。
  Future<int> syncPending() async {
    if (!fixturesDir.existsSync()) return 0;
    final uploaded = (prefs.getStringList(kUploadedKey) ?? const []).toSet();
    final jsons = fixturesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    var sent = 0;
    for (final f in jsons) {
      final name = f.uri.pathSegments.last.replaceAll('.json', '');
      if (uploaded.contains(name)) continue;
      try {
        final photo = File(f.path.replaceAll('.json', '.jpg'));
        await channel.invokeMethod('upload', {
          'name': name,
          'json': f.readAsStringSync(),
          if (photo.existsSync()) 'photoPath': photo.path,
        });
        uploaded.add(name);
        sent++;
      } catch (_) {
        // 失敗分は残す→次回のsyncPendingで再試行
      }
    }
    if (sent > 0) {
      await prefs.setStringList(kUploadedKey, uploaded.toList()..sort());
    }
    return sent;
  }

  /// 保存確定ラベル書き込み後の再送: 送信済みマークを外して同期する
  /// （recordName同一なのでCloudKit側は上書き）。
  Future<void> resendAfterLabel(String jsonPath) async {
    final name = Uri.file(jsonPath).pathSegments.last.replaceAll('.json', '');
    final uploaded = (prefs.getStringList(kUploadedKey) ?? const []).toSet();
    if (uploaded.remove(name)) {
      await prefs.setStringList(kUploadedKey, uploaded.toList()..sort());
    }
    await syncPending();
  }

  /// 開発者用: CloudKitの全レコードを [outDir] にファイルとして取り込む。
  /// 取り込んだ件数を返す。
  Future<int> fetchAllTo(Directory outDir) async {
    final raw = await channel.invokeMethod<List<Object?>>('fetchAll');
    if (raw == null) return 0;
    outDir.createSync(recursive: true);
    var count = 0;
    for (final item in raw) {
      if (item is! Map) continue;
      final name = item['name'] as String?;
      final json = item['json'] as String?;
      if (name == null || json == null || json.isEmpty) continue;
      File('${outDir.path}${Platform.pathSeparator}$name.json')
          .writeAsStringSync(json);
      final photoPath = item['photoPath'] as String?;
      if (photoPath != null && File(photoPath).existsSync()) {
        File(photoPath)
            .copySync('${outDir.path}${Platform.pathSeparator}$name.jpg');
      }
      count++;
    }
    return count;
  }
}
