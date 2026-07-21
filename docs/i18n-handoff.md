# i18n ハンドオフ — 多言語・国際化リリース（feature/i18n）

継続の正典（この作業ライン）。まずこれを読む。前段の受入版は `docs/phase8-handoff.md`
（内訳入力リデザイン収束・build 15）。i18n は build 15 の上に載せた大改修。

## 1行サマリ

- **ブランチ `feature/i18n`・HEAD `f4ddf30`・version `2.0.0+16`・ipa 生成＆検証済**
  （`build/ios/ipa/kakeibo_app.ipa`・23.0MB・ipa内 CFBundleShortVersionString=2.0.0 /
  CFBundleVersion=16 / CFBundleLocalizations=9言語 を検証済）。
- **Phase 1〜9 実装完了・370テスト緑・`flutter analyze` 0・gen-l10n 未翻訳 0**。作業ツリー
  クリーン（f4ddf30 に全部コミット済・**未push**）。
- **9ロケール**（ja/en/zh簡体/ko/es/fr/de/it/pt）で動く。日本特化部分（円/万/8-10%消費税/
  レシートOCR）は **JPYのとき従来通り**、非JPでは自然に無効化。JPYの挙動はバイト等価。
- **ユーザー待ち = 本リリース手順（下記「本リリースまでの手順」）**。

## 確定仕様（ユーザー決定・このセッションで確定）

- **1アプリ**多ロケール（別アプリ化はしない）。
- **小数通貨まで対応**（完全国際版）。`amount` を「整数 minor unit」に一般化（JPY=0桁で
  既存データ移行不要）。金額入力は**左→右の自然入力＋小数点キー**（英米の家計簿アプリ標準）。
- **カテゴリは端末言語でローカライズ**（slug 方式）。
- **OCRはJPYのとき隠す**（日本語レシート専用）。**非JP(JPY以外)は消費税UI非表示**。
- **取引が1件でもあれば通貨変更ロック**（行ごとの通貨列は無く、アプリ全体で1通貨のため）。
- **CSVヘッダ・区分・支払方法は英語固定**（相互運用）。カテゴリ名/メモはユーザーデータ。

## 実装マップ（どこに何があるか）

- 計画: `~/.claude/plans/tingly-napping-bunny.md`（Phase 1〜9 の全設計）。
- ARB: `lib/l10n/app_*.arb`（**189キー×9ロケール**）＋生成物 `lib/l10n/app_localizations*.dart`。
  `l10n.yaml`。翻訳は placeholder 整合を全言語検証済。
- i18n provider: `lib/app/l10n_providers.dart`（effectiveLocale / appLocalizations /
  currency / moneyFormatter / taxProfile）。
- 通貨: `lib/core/money.dart`（`Currency` / `MoneyFormatter`。JPYは既存 formatYen 等に委譲・
  他は intl）。`lib/core/format.dart` は JPY ヘルパとして残置。
- 電卓の小数: `lib/features/entry/application/split_calc.dart` `evalCalcExpr(expr,{decimals})`。
  入力バッファ `EntryFormState.amountText`。小数点キー `numpad.dart`（`np-dot`・00と入替）。
- カテゴリ slug: `lib/data/db/tables.dart`（`Categories.slug`）・schema **v5**＋名前一致
  バックフィル（`database.dart`）。シード定義 `lib/data/db/category_seeds.dart`（slug/emoji/
  9言語名）。絵文字 `lib/core/category_emoji.dart`（slug基準）。自動税率も slug基準。
- 税: `lib/core/tax_config.dart`（`TaxProfile`・`taxProfileProvider`=JPY→日本税/他→kNoTax）。
- 設定: 言語/通貨ピッカー `lib/features/settings/presentation/settings_screen.dart`
  （`language-tile`/`currency-tile`）。`SettingsState.locale`/`currencyCode`。
- バックアップ: `formatVersion 2→3` で slug を round-trip（`backup_codec.dart`）。
- iOS: `ios/Runner/Info.plist` に `CFBundleLocalizations`（9言語）。

## 本リリースまでの手順（次回セッションで支援）

1. **ipa を App Store Connect へアップロード**
   - Transporter（macOSアプリ）に `build/ios/ipa/kakeibo_app.ipa` をドラッグ＆ドロップ、
     または `xcrun altool --upload-app --type ios -f build/ios/ipa/kakeibo_app.ipa
     --apiKey <KEY> --apiIssuer <ISSUER>`。
   - **これはユーザーの手動作業**（過去ビルドも Transporter 手動アップロード）。build 16 は
     version 2.0.0 なので ASC 側で新バージョン 2.0.0 の枠が要る場合あり。
2. **App Store Connect: 9ロケールのストア掲載情報**（ユーザー作業・コード外）
   - 各ロケール（ja/en/zh-Hans/ko/es/fr/de/it/pt）にアプリ名/サブタイトル/キーワード/説明/
     スクショ。主要言語は日本語のまま。※ **アプリ内文言(ARB)とは別物**。ここは私が下書きを
     作れる（各言語の説明文/キーワード）ので、次回セッションで依頼可。
3. **実機/simで9言語の目視QA**（次回セッションで私が sim ドライブ可能）
   - 特に狭いUI（税セグメント・電卓・カテゴリ帯）で長文言語（de/fr）が崩れないか。widget test
     では en/de のタブ描画オーバーフローは検知済み（`test/ui/localization_test.dart`）だが、
     入力/内訳/一括の実描画は未目視。
   - 通貨を USD/EUR にして小数点入力（12.50→$12.50）と、JPY で従来通り（¥・万・8/10%税・
     OCRボタン表示）を回帰確認。
4. **ブランチ統合**: `feature/i18n` を main（or 運用ブランチ）へマージ。**未push**なので方針は
   ユーザーに確認（他プロジェクトは master/main マージ済の例あり）。
5. **TestFlight → 審査提出**。
6. **（任意polish）iOSホーム画面のアプリ名ローカライズ**: `ios/Runner/<locale>.lproj/
   InfoPlist.strings` の `CFBundleDisplayName`。**pbxproj に lproj 登録が要る**ため保留中
   （Xcode無しだと壊しやすい）。アプリ名は appTitle と同じ（en=Kakeibo/zh=家计簿/ko=가계부/
   欧州=Kakeibo/ja=家計簿）。カメラ/写真の権限文言は日本語のまま（OCRがJPY限定＝非JPでは
   発火しないので可）。

## 検証状況

- `flutter analyze` 0・`flutter test` 370緑・`flutter gen-l10n` 未翻訳0。
- 新規テスト: `test/core/money_test.dart`（通貨書式）・`test/ui/localization_test.dart`
  （en描画＋de無オーバーフロー）・`test/category_seeds_test.dart`（ja/en/ko/es/fallback）・
  `split_calc_test`（小数）・controller の小数入力/税プロファイル。
- 更新: format/controller/csv/migration/seed/backup を l10n・slug・minor unit に対応。

## 持ち越し宿題（i18nとは別・phase8から継続）

- 母親の収集レシート（生OCR＋保存確定 expected ラベル）を回収 → パーサ通しで精度検証 →
  回帰テスト化。`kCollectReceiptPhotosDuringTest` は公開前に false 必須（テスト送信一式を撤去）。
