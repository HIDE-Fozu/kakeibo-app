# Phase 4.5 ハンドオフ（2026-07-03 セッション終了時点）

次セッションはこのファイルと `memory/project_kakeibo_app.md` から再開する。

## 現在地

- **P1〜P4 完了**: 全UI実装済み・**210テスト緑**・`flutter analyze` 0・main クリーン（全コミット済み・リモートなし）
- 実行済みplan: `docs/superpowers/plans/`（P4は逸脱メモ・実行結果メモをファイル冒頭に記録済み）
- **UIモック v3**: `docs/mockups/ui-mock-v1.html`（ファイル名はv1のままartifactのURL固定用。中身はv3）
  - Artifact URL: https://claude.ai/code/artifact/8f421f50-97ea-476a-8ab9-7b9b15b384db
  - ユーザー評価「便利だね」。**このURLへの再デプロイは同じファイルパスを使うこと**

## モックで確定した仕様（Phase 4.5 の要求）

1. **カレンダーセルは万表記**: `980`（1,000円未満は生数字）/ `0.3万` / `1.2万` / `28.5万` / `123万`
   - 実装規則: <1000→そのまま、<100万→万単位で小数1桁（`.0`はトリム）、≥100万→整数万。¥プレフィックスなし
   - ドット/ヒートバー案は落選見込み（万表記が有力。最終確定は実機で）
2. **階層の呼称は「カテゴリ／内訳」**（「親子」「サブカテゴリ」はUI文言に使わない。ユーザー明示指定）
3. **内訳（サブカテゴリ）機能**:
   - 入力画面: 内訳を持つカテゴリに▼マーク → タップで選択＋内訳チップ列が**カテゴリグリッドの直上**に出現 → **同じカテゴリを再タップで格納（選択は維持）** → 内訳未選択で保存すればカテゴリ本体に計上
   - 内訳選択中はカテゴリボタンのラベルが内訳名に変わる（食費→外食）
   - デモ構成: 食費［外食/スーパー/コンビニ/カフェ］、趣味・娯楽［ゲーム/書籍/映画］
4. **サマリの入れ子グラフ**: 内訳ありカテゴリは積み上げバー（深緑の濃淡5色 `#1E6B5A #4E937E #7BB3A0 #A8CFC0 #CFE4DB` 循環）＋「▼内訳」タップで展開（内訳別の金額と親内%）。直接計上分は「（内訳なし）」
5. **カテゴリ管理**: 各カテゴリ行に「＋内訳」、右上「＋」=新カテゴリ。内訳は`└`ネスト表示。並べ替えは同カテゴリ内のみ。**階層は2段まで**
6. **デザイントークン（Flutterテーマへ移植）**:
   - paper `#F6F5F0` / card `#FFFFFF` / ink `#20241F` / muted `#6F756A` / line `#E3E2D8`
   - primary `#1E6B5A`（primary-soft `#E4EFE9`）
   - 支出=紅 `#B8433A`（soft `#F7E9E7`）／収入=藍 `#2E6E93`（soft `#E7EFF5`）
   - 確信度: high=緑soft `#E2F0E6`／medium=琥珀 `#A8741A`(soft `#F6EDDC`)／low=紅soft
   - 金額は tabular figures（`FontFeature.tabularFigures()`）

### モックの未決事項（v4で詰めるか実装中に判断）

- 1,000円未満セルの生数字表記の是非（全部万に寄せる案あり）
- 内訳チップの位置（グリッド直上 vs 金額表示の下）
- 「（内訳なし）」の名称
- サマリ展開のアコーディオン化（現状は複数同時展開可）
- バックアップバナーの存在感

## 次アクション = Phase 4.5（Windows完結・いつもの型で）

**スコープ**: 内訳機能＋テーマ/万表記の移植。データ影響が本体:
1. `categories` に `parentId`（nullable, FK self）追加 → **drift schemaVersion 2 + マイグレーション**（既存行はparentId=null）
2. **バックアップ formatVersion 2**（parentId同梱。v1からの前方マイグレーション=parentId nullで補完。新しい版の拒否ロジックは既存のまま）
3. 集計: カテゴリ計は内訳込みで親にロールアップ＋内訳別内訳（bySub）。不変条件テスト（内訳和+直接分==親計、親計和==月次合計）を拡張
4. リポジトリ/provider: addCategory({parentId})・watchAllの階層整列・entryCategoriesは親のみ・内訳リスト取得
5. UI: 入力の内訳チップ（上記挙動）／サマリ積み上げ+展開／カテゴリ管理の＋内訳／セル万表記（compactYen置換→manYen）／ThemeData移植
6. システム「未分類」は親のみ・内訳不可。内訳のアーカイブは親と独立

**進め方**: writing-plans → 敵対的検証workflow → 修正 → executing-plansインラインTDD → 全テスト+analyze → no-ffマージ（P1〜P4と同じ）。
サブエージェントのモデルは毎回明示指定（Fable優先可・簡単な仕事はOpus/Sonnet。~/.claude/CLAUDE.md参照）。

**P4で確立した技術的注意（詳細はmemoryの「運用の学び」）**:
- riverpodは**2.6.1手書きprovider**継続（drift_devのanalyzer ^13とcodegen系が共存不能）。複数キーfamilyは`(int,int)`レコード
- widgetテスト(FakeAsync)ではUI経路のファイルIOは**同期API**／SnackBarテストは末尾`pump(5s)`／fullscreenDialogはCloseButton／containerOfはMaterialApp基準／ダイアログのTextEditingControllerはダイアログ自身のStatefulWidgetへ／`onReorderItem`使用／テスト時計はハーネス（AutoBackupStoreは1秒tick）

## TestFlight ロードマップ（ユーザー表明済み）

- **ユーザー側（並行して今すぐ）**: Apple Developer Program登録（$99/年・審査1〜2日）＋ Mac + Xcode
- **Mac到着後（Phase 5）**: Bundle ID決定 → 署名 → `flutter build ipa` → TestFlight。**カメラ/Visionは初回配信に必須ではない**（レシートボタンを非表示 or 「利用できません」のまま配信可）。Info.plistに `UIFileSharingEnabled`/`LSSupportsOpeningDocumentsInPlace`（エクスポート取り出し経路）。deployment target **iOS 16**（Vision日本語認識の下限）
- その後: 実レシート~15枚→フィクスチャ化→パーサ再調整（spec §13）

## 参照パス

- spec: `docs/superpowers/specs/2026-07-03-kakeibo-app-design.md`
- P4 plan（逸脱メモ込み）: `docs/superpowers/plans/2026-07-03-kakeibo-phase4-ui.md`
- モック: `docs/mockups/ui-mock-v1.html`
- テストハーネス: `test/support/test_app.dart`（固定時計2026-07-15）
- Windowsデスクトップ実行はVSのC++コンポーネント不足で不可（VS Installerで「C++によるデスクトップ開発」追加なら可）
