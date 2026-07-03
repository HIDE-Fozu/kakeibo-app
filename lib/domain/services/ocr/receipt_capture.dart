/// レシート画像の取得（カメラ/ギャラリー）の抽象。
/// 戻り値はアプリ専用一時パス。キャンセル・未対応プラットフォームは null。
/// 実装: Phase 5 で image_picker + カメラ（iOS/Mac）。テストは Fake を注入。
abstract interface class ReceiptCapture {
  Future<String?> capture();
}

/// 撮影非対応環境（Windows開発・Vision未配線）用: 常に null。
class UnavailableReceiptCapture implements ReceiptCapture {
  const UnavailableReceiptCapture();
  @override
  Future<String?> capture() async => null;
}
