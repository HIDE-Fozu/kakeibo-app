# Phase 5 ハンドオフ（2026-07-05 更新 / build 4 時点）

次セッションはこのファイルと `memory/`（特に `feedback-no-ui-mocks`）、`docs/phase5-mac-runbook.md` から再開する。

## いまどこ（TL;DR）

- **build 1 と build 3 は配信済み**（母親テスト→入力画面リデザイン）。
- **build 4 の ipa を生成**（`1.0.0+4`）。母親フィードバック後の大きめのUI改修一式（下記「build 4 の変更」）が入っている。**TestFlight へのアップロードはユーザー手動待ち**（`build/ios/ipa/kakeibo_app.ipa` を Transporter → Deliver で内部グループ「111」へ自動配信）。
- コード: **277テスト全緑・`flutter analyze` 0**。作業ツリーはコミット済み（`grep -rc TEMP-DEMO lib/` = 0 を確認済み）。**main はローカルのみ（origin/main より先行・未push）**。

## build 4 の変更（このセッション）

ユーザーの実機フィードバックに沿った最小差分の積み上げ。UI判断は勝手にせず、都度スクショ確認・要望どおりに実装。

1. **入力タブ廃止 → 3タブ**（カレンダー/サマリ/設定）。入力は**カレンダー右下の拡張FAB「＋ 金額を入力する」**から開く。入力画面は**左上に戻る**＋**タブ据え置き**でカレンダーへ戻れる（`home_shell.dart` の `_navToShell=[0,2,3]`、`entry_screen.dart` の embedded 時 leading）。空の日の「この日に追加」は削除。
2. **ページ色・アクセント色を設定可能**（設定→「ページの色（背景）」「アクセント色」）。**パッケージ非依存の自前RGBフルカラーピッカー**（`color_picker_dialog.dart`）。`KakeiboApp` を ConsumerWidget 化し `buildKakeiboTheme(background, accent)` に反映。既定は kPaper / kPrimary。設定は SharedPreferences（`pageColor`/`accentColor`=ARGB int、`toARGB32()`）。**注意**: 暗い背景でも選べる＝固定文字色 kInk が読みにくくなる可能性あり（自由選択を優先し未制約。要望あれば文字色自動調整を追加）。
3. **カテゴリ並び順を設定可能**（`categoryOrder`: `recentlyUsed`(既定)/`manual`）。設定に「カテゴリを自分の順で並べる」スイッチ。`entryCategoriesProvider` がモードを見て並べる。
4. **入力グリッドの並べ替え**（iPhoneホーム画面風）: タイル**長押し→そのままドラッグ**で並べ替え、他タイルは `AnimatedPositioned` で avoiding、離すと `repo.reorder` に保存＋（recentlyUsedなら）manualへ自動切替。**編集中はジグル**（掴んだタイル以外を小刻み回転、振れ幅 `kCatJiggleAmplitude=0.022`≒1.3°・340ms、id位相ずらし）。内訳追加ダイアログにも**「アイコンの表示順設定」**（親をドラッグハンドルで並べ替え、`subcategory_chips.dart`）。
5. **入力グリッドのレイアウト刷新**（`category_grid.dart`）: **4列×2段=1ページ・行優先**（index0の下=index4）。Flutter標準に2段グリッド並べ替えが無いため `GridView`をやめ**Stack＋AnimatedPositioned**の自前実装（`CatGridMetrics` で幅に応じてタイル幅を算出＝約84px）。**ページ間に薄い縦点線**、**横スワイプ/右送りボタンでページ送り**。右送りボタンは**右端オーバーレイ（半透明の丸・タイルに重なる）**で復活（`cat-scroll-right`）。当たり判定・オーバーレイ位置（`catIsBottomRow`）も新レイアウトに追従。
6. **カレンダー刷新**（`calendar_screen.dart`）: 曜日は**日本語＋日曜=薄赤/土曜=薄青**（dowBuilder）。日セルは**数字を上・支出額を下に分離**（`_dayCell`）＝今日/選択の丸に金額が被らない。**選択=塗り丸/今日=リング**（数字だけを囲む小丸、色 `_kSelectedRing=#5C6BC0`/`_kTodayRing=#9FA8DA`）。**週ごとに薄い横罫線**（`CalendarStyle.tableBorder.horizontalInside`, kLine/0.6）。rowHeight 58。

## リリース系の確定情報（変更不可）

| 項目 | 値 |
|---|---|
| Bundle ID | `com.hidefozu.kakeibo`（**App作成済み＝永久固定**） |
| Team ID | `Q7T6APPS23`（Hideaki Sato・個人アカウント） |
| App Store Connect App | 名前「経理の家計簿」／SKU `kakeibo-001`／プライマリ言語 日本語 |
| TestFlight | 内部グループ「**111**」・テスター2名・**自動配信ON**（build上げるだけで自動配布） |
| 署名 | pbxprojのRunner 3コンフィグに `CODE_SIGN_STYLE=Automatic`＋`DEVELOPMENT_TEAM=Q7T6APPS23`。証明書 Dev/Distribution 済み |
| 現在バージョン | `1.0.0+4`（pubspec・コミット済み） |

## iOSビルドの前提（重要・runbookの補足）

- **SPM構成**（CocoaPodsではない）。`ios/Podfile` は無い・生成されない。deployment target は pbxproj の `IPHONEOS_DEPLOYMENT_TARGET=16.0`。
- `sqlite3_flutter_libs` は **native assets** で自動バンドル（`sqlite3.framework`）。プラグイン一覧には出ない。
- ipa生成: `flutter build ipa` → `build/ios/ipa/kakeibo_app.ipa`。**次のビルドはビルド番号を +1（次は `1.0.0+5`）**にしてから。App Store Connectはビルド番号の重複を拒否する（番号が飛ぶのはOK）。

## アーキテクチャ現状（入力/グリッド/カレンダー）

- `lib/app/home_shell.dart`: 3タブ＋IndexedStack(0=カレンダー/1=入力/2=サマリ/3=設定)。入力(1)はタブに出さずFABから。`_navToShell=[0,2,3]`。
- `lib/app/navigation.dart`: `homeTabIndexProvider`（IndexedStack index）、`kInputTabIndex=1`。
- `lib/features/entry/presentation/category_grid.dart`: 自前2段ページグリッド＋長押しドラッグ並べ替え＋ジグル＋右送りボタン。`CatGridMetrics`/`catIsBottomRow` は top-level（layout単体テストあり）。
- `lib/features/entry/presentation/subcategory_chips.dart`: 内訳チップ＋追加ダイアログ（「既存の内容を編集」「アイコンの表示順設定」）。
- `lib/features/settings/application/settings_controller.dart`: `SettingsState` に pageColor/accentColor/categoryOrder。
- `lib/features/settings/presentation/color_picker_dialog.dart`（新規）: RGBスライダの自前ピッカー。
- `lib/features/calendar/presentation/calendar_screen.dart`: 日本語曜日・数字上/金額下・選択丸/今日リング・週罫線。

**注意（重要な逸脱・継続）**: カテゴリ絵文字は **schema v3 マイグレーションではなく表示専用**（`schemaVersion => 2` のまま。`core/category_emoji.dart` の表示マップ）。ユーザーが自分でicon（絵文字）を設定していればそれを優先。過去にマイグレーション実装→revert済みの経緯あり、DB/マイグレーションは触らない。

## ユーザーの強い要望・スタイル（守ること）

- **HTMLモックを作らない・参照しない**（`memory/feedback-no-ui-mocks`）。UI変更は**実機画面＋ユーザーのスクショ**だけを基準に**実Flutterコードへ最小差分**。美観の判断（色・アイコン・サイズ等）を勝手にしない＝迷ったらスクショで見せて確認。
- 用語は「カテゴリ／内訳」のみ（「親子」「サブカテゴリ」はUI文言禁止）。
- 要望は具体的（例:「食費の下＝5番目」「4列右に薄点線」「右送りボタンは残す・タイルに被ってOK」）。額面どおり実装する。

## 開発環境・ツールの注意

- **cliclick（シミュレータへの合成クリック）が効かない**。見た目を見せたい時は、`home_shell.dart` の initState postFrame に **一時デモコード（`// TEMP-DEMO`）**を仕込んで状態を作り（例: 入力タブを開く `startCreate`＋`set(1)`、シートを開く等）→`xcrun simctl io <UDID> screenshot`→**必ず削除**。コミット前に `grep -rc TEMP-DEMO lib/` が 0 か確認。
- Boot中シミュレータ: iPhone 17 iOS26.4 `9EC1319F-690F-4FCA-BAB7-97B2F6A1D1BA` / iOS26.5 `263FF66C-20AE-46F5-9E41-059FA834CD09`。`simctl` は UDID 指定推奨。`flutter run -d <UDID>` はバックグラウンド起動＋ログを grep で「Dart VM Service」待ち→スクショ、が回しやすい。
- テストシミュレータのDBにデモ取引・並び替え結果が残っている（支出¥84万など）。実機・配信物には無関係。

## 次アクション候補

1. **ユーザーが build 4 を Transporter でアップロード**（未実施）→ 実機で確認。
2. さらなるUIフィードバックがあれば最小差分で対応（上記スタイル厳守）。調整余地: 週罫線の濃さ / 選択丸の色 / 週末の日付数字の色付け / 暗い背景時の文字色自動調整 / ジグル強さ。
3. **git push 未実施**（origin/main より先行）。必要ならユーザー確認の上で `git push`。
4. **Phase 5後半（Vision/カメラ）は未着手**（`docs/phase5-mac-runbook.md` §9・spec §13）。初回配信スコープ外。実レシート~15枚を貯めてフィクスチャ化→パーサ再調整。
5. アプリアイコンがFlutterデフォルトのまま（内部テストは通るが**一般公開前に差し替え必須**）。

## 参照

- Mac作業手順: `docs/phase5-mac-runbook.md`（Step進捗表・SPM/署名の詳細）
- Phase 4.5ハンドオフ: `docs/phase45-handoff.md`
- spec: `docs/superpowers/specs/2026-07-03-kakeibo-app-design.md`
- テストハーネス: `test/support/test_app.dart`（固定時計2026-07-15・`setPhoneSurface`）
