# Phase 8 ハンドオフ — 内訳入力リデザイン収束（build 13〜15）

継続の正典。まずこれを読む。前段は `docs/phase7-handoff.md`（build 12・入力画面リデザイン）、
さらに前は `docs/phase6-handoff.md`（OCR・CloudKit・アーキ地図）。

## 1行サマリ

- **ブランチ `feature/receipt-ocr`・HEAD `5460b21`・version `1.0.0+15`・ipa 生成済＆アップロード済**
  （`build/ios/ipa/kakeibo_app.ipa`、ipa内 CFBundleVersion=15 検証済、22.5MB）。
- 作業ツリーはクリーン（全コミット済み）。**343テスト緑・`flutter analyze` 0**。
- **ユーザーが 2026-07-21 に build 15 を Transporter でアップロード済** → 実機で内訳入力を試す段階。
- **本命の宿題（未着手）: 母親の収集レシートを回収 → OCR精度検証 → 回帰テスト化**（後述）。

## このフェーズでやったこと（build 12 → 15）

内訳入力（分割入力）画面をユーザーと多数往復して作り込んだ。build 13〜15 の3コミット。

### build 13（`c29ecf8`）— 内訳リデザイン第1版＋色調整
- 前セッションからの未コミット「内訳入力リデザイン」を確定コミット。
  カテゴリを電卓に被せるボトムシートで選ぶ方式／leafカテゴリ確定で残額行を自動追加／
  税率を「行ごと個別・一括」の2モード（`splitPerLineTax`）。
- 追加: **税ボタン選択色をパステル化**（`scheme.primary`濃緑塗り＋白 →
  `scheme.primary.withValues(alpha:.22)`淡ティント＋濃緑文字＋w700。alphaベースなので
  custom accentでも自動パステル化）。**内訳行の「税込 ¥X」を可読色に**
  （`scheme.outline`＝罫線色kLine → `scheme.onSurfaceVariant`＝二次テキスト色）。
- **見送った案**: (a)電卓の「次へ(Enter)」＝使いづらいと判断・配線前に廃止。
  (b)「常に3行開始」＝`startSplit`を3行にしたが**残額ロジック（`splitLineAmount`は
  末尾の空行だけが残額を担う）と衝突**し、行0入力→行1にカテゴリでも残額が行2へ飛び
  未カテゴリ＝`canSave` false になる実害バグ（controllerテストが検出）→**2行にリバート**。

### build 14（`5d19562`）— 確定モックv4に刷新（大改修）
モック駆動で収束（下記「モック遍歴」）。内訳入力の骨格を作り替え。
- **残額行を最下段に固定**（差分表示・超過は赤系「超過 ¥X」・カテゴリを付けるだけで最後の1品に）。
- **入力行は2行分の窓でスクロール**。「＋品目」は残額行の直前に挿入。
- **残額行(末尾expr空)への打鍵は直前に入力行を挿して受ける**（`_retargetIfRemainder`・
  digit/operatorのみ）。残額行が打鍵で普通の行に化けない。
- 税は**タイトル行の [内税|8%|10%] 常時トグル**（全行に即適用・既定=内税・
  内税を外すと「外税」表記）＋**「個別」→品目ごとダイアログ**（`split_tax_dialog.dart`）。
  一括税バー・行内税UI・`splitPerLineTax` を廃止。
- カテゴリは**電卓の上のオンデマンド帯**（`split_category_strip.dart`・絵文字チップ・横スクロール・
  親タップで親割当＋子チップ切替・‹戻る・✕閉）。ボトムシート `split_category_sheet.dart` を削除。
- **分割中は下部タブ（カレンダー/サマリ/設定）を復活**（`home_shell`：`splitActive` 時は
  `NavigationBar` を出す）。行ラベルは絵文字付き（`entry_screen` の `categoryNames` を
  `categoryEmoji` 付きラベルに）。
- `startEditSplitGroup`（グループ開き直し）は末尾に空残額行を追加（`_retargetIfRemainder`との
  整合。無いと末尾の実データ行が壊れるバグをテストが検出→修正）。

### build 15（`5460b21`）— 税グループ化・残額行の左右入替・＋の位置
モックv3（`dfc01a87`）承認→実装。
- **消費税グループ化**: タイトル横に「消費税」ラベル＋内税トグル＋8%/10%セグ＋個別を
  `scheme.primaryContainer` の1つの背景でまとめる。**内税と8/10を別セグに分離**
  （内税＝単独InkWellトグル、8/10＝`_seg`を `Opacity(incAll?0.4:1)` で内税時は淡色無効、
  個別＝白ピル `_chipButton`）。「個別が浮く」問題を解消。
- **残額行を左右入替**: カテゴリを追加(左)｜残り¥(右)｜＋(右端)。
- **＋品目を残額行の右端に移動**（緑の＋square）。
- **fix（実機で発見）**: ＋が残額行全体の `InkWell`（`openSplitCatPicker`）の入れ子で、
  タップが親に横取りされ「行追加でなくカテゴリ帯が開く」不具合 → 残額行を「行全体1タップ」に
  せず、左（カテゴリ追加＝key `split-remainder`）と右（＋＝key `split-add`）を
  **独立した兄弟InkWell**に分離（親Containerは onTap なし）で解消。

## いまの内訳入力画面（build 15 時点の確定形）

上から: 店名行 → タイトル行 → 入力行(2行窓) → 残額行(最下段固定) → 電卓 → 保存 → 下部タブ。

- **タイトル行**: 「内訳」＋ 右に消費税グループ `[消費税  内税  8% 10%  個別]`（同背景）。
  内税ON時は8/10淡色。内税をタップで外税⇄内税トグル（全行即適用）。個別でダイアログ。
- **入力行**: `[＋カテゴリ / チップ]  [メモ]  [金額(外税なら税込併記)]  [×削除(3行以上)]`。
  タップで電卓上のカテゴリ帯を開く。
- **残額行**: `[＋カテゴリを追加/チップ]（左）  …  残り ¥X（右）  [＋品目]（右端）`。
  左タップ=帯を開く / ＋=残額の直前に入力行を挿入。
- **税モデル**: `SplitLine.taxIncluded`(内税=そのまま/外税=rate乗せ切り捨て)＋`rate`(8/10)＋
  `taxTouched`(手動は自動税率で上書きしない)。食費→自動8%・外食→10%（`_autoRateForCategory`、
  名前判定）。保存額は税込（`amountYen`）。

### 主なファイル
- `lib/features/entry/application/entry_form_controller.dart` — `EntryFormState`/`SplitLine`/
  `startSplit`/`addSplitLine`/`_retargetIfRemainder`/`splitLineAmount`/`splitRemainder`/
  `openSplitCatPicker`/`setSplitBulkIncluded`/`setSplitBulkRate`/`startEditSplitGroup`/`save` 系。
  分割の状態フラグは `splitCatPickerOpen`（旧 `splitPerLineTax` は廃止）。
- `.../presentation/split_entry_panel.dart` — パネル本体（タイトル行の消費税グループ・
  入力行 `_line`・残額行 `_remainderRow`・税セグ `_seg`・`_chipButton`）。
- `.../presentation/split_category_strip.dart` — 電卓上のカテゴリ帯（新規）。
- `.../presentation/split_tax_dialog.dart` — 「個別」税ダイアログ（新規）。
- `.../presentation/entry_screen.dart` — 画面骨格（分割中は帯を電卓の上に差し込む・
  `categoryNames` は絵文字付きラベル）。
- `lib/app/home_shell.dart` — 分割中の下部タブ復活（`splitActive`）。

## モック遍歴（このプロジェクトはHTMLモック先行が流儀）

承認済み・参考モック（claude.ai artifact）:
- 4案比較（常設グリッド/帯/シート/タブ）: `3427c775-7995-4ef1-a43d-83c0aeb2380a`
- 残額ピン留め方式（ユーザー発案の確認用）: `ac9236b7-b508-4ab6-9ab3-265aed5cb0bc`
- **構造モック100選**（10家系×各10案・Workflowで並列生成→選別）:
  `b8c3be2d-effc-45b2-8509-cc04c2d62488`
- **確定案 v3（実装対象・build 15の元）**: `dfc01a87-4bcc-48b7-a7c0-92b9c4bfdf4e`

「100種モック」はユーザーの「色違いは1種とみなす」指示で、Workflow（Sonnet量産→上位モデルで
検品・選別）で作った。設計軸の掛け合わせで構造だけを変え、配色トークンは全案共通。

## 次アクション

1. **build 15 の実機フィードバック**（ユーザーがアップロード済み）。特に注視:
   **＋品目の＋の見せ方**が実機で直感的か（残額行の右端に＋アイコンだけ＝"要検討"のまま。
   違和感あればラベル付き `＋品目` に戻す等）。
2. **母親の収集レシートの回収 → OCR精度検証（本命）**:
   - 現物はまだ Mac に無い。端末内 `Documents/exports/`（`receipt-*.json`＋写真）にある。
     回収経路: 母の iPhone「ファイル」→ このiPhone内 → 家計簿 → exports → 共有(AirDrop/LINE)、
     or 設定「テストデータを送る」zip共有、or CloudKit「収集データを取り込む」。
   - JSON には生OCRブロック＋保存確定の `expected`(合計/日付/店名)。パーサに通して的中/外しを
     照合 → パーサ調整 → ラベル付き実レシートを**回帰テスト**に固定化。
3. **親子カテゴリ（外食⊂食費）**: 集計は**既に実装済み**（シードで外食は食費の子・
   サマリの積み上げバー `kSubScale`＋「▼内訳」ドリルダウンで親合計に内包）。
   `lib/domain/services/spending_rollup.dart` の `rollupSpending` が親total=直接分+子合計を算出。
   **未実装**: 既存トップレベルカテゴリを別の親の下へ移す reparent 操作（付け替えUI/メソッドが無い。
   カテゴリの親は作成時のみ決定）。「繋がりを後から編集したい」なら要新規開発。
4. **呼称の整理（未対応課題）**: 「内訳」が分割機能と子カテゴリ（内訳を追加/改名）で衝突。

## 動かし方（開発）

- **シミュレータ**: `flutter run -d <iPhone17 sim UDID> --debug`（profileはsim非対応）。
  スクショ `xcrun simctl io booted screenshot out.png`。
- **ipa**: `flutter build ipa` → `build/ios/ipa/kakeibo_app.ipa`。ipa内版番は `unzip` して
  `plutil -extract CFBundleVersion raw Payload/*.app/Info.plist` で検証。
- **テスト**: `flutter test`（343緑）。`flutter analyze`（0）。
- コミットはこのブランチで、ユーザー依頼時のみ。version は次ビルドで +16。
- **sim駆動 tip**: Flutterのボタンは `cliclick` で取りこぼしやすい。移動付き
  `m:x,y w:60 dd:x,y w:90 du:x,y` が確実、1タップごとにスクショ検証。小ボタン(税トグル/＋、27-40px)と
  画面遷移直後の初回タップは特に外しやすい。座標較正（窓 577,32,440,940・disp920px基準）:
  `screen_x = 577 + disp_x*0.479` / `screen_y = 130 + disp_y*0.413`
  （digit1=disp(170,580)→screen(658,370) と digit0=disp(458,892)→screen(796,499) の2点で確定）。
  FABは画面座標 (907,806)。
