# 引き継ぎ 2026-08-27 — ★メモのキーボードが落ちる（原因特定済み・未修正）

前の正典: docs/handoff-2026-08-27-payment-mode.md（支払い区分モードの全体像）。
本書が新しい正典。**次セッションはここの「最優先」から始める。**

## 🎯 現在地

- ブランチ **`feature/paper-design`**・HEAD = 3317bef ＋本書。**未push**。
- **684テスト緑（skip 1 = 下記の再現テスト）/ analyze 0**。
- 実機 TI10B1 = **2.4.0(50)**。この不具合を含んだ状態で入っている。
- 2.3.0(47) は App Store 審査中。本セッション分は 47 に入っていない。

---

## ★最優先: メモを書こうとするとキーボードがすぐ引っ込む

ユーザー報告:「キーボードがすぐ戻っていくけど。メモ入力しようとすると。」

### 原因（**特定済み・推測ではない**）

キーボードが出て縦が縮むと、`calendar_screen.dart` の `tight` / `overlay` が
切り替わり、`_DaySection` が **Column のスロットから Stack のオーバーレイへ
ツリー上の別の場所に移動する**。Flutter は位置が変われば State を作り直すので、
`_ShoppingMemoPadState` が破棄され → `FocusNode` も作り直され → フォーカスが
外れ → キーボードが閉じる。

再現テストで裏取り済み（`test/ui/memo_keyboard_focus_test.dart`・現在 `skip: true`）:

```
FOCUS_BEFORE=true
FOCUS_AFTER=false
SAME_FOCUSNODE=false   ← State が作り直されている
SAME_ELEMENT=false     ← ツリー上の位置が変わっている
```

### 直し方の方針

1. **`_DaySection` をツリー上の1か所だけに置く。** 具体的には常に Stack の
   オーバーレイに置き、Column の `Expanded` は**高さを測るためだけの空の
   スロット**にする（`_DaySheetSlot(child: SizedBox.expand())`）。
   位置が変わらなければ State は保たれ、フォーカスも落ちない。
   - 初回フレームは `daySheetBaseHeightProvider` がまだ null なので、
     カードを描けるのは2フレーム目から。1フレームの空白は許容範囲だが、
     気になるなら測定前のフォールバック高さを用意する。
2. **キーボードの検出を `outer.maxHeight < 640` からやめる。**
   小さい端末では常に true になり、キーボードが無くても切り取りモードに
   入ってしまう。`MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0`
   なら Scaffold に食われる前の生の値が取れる。
3. **キーボードが出ている間は基準高さを測り直さない**（`daySheetBaseHeightProvider`
   が縮んだ値で上書きされて基準がずれる）。
4. 直したら `memo_keyboard_focus_test.dart` の `skip: true` を外す。これが
   合格すれば直っている。

### 触るファイル

- `lib/features/calendar/presentation/calendar_screen.dart`
  （`tight` / `overlay` / `_DaySheetSlot` / Stack の組み立て）
- `lib/features/calendar/application/calendar_providers.dart`
  （`daySheetRaiseProvider` / `daySheetBaseHeightProvider`）
- `lib/features/memo/presentation/shopping_memo_pad.dart`（触らなくても直るはず）

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

1. ★メモのキーボード不具合（上記）
2. 実機配備の方式（Xcode / TestFlight）をユーザーと決める
3. 審査結果（2.3.0(47)）→ 通過なら main マージ / push 承認
4. 支払い区分の実機受入 → FB反映
5. 未払金の個別月の金額編集（合計＝総額の機械判定は実装済み）
6. prefs のカード（分割払い画面）と DB のカード（支払い区分）の統合
7. 入力画面の抜本リデザイン・母レシート回収→expected回帰テスト化

## 動かし方

- テスト: `flutter test`（684件・skip 1）
- スクショ: `flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/memo_shots_test.dart -d <sim-id>`
  → `build/qa_screens/<日付>/`
