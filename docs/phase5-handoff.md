# Phase 5 ハンドオフ（2026-07-05 セッション終了時点）

次セッションはこのファイルと `memory/`（特に `feedback-no-ui-mocks`）、`docs/phase5-mac-runbook.md` から再開する。

## いまどこ（TL;DR）

- **初回TestFlight配信は完了済み**（build 1）。母親テストのフィードバックを受けて**入力画面を大幅リデザイン**し、**build 3 のipaを生成済み**。
- **build 3 の ipa は生成しただけ。TestFlightへのアップロードはユーザー手動待ち**（`build/ios/ipa/kakeibo_app.ipa`／CFBundleVersion=3／App Store署名済み）。Transporterにドラッグ→Deliverで内部グループ「111」へ自動配信される。
- コード: **263テスト全緑・`flutter analyze` 0**。**main はローカルのみ（origin/main より 22 コミット先行・未push）**。作業ツリーはクリーン。

## リリース系の確定情報（変更不可）

| 項目 | 値 |
|---|---|
| Bundle ID | `com.hidefozu.kakeibo`（**App作成済み＝永久固定**） |
| Team ID | `Q7T6APPS23`（Hideaki Sato・個人アカウント） |
| App Store Connect App | 名前「経理の家計簿」／SKU `kakeibo-001`／プライマリ言語 日本語 |
| TestFlight | 内部グループ「**111**」・テスター2名・**自動配信ON**（build上げるだけで自動配布） |
| 署名 | pbxprojのRunner 3コンフィグに `CODE_SIGN_STYLE=Automatic`＋`DEVELOPMENT_TEAM=Q7T6APPS23` をCLIで設定済み。証明書 Dev/Distribution 済み |
| 現在バージョン | `1.0.0+3`（pubspec・コミット済み） |

## iOSビルドの前提（重要・runbookの補足）

- **SPM構成**（CocoaPodsではない）。`ios/Podfile` は無い・生成されない。deployment target は pbxproj の `IPHONEOS_DEPLOYMENT_TARGET=16.0`。
- `sqlite3_flutter_libs` は **native assets** で自動バンドル（`sqlite3.framework`）。プラグイン一覧には出ない。
- ipa生成: `flutter build ipa` → `build/ios/ipa/kakeibo_app.ipa`。**次のビルドはビルド番号を +1（次は `1.0.0+4`）**にしてから。App Store Connectはビルド番号の重複を拒否する（番号が飛ぶのはOK。build 2 は生成したが未アップロードのため 3 に飛ばした）。

## この画面まわりの現状アーキテクチャ（入力画面）

新規/変更した主なファイル（`git diff --name-only ff88610 HEAD`）:
- `lib/app/navigation.dart`（新規）: `homeTabIndexProvider`（Notifier<int>）と `kInputTabIndex=1`。
- `lib/app/home_shell.dart`: **4タブ**［カレンダー(0)/入力(1)/サマリ(2)/設定(3)］。入力タブ選択で `startCreate` 初期化。FAB/「この日に追加」は入力タブへ遷移。
- `lib/features/entry/presentation/entry_screen.dart`: `embedded` 引数（true=タブ埋め込み・保存でカレンダーへ切替／false=編集モーダル・保存でpop）。1画面完結（LayoutBuilder+ConstrainedBox(minHeight)+Spacerで保存を最下部固定・通常スクロールなし）。内訳チップは**カテゴリグリッドにStackで重ねる**（グリッドindexの偶奇で上段/下段へ反転＝押した行を隠さない）。**淡い緑パネル `#EAF4EF`＋枠 `#CFE4DB`**。
- `lib/features/entry/presentation/numpad.dart`: フルサイズ（各セル高さ56・4行=224）に戻してある。
- `lib/features/entry/presentation/subcategory_chips.dart`: 横スクロール1行＋右端「追加」。選択チップは**白背景＋緑チェックマーク**（塗り変更なし）。**チップ長押し→編集シート**（名前変更/削除=アーカイブ）。**「追加」ダイアログ**は本文内にボタン、その下に折りたたみ「**既存の内容を編集**」（名前変更・削除）。
- `lib/core/category_emoji.dart`（新規）: プリセット名→絵文字の**表示専用マップ**。`categoryEmoji(icon, name)`。入力グリッド/カレンダー明細/カテゴリ管理で共用。
- `lib/features/entry/application/entry_form_controller.dart`: `EntryFormState.formSeq`追加（メモ欄を新フォームで確実にリセットするkey用）。

**注意（重要な逸脱）**: カテゴリ絵文字は当初 **schema v3 マイグレーション**で入れる実装をしたが、ユーザーの怒りで一括revert済み。**現在は `schemaVersion => 2` のまま**で、絵文字は**表示専用**（DB/マイグレーション未変更）。ユーザーが自分でicon（絵文字）を設定していればそれを優先。

## ユーザーの強い要望・スタイル（守ること）

- **HTMLモックを作らない・参照しない**（`memory/feedback-no-ui-mocks`）。UI変更は**実機画面＋ユーザーのスクショ**だけを基準に**実Flutterコードへ最小差分**。美観の判断（色・アイコン等）を勝手にしない。
- 反復は**シミュレータのスクショで見せて確認**する流れ。ただし下記のツール制約に注意。
- 用語は「カテゴリ／内訳」のみ（「親子」「サブカテゴリ」はUI文言禁止）。

## 開発環境・ツールの注意

- **cliclick（シミュレータへの合成クリック）が途中から効かなくなった**（日付タップも無反応）。シミュレータのスクショで見た目を見せたい時は、`home_shell.dart` の `initState` postFrame に **一時デモコード（`// TEMP-DEMO`）**を仕込んで状態を作り→`xcrun simctl io <UDID> screenshot`→**必ず削除**、で対応した。コミット前に `grep -c TEMP-DEMO lib/app/home_shell.dart` が 0 か確認。
- Boot中シミュレータ（このセッション時点）: iPhone 17 iOS26.4 `9EC1319F-690F-4FCA-BAB7-97B2F6A1D1BA` / iOS26.5 `263FF66C-20AE-46F5-9E41-059FA834CD09`。`simctl` は `booted` が曖昧になるので UDID 指定推奨。
- テストシミュレータのDBに、デモで作った内訳（例「ドラッグストア」「スーパー」）が残っている場合あり。実機には無関係。

## 次アクション候補

1. **ユーザーが build 3 を Transporter でアップロード**（未実施）→ 実機で確認。
2. さらなる入力画面フィードバックがあれば最小差分で対応（上記スタイル厳守）。
3. **git push 未実施**（22コミット先行）。必要ならユーザー確認の上で `git push`。
4. **Phase 5後半（Vision/カメラ）は未着手**（`docs/phase5-mac-runbook.md` §9・spec §13）。初回配信スコープ外。実レシート~15枚を貯めてフィクスチャ化→パーサ再調整。
5. アプリアイコンがFlutterデフォルトのまま（内部テストは通るが**一般公開前に差し替え必須**）。

## 参照

- Mac作業手順: `docs/phase5-mac-runbook.md`（Step進捗表・SPM/署名の詳細）
- Phase 4.5ハンドオフ: `docs/phase45-handoff.md`
- spec: `docs/superpowers/specs/2026-07-03-kakeibo-app-design.md`
- テストハーネス: `test/support/test_app.dart`（固定時計2026-07-15・`setPhoneSurface`）
