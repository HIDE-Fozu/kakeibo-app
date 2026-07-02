# Apple Vision OCR → Flutter MethodChannel: Technical Brief

Scope: on-device, offline text recognition for Japanese receipts, exposed to Flutter iOS via a `MethodChannel`. Framework: `Vision` (`import Vision`). No network, no entitlements needed — the models ship with the OS.

## 1. Core API surface

- **Request:** `VNRecognizeTextRequest` (a `VNImageBasedRequest`).
- **Runner:** `VNImageRequestHandler(cgImage:orientation:options:)` → `handler.perform([request])` (synchronous; run off the main thread).
- **Results:** `request.results` is `[VNRecognizedTextObservation]`.

### VNRecognizedTextObservation output structure
`VNRecognizedTextObservation` inherits the geometry chain `VNObservation → VNDetectedObjectObservation → VNRectangleObservation → VNRecognizedTextObservation`, so each observation carries:

- `func topCandidates(_ maxCandidateCount: Int) -> [VNRecognizedText]` — ranked candidate strings for that text region.
- Each `VNRecognizedText` has:
  - `string: String` — the recognized text.
  - `confidence: VNConfidence` (`Float`, 0.0–1.0).
  - `func boundingBox(for range: Range<String.Index>) throws -> VNRectangleObservation?` — tighter box for a *substring* (useful to crop a price/date out of a line).
- `boundingBox: CGRect` — **normalized [0,1], origin at BOTTOM-LEFT** (Vision convention, y increases upward). This is the region-level box.
- Corner points `topLeft / topRight / bottomLeft / bottomRight` (`CGPoint`, normalized) — the true quadrilateral, non-axis-aligned; use these if the receipt is skewed.
- `confidence: VNConfidence` — region-level confidence (distinct from per-candidate confidence).

Typical extraction: take `topCandidates(1).first`, read its `.string` and `.confidence`, and pair it with the observation's `.boundingBox`.

## 2. Recommended settings for Japanese receipts

```swift
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate            // NOT .fast — accuracy matters for kanji/digits
request.revision = VNRecognizeTextRequest.currentRevision   // or pin: VNRecognizeTextRequestRevision3
request.automaticallyDetectsLanguage = false    // iOS 16+; force the language set explicitly
request.recognitionLanguages = ["ja-JP", "en-US"]  // JA first; en for ASCII digits/¥/店名
request.usesLanguageCorrection = true           // keep ON for prose; see caveat below
request.minimumTextHeight = 0.0                 // 0 = detect smallest text (receipts have tiny rows); raise (e.g. 1/32) to speed up
request.customWords = ["合計", "小計", "税込", "税抜", "お預り", "釣り", "ポイント"]  // only used when usesLanguageCorrection == true
```

Notes / trade-offs:
- **`recognitionLanguages`** are BCP-47 codes. The canonical Japanese entry returned by the OS is **`"ja-JP"`** (plain `"ja"` is also accepted). Order = priority.
- **`usesLanguageCorrection`**: helps kana/kanji words but can "correct" product codes / SKUs / phone numbers. If you find digit strings being mangled, run a second pass with correction off, or rely on `customWords` to anchor known tokens. `customWords` are ignored when correction is off.
- **`minimumTextHeight`** is a fraction of image height. Lower = catch small print, slower. `0.0` lets Vision decide.
- Verify at runtime what the current OS actually supports:
  ```swift
  let langs = try VNRecognizeTextRequest.supportedRecognitionLanguages(
      for: .accurate, revision: VNRecognizeTextRequestRevision3)
  ```

## 3. iOS version availability (load-bearing constraint)

| Revision | Min OS | Japanese? |
|---|---|---|
| `VNRecognizeTextRequestRevision1` | iOS 13 | No (Latin only) |
| `VNRecognizeTextRequestRevision2` | iOS 14 | No (adds more Latin + Chinese) |
| **`VNRecognizeTextRequestRevision3`** | **iOS 16.0 / iPadOS 16 / macOS 13** | **Yes — Japanese & Korean added here** |

**Japanese recognition requires iOS 16+.** Set your Podfile / deployment target accordingly, and gate the code with `if #available(iOS 16.0, *)`. `automaticallyDetectsLanguage` is also iOS 16+. On <16 you should fail gracefully back to Flutter (return an error over the channel) or restrict to Latin.

## 4. Coordinate conversion (normalized bottom-left → pixel top-left)

Vision's box is normalized with a **bottom-left origin**; Flutter/UIKit/image pixels use **top-left origin**. You must flip Y.

```swift
/// Convert a Vision normalized rect (bottom-left origin) to pixel rect (top-left origin).
func pixelRect(_ box: CGRect, width W: CGFloat, height H: CGFloat) -> CGRect {
    let x = box.origin.x * W
    let w = box.size.width  * W
    let h = box.size.height * H
    let y = (1.0 - box.origin.y - box.size.height) * H   // flip Y
    return CGRect(x: x, y: y, width: w, height: h)
}
```
`VNImageRectForNormalizedRect(box, Int(W), Int(H))` exists but **keeps Vision's bottom-left origin** — you'd still flip Y afterward, so the explicit math above is clearer. Use `W`/`H` of the **oriented** image (post-orientation, see §5).

## 5. Orientation, rotation, and vertical Japanese text

- Pass the photo's EXIF orientation into the handler so Vision reads upright text: `VNImageRequestHandler(cgImage:, orientation: cgOrientation, options: [:])`. Map from `UIImage.imageOrientation`:

```swift
func cgOrientation(from ui: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch ui {
    case .up: return .up;                     case .down: return .down
    case .left: return .left;                 case .right: return .right
    case .upMirrored: return .upMirrored;     case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored; case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
}
```
- Returned bounding boxes are in the coordinate space of the **oriented** image. So when converting to pixels, use the oriented dimensions: if orientation is `.left/.right/.leftMirrored/.rightMirrored`, swap `CGImage` width/height. Simplest robust path: **bake orientation into pixels first** (redraw the `UIImage` into an `.up` `CGImage`) and then pass `.up` — this eliminates the swap bookkeeping.
- **Vertical Japanese (縦書き):** Vision is optimized for horizontal text. Revision 3 handles Japanese but vertical columns are the weak spot — a column may fragment into multiple observations, per-character boxes, or reordered candidates, with lower confidence. Mitigations: (a) if you control capture, prompt for horizontal orientation; (b) detect vertical layout heuristically (tall-narrow boxes stacked in a column) and re-order/merge in your own post-processing; (c) don't rely on reading order from Vision — reconstruct layout yourself from the pixel boxes (sort by column-x then y). Treat vertical support as best-effort, not guaranteed.

## 6. Full OCR + serialization for MethodChannel

Flutter's `StandardMethodCodec` maps directly to `NSNumber`/`NSString`/`NSArray`/`NSDictionary`, so you can **return native `[[String: Any]]` directly** (preferred — Dart receives `List<Map>`). A JSON `String` alternative via `Codable` is also shown.

```swift
import Vision
import UIKit

struct OCRWord: Codable {
    let text: String
    let x: Double, y: Double, w: Double, h: Double   // pixel, top-left origin
    let confidence: Double
}

enum OCRError: Error { case badImage, unsupportedOS }

@available(iOS 16.0, *)
func recognize(cgImage: CGImage,
               orientation: CGImagePropertyOrientation) throws -> [OCRWord] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.revision = VNRecognizeTextRequestRevision3
    request.automaticallyDetectsLanguage = false
    request.recognitionLanguages = ["ja-JP", "en-US"]
    request.usesLanguageCorrection = true
    request.minimumTextHeight = 0.0
    request.customWords = ["合計", "小計", "税込", "税抜"]

    let handler = VNImageRequestHandler(cgImage: cgImage,
                                        orientation: orientation, options: [:])
    try handler.perform([request])

    let W = CGFloat(cgImage.width), H = CGFloat(cgImage.height)   // see §5 re: orientation swap
    let observations = request.results ?? []
    return observations.compactMap { obs -> OCRWord? in
        guard let best = obs.topCandidates(1).first else { return nil }
        let r = pixelRect(obs.boundingBox, width: W, height: H)
        return OCRWord(text: best.string,
                       x: Double(r.origin.x), y: Double(r.origin.y),
                       w: Double(r.size.width), h: Double(r.size.height),
                       confidence: Double(best.confidence))
    }
}
```

MethodChannel wiring (in `AppDelegate` or a `FlutterPlugin`). Do the CPU-heavy `perform` off the main thread and hop back for `result`:

```swift
let channel = FlutterMethodChannel(name: "app/ocr",
                                   binaryMessenger: controller.binaryMessenger)
channel.setMethodCallHandler { call, result in
    guard call.method == "recognize" else { result(FlutterMethodNotImplemented); return }
    guard #available(iOS 16.0, *) else {
        result(FlutterError(code: "UNSUPPORTED_OS", message: "Requires iOS 16+", details: nil)); return
    }
    // Accept either a file path or raw bytes from Dart:
    let args = call.arguments as? [String: Any]
    guard let image = Self.loadImage(from: args),                 // -> UIImage
          let cg = image.cgImage else {
        result(FlutterError(code: "BAD_IMAGE", message: "Cannot decode image", details: nil)); return
    }
    let orient = cgOrientation(from: image.imageOrientation)

    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let words = try recognize(cgImage: cg, orientation: orient)

            // Option A — return native structures (StandardMethodCodec):
            let payload: [[String: Any]] = words.map {
                ["text": $0.text,
                 "rect": ["x": $0.x, "y": $0.y, "w": $0.w, "h": $0.h],
                 "confidence": $0.confidence]
            }
            DispatchQueue.main.async { result(payload) }   // Dart: List<Map>

            // Option B — return a JSON string instead:
            // let data = try JSONEncoder().encode(words)
            // let json = String(data: data, encoding: .utf8)
            // DispatchQueue.main.async { result(json) }
        } catch {
            DispatchQueue.main.async {
                result(FlutterError(code: "OCR_FAILED", message: "\(error)", details: nil))
            }
        }
    }
}
```

Passing image bytes from Dart arrives as `FlutterStandardTypedData`; read `.data` and `UIImage(data:)`. For a file path, `UIImage(contentsOfFile:)`.

### JSON shape delivered to Dart
```json
[
  { "text": "合計", "rect": { "x": 42.0, "y": 880.5, "w": 96.0, "h": 34.0 }, "confidence": 0.97 },
  { "text": "¥1,280", "rect": { "x": 300.0, "y": 880.0, "w": 140.0, "h": 36.0 }, "confidence": 0.91 }
]
```
Coordinates are **pixels, top-left origin**, matching the oriented image you can display in Flutter (scale by displayed-widget size / image size to overlay boxes).

## Implementation gotchas checklist
- Deployment target **iOS 16+** for `"ja-JP"`; guard with `#available`.
- Flip Y and, if not pre-baking orientation, swap W/H for `.left/.right` orientations.
- Use `topCandidates(1)` and its per-candidate `confidence`, not just the region confidence, if you filter by threshold (e.g. drop < 0.3).
- Prefer returning `List<Map>` natively over a JSON string — avoids a double encode/parse; both are valid.
- Vertical text: reconstruct reading order yourself from boxes; don't trust Vision's ordering.
- Run `perform` off the main thread; a full-res receipt in `.accurate` can take 100s of ms.

Sources: [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest), [supportedRecognitionLanguages(for:revision:)](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/supportedrecognitionlanguages(for:revision:)), [VNRecognizeTextRequestRevision3](https://developer.apple.com/documentation/vision/vnrecognizetextrequestrevision3), [automaticallyDetectsLanguage](https://developer.apple.com/documentation/vision/recognizetextrequest/automaticallydetectslanguage), [Japanese config example (GitHub)](https://github.com/tomoakiWeb/VisionFoundationModel).