import 'dart:io';

import 'package:archive/archive.dart';

/// 収集済みOCRフィクスチャ（JSON＋写真）を1つのzipに固める。
/// 「テストデータを送る」ボタン（共有シート）用。ユーザーの明示操作でのみ
/// 端末外へ出る＝spec §2.1（自動送信しない）と両立する回収経路。
/// 返り値は生成したzipのパス。対象が無ければ null。
String? zipOcrFixtures(Directory fixturesDir, Directory tmpDir) {
  if (!fixturesDir.existsSync()) return null;
  final files = fixturesDir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) return null;

  tmpDir.createSync(recursive: true);
  final stamp = files.last.uri.pathSegments.last
      .replaceAll(RegExp(r'\.[^.]+$'), ''); // 最新ファイル名を目印に
  final zipPath =
      '${tmpDir.path}${Platform.pathSeparator}ocr-fixtures-$stamp.zip';

  // 同期で確実に固める（ZipFileEncoder.addFileは非同期でawait漏れ事故のもと）。
  // 対象は最大 200 JSON + 30 写真程度＝メモリ上で組んで問題ないサイズ。
  final archive = Archive();
  for (final f in files) {
    final bytes = f.readAsBytesSync();
    archive.add(ArchiveFile.bytes(f.uri.pathSegments.last, bytes));
  }
  File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive));
  return zipPath;
}

/// フィクスチャ件数（JSON基準）。ボタンの説明表示用。
int countOcrFixtures(Directory fixturesDir) => !fixturesDir.existsSync()
    ? 0
    : fixturesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .length;
