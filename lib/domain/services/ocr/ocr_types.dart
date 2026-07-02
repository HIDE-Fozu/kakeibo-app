/// OCR結果の正準空間モデル。
/// 規約: 左上原点・y下向き・0..1正規化・「行」粒度・per-block確信度。
/// Apple Vision(左下原点・正規化)や ML Kit(左上原点・ピクセル)からの変換は
/// 各 OcrService 実装の責務。パーサはこの空間だけを仮定する。
class OcrRect {
  final double x;
  final double y;
  final double w;
  final double h;
  const OcrRect(this.x, this.y, this.w, this.h);

  double get centerY => y + h / 2;
  double get right => x + w;
  double get bottom => y + h;
}

class OcrBlock {
  final String text;
  final OcrRect rect;
  final double confidence;
  const OcrBlock({required this.text, required this.rect, required this.confidence});
}

/// OCRエンジンの抽象。実装: AppleVisionOcrService(iOS/Mac, 後続Phase), FakeOcrService(テスト)。
abstract interface class OcrService {
  Future<List<OcrBlock>> recognize(String imagePath);
}

/// テスト・開発用: 固定のブロック列を返す。
class FakeOcrService implements OcrService {
  final List<OcrBlock> blocks;
  const FakeOcrService(this.blocks);

  @override
  Future<List<OcrBlock>> recognize(String imagePath) async => blocks;
}
