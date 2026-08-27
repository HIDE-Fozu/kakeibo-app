# 引き継ぎ 2026-08-27 — メモのキーボード不具合（★修正済み）

前の正典: docs/handoff-2026-08-27-payment-mode.md（支払い区分モードの全体像）。
本書が新しい正典。

## 🎯 現在地

- ブランチ **`feature/paper-design`**・**未push**。
- **686テスト緑（skip 0）/ analyze 0**。
- 実機 TI10B1 = 2.4.0(53) まで配備済み（スクリム復活＋解除の即時化までOK確認済み）。**2.4.0(54)**（スクリムを升目だけに）が未配備。
- 2.3.0(47) は App Store 審査中。本セッション分は 47 に入っていない。

---

## ✅ 解決: メモを書こうとするとキーボードがすぐ引っ込む

ユーザー報告:「キーボードがすぐ戻っていくけど。メモ入力しようとすると。」

### 原因

キーボードが出て縦が縮むと `calendar_screen.dart` のレイアウトが切り替わり、
`_DaySection` が Column のスロットから Stack のオーバーレイへ**ツリー上の別の
場所へ移動していた**。Flutter は位置で State を同一視するので
`_ShoppingMemoPadState` が破棄され → `FocusNode` も作り直され → フォーカスが
外れ → キーボードが閉じる。

シミュレータ（本物のキーボード）での裏取り:

| | 修正前 | 修正後 |
|---|---|---|
| viewInsets.bottom | **0.0**（＝一瞬で引っ込んだ） | **336.0** |
| 同じ FocusNode か | false | **true** |
| フォーカス継続 | false | **true** |

### 直した内容（`calendar_screen.dart`）

1. **カードの置き場所を Stack の1か所に固定した。** Column 側の `Expanded` は
   **高さを測るためだけの空きスロット**（`SizedBox.expand()`）にし、カード本体は
   常に Stack のオーバーレイが描く。通常位置では測った基準の高さそのままなので
   スロットにぴったり重なり、**見た目は従来と1ピクセルも変わらない**（下記の
   スクショ突き合わせで確認済み）。
   - 基準を測れるまでの初回フレームだけはスロット側に出す。
2. **Stack の子を「背景 / 覆い / カード」の3枠に固定した。** 枠を条件で出し
   入れすると子の番号がずれ、それだけでも State が作り直される。覆いは浮いて
   いないとき中身を空（`SizedBox.shrink()`）にして枠だけ残す。
   背景の `ClipRect`+`OverflowBox` も常時同じ形にした（通常時は素通し）。
3. **キーボードの検出を `outer.maxHeight < 640` からやめた。**
   小さい端末では常に true になり、キーボードが無くてもカレンダーが暗いまま
   だった。`MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0` で
   Scaffold(resizeToAvoidBottomInset) に食われる前の生の値を読む。
   LayoutBuilder の中で読むのは、body が縮むと必ず呼び直されるから。
4. **キーボードが出ている間は基準高さを測り直さない**（`_DaySheetSlot.measure`）。
   縮んだ値で基準が上書きされると、書いている最中にカードが縮む。

### 回帰テスト

- `test/ui/memo_keyboard_focus_test.dart` — **skip を外した**。
  viewInsets を偽装してフォーカスと FocusNode の同一性を見る。
  修正前のコードで走らせると落ちることを確認済み（＝空振りしない番人）。
- `integration_test/memo_keyboard_accept_test.dart`（新規）— シミュレータ/実機で
  **本物のキーボード**を出して同じことを確かめる。単体テストでは偽装しか
  できないので、こちらが最終的な受入。
  ```
  flutter drive --driver=test_driver/integration_test.dart \
    --target=integration_test/memo_keyboard_accept_test.dart -d <device>
  ```
  ⚠️ シミュレータで走らせるときは**ソフトウェアキーボードを出す設定**が要る
  （I/O > Keyboard > Connect Hardware Keyboard を切る。CLI なら
  `defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false`
  → Simulator 再起動）。出ていないと `KB_INSETS=0` でテスト自体が
  「無意味」として落ちるようにしてある。

### 追加FB: メモ→カレンダー復帰の「ホワイトアウト」（2026-08-27・修正済み）

実機2.4.0(51)で確認。キーボード修正で**キーボードが出たままになった結果**、
今まで到達できなかった「キーボードを閉じてカレンダーに戻る」局面が露出した。
覆い（スクリム）を `raise > 0 || keyboard` に連動させていたため、カードはもう
通常位置に戻っているのに、キーボードが閉じ切る（insets=0）まで**カレンダーが
0.72 alpha の紙色で白く飛んだまま**待たされていた。

★ここで一度**スクリム自体を消す**方向に直して差し戻された。ユーザーの意図は
「メモ開いてる時はスクリム入れよう。**解除の動作を早めて**」＝スクリムは要る、
遅いのは解除。**要望を読み違えないこと。**

**直し（採用版）**: 落とす条件を**フォーカス**にした。
`dimmed = raise > 0 || (メモにフォーカス && タブ==メモ)`。
`viewInsets` が 0 になるのは閉じるアニメーションが終わった後なので、それに
紐づける限り解除は必ずアニメーション分だけ遅れる。フォーカスなら背景タップの
`unfocus()` と同じフレームで false になる＝即座に晴れる。

- フラグは `shoppingMemoFocusedProvider`（`shopping_memo_controller.dart`）。
  `ShoppingMemoPad` が FocusNode のリスナーで流す。
- **dispose では畳まない**（widget のライフサイクル中に provider を触ると
  Riverpod が例外を投げる＝一度踏んだ）。代わりにカレンダー側が
  `タブ==メモ` で見分けるので、立ち残りは無害。
- 覆い（＝背景タップで戻る面）自体は浮いている間ずっと出す。落とすかどうかだけ
  が上の条件。

**実測**（`integration_test/memo_return_probe_test.dart` でコマ送り）:

| | 修正前 | 修正後 |
|---|---|---|
| 編集中 | 落ちている | **落ちている（維持）** |
| 復帰 t=100ms（insets=75＝閉じ切る前） | 白飛びのまま | **くっきり** |

回帰テスト: `test/ui/memo_keyboard_focus_test.dart` の2件目。
`dimmed` を insets 連動に戻すと落ちることを確認済み。

### 追加FB: スクリムは升目だけ（2026-08-27・対応済み）

「スクリムはカレンダー部分だけにできる？」→ **升目だけ**を選択（3案提示・
ユーザー決定）。月見出し・サマリ（支出/収入/差引・見込み収支）は読めるまま。

- 落としは `Padding`(カレンダー) の中の `Stack` に `Positioned.fill` で敷く。
  キーは `calendar-dim`。枠は常に置き中身だけ差し替える（枠を出し入れすると
  TableCalendar の位置がずれて State ごと作り直される）。
- `day-sheet-scrim` は**当たり判定だけ**の透明な面に徹する。全面のままなので
  サマリや月見出しを押しても戻れる。
- ⚠️**了解済みのトレードオフ**: メモを上にあげると升目はカードの下に隠れる
  （上に残るのは150px／キーボード時60px＝バックアップ行・月見出し・サマリの
  一部だけ）ので、**上にあげた状態では落としが見えない**。ユーザー承知の上。

### 見た目が変わっていないことの確認

`memo_shots_test` / `design_shots_test` を修正前後で撮って突き合わせ:

- `design_1_calendar` `design_1b_chores_tab` `design_2_empty_day`
  `design_3_income_entry` `memo_1_one_line` `memo_5_dragged_chores`
  `memo_6_back` … **バイト単位で一致**
- 差が出たのは `memo_2_tap_to_type` `memo_3_typed` `memo_4_dragged_up` だけ＝
  いずれも**キーボードが出ている状態**（修正前は落ちていたので出ていなかった）。

---

## このセッションで入れたもの

### 支払い区分モード（未払金・あとから分割）— 詳細は前の正典

締め日をカードごとに設定できるようにし、バッジを「未払」から**いつ払うか**
（翌月 / 翌々月 / N月 / N回）に変えた（3309421）。

### 買い物メモの操作系（試行錯誤の結果・現在の形）

ユーザーFBを3回受けて、いまはこうなっている:

- **タップ＝編集 / ドラッグ＝広げる**。フォーカスで画面がせり上がると入力を
  取りこぼす（「1回目は空振り、2回目でやっと入力」）ので役割を分けた。
- 入力欄は**1行から始まり**、書いた行数だけ伸びる。1行しか無くてもカードの
  どこを押しても書き始められる。
- **タブ行を上へドラッグするとカードが広がる**（連続量・24px未満は通常位置へ戻す）。
  日付・つきいちタブでも同じ。背景タップで戻る。
- 別ページの編集画面は**撤去済み**（「別ページに飛ぶの気持ち悪い」）。

★この操作系自体は合意が取れている。壊さずにキーボードの不具合だけ直すこと。

---

## ★配備の手順（必ずこの順で・検証まで含めて1セット）

`flutter install` は**再ビルドしない**。コードを直して install を繰り返すと
古いバイナリが入り続ける。実際にこれで2回、入っていない物を「入れた」と
報告してユーザーに指摘された。

1. `flutter build ios --release`
2. `flutter install -d 00008140-00180D0911C2801C --release`
3. **端末側で検証**:
   `xcrun devicectl device info apps --device 00008140-00180D0911C2801C | grep kakeibo`
   → 版数が上がっていること。判別できるよう**配備のたびに build number を上げる**。
4. `xcrun devicectl device process launch --device 00008140-00180D0911C2801C com.hidefozu.kakeibo`

## ⚠️ 配備するたびに実機のデータが消える

`flutter install` は既存アプリを「Uninstalling old version...」で先に消してから
入れる。iOSではアンインストール＝データコンテナごと削除なので、**アプリ内の
データも自動バックアップも全部消える**。偶発ではなく毎回起きる。

- 生き残るのは、共有シートで**アプリの外**（ファイルApp / ドライブ等）へ
  書き出したバックアップだけ。
- **配備前に必ずユーザーへバックアップの書き出しを依頼し、消える旨に同意を取る。**
- データを保持したまま更新したいなら Xcode から Run するか TestFlight 配信に
  切り替える必要がある。**どちらにするかユーザー未決**。

## 積み残し

1. ★**実機配備**（この修正も、メモ・予算・支払い区分も、実機で1つも確認できて
   いない。実機には 8/23 の版しか入っていない）
2. 実機配備の方式（Xcode / TestFlight）をユーザーと決める
3. 審査結果（2.3.0(47)）→ 通過なら main マージ / push 承認
4. 支払い区分の実機受入 → FB反映
5. 未払金の個別月の金額編集（合計＝総額の機械判定は実装済み）
6. prefs のカード（分割払い画面）と DB のカード（支払い区分）の統合
7. 入力画面の抜本リデザイン・母レシート回収→expected回帰テスト化

## 動かし方

- テスト: `flutter test`（686件・skip 0）
- スクショ: `flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/memo_shots_test.dart -d <sim-id>`
  → `build/qa_screens/<日付>/`
