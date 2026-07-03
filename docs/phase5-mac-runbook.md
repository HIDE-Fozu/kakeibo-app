# Phase 5 Mac作業手順書（TestFlight配信まで）

Windows側の仕込みは完了済み。このファイルの手順をMacで上から実行すればTestFlight配信に到達する。
MacでClaude Codeを使う場合は、このファイルと `docs/phase45-handoff.md` を読ませれば続きから動ける。

## Windows側で設定済みのもの（2026-07-03）

| 項目 | 値 | 変更する場合 |
|---|---|---|
| Bundle ID | `com.hidefozu.kakeibo` | `ios/Runner.xcodeproj/project.pbxproj` を一括置換（**App Store ConnectでApp作成後は変更不可**。作成前なら自由） |
| iOS deployment target | **16.0**（Vision日本語認識の下限） | 同上pbxproj 3箇所 |
| アプリ表示名 | 家計簿 | `ios/Runner/Info.plist` の CFBundleDisplayName |
| Files共有 | UIFileSharingEnabled / LSSupportsOpeningDocumentsInPlace = true | バックアップJSON/CSVをFilesアプリから取り出す経路（spec確定） |
| 輸出コンプライアンス | ITSAppUsesNonExemptEncryption = false | バックアップ暗号化はAES-GCM等の標準アルゴリズム＝免除対象。ビルド毎の質問がスキップされる |

## 0. 前提（ユーザー確認済み）

- Apple Developer Program 登録済み（$99/年）
- Mac + Xcode（最新の安定版をApp Storeから）

## 1. Mac環境構築

```bash
xcode-select --install                # コマンドラインツール
sudo xcodebuild -license accept
# Flutter SDK（Windows側は 3.44.4 / Dart 3.12.2。同系列を入れる）
# https://docs.flutter.dev/get-started/install/macos → PATHを通す
flutter precache --ios
sudo gem install cocoapods            # または brew install cocoapods
gh auth login                         # GitHub CLI（またはSSHキー設定）
```

## 2. クローンとテスト

```bash
gh repo clone HIDE-Fozu/kakeibo-app && cd kakeibo-app
flutter pub get
flutter analyze     # 期待: 0 issues
flutter test        # 期待: 256本全緑（Windowsと同じ）
flutter doctor      # iOS toolchainが緑であること
```

## 3. Podfileのdeployment target（初回ビルド時に生成される）

初回の `flutter build` / `pod install` で `ios/Podfile` が生成される。生成されたら先頭付近の
`# platform :ios, '13.0'` のコメントを外して **`platform :ios, '16.0'`** に変更してコミット。

## 4. 署名設定（Xcode）

```bash
open ios/Runner.xcworkspace
```

1. 左ペインで Runner プロジェクト → TARGETS Runner → **Signing & Capabilities**
2. 「Automatically manage signing」をON
3. **Team** に自分のApple Developer Programチームを選択
4. Bundle Identifier が `com.hidefozu.kakeibo` であること（変えるなら**この時点まで**に）
5. RunnerTests ターゲットも同様にTeamを設定

## 5. シミュレータ/実機でスモーク確認

```bash
flutter run   # シミュレータでOK。実機ならiPhoneを接続して選択
```

確認項目（Phase 4.5の新機能）:
- [ ] 入力: 食費タップ→内訳チップ（外食）→選択でボタンラベルが「外食 ▾」
- [ ] カレンダーセルが万表記（1.2万）・支出紅
- [ ] サマリ: 食費の積み上げバー＋「▼内訳」展開で（内訳なし）と外食
- [ ] カテゴリ管理: ＋内訳で追加・└表示
- [ ] 設定→エクスポート→**Filesアプリの「このiPhone内/家計簿」にJSONが見える**（UIFileSharingEnabledの確認）
- [ ] レシートボタン→「この端末ではレシート撮影を利用できません」SnackBar（Vision実装前の正常挙動）

## 6. App Store Connect の準備（Webで一度だけ）

1. developer.apple.com → Certificates, Identifiers & Profiles → **Identifiers → App IDs → +**
   - Bundle ID: `com.hidefozu.kakeibo`（Explicit）・Capabilitiesは既定のまま
2. appstoreconnect.apple.com → マイApp → **+ → 新規App**
   - プラットフォーム: iOS ／ 名前: 家計簿（ストア全体でユニーク制約。弾かれたら「家計簿 - シンプル家計簿」等に）
   - プライマリ言語: 日本語 ／ Bundle ID: 上で作ったもの ／ SKU: `kakeibo-001`

## 7. ビルド → アップロード → TestFlight

```bash
flutter build ipa   # 成果物: build/ios/ipa/kakeibo_app.ipa
```

アップロードはどちらか:
- **Transporterアプリ**（Mac App Store）にipaをドラッグ&ドロップ → 配信
- または Xcode → Product → Archive → Distribute App → App Store Connect

その後:
1. App Store Connect → 対象App → **TestFlight** タブ（ビルドの処理完了まで数分〜30分待つ）
2. **内部テスト** → グループ作成 → 自分のApple IDをテスターに追加
3. iPhoneに **TestFlightアプリ** を入れ、招待メールから受諾 → インストール

**内部テスターのみなら審査なし**で即配信される（ビルドアップロードのたびに自動配布）。

## 8. 配信後（実データ運用開始）

- 実データを入れ始める前提でOK（バックアップ/復元はformatVersion 2で後方互換が保証されている）
- **レシートを15枚ほど貯めておく**: Phase 5後半でVision/カメラを実装したら、
  実レシートでフィクスチャを作りパーサ再調整する（spec §13）

## 9. Phase 5後半（Vision/カメラ・別途planを書く）

初回配信には含めない。スコープ:
- `ReceiptCapture` のiOS実装（カメラ/フォトライブラリ → NSCameraUsageDescription等をこの時点で追加）
- `OcrService` のVision実装（VNRecognizeTextRequest・日本語・iOS 16+）
- 実レシートフィクスチャ→ `receipt_parser` 再調整
- 進め方はいつもの型（writing-plans → 敵対的検証workflow → インラインTDD）
