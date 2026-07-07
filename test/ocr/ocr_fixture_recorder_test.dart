import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/ocr/ocr_fixture_recorder.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../support/receipt_fixtures.dart';

void main() {
  test('保存したJSONは loadFixture でそのまま読める（往復）', () {
    final dir = Directory.systemTemp.createTempSync('ocr-fixtures');
    addTearDown(() => dir.deleteSync(recursive: true));
    final recorder =
        OcrFixtureRecorder(dir, now: () => DateTime.utc(2026, 7, 6, 12));

    const blocks = [
      OcrBlock(
          text: '合計 ¥1,080',
          rect: OcrRect(0.1, 0.5, 0.8, 0.03),
          confidence: 0.99),
      OcrBlock(
          text: 'スーパーA', rect: OcrRect(0.1, 0.05, 0.5, 0.03), confidence: 0.9),
    ];
    final path = recorder.record(blocks);

    final fixture = loadFixture(path);
    expect(fixture.name, startsWith('receipt-2026-07-06'));
    expect(fixture.blocks.length, 2);
    expect(fixture.blocks.first.text, '合計 ¥1,080');
    expect(fixture.blocks.first.rect.y, closeTo(0.5, 1e-9));
    expect(fixture.blocks.first.confidence, closeTo(0.99, 1e-9));
    expect(fixture.expectedTotalYen, isNull); // expected は収集後に手で書く
  });

  test('写真収集ON: JSONと同名で画像がコピーされる（コピー元は残る）', () {
    final dir = Directory.systemTemp.createTempSync('ocr-fixtures-photo');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = File('${dir.path}${Platform.pathSeparator}cap.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final recorder = OcrFixtureRecorder(
        Directory('${dir.path}${Platform.pathSeparator}out'),
        collectPhotos: true,
        now: () => DateTime.utc(2026, 7, 8, 9));
    final jsonPath = recorder.record(
      const [OcrBlock(text: 'x', rect: OcrRect(0, 0, 1, 0.03), confidence: 0.9)],
      imagePath: src.path,
    );
    final photo = File(jsonPath.replaceAll('.json', '.jpg'));
    expect(photo.existsSync(), isTrue);
    expect(photo.readAsBytesSync(), [1, 2, 3]);
    expect(src.existsSync(), isTrue); // 一時画像のライフサイクルは変えない
  });

  test('写真収集OFF: 画像はコピーされない', () {
    final dir = Directory.systemTemp.createTempSync('ocr-fixtures-nophoto');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = File('${dir.path}${Platform.pathSeparator}cap.jpg')
      ..writeAsBytesSync([1]);
    final recorder = OcrFixtureRecorder(
        Directory('${dir.path}${Platform.pathSeparator}out'),
        collectPhotos: false,
        now: () => DateTime.utc(2026, 7, 8, 9));
    final jsonPath = recorder.record(
      const [OcrBlock(text: 'x', rect: OcrRect(0, 0, 1, 0.03), confidence: 0.9)],
      imagePath: src.path,
    );
    expect(File(jsonPath.replaceAll('.json', '.jpg')).existsSync(), isFalse);
  });

  test('写真のローリング保持: maxPhotos件に保たれる（JSONは別枠）', () {
    final dir = Directory.systemTemp.createTempSync('ocr-fixtures-photoprune');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = File('${dir.path}${Platform.pathSeparator}cap.jpg')
      ..writeAsBytesSync([1]);
    var tick = 0;
    final out = Directory('${dir.path}${Platform.pathSeparator}out');
    final recorder = OcrFixtureRecorder(out,
        maxFiles: 10,
        maxPhotos: 2,
        collectPhotos: true,
        now: () => DateTime.utc(2026, 7, 8).add(Duration(seconds: tick++)));
    for (var i = 0; i < 4; i++) {
      recorder.record(
        const [
          OcrBlock(text: 'x', rect: OcrRect(0, 0, 1, 0.03), confidence: 0.9)
        ],
        imagePath: src.path,
      );
    }
    final jsons =
        out.listSync().where((f) => f.path.endsWith('.json')).length;
    final photos =
        out.listSync().where((f) => f.path.endsWith('.jpg')).length;
    expect(jsons, 4); // JSONは上限内なので全部残る
    expect(photos, 2); // 写真は直近2枚だけ
  });

  test('ローリング保持: maxFilesを超えた古いファイルは消える', () {
    final dir = Directory.systemTemp.createTempSync('ocr-fixtures-prune');
    addTearDown(() => dir.deleteSync(recursive: true));
    var tick = 0;
    final recorder = OcrFixtureRecorder(dir,
        maxFiles: 3,
        now: () => DateTime.utc(2026, 7, 7).add(Duration(seconds: tick++)));
    for (var i = 0; i < 5; i++) {
      recorder.record(const [
        OcrBlock(text: 'x', rect: OcrRect(0, 0, 1, 0.03), confidence: 0.9),
      ]);
    }
    final names = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    expect(names, hasLength(3));
    expect(names.first, contains('00-00-02')); // 古い2件（00,01秒）が消えた
  });
}
