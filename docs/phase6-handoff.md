# Phase 6 ハンドオフ（2026-07-08 / build 8・feature/receipt-ocr）

**次セッションはこのファイルから再開する**（旧: `docs/phase5-handoff.md` は履歴）。
フェーズの主題: **TestFlightで母親から実データを収集 → expected付き実データでOCR/パーサを鍛える → 公開準備**。

## いまどこ（TL;DR）

- ブランチ **`feature/receipt-ocr`**（main未マージ・未push）。主要コミット:
  e9ccf49=OCR実装 / 2115097=一括内訳+splitGroupId / f23da34=正解ラベル書き戻し / 49cdf3f=CloudKit自動送信。
- **build 8（1.0.0+8）の ipa 生成済み**（`build/ios/ipa/kakeibo_app.ipa`）。**Transporterアップロードはユーザー待ち**（Deliver→内部グループ「111」へ自動配信）。build 5〜7は未アップロードの欠番（問題なし。重複だけNG）。**次のビルドは +9**。
- コード: **333テスト全緑・analyze 0**。実レシートフィクスチャ10枚同梱（`test/fixtures/receipts/`、観測は `test/receipt/real_fixture_probe_test.dart` のprint）。

## build 8 に入っている機能

1. **レシートOCR**: Apple Vision（`ios/Runner/ReceiptOcrPlugin.swift`、正準空間=左上原点0..1へY反転）＋カメラ/写真取得。
2. **パーサ**: 合計（クレジット行クロスチェック・小計±税導出・候補チップ）／日付／店名候補（**ゾーン=最初の日付行より上**。OKストア対応済み）／明細行抽出（`items.dart`）。
3. **一括内訳モード**（OCR明細がある時の「詳細入力」）: 明細行は**写真の行切り抜き**（`receipt_line_strip.dart`）。D1選んで割当/D2塗り分けトグル・税ヘッダ(内税/外税8/10)+行%上書き(※→外税10%時自動8%)・B2レシート紙照合・差額行（同カテゴリ合算）。手入力時は電卓行方式（＋−×÷左から・切り捨て）にフォールバック。
4. **「1枚のレシート」**: schema **v3** `transactions.splitGroupId`。日別一覧C1グループカード（ヘッダタップ→詳細入力で開き直し=置換保存・groupId引継）。バックアップJSON/CSV追随済み。
5. **テストデータ収集（全て `kCollectReceiptPhotosDuringTest` 配下・公開前に撤去）**:
   - スキャン毎に JSON（200件）＋写真（30枚）を `exports/ocr-fixtures` にローリング保存
   - **保存確定値（合計/日付/店名）を expected として書き戻し**＝普通に使うだけで正解ラベル付きデータになる
   - 設定「テストデータを送る」= zip→共有シート（手動）
   - 設定「テスト協力（自動送信）」= **オプトイン**でCloudKit公開DBへ自動送信（起動時に未送信再送）
   - 設定「収集データを取り込む（開発者用）」= 全端末分→ `exports/ocr-collected`

## ユーザーがやること（未完了）

1. **CloudKit初回儀式**（順番厳守。実機TI10B1に配備済みの開発(profile)ビルドで）:
   a. 設定→「テスト協力（自動送信）」ON → レシート1枚スキャン→保存（Dev環境にFixture型が自動作成される）
   b. icloud.developer.apple.com → コンテナ `iCloud.com.hidefozu.kakeibo` → Schema → Fixture → Indexes に **recordName: Queryable** 追加
   c. **Deploy Schema Changes to Production**
2. **Transporter で build 8 をアップロード** → 母親の端末でスイッチON（初回設定を手伝うのが確実）。
3. 修正点・データ送信の報告があれば次セッションへ。

## 次セッションの作業候補

- 収集データ（`exports/ocr-collected` or zip）を `test/fixtures/receipts/` に取り込み、**expected付き回帰テスト化**→パーサ調整（probeテストで観測→修正のループ）。
- 実機フィードバックの修正（報告ベース）。
- 公開準備: `kCollectReceiptPhotosDuringTest=false`・アプリアイコン差し替え（必須）・feature→mainマージ・push・App Store審査情報。
- ロードマップ登録済み: **入力履歴ビュー**（日をまたぐ履歴一覧から編集・削除。日単位は対応済み）。

## リリース系の確定情報（変更不可）

| 項目 | 値 |
|---|---|
| Bundle ID | `com.hidefozu.kakeibo`（永久固定） |
| Team ID | `Q7T6APPS23` |
| App | 「経理の家計簿」/ SKU `kakeibo-001` / 日本語 |
| TestFlight | 内部グループ「111」・自動配信ON |
| CloudKitコンテナ | `iCloud.com.hidefozu.kakeibo`（entitlements設定済み） |
| 現在バージョン | `1.0.0+8`（次は+9） |

## 開発環境の要点

- **debugビルドはホーム画面から起動不可**（JIT制約）。実機は `flutter build ios --profile` → `xcrun devicectl device install app --device 00008140-00180D0911C2801C build/ios/iphoneos/Runner.app` → `... process launch ... com.hidefozu.kakeibo`。
- 実機のフィクスチャ回収: `xcrun devicectl device copy from --device 00008140-00180D0911C2801C --source Documents/exports/ocr-fixtures --destination <dir> --domain-type appDataContainer --domain-identifier com.hidefozu.kakeibo`（release/TestFlightビルドでは不可→Finderのファイル共有 or アプリ内ボタン）。
- SPM構成（Podfile無し）。Swiftファイル追加時は pbxproj に4箇所手動登録（BuildFile/FileRef/Group/Sources。AA01F00x... のID採番例あり）。
- 見た目確認: `home_shell.dart` initState postFrame に `// TEMP-DEMO` を仕込み→シミュレータ（iPhone17 `9EC1319F-...`）でスクショ→**必ず撤去**（`grep -rc TEMP-DEMO lib/` = 0）。
- UIモック（確定済みの選定; 経緯参照用）: https://claude.ai/code/artifact/ade361b4-d022-4590-aa77-288bc167ed1f — D1+D2/A4改/B2/C1。

## アーキテクチャ地図（今回分）

- OCR: `lib/data/ocr/apple_vision_ocr_service.dart` / `image_picker_receipt_capture.dart` / `ocr_fixture_recorder.dart`（写真収集・expected書き戻し）/ `ocr_fixture_share.dart`（zip）/ `cloud_fixture_uploader.dart`（CloudKit）。Swift: `ReceiptOcrPlugin.swift` / `CloudFixturePlugin.swift`。
- パーサ: `lib/domain/services/receipt/`（total/date/store/items/rows/amounts/normalize）。合成は `receipt_parser.dart`（ParsedReceipt: total/date/store候補/itemLines）。
- 入力: `entry_form_controller.dart`（SplitLine電卓分割・BatchItem一括内訳・_saveGroupLines共通保存・_labelFixture）。UI: `batch_itemize_panel.dart` / `split_entry_panel.dart` / `receipt_line_strip.dart` / `receipt_review_panel.dart`（店名候補チップ）。
- 一覧: `day_transaction_list.dart`（C1グループカード・開き直し）。
- DB: schema v3（`splitGroupId`）。マイグレーションテスト `test/migration_test.dart`。

## ユーザーの要望・スタイル（守ること）

- 用語は「カテゴリ／内訳」（一括内訳の呼称は「詳細入力/一括内訳」。分割の呼称に「内訳を入力」は不採用=用語衝突）。
- UI変更は実機基準・最小差分。**ただし難しいUIはユーザー指示によりHTMLモック先行が実績あり**（多種=構造違い・カラートーンは実配色で統一・色違いは重複扱い）。
- 税の端数は**切り捨て**・電卓は**左から**評価。
- 「財務データを自動送信しない」原則: テスト収集はオプトイン+期間限定フラグで例外化した経緯（ユーザー確認済み）。**公開前に必ず撤去**。
