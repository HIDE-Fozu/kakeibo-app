import 'dart:convert';
import 'dart:io';

import '../../domain/services/ocr/ocr_types.dart';

/// スキャンごとのOCRブロック列をフィクスチャJSONとして保存する（spec §8.2）。
/// 形式は test/support/receipt_fixtures.dart の loadFixture と同一
/// （実レシートをそのままパーサ再調整のテスト入力にできる）。
/// exports/ 配下なので Files アプリの「このiPhone内/家計簿」から取り出せる。
/// releaseビルドでも記録する（TestFlightテスターからの標本回収経路）。
/// 直近 [maxFiles] 件のローリング保持（財務データを無際限に溜めない）。
class OcrFixtureRecorder {
  final Directory dir;
  final DateTime Function() now;
  final int maxFiles;
  OcrFixtureRecorder(this.dir, {required this.now, this.maxFiles = 200});

  /// 同期書き込み。widgetテストのFakeAsyncゾーンでも完了し、
  /// スキャンフローを止めない（デバッグ用のスナップショットなので十分）。
  String record(List<OcrBlock> blocks) {
    dir.createSync(recursive: true);
    final name = 'receipt-${now().toIso8601String().replaceAll(':', '-')}';
    final file = File('${dir.path}${Platform.pathSeparator}$name.json');
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert({
      'name': name,
      'blocks': [
        for (final b in blocks)
          {
            'text': b.text,
            'x': b.rect.x,
            'y': b.rect.y,
            'w': b.rect.w,
            'h': b.rect.h,
            'confidence': b.confidence,
          },
      ],
    }));
    _pruneOld();
    return file.path;
  }

  /// 古いものから削除して maxFiles 件に保つ。
  /// ファイル名はISOタイムスタンプ由来なので辞書順=時刻順。
  void _pruneOld() {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (var i = 0; i < files.length - maxFiles; i++) {
      try {
        files[i].deleteSync();
      } catch (_) {}
    }
  }
}
