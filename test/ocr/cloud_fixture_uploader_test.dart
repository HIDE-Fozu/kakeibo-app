import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/ocr/cloud_fixture_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kakeibo/cloud-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<(CloudFixtureUploader, Directory, List<MethodCall>)> setup(
      {bool failUpload = false}) async {
    final dir = Directory.systemTemp.createTempSync('cloud-up');
    addTearDown(() => dir.deleteSync(recursive: true));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'upload' && failUpload) {
        throw PlatformException(code: 'upload_failed');
      }
      if (call.method == 'fetchAll') {
        return <Map<String, Object?>>[
          {'name': 'receipt-x', 'json': '{"name":"receipt-x","blocks":[]}'},
        ];
      }
      return true;
    });
    return (CloudFixtureUploader(dir, prefs, channel: channel), dir, calls);
  }

  File writeFixture(Directory dir, String name) =>
      File('${dir.path}${Platform.pathSeparator}$name.json')
        ..writeAsStringSync('{"name":"$name","blocks":[]}');

  test('syncPending: 未送信のみ送り、写真があれば添付、送信済みは再送しない', () async {
    final (up, dir, calls) = await setup();
    writeFixture(dir, 'receipt-a');
    writeFixture(dir, 'receipt-b');
    File('${dir.path}${Platform.pathSeparator}receipt-a.jpg')
        .writeAsBytesSync([1]);

    expect(await up.syncPending(), 2);
    expect(calls, hasLength(2));
    final a = calls.firstWhere((c) => (c.arguments as Map)['name'] == 'receipt-a');
    expect((a.arguments as Map)['photoPath'], isNotNull);
    final b = calls.firstWhere((c) => (c.arguments as Map)['name'] == 'receipt-b');
    expect((b.arguments as Map).containsKey('photoPath'), isFalse);

    calls.clear();
    expect(await up.syncPending(), 0); // 送信済みはスキップ
    expect(calls, isEmpty);
  });

  test('失敗分はマークされず、次回のsyncPendingで再試行される', () async {
    final (up, dir, calls) = await setup(failUpload: true);
    writeFixture(dir, 'receipt-a');
    expect(await up.syncPending(), 0);
    expect(calls, hasLength(1));
    calls.clear();
    expect(await up.syncPending(), 0); // まだ未送信扱い→再試行
    expect(calls, hasLength(1));
  });

  test('resendAfterLabel: 送信済みでもラベル後は上書き再送', () async {
    final (up, dir, calls) = await setup();
    final f = writeFixture(dir, 'receipt-a');
    await up.syncPending();
    calls.clear();
    await up.resendAfterLabel(f.path);
    expect(calls, hasLength(1)); // 再送された
  });

  test('fetchAllTo: レコードをファイルとして取り込む', () async {
    final (up, dir, _) = await setup();
    final out = Directory('${dir.path}${Platform.pathSeparator}collected');
    expect(await up.fetchAllTo(out), 1);
    expect(
        File('${out.path}${Platform.pathSeparator}receipt-x.json')
            .existsSync(),
        isTrue);
  });
}
