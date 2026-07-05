import Flutter
import UIKit
import Vision

/// レシートOCRのプラットフォームチャネル（spec §8）。
/// MethodChannel `kakeibo/ocr` の `recognize(path)` を Apple Vision で処理し、
/// **正準空間**（左上原点・y下向き・0..1 正規化・upright）の行ブロック列
/// `[{text,x,y,w,h,confidence}]` を返す。座標系の仮定はここで吸収する（§7.1）。
final class ReceiptOcrPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kakeibo/ocr",
                                       binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ReceiptOcrPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String else {
      result(FlutterError(code: "bad_args", message: "path が必要です", details: nil))
      return
    }
    guard #available(iOS 16.0, *) else {
      // 日本語認識は Revision3（iOS 16+）が必須。deployment target は 16 だが安全側で明示。
      result(FlutterError(code: "unsupported",
                          message: "日本語OCRには iOS 16 以降が必要です", details: nil))
      return
    }
    guard let uiImage = UIImage(contentsOfFile: path),
          let cgImage = Self.uprightCGImage(uiImage) else {
      result(FlutterError(code: "bad_image", message: "画像を読み込めません", details: nil))
      return
    }

    // 認識は重いのでバックグラウンドで。結果はメインで返す。
    DispatchQueue.global(qos: .userInitiated).async {
      let request = VNRecognizeTextRequest { req, err in
        if let err = err {
          DispatchQueue.main.async {
            result(FlutterError(code: "ocr_failed", message: err.localizedDescription, details: nil))
          }
          return
        }
        let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
        var blocks: [[String: Any]] = []
        for obs in observations {
          guard let candidate = obs.topCandidates(1).first else { continue }
          // boundingBox は正規化・左下原点。左上原点へ Y 反転（§8.1）。
          let bb = obs.boundingBox
          blocks.append([
            "text": candidate.string,
            "x": bb.origin.x,
            "y": 1.0 - bb.origin.y - bb.size.height,
            "w": bb.size.width,
            "h": bb.size.height,
            "confidence": Double(candidate.confidence),
          ])
        }
        DispatchQueue.main.async { result(blocks) }
      }
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["ja-JP", "en-US"]
      request.usesLanguageCorrection = true
      request.automaticallyDetectsLanguage = false
      request.customWords = ["合計", "小計", "税込", "税抜", "お預り"]
      request.minimumTextHeight = 0
      request.revision = VNRecognizeTextRequestRevision3

      // upright に焼き込み済みなので orientation は .up。
      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  /// EXIF 由来の向きをピクセルに焼き込んで .up の CGImage を得る。
  /// これで VNImageRequestHandler に .up を渡せ、向きマッピングのバグを避ける（§8.1）。
  private static func uprightCGImage(_ image: UIImage) -> CGImage? {
    if image.imageOrientation == .up { return image.cgImage }
    let renderer = UIGraphicsImageRenderer(size: image.size)
    let normalized = renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
    return normalized.cgImage
  }
}
