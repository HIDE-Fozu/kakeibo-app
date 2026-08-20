# 引き継ぎ 2026-08-20 — カレンダー画面の紙デザイン刷新（feature/paper-design）

前の正典: docs/handoff-2026-08-19-trash-installments.md（ごみ箱 schema v11・分割払い回数拡張）。
本書はその直後のデザイン刷新セッションの記録。**ブランチ feature/paper-design**
（feature/split-bottomup の 05e9014 から分岐・HEAD=ba454ea・未push）。

## 🎯 ユーザー指示とスコープ（AskUserQuestionで確定）

モック2枚（1枚目=帳簿風の紙ノート・2枚目=角丸カードのカレンダー）を提示され
「カレンダーは2枚目、他の部分は1枚目を参考に」。確認の結果:
- **見た目のみ刷新**（ハンバーガー・日別/カテゴリ/メモの右タブ・メモ機能は入れない。
  空状態の支出/収入ボタンだけは追加=入力画面を種別指定で開くだけなので軽い）
- **フォントは変えない**（明朝化しない）
- **フラット近似**（紙テクスチャ・テープ・イラスト等の画像アセットは作らない）

## 実装内容（ba454ea・カレンダータブのみ・567テスト緑）

- **月サマリカード**（モック1）: 支出/収入/差引の3カラム（ラベル上・金額下・色分け）＋
  区切り線＋見込み収支行。`month-summary-card`。基準日変更（forecast-line タップ）は従来通り。
  旧1行文字列 calendarMonthSummary は廃止。
- **カレンダー**（モック2）: 週罫線廃止→白の角丸カードセル（_kCellDeco・margin1.5・radius9・
  微影）。前後月マスも空の白カード（outsideBuilder）。rowHeight 62→66。
  選択=塗り丸・今日=輪郭丸・曜日色は従来（日=赤/土=青）。
- **日別セクション** `_DaySection`: 選択日タブ（`day-tab-label`・DateFormat.MMMEd・主色塗り）＋
  白カード（topRight/bottom角丸・kLine枠）。
- **FAB廃止→「＋」移設**: 日付タブ行の右端の丸ボタン（**キー fab-entry・
  tooltip=homeFabEntryLabel を継承**したので既存テスト・integrationスクリプトは無改修で動く）。
  経緯: FABはextended→小型丸→廃止と段階的に追い込んだ。**6週ある月は日別カードが
  実質90px程度**しかなく、FABがどこにいてもカード内容（金額・ボタン）を塞ぐため。
- **空の日の空状態**: 「この日の記録はまだありません」＋**支出を追加/収入を追加**
  （`day-add-expense`/`day-add-income`・startCreate(選択日)+setType→入力タブへ）。
  **LayoutBuilderで2段構え**: maxHeight<120（6週の月）は文言＋ボタンのみ、
  広い月はアイコン付き中央寄せ。どちらもSingleChildScrollView。
- **バックアップ表示**: 全幅チップ帯→右上の小さな「☁ 前回バックアップ:◯」（BackupBanner改装）。
- **下部ナビ**: 毎月=menu_book・サマリ=pie_chart・未選択は kNavIdle(グレー)統一
  （kNavMonthly/kNavSummary/kNavSettings 撤去）。
- **l10n**（9ロケール）: calendarAddExpense/Income 追加・calendarDayEmptyTitle
  「この日の記録はまだありません」（placeholders廃止）・calendarDayEmptyHint 刷新・
  calendarMonthSummary / calendarDayEmptyHintFirst 削除。

## 検証

- `flutter test` **567本全緑**（+1: 空の日の「収入を追加」→収入・選択日で入力が開く）・analyze 0。
- sim（iPhone 17）スクショ3枚目視済: `build/qa_screens/design_1..3_*.png`
  （integration_test/design_shots_test.dart・使い捨て）。
  design_3 で「収入を追加」→入力画面が収入タブ・8/5で開くところまで確認。

## テストの罠（今回踏んだもの）

- **旧FABのextendedラベルをやめると `find.text('金額を入力する')` が死ぬ** →
  `find.byTooltip(...)` に変更（home_shell_test・localization_test）。キーは fab-entry を継承。
- サマリカード化で「差引 -¥800」が日別リストの行と同文字列になる →
  `find.widgetWithText(ListTile, ...)` で行側に絞る（calendar_screen_test）。
- 見込み行はラベルと金額が別Textに → forecast-line の descendant で金額を確認
  （calendar_chore_ghost_test）。
- 空状態はSingleChildScrollView必須（キーボード表示・小型端末の縦潰れでRenderFlex溢れ）。

## 追記（同日FB・3525474）

- **日付セルは比率1の正方形・日付はセル左上**（2段階のFBで確定）:
  LayoutBuilder で行高＝セル幅（幅/7）。日付数字（丸20・font11）は左上、
  金額（9pt/height1.15）・家事ドット（4px）はその下に中央揃え。
  縦予算はセル幅-3（SE級375pxで約48）に収まる構成。
  ⚠️罠: セルの Container は alignment を指定しないと中身の高さに縮んで
  正方形にならない（Align(topCenter)相当の広げ役が必要）。
  副次効果で日別カードが高くなり6週の月の空状態も窮屈さが緩和。
- **QAスクショは日付フォルダ分け**: 撮影ドライバ（test_driver/integration_test.dart）の
  保存先を `build/qa_screens/<YYYY-MM-DD>/` に変更。既存画像も更新日で整理済み。

## ★次にやること

1. **ユーザーの見た目レビュー**（design_1〜3スクショ or 実機）→ 微調整FB。
2. 他画面（毎月/サマリ/設定/入力）への同トーン展開は**未着手**（今回はカレンダータブのみ）。
3. 実機配備はごみ箱/回数拡張と合わせて（前正典の「次にやること」参照・
   ユーザーの旧ビルドテスト完了待ち）。
4. マージ順: feature/split-bottomup → feature/paper-design の順で積んである。
   ストア提出時は 2.3.0 想定（前正典）。
