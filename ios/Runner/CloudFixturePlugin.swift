import CloudKit
import Flutter

/// 【テスト期間限定】収集フィクスチャ（JSON+写真+確定ラベル）を
/// CloudKit 公開DBへ送る/取り込むチャネル。オプトインのユーザーのみ使用。
/// 一般公開前に Dart 側フラグ（kCollectReceiptPhotosDuringTest）ごと撤去する。
final class CloudFixturePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kakeibo/cloud",
                                       binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(CloudFixturePlugin(), channel: channel)
  }

  private let container = CKContainer(identifier: "iCloud.com.hidefozu.kakeibo")

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "upload": upload(call, result)
    case "fetchAll": fetchAll(result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  /// recordName=フィクスチャ名で保存（同名は上書き=ラベル追記の再送に対応）。
  private func upload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let name = args["name"] as? String,
          let json = args["json"] as? String else {
      result(FlutterError(code: "bad_args", message: "name/json が必要です", details: nil))
      return
    }
    let photoPath = args["photoPath"] as? String
    let db = container.publicCloudDatabase
    let recordID = CKRecord.ID(recordName: name)

    func fail(_ error: Error) {
      DispatchQueue.main.async {
        result(FlutterError(code: "upload_failed",
                            message: error.localizedDescription, details: nil))
      }
    }

    db.fetch(withRecordID: recordID) { existing, _ in
      // 未存在エラーは新規作成として正常系
      let record = existing ?? CKRecord(recordType: "Fixture", recordID: recordID)
      record["json"] = json as CKRecordValue
      if let p = photoPath, FileManager.default.fileExists(atPath: p) {
        record["photo"] = CKAsset(fileURL: URL(fileURLWithPath: p))
      }
      db.save(record) { _, error in
        if let error = error { fail(error); return }
        DispatchQueue.main.async { result(true) }
      }
    }
  }

  /// 開発者端末用: 全レコードを取得して [{name, json, photoPath?}] で返す。
  /// 写真は一時ディレクトリへコピーして返す。
  private func fetchAll(_ result: @escaping FlutterResult) {
    let db = container.publicCloudDatabase
    var items: [[String: Any]] = []
    let tmp = FileManager.default.temporaryDirectory
      .appendingPathComponent("ck-fixtures", isDirectory: true)
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

    func collect(_ record: CKRecord) {
      var item: [String: Any] = ["name": record.recordID.recordName]
      item["json"] = record["json"] as? String ?? ""
      if let asset = record["photo"] as? CKAsset, let url = asset.fileURL {
        let dest = tmp.appendingPathComponent(record.recordID.recordName + ".jpg")
        try? FileManager.default.removeItem(at: dest)
        if (try? FileManager.default.copyItem(at: url, to: dest)) != nil {
          item["photoPath"] = dest.path
        }
      }
      items.append(item)
    }

    func run(_ cursor: CKQueryOperation.Cursor?) {
      let op: CKQueryOperation
      if let cursor = cursor {
        op = CKQueryOperation(cursor: cursor)
      } else {
        let query = CKQuery(recordType: "Fixture", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        op = CKQueryOperation(query: query)
      }
      op.recordMatchedBlock = { _, r in
        if case .success(let record) = r { collect(record) }
      }
      op.queryResultBlock = { r in
        switch r {
        case .success(let next):
          if let next = next { run(next) } else {
            DispatchQueue.main.async { result(items) }
          }
        case .failure(let error):
          DispatchQueue.main.async {
            result(FlutterError(code: "fetch_failed",
                                message: error.localizedDescription, details: nil))
          }
        }
      }
      db.add(op)
    }
    run(nil)
  }
}
