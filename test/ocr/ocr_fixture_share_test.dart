import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/ocr/ocr_fixture_share.dart';

void main() {
  test('zipOcrFixtures: JSONと写真が1つのzipに入る', () {
    final root = Directory.systemTemp.createTempSync('fixture-share');
    addTearDown(() => root.deleteSync(recursive: true));
    final src = Directory('${root.path}${Platform.pathSeparator}fx')
      ..createSync();
    File('${src.path}${Platform.pathSeparator}receipt-a.json')
        .writeAsStringSync('{"name":"a","blocks":[]}');
    File('${src.path}${Platform.pathSeparator}receipt-a.jpg')
        .writeAsBytesSync([1, 2, 3]);
    final tmp = Directory('${root.path}${Platform.pathSeparator}tmp');

    final zipPath = zipOcrFixtures(src, tmp)!;
    expect(File(zipPath).existsSync(), isTrue);

    final archive =
        ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync());
    final names = archive.files.map((f) => f.name).toSet();
    expect(names.any((n) => n.endsWith('receipt-a.json')), isTrue);
    expect(names.any((n) => n.endsWith('receipt-a.jpg')), isTrue);
    expect(countOcrFixtures(src), 1);
  });

  test('空/不存在ディレクトリは null', () {
    final root = Directory.systemTemp.createTempSync('fixture-share-empty');
    addTearDown(() => root.deleteSync(recursive: true));
    final empty = Directory('${root.path}${Platform.pathSeparator}fx')
      ..createSync();
    expect(zipOcrFixtures(empty, root), isNull);
    expect(
        zipOcrFixtures(
            Directory('${root.path}${Platform.pathSeparator}nope'), root),
        isNull);
    expect(countOcrFixtures(empty), 0);
  });
}
