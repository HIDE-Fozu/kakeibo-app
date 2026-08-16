# 引き継ぎ 2026-08-16 — 内訳フローの刷新・固定費の終了月・分割払い（schema v10）

前の正典: docs/handoff-2026-08-08-v2.2.0.md（v2.2.0の全経緯・build 33〜46・審査提出まで）。
本書はこの日の大型セッション（ユーザーFB 10連発）の全変更と次アクションをまとめた現時点の正典。

## 🎯 現在地

- ブランチ **`feature/split-bottomup`**・HEAD = 560c262 ＋ 本書コミット。**未push・リモート無し**。
  審査提出済みの v2.2.0(46) = `feature/tsukiichi-merge` 568c… (568fc3a) から分岐。
- **554テスト緑 / analyze 0**。実機 TI10B1 に profile ビルド配備・起動済み（560c262 時点）。
- **v2.2.0(46) は審査待ちのまま**（2026-08-16 提出・承認後自動リリース）。main 未マージ。
- バージョン未bump。**次のストア提出時に 2.2.0(47) か 2.3.0 かを判断**
  （今回の分はスキーマ変更を含む機能追加なので 2.3.0 が妥当そう）。

## ★次セッションの最初にやること

1. **ユーザーの実機テストのFBを聞いて対応**（今回の10機能はすべて実機受入が未）。
2. **「削除しました」が永久に表示される問題の修正（ユーザー指定済みの仕様）**:
   - 現状: カレンダーの日別リストで取引を削除すると
     `lib/features/calendar/presentation/day_transaction_list.dart` の `_deleteWithUndo`
     が SnackBar（「削除しました」＋「元に戻す」アクション・duration未指定=既定4秒）を出す。
     「永久に出る」原因は未特定。**有力候補: iOSのVoiceOver等で
     `MediaQuery.accessibleNavigation` が true だとアクション付きSnackBarは
     自動で消えないというFlutter仕様**。実機で再現条件を確認してから直すこと
     （[[feedback_investigate_first]]）。
   - **直し方（ユーザー指定）**:
     1. SnackBar に **バツ（閉じる）ボタン**を追加（`showCloseIcon: true` が標準機能）
     2. **10秒で自動的に消える**（`duration: Duration(seconds: 10)`）
     3. **「元に戻す」アクションは SnackBar から撤去し、設定画面から復元できる形へ**
        （=「最近削除した取引」的なごみ箱機能。実装は要設計:
        現在はhard delete＋Undoは同内容の再add。設定からの復元にするなら
        削除ログ（別テーブル or ソフトデリート）が要る。スキーマを触るなら v11）。
   - 同型のSnackBar（家事の記録取り消し chore_ui_common.dart 等）も同じ罠がないか確認。

## 今回やったこと（コミット順・すべてFB起点）

| commit | 内容 |
|---|---|
| 0de385b | 案B ボトムアップ内訳（金額0で内訳へ・末尾が「合計」行）※後に置き換え |
| 7620eec | FB「合計が重複」→ 末尾は従来の「残り」表示に戻す |
| bddda56 | 通常入力のメモを品目行のセル内ボタンへ（独立した「詳細メモ」欄を廃止・部品共通化 MemoPillButton/SplitMemoDialog） |
| a4f6026 | 残額行にもメモボタン（「品目2にメモが出ない」）＋内訳中の店舗名欄を通常入力と同じ見た目に |
| ca8c09a | **金額0の「カテゴリを追加」=「まず合計値の入力」フェーズ**（splitTotalPending・電卓を合計へ配線・合計0の間は行/帯をブロック＆ディム・行タップで解除→通常トップダウン）。ボトムアップ機構(splitBottomUp/displayAmountYen)は撤去 |
| 0ce937f | ①フェーズ中のハイライトは上部合計の1つだけ・案内文なし（「選択は1つのみ」FB） ②固定費に「終了」欄（endYm・実効開始月から36ヶ月。バックエンドは対応済でUIのみ） ③カレンダー凡例「固定費の予定」撤去（常時表示FB・calendarLegendGhost削除） |
| 15363a5 | 分割払いの登録: installment_calc.dart（実質年率の元利均等 P·r/(1−(1+r)^−n)・総額丸め・**端数は初回**・0%/1回無手数料。15%/10回→手数料7.0円/100円でカード表とほぼ一致）＋ InstallmentPage ＋ カード名称+年率を prefs（installmentCards）に記憶→次回選択で省略。l10n installment* 14キー×9 |
| 560c262 | **分割払いを計画として管理**: schema **v10**（installment_plans＋transactions.installment_plan_id FK cascade）・backup **formatVersion 8**・DriftInstallmentPlanRepository（add/replace/delete=取引を作り直し/一括削除）・毎月タブ「分割払い」セクション（一覧→タップで編集・AppBar削除）・InstallmentPage編集モード（開始月±18ヶ月ドロップダウン） |

- スクショ（build/qa_screens/）: tf_1〜4（合計入力フェーズ）・fb_1〜5（凡例なしカレンダー・
  終了月・分割払いフォーム/毎月セクション）・bu_*（旧ボトムアップ・参考）。
- ⚠️ **15363a5 時点（計画テーブル以前）に実機で登録した分割払いは計画に紐づかず
  管理セクションに出ない**（取引としては残る。手で削除して登録し直してもらう）。

## スキーマ・データ変更まとめ

- **DB schema v10**: `installment_plans`（principal/count/annual_rate_percent/category_id/
  day_of_month/start_ym/card_name）＋ `transactions.installment_plan_id`（FK cascade）。
- **backup formatVersion 8**: installmentPlans 同梱＋取引の installmentPlanId
  （計画IDに解決できなければ拒否・v7以前は空/nullで復元）。
- **SharedPreferences**: `installmentCards`（"名称\t実質年率" の StringList・
  設定の InstallmentCard/saveInstallmentCard）。**バックアップ非同梱**（今後の宿題）。
- l10n: installment* 15キー＋recurringEnd* 3キー追加 / entrySplitNeedsAmountSnack・
  calendarLegendGhost 削除（すべて9ロケール）。

## テストの罠（今回踏んだもの・再発注意）

- **widgetテストで drift の stream を await すると fake async でデッドロック**
  （`watchAll().first` 等）→ `tester.runAsync(() => ...)` で包むか、
  画面が購読済みの StreamProvider の現在値を `c.read(...).valueOrNull` で読む。
- **内訳の行の中央タップはメモボタンに当たる**（ダイアログが開く）→
  行の切替を試すテストは番号バッジ `split-lineno-N` か「残り」表示 `split-tail-label` を狙う。
- **実機での integration shots はキーボードでビューポートが縮み ListView が遅延構築**
  → `ensureVisible` が No element。`t.drag(find.byType(Scrollable).first, ...)` でスクロール。
- **root ページで `Navigator.pop` するとテストの履歴が空になり assert**
  → ページは `nav.push(MaterialPageRoute(...))` で開いてから操作する。
- **migration テストの最小DB**には、以後のマイグレーションが触るテーブル
  （今回 transactions）を必ず定義しておく（v7/v8 テストに追加済み）。
- `flutter drive ... | tail` はパイプで進捗が見えずハングと区別不能 →
  `> log 2>&1` でログを追う（既知の罠・継続）。

## 動かし方（今回使った反復ループ）

```
flutter test                      # 554本・約30秒
flutter analyze
# 目視スクショ（iPhone 17 sim 9EC1319F-690F-4FCA-BAB7-97B2F6A1D1BA）
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/fb0816_shots_test.dart -d <sim> > log 2>&1
# 実機配備（TI10B1 188670B5-1E37-5AB9-A069-557E148BC045・uninstall厳禁）
flutter build ios --profile
xcrun devicectl device install app --device 188670B5-... build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device 188670B5-... com.hidefozu.kakeibo
```

## 積み残し（優先順は次回ユーザーと確認）

1. 「削除しました」問題（上記★・仕様確定済み）
2. 今回10機能の実機受入FBの反映
3. 分割払いの発展: 固定費UIへの本統合・installmentCards のバックアップ同梱
   （DBテーブル化するなら v11）・支払い済み/残り回数の表示
4. 審査結果（v2.2.0(46)）対応・通過後の main マージ・push の承認
5. 入力画面の抜本リデザイン（前正典の2026-08-14節・モックURLあり・合計値の置き場所が未決）
6. 宿題: 母レシート回収→expected回帰テスト化
