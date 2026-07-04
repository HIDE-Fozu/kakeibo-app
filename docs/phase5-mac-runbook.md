# Phase 5 Mac作業手順書（TestFlight配信まで）

Windows側の仕込みは完了済み。このファイルの手順をMacで上から実行すればTestFlight配信に到達する。
MacでClaude Codeを使う場合は、このファイルと `docs/phase45-handoff.md` を読ませれば続きから動ける。

## ✅ Phase 5（初回TestFlight配信）完了 — 2026-07-04

初回TestFlight配信に到達。以下すべて完了:
- App Store Connect App「**経理の家計簿**」作成（ストア表示名。端末上の名前はCFBundleDisplayName「家計簿」）
- **Bundle ID `com.hidefozu.kakeibo` は永久固定**（App作成＋App ID登録済み・以後変更不可）
- Team `Q7T6APPS23`・自動署名で `flutter build ipa` → `kakeibo_app.ipa`(21MB)をTransporterでアップロード成功
- 内部テストグループ「111」に2テスター招待済み（自動配信ON）

**残るフォローアップ（初回配信には不要）:**
- ⚠️ **アプリアイコンがFlutterデフォルトのまま** → 一般公開前に差し替え必須（内部テストは通る）
- 実レシート~15枚を貯める → Phase 5後半（Vision/カメラ）でフィクスチャ化・パーサ再調整（spec §13・下記§9）

## Mac側の進捗（2026-07-03）

| Step | 状態 | メモ |
|---|---|---|
| 1 環境構築 | ✅ 完了 | Flutter 3.44.4 / Dart 3.12.2・Xcode 26.6・CocoaPods 1.16.2・gh認証済み（全て導入済みだった） |
| 2 クローンとテスト | ✅ 完了 | `flutter analyze` 0 issues・`flutter test` **256本全緑**・`flutter doctor` iOS toolchain緑 |
| 3 Podfile | ⏭ 該当なし | SPM構成のためPodfile無し（下記§3参照） |
| 4 署名 | ✅ 完了（CLI） | pbxprojのRunner 3コンフィグに `CODE_SIGN_STYLE=Automatic`＋`DEVELOPMENT_TEAM=Q7T6APPS23` を追記（Xcode GUI不要）。`xcodebuild -showBuildSettings` で反映確認済み（Appleサーバー未接触）。コミット `38eadcd` |
| 5 スモーク確認 | ◐ 一部 | iPhone 17シミュレータ(iOS 26.4)でビルド＆起動成功・テーマ/カレンダー描画OK・DB初期化OK。UIタップ確認はユーザーで |
| 6 App Store Connect | ✅ 完了 | App「経理の家計簿」作成・App ID `com.hidefozu.kakeibo` 自動登録・Bundle ID永久固定（2026-07-04） |
| 7 build ipa→配信 | ✅ build1配信済 / build3生成済 | build1はTestFlight配信・母テスト実施。入力画面リデザイン後の**build 3 ipa生成済み（未アップロード）**。以降の続きは `docs/phase5-handoff.md` を参照 |

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

## 3. Podfileのdeployment target — 【該当なし: SPM構成】

> **【2026-07-03 Mac側で判明】このプロジェクトはCocoaPodsではなくSwift Package Manager (SPM) を使う。**
> `project.pbxproj` にSPM参照がコミット済み（Windows側 d82a7c1）で、`flutter build` しても `ios/Podfile` は**生成されない**（Pods/ ディレクトリも無い）。
> - deployment targetは Podfile ではなく **pbxprojの `IPHONEOS_DEPLOYMENT_TARGET = 16.0`（3箇所・設定済み）** が支配する。編集不要。
> - 標準プラグイン（`path_provider_foundation` / `shared_preferences_foundation`）はSPM統合。`sqlite3_flutter_libs` は native assets 機構で自動バンドル（プラグイン一覧には出ない）。
> - `flutter build ios --config-only` 実行時に `.gitignore` へ `.build/` `.swiftpm/` が自動追記される（コミット済み）。
> - **→ この節はスキップして Step 4 へ。**

## 4. 署名設定（Xcode）

```bash
open ios/Runner.xcworkspace
```

1. 左ペインで Runner プロジェクト → TARGETS Runner → **Signing & Capabilities**
2. 「Automatically manage signing」をON
3. **Team** に自分のApple Developer Programチームを選択（**確認済み Team ID = `Q7T6APPS23`（Hideaki Sato）**）
4. Bundle Identifier が `com.hidefozu.kakeibo` であること（変えるなら**この時点まで**に）
5. RunnerTests ターゲットも同様にTeamを設定

> **【2026-07-03 Mac側で判明】署名の土台は既に用意されている:**
> - Apple ID は Xcode にサインイン済み。証明書は `Apple Development` と **`Apple Distribution`（配布=TestFlight用）** の2枚がキーチェーンに存在。Team ID = **`Q7T6APPS23`**。
> - ただし pbxprojの Runner ターゲットには `DEVELOPMENT_TEAM` 未設定・`CODE_SIGN_STYLE` 未指定（デフォルトの "iPhone Developer"）。**このStep 4でTeamを選ぶと自動でAutomaticになりTeamが入る**。プロビジョニングプロファイルもこの時点でXcodeが取得/作成する。
> - CLIで済ませたい場合は pbxproj の Runner 3コンフィグに `CODE_SIGN_STYLE = Automatic;` と `DEVELOPMENT_TEAM = Q7T6APPS23;` を追記して `flutter build ipa --export-options-plist` でも可だが、初回はXcode GUIが確実（App IDの自動登録・プロファイル取得を任せられる）。

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
