import 'package:flutter/services.dart';

import '../../domain/services/ocr/ocr_types.dart';

/// iOS の Apple Vision（VNRecognizeTextRequest）を MethodChannel 経由で呼ぶ。
///
/// Swift 側（`ReceiptOcrPlugin`）が座標を**正準空間**（左上原点・y下向き・
/// 0..1 正規化・upright）へ変換済みの `[{text,x,y,w,h,confidence}]` を返す
/// （spec §7.1 / §8.1）。ここはその 1:1 写像のみ＝原点仮定を持たない。
class AppleVisionOcrService implements OcrService {
  static const MethodChannel _defaultChannel = MethodChannel('kakeibo/ocr');

  final MethodChannel _channel;

  AppleVisionOcrService({MethodChannel? channel})
      : _channel = channel ?? _defaultChannel;

  @override
  Future<List<OcrBlock>> recognize(String imagePath) async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'recognize',
      <String, Object?>{'path': imagePath},
    );
    if (result == null) return const [];
    return [
      for (final item in result)
        if (item is Map)
          OcrBlock(
            text: item['text'] as String? ?? '',
            rect: OcrRect(
              (item['x'] as num).toDouble(),
              (item['y'] as num).toDouble(),
              (item['w'] as num).toDouble(),
              (item['h'] as num).toDouble(),
            ),
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
          ),
    ];
  }
}
