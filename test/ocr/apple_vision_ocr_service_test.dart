import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/ocr/apple_vision_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kakeibo/ocr');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('チャネル応答を OcrBlock へ 1:1 写像（座標はそのまま）', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <Map<String, Object?>>[
        {
          'text': '合計 ¥1,080',
          'x': 0.1,
          'y': 0.5,
          'w': 0.8,
          'h': 0.03,
          'confidence': 0.99,
        },
        {
          'text': 'スーパーA',
          'x': 0.1,
          'y': 0.05,
          'w': 0.5,
          'h': 0.03,
          'confidence': 0.9,
        },
      ];
    });

    final service = AppleVisionOcrService(channel: channel);
    final blocks = await service.recognize('/tmp/receipt.jpg');

    expect(received?.method, 'recognize');
    expect(received?.arguments, {'path': '/tmp/receipt.jpg'});
    expect(blocks.length, 2);
    expect(blocks.first.text, '合計 ¥1,080');
    expect(blocks.first.rect.x, closeTo(0.1, 1e-9));
    expect(blocks.first.rect.y, closeTo(0.5, 1e-9));
    expect(blocks.first.rect.w, closeTo(0.8, 1e-9));
    expect(blocks.first.rect.h, closeTo(0.03, 1e-9));
    expect(blocks.first.confidence, closeTo(0.99, 1e-9));
  });

  test('null 応答は空リスト', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final service = AppleVisionOcrService(channel: channel);
    expect(await service.recognize('/tmp/x.jpg'), isEmpty);
  });

  test('confidence 欠落は 0 として扱う', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return <Map<String, Object?>>[
        {'text': 'x', 'x': 0.0, 'y': 0.0, 'w': 0.1, 'h': 0.1},
      ];
    });
    final service = AppleVisionOcrService(channel: channel);
    final blocks = await service.recognize('/tmp/x.jpg');
    expect(blocks.single.confidence, 0);
  });
}
