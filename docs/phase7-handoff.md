# Phase 7 ハンドオフ — 入力画面リデザイン + 内訳入力（build 12）

継続の正典。まずこれを読む。前段の全体像は `docs/phase6-handoff.md`（OCR・データ収集・CloudKit・アーキ地図）を参照。

## 1行サマリ

- **ブランチ `feature/receipt-ocr`・HEAD `5852d50`・version `1.0.0+12`・ipa 生成済**
  （`build/ios/ipa/kakeibo_app.ipa`、ipa内 CFBundleVersion=12 検証済、22.5MB）。
- 作業ツリーはクリーン（全コミット済み）。**340テスト緑・`flutter analyze` 0**。
- **ユーザー待ち①: Transporter で build 12 をアップロード → 実機確認**。
- **ユーザー待ち②: 母親が撮った収集レシートを回収 → OCR精度検証 → 回帰テスト化**（下記「次アクション」）。

## build 12 に入っている変更（build 11 以降＝コミット c2c2458〜5852d50）

phase6 の build 8〜11 の続き。build 12 は未アップロードのまま追記修正を重ね、同一版番で ipa を再生成してきた。

### A. 店舗名／詳細メモの分離（`c2c2458`）
- 取引に **`storeName` 列を新設**、`memo` は自由記述の詳細専用に。**schema v3→v4**
  （`store_name` 追加 ＋ `UPDATE transactions SET store_name = memo, memo = NULL`
  で既存メモを店名へ移行＝ユーザー選択）。`lib/data/db/tables.dart` / `database.dart`。
- 影響: `entities.dart`・repository・DAO・backup(codec/service/CSV)・OCRフィクスチャの正解ラベル(store)。
  旧バックアップは storeName キー無し→ memo を店名へフォールバック。
- カレンダー行/グループカードは `txDisplayLabel`＝「店舗名 - 詳細メモ」。

### B. 共有クラッシュ修正（`4f6dbc6`）
- 設定の「テストデータを送る」が母親端末で `PlatformException(sharePositionOrigin ...)`。
  `Share.shareXFiles` に `sharePositionOrigin`（画面中央の非ゼロ矩形）を渡して全端末対応。
  （iPhoneのシート経路では不要なため環境依存だった）。

### C. 入力画面リデザイン（`a0ee631`〜、build 11 の ipa は a0ee631 まで）
- 日付を金額と同じ行へ統合・**年月日表記**（`_dateLabel`=`YYYY年M月D日`、`_pickDate`）。
- テンキー(`Numpad.cellHeight` 56→46)・カテゴリタイル(`kCatTileH` 64→56)を圧縮。
- 保存エリアを**固定フッター化**（`body`=Column>Expanded(SingleChildScrollView)+固定Padding）。
  内容が伸びても保存ボタンが画面外に出ない。
- **保存できない理由の表示**（`EntryFormState.saveHint`）: 「カテゴリを選んでください」
  「金額とカテゴリを入力してください」「内訳が合計を超えています」等。
- カテゴリグリッド上に「カテゴリ」見出し。

### D. 内訳入力（旧「詳細入力」）の税を2軸化（`697e637`）
- `SplitLine` を **`taxIncluded`(税込/税抜)+`rate`(8/10)+`taxTouched`** に（旧 `taxPercent` 廃止）。
  税込=入力額そのまま／税抜=rate を乗せ切り捨て。`amountYen`=税込値。
- 既定=**税抜10%**。**食費→自動8%・外食→10%**（`_autoRateForCategory`、名前判定：
  食費(親)orその子=8/外食=10）。手動(`taxTouched`)はカテゴリ選択で上書きしない。
- **一括**（全行の税込/税抜・税率をまとめて設定）。`setSplitBulkIncluded/Rate`。
- 保存額は**税込**。開き直しは確定額を税込・手動扱いで維持。

### E. 内訳入力の使い勝手改善（`629f00c`〜`5852d50`）
- **2行で開始**・タイプで自動追加せず「**＋追加**」ボタンで手動追加
  （`_autoExtend` 削除、`addSplitLine`、空枠は `_splitsValid`/save で無視）。
- **圧縮レイアウトでスクロール解消**（`56d6bf4`）: 行を高さ固定スクロール枠
  (`ConstrainedBox maxHeight:150`)に収め、**電卓・カテゴリは固定**＝行追加で動かない。
  重複削除（見出しは「内訳」だけ／下部の合計・一致表示を廃止）。一括1行＋「＋追加」右。
- **入力画面表示中は下部ナビ(タブ)を非表示**（`home_shell.dart`：`index==kInputTabIndex`
  なら `bottomNavigationBar: null`。戻るは入力画面の「←」）で約80px確保。
- **分割中も店名(上部)・詳細メモ**（`a37fb5e`〜）: 店名は内訳ヘッダの下線欄、
  **行ごとの詳細メモ**はカテゴリ選択後にカテゴリ名の右へ（`SplitLine.memo`、
  `_saveGroupLines` を `(cat,amount,memo)` にして各取引へ個別メモ保存。一括内訳は
  グループメモをフォールバック。開き直しも行メモ復元）。
- **行の金額表示は「入力した値」を主表示に固定**（`5852d50`）：税抜入力が勝手に税込へ
  化けない。税抜のときだけ下に「税込 ¥X」を小さく併記。残額行は「残り ¥X」。
- **呼称**: 他アプリ調査（Zaim/マネフォ＝カテゴリが主流・分割は「内訳」が標準）を経て、
  「詳細入力」→「**内訳入力**」に改名（`48087c1`→`5852d50`）。カテゴリ呼称は据え置き。

### 承認済みモック（HTML先行）
- 税・残額 v2: https://claude.ai/code/artifact/ec2b592e-47ea-4b6d-9079-4d95191f20aa
- 圧縮レイアウト: https://claude.ai/code/artifact/ead810cb-7a75-4ab8-8778-20e490107d2a

## 実装メモ（迷いやすい所）

- **内訳入力の金額モデル**: 合計は先に入れた「支払った税込総額」。内訳は「合計の内いくら」を
  レシート表記のまま入力。税抜行は税込換算し、**税込値の合計が合計に一致するか**を判定。
  末尾の空行が残額（税込）を担う（`splitLineAmount` の `hasFilled` ＋末尾判定）。
- **税用語**: 税込＝内税、税抜＝外税（逆ではない）。2021年〜消費者向けは税込総額表示が義務。
- **食費の自動税率**は名前判定（`食費`/`外食`）でやや脆い（リネームで崩れる）。
  将来カテゴリに軽減税率フラグを持たせるのが本筋。
- **モデル/UIの主なファイル**: `lib/features/entry/application/entry_form_controller.dart`
  （`EntryFormState`/`SplitLine`/save系）、`.../presentation/entry_screen.dart`（画面骨格）、
  `.../presentation/split_entry_panel.dart`（内訳パネル）、`lib/app/home_shell.dart`（タブ）。

## 次アクション

1. **build 12 を Transporter でアップロード**（no-arg で内部グループ「111」自動配信）→ 実機確認。
2. **母親の収集レシートの回収 → OCR精度検証**（本命）:
   - 現物はまだ Mac に無い。端末内 `Documents/exports/`（`UIFileSharingEnabled`/
     `LSSupportsOpeningDocumentsInPlace` 済）にある。回収経路:
     - 母の iPhone「ファイル」→ このiPhone内 → 家計簿 → exports →
       `receipt-*.json`(+写真) を選択 → 共有(AirDrop/LINE)。
     - or 設定「テストデータを送る」zip共有（build 12 で sharePositionOrigin 修正済）。
     - or CloudKit「収集データを取り込む」（自動送信ON＋本番スキーマ配備が前提）。
   - JSON には生OCRブロック＋保存確定の `expected`(合計/日付/店名) が入る。パーサに通して
     的中/外しを1枚ずつ照合 → パーサ調整 → ラベル付き実レシートを**回帰テスト**に固定化。
3. 余力: 食費の自動税率をカテゴリのフラグ化（名前依存の解消）。

## 動かし方（開発）

- **シミュレータ**: `flutter run -d <iPhone17 sim UDID> --debug`（profile はsim非対応）。
  スクショ `xcrun simctl io booted screenshot out.png`。
- **ipa**: `flutter build ipa` → `build/ios/ipa/kakeibo_app.ipa`。ipa内版番は
  `unzip` して `Payload/*.app/Info.plist` の `CFBundleVersion` で検証。
- **テスト**: `flutter test`（340緑）。`flutter analyze`（0）。
- コミットはこのブランチで、ユーザー依頼時のみ。version は次ビルドで +13。
