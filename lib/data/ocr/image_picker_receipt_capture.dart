import 'package:image_picker/image_picker.dart';

import '../../domain/services/ocr/receipt_capture.dart';

/// image_picker によるレシート取得（iOS）。
///
/// カメラ/ライブラリのどちらでも、image_picker は選んだ画像を
/// **アプリ専用の一時パスにコピー**して返す（共有フォトライブラリに
/// 追加しない＝spec §7.6「カメラロールに残さない」を満たす）。
/// OCR 精度優先で縮小・再圧縮はしない。
class ImagePickerReceiptCapture implements ReceiptCapture {
  final ImagePicker _picker;

  ImagePickerReceiptCapture({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<String?> capture(ReceiptSource source) async {
    final file = await _picker.pickImage(
      source: source == ReceiptSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    return file?.path;
  }
}
