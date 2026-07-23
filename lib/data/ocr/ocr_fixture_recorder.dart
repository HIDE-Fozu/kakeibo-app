import 'dart:convert';
import 'dart:io';

import '../../domain/services/ocr/ocr_types.dart';

/// 【テスト期間限定】レシート写真もフィクスチャと同名で保存する。
/// 収集した写真で座標/切り抜き/OCR品質を実物照合できる。
/// **一般公開前に false へ戻すこと**（写真は端末容量を食う・spec §7.6）。
const bool kCollectReceiptPhotosDuringTest = false;

/// スキャンごとのOCRブロック列をフィクスチャJSONとして保存する（spec §8.2）。
/// 形式は test/support/receipt_fixtures.dart の loadFixture と同一
/// （実レシートをそのままパーサ再調整のテスト入力にできる）。
/// exports/ 配下なので Files アプリの「このiPhone内/家計簿」から取り出せる。
/// releaseビルドでも記録する（TestFlightテスターからの標本回収経路）。
/// JSONは直近 [maxFiles] 件、写真は直近 [maxPhotos] 件のローリング保持。
class OcrFixtureRecorder {
  final Directory dir;
  final DateTime Function() now;
  final int maxFiles;
  final int maxPhotos;
  final bool collectPhotos;
  OcrFixtureRecorder(
    this.dir, {
    required this.now,
    this.maxFiles = 200,
    this.maxPhotos = 30,
    this.collectPhotos = kCollectReceiptPhotosDuringTest,
  });

  /// 同期書き込み。widgetテストのFakeAsyncゾーンでも完了し、
  /// スキャンフローを止めない（デバッグ用のスナップショットなので十分）。
  /// [imagePath] があり収集フラグONなら、写真をJSONと同名でコピーする
  /// （一時画像は保存時に消える/移動するため、スキャン時点でコピーが必要）。
  String record(List<OcrBlock> blocks, {String? imagePath}) {
    dir.createSync(recursive: true);
    final name = 'receipt-${now().toIso8601String().replaceAll(':', '-')}';
    if (collectPhotos && imagePath != null) {
      try {
        final src = File(imagePath);
        if (src.existsSync()) {
          final ext = imagePath.contains('.')
              ? imagePath.substring(imagePath.lastIndexOf('.'))
              : '.jpg';
          src.copySync('${dir.path}${Platform.pathSeparator}$name$ext');
        }
      } catch (_) {} // 写真コピー失敗はJSON記録を妨げない
    }
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

  /// 保存確定時に「人間が確定した正解」をフィクスチャへ書き戻す。
  /// 普通に家計簿として使うだけで、OCR生出力と正解のペア（ラベル付き
  /// データ）が溜まる。loadFixture の expected と同形式。
  void writeExpected(String jsonPath,
      {required int totalYen, required String dateIso, String? store}) {
    try {
      final f = File(jsonPath);
      if (!f.existsSync()) return;
      final root = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      root['expected'] = {
        'totalYen': totalYen,
        'date': dateIso,
        if (store != null && store.isNotEmpty) 'store': store,
      };
      f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(root));
    } catch (_) {} // ラベル書き込み失敗は保存を妨げない
  }

  /// 古いものから削除して JSON=maxFiles件・写真=maxPhotos件 に保つ。
  /// ファイル名はISOタイムスタンプ由来なので辞書順=時刻順。
  void _pruneOld() {
    final all = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final jsons = all.where((f) => f.path.endsWith('.json')).toList();
    final photos = all.where((f) => !f.path.endsWith('.json')).toList();
    for (var i = 0; i < jsons.length - maxFiles; i++) {
      try {
        jsons[i].deleteSync();
      } catch (_) {}
    }
    for (var i = 0; i < photos.length - maxPhotos; i++) {
      try {
        photos[i].deleteSync();
      } catch (_) {}
    }
  }
}
