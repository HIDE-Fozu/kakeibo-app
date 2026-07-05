/// レシート画像の取得元。カメラで撮る / 写真ライブラリから選ぶ。
enum ReceiptSource { camera, library }

/// レシート画像の取得（カメラ/ギャラリー）の抽象。
/// 戻り値はアプリ専用一時パス。キャンセル・未対応プラットフォームは null。
/// 実装: Phase 5 で image_picker（iOS カメラ/ライブラリ）。テストは Fake を注入。
abstract interface class ReceiptCapture {
  Future<String?> capture(ReceiptSource source);
}

/// 撮影非対応環境（Windows開発・Vision未配線）用: 常に null。
class UnavailableReceiptCapture implements ReceiptCapture {
  const UnavailableReceiptCapture();
  @override
  Future<String?> capture(ReceiptSource source) async => null;
}
