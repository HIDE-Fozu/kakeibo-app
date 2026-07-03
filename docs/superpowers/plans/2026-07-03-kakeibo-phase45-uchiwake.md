# Phase 4.5: 内訳（サブカテゴリ）＋テーマ・万表記移植 Implementation Plan

> **【実行結果メモ 2026-07-03】全Task完了（Task 0〜13）・256テスト緑・analyze 0・mainへno-ffマージ済み。**
> 実行中の逸脱（planに無かった追加対応）:
> 1. **アーカイブ/changeTypeガードの余波で既存テスト4本が食費前提で衝突** → 内訳を持たないカテゴリへ差し替え: `calendar_providers_test`（アーカイブ→趣味・娯楽）／`category_integrity_test` changeType取引ガード（→日用品）／`category_crud_test` setArchived往復（→日用品）／`category_manage_test` 改名アーカイブ復帰（→日用品）
> 2. **manYen境界値の修正**: 99.9万→100万の繰り上がり境界は999,950ではなく**999,500**（丸め単位=0.05万。planの初版が誤り）
> 3. **チップ列が開くと下のボタン/タイルが画面外に押し下げられる** → entry系UIテストのタップ前に `tester.ensureVisible(...)` を挿入（4テスト・計7箇所）。アーカイブ済みセクションのテストにも `scrollUntilVisible` が必要だった
> 4. csv_exporter_test はBackupCategoryを構築していなかったため構築修正は backup_codec/auto_backup_store/backup_restore の3ファイルのみ

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** カテゴリに「内訳」（2段階層）を追加し、入力チップ／サマリ積み上げ／カテゴリ管理へ展開。カレンダーセルを万表記に置換し、モック確定デザイントークンをFlutterテーマへ移植する。

**Architecture:** `categories.parentId`（nullable自己FK）を schemaVersion 2 で追加。集計はDAOのカテゴリ別行（parentId付き）を純関数 `rollupSpending` で親へロールアップ（SQLは変えず内訳次元だけ列追加）。バックアップは formatVersion 2（parentId同梱・v1は前方migrate）。UIは既存3タブ構成のまま各画面を拡張。

**Tech Stack:** Flutter 3.44.4 / Dart 3.12.2 / drift 2.34（codegenはbuild_runnerのみ）/ flutter_riverpod 2.6.1 **手書きprovider**（riverpod系codegen禁止・依存衝突のため）/ table_calendar 3.2

## Global Constraints

- **UI文言は「カテゴリ」「内訳」のみ**。「親子」「サブカテゴリ」をUI文字列に使わない（ユーザー明示指定）
- **階層は2段まで**。システム「未分類」は親のみ・内訳不可
- 復元/コーデックの検証は BackupCodec に集約（唯一の門番）。新しい版の拒否ロジックは既存構造のまま
- デザイントークン: paper `#F6F5F0` / card `#FFFFFF` / ink `#20241F` / muted `#6F756A` / line `#E3E2D8` / primary `#1E6B5A`(soft `#E4EFE9`) / 支出紅 `#B8433A`(soft `#F7E9E7`) / 収入藍 `#2E6E93`(soft `#E7EFF5`) / 確信度 high=`#E2F0E6`・medium=`#A8741A`(soft `#F6EDDC`)・low=紅soft / 積み上げ5色 `#1E6B5A #4E937E #7BB3A0 #A8CFC0 #CFE4DB`
- セル万表記: `980`（<1000は生数字・¥なし）/ `0.3万` / `1.2万` / `28.5万`（<100万は小数1桁・`.0`トリム）/ `123万`（≥100万は整数万）
- 金額表示は tabular figures（`FontFeature.tabularFigures()`）
- widgetテスト規律（P4確立）: UI経路のファイルIOは同期API／SnackBarテスト末尾は `pump(Duration(seconds:5))`／fullscreenDialogは `CloseButton`／`containerOf` はMaterialApp基準／ダイアログのTextEditingControllerはダイアログ自身のStatefulWidgetへ／`ReorderableListView` は `onReorderItem`／固定時計 2026-07-15
- **datetime列は全てISO-8601 TEXT**（build.yamlの `store_date_time_values_as_text: true`。UTCは末尾Z）。テストフィクスチャのDDL/値も必ずTEXTで書くこと（INTEGERだと行マッピングでFormatException）
- 検証コマンド: `flutter test` ／ `flutter analyze` ／ スキーマ変更後は `dart run build_runner build --delete-conflicting-outputs`
- コミットは各タスク末尾で（feature branch `phase45-uchiwake` 上、最後にmainへ `--no-ff` マージ）

## 実装中判断（モック未決事項の確定）

- 1,000円未満セルは**生数字採用**（manYen仕様どおり）
- 内訳チップは**グリッド直上**（確定済み）
- 直接計上分の名称は**「（内訳なし）」**をそのまま採用
- サマリ展開は**複数同時展開可**（アコーディオン化しない）
- バックアップバナーはPhase 4.5スコープ外（触らない）
- **シード変更**: プリセットの「外食」を「食費」の内訳としてシード（モック確定のデモ構成に整合。新規DBのみ影響・既存DBのマイグレーションは全行parentId=null）。スーパー/コンビニ等の追加シードはしない（ユーザーが自分で作る）
- **万表記の丸めは四捨五入**（モック実装のMath.round準拠。9999→1万・1235000→124万。切り捨てだとモック表示とズレる）
- **格納後の再展開でも内訳選択は維持**（モック実装は再展開時に親へリセットするが、handoff確定は格納側の「選択は維持」のみ。一貫性を優先して維持に統一）
- **サマリ展開の「（内訳なし）」は内訳と同列・金額降順に混ぜる**（モック準拠。積み上げバーの区間色も降順位置で割当）
- **親のアーカイブは、アクティブな内訳が残っている間は拒否**（CategoryHierarchyError）。許すと内訳が管理ページにも入力グリッドにも出ない「幽霊カテゴリ」になるため。内訳→親の順なら従来どおり可（内訳アーカイブの独立性は維持）
- **changeTypeに階層ガード追加**: 内訳自身／内訳を持つ親のtype変更は拒否。許すと「typeは親と一致」の不変条件が破れ、自分のバックアップがcodec検証（Task 5）で復元不能になる

## File Structure（作成/変更マップ）

| ファイル | 変更 |
|---|---|
| `lib/data/db/tables.dart` | Categories に parentId 列 |
| `lib/data/db/database.dart` | schemaVersion 2・onUpgrade・シード変更 |
| `lib/data/db/daos.dart` | CategorySpendRow.parentId・maxSortOrderWithin |
| `lib/domain/entities.dart` | CategoryEntity.parentId |
| `lib/domain/repositories.dart` | addCategory({parentId})・watchAll/reorderのdoc |
| `lib/data/repositories/drift_category_repository.dart` | 階層検証・階層整列・スコープreorder |
| `lib/domain/services/spending_rollup.dart` | **新規** ロールアップ純関数 |
| `lib/data/backup/backup_data.dart` | BackupCategory.parentId |
| `lib/data/backup/backup_codec.dart` | formatVersion 2・階層検証・v1→v2 migrate |
| `lib/data/backup/backup_service.dart` | export parentId・restoreのFK defer |
| `lib/data/backup/csv_exporter.dart` | 内訳列追加 |
| `lib/core/format.dart` | compactYen → manYen |
| `lib/app/theme.dart` | **新規** トークン・KakeiboColors・buildKakeiboTheme |
| `lib/app/app.dart` | テーマ適用 |
| `lib/features/entry/application/entry_category_providers.dart` | 親のみ＋lastUsedロールアップ＋内訳provider |
| `lib/features/entry/application/entry_form_controller.dart` | expandedParentId・tapCategory・toggleSubcategory |
| `lib/features/entry/presentation/category_grid.dart` | ▾マーク・ラベル差替・タップ判定 |
| `lib/features/entry/presentation/subcategory_chips.dart` | **新規** 内訳チップ列 |
| `lib/features/entry/presentation/entry_screen.dart` | チップ列配置・金額tabular |
| `lib/features/entry/presentation/receipt_review_panel.dart` | confidenceTint新色 |
| `lib/features/summary/application/summary_providers.dart` | **新規** rollup provider |
| `lib/features/summary/presentation/summary_screen.dart` | 積み上げバー＋展開 |
| `lib/features/calendar/presentation/calendar_screen.dart` | セル万表記・色 |
| `lib/features/calendar/presentation/day_transaction_list.dart` | 紅/藍・tabular |
| `lib/features/settings/presentation/category_manage_page.dart` | ＋内訳・└表示・同スコープ並べ替え |

テスト: `test/migration_test.dart`（新規）・`test/category_hierarchy_test.dart`（新規）・`test/spending_rollup_test.dart`（新規）・`test/ui/theme_test.dart`（新規）＋既存の `seed_test` / `aggregation_test` / `format_test` / `backup_*` / `csv_exporter_test` / `ui/*` を更新。

---

### Task 0: ブランチ作成

- [ ] **Step 1: featureブランチを切る**

```bash
git checkout -b phase45-uchiwake
```

---

### Task 1: DBスキーマ v2（parentId列＋マイグレーション）

**Files:**
- Modify: `lib/data/db/tables.dart`
- Modify: `lib/data/db/database.dart`（schemaVersion/onUpgradeのみ。シードはTask 2）
- Test: `test/migration_test.dart`（新規）

**Interfaces:**
- Produces: `CategoryRow.parentId`（int?、build_runner再生成後）／`CategoriesCompanion` の `parentId: Value<int?>`

- [ ] **Step 1: 失敗するマイグレーションテストを書く**

`test/migration_test.dart` を新規作成:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/test_db.dart';

void main() {
  test('schema v1 → v2: parentId列が追加され既存行はnull・取引も無傷', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v1.db');

    // v1スキーマを素のsqlite3で構築（v1当時のdrift生成DDL相当）
    final raw = sqlite3.open(file.path);
    raw.execute('''
CREATE TABLE "categories" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "name" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "icon" TEXT NULL,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "is_archived" INTEGER NOT NULL DEFAULT 0,
  "is_system" INTEGER NOT NULL DEFAULT 0
);''');
    raw.execute('''
CREATE TABLE "transactions" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "type" TEXT NOT NULL,
  "amount" INTEGER NOT NULL,
  "date" TEXT NOT NULL,
  "category_id" INTEGER NOT NULL REFERENCES "categories" ("id") ON DELETE RESTRICT,
  "payment_method" TEXT NULL,
  "memo" TEXT NULL,
  "source" TEXT NOT NULL,
  "image_path" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    raw.execute(
        "INSERT INTO categories (name, type, sort_order) VALUES ('旧食費', 'expense', 0)");
    raw.execute(
        "INSERT INTO transactions (type, amount, date, category_id, source, created_at, updated_at) "
        "VALUES ('expense', 500, '2026-07-01', 1, 'manual', "
        "'2026-07-01T00:00:00.000Z', '2026-07-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    // AppDatabase で開く → onUpgrade が走る
    final db = AppDatabase(NativeDatabase(file));
    final cats = await db.categoryDao.allCategories();
    expect(cats.single.name, '旧食費');
    expect(cats.single.parentId, isNull); // 追加列はnull補完
    final txs = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(txs.single.amount, 500);
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 2);
    await db.close();
  });

  test('新規DB: システム未分類はparentId=null', () async {
    final db = newMemoryDb();
    addTearDown(db.close);
    final all = await db.categoryDao.allCategories();
    expect(all.where((c) => c.isSystem).every((c) => c.parentId == null), isTrue);
  });
}
```

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/migration_test.dart`
Expected: コンパイルエラー（`parentId` が `CategoryRow` に存在しない）

- [ ] **Step 3: parentId列とマイグレーションを実装**

`lib/data/db/tables.dart` の `Categories` に追加（`isSystem` の下）:

```dart
  /// 非null=内訳（親カテゴリのid）。階層は2段まで（アプリ側で保証）。
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
```

`lib/data/db/database.dart`:

```dart
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: 内訳機能。既存カテゴリは全て親（parentId=null）のまま。
            await m.addColumn(categories, categories.parentId);
          }
        },
        beforeOpen: (details) async {
          // FK は接続ごとに有効化しないと SQLite が無視する。
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated) {
            await _seedInitialCategories();
          }
        },
      );
```

- [ ] **Step 4: コード生成**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `database.g.dart` / `daos.g.dart` 再生成、`CategoryRow.parentId` が生える

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/migration_test.dart`
Expected: PASS（2件）

- [ ] **Step 6: 全テスト＋analyze（既存が壊れていないこと）**

Run: `flutter analyze && flutter test`
Expected: analyze 0 / 210＋2 全緑

- [ ] **Step 7: Commit**

```bash
git add lib/data/db/tables.dart lib/data/db/database.dart lib/data/db/database.g.dart lib/data/db/daos.g.dart test/migration_test.dart
git commit -m "feat(db): categories.parentId column with schema v2 migration"
```

---

### Task 2: シード変更（外食を食費の内訳に）

**Files:**
- Modify: `lib/data/db/database.dart:34-84`（`_seedInitialCategories`）
- Modify: `lib/data/db/daos.dart`（並び順のタイブレーク）
- Test: `test/seed_test.dart`

**Interfaces:**
- Produces: 新規DBのシード＝支出親13（食費0〜その他12）＋内訳1（外食、食費の下・sortOrder 0）＋収入4＋未分類2 ＝ **計20行（従来と同数）**

- [ ] **Step 1: seed_testに失敗する期待を足す**

`test/seed_test.dart` の1本目のテスト末尾に追加:

```dart
    // 外食は食費の内訳としてシードされる（モック確定のデモ構成）
    final food = all.firstWhere((c) => c.name == '食費');
    final eatOut = all.firstWhere((c) => c.name == '外食');
    expect(eatOut.parentId, food.id);
    expect(eatOut.sortOrder, 0); // 内訳スコープ内の先頭
    // 内訳シードは外食のみ。他は全て親
    expect(all.where((c) => c.parentId != null).length, 1);
```

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/seed_test.dart`
Expected: FAIL（`eatOut.parentId` が null）

- [ ] **Step 3: シードを書き換える**

`lib/data/db/database.dart` の `_seedInitialCategories` 全体を置換:

```dart
  Future<void> _seedInitialCategories() async {
    // 並び順は sortOrder に一致（スコープ＝同じ親の中）。システム「未分類」は末尾。
    // 外食は食費の内訳としてシード（モック確定のデモ構成に合わせる）。
    final foodId = await into(categories).insert(CategoriesCompanion.insert(
      name: '食費',
      type: CategoryType.expense,
      sortOrder: const Value(0),
    ));
    const expensePresets = <String>[
      '日用品', '水道光熱費', '通信費', '交通費', '交際費',
      '趣味・娯楽', '衣服・美容', '医療・健康', '住居', '教育', '特別費', 'その他',
    ];
    const incomePresets = <String>['給与', '賞与', '副収入', 'その他'];

    await batch((b) {
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '外食',
          type: CategoryType.expense,
          sortOrder: const Value(0), // 内訳スコープ内の先頭
          parentId: Value(foodId),
        ),
      );
      var order = 1; // 食費=0 の続きから
      for (final name in expensePresets) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.expense,
            sortOrder: Value(order++),
          ),
        );
      }
      for (final name in incomePresets) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.income,
            sortOrder: Value(order++),
          ),
        );
      }
      // システム「未分類」（削除不可・親のみ・内訳不可）
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '未分類',
          type: CategoryType.expense,
          sortOrder: Value(order++),
          isSystem: const Value(true),
        ),
      );
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '未分類',
          type: CategoryType.income,
          sortOrder: Value(order++),
          isSystem: const Value(true),
        ),
      );
    });
  }
```

- [ ] **Step 4: 並び順のタイブレークを決定的にする**

このシードで「食費(親スコープ sortOrder 0)」と「外食(内訳スコープ sortOrder 0)」がフラットな `ORDER BY sort_order` で同順位になる。SQLiteのタイ順（rowid順）は未保証なので、`lib/data/db/daos.dart` の `CategoryDao.allCategories` / `watchAllCategories` の両方に第2キーを足して決定的にする:

```dart
  Future<List<CategoryRow>> allCategories() => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .get();

  Stream<List<CategoryRow>> watchAllCategories() => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .watch();
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/seed_test.dart`
Expected: PASS

- [ ] **Step 6: 全テスト（外食参照テストの回帰確認）**

Run: `flutter test`
Expected: 全緑。`aggregation_test` と `category_integrity_test` は外食を参照するがDAO直叩きなので挙動不変。`ui/category_manage_test` の並べ替えテストはこの時点では旧reorder（スコープ検証なし）のまま動き、Step 4のタイブレークでページのリスト順も決定的（食費が外食より先）なので緑

- [ ] **Step 7: Commit**

```bash
git add lib/data/db/database.dart lib/data/db/daos.dart test/seed_test.dart
git commit -m "feat(db): seed eat-out as a breakdown of food category"
```

---

### Task 3: エンティティ＋リポジトリの階層対応

**Files:**
- Modify: `lib/domain/entities.dart`（CategoryEntity.parentId）
- Modify: `lib/domain/repositories.dart`（addCategory署名・doc）
- Modify: `lib/data/db/daos.dart`（maxSortOrderWithin追加・maxSortOrder削除・countChildrenOf系）
- Modify: `lib/data/repositories/drift_category_repository.dart`
- Modify: `lib/features/settings/presentation/category_manage_page.dart`（暫定パッチ・Step 6.5）
- Test: `test/category_hierarchy_test.dart`（新規）・`test/category_crud_test.dart`・`test/ui/category_manage_test.dart`・`test/category_integrity_test.dart`（Step 6.5で更新）

**Interfaces:**
- Consumes: `CategoryRow.parentId`（Task 1）
- Produces:
  - `CategoryEntity.parentId`（int?・省略可能named引数、デフォルトnull）
  - `CategoryRepository.addCategory({required String name, required CategoryType type, String? icon, int? parentId})`
  - `class CategoryHierarchyError implements Exception { final String message; }`（drift_category_repository.dart内）
  - `watchAll()`: 親をsortOrder順、各親の直後にその内訳をsortOrder順で返す
  - `reorder(List<int>)`: 同一スコープ（同じ親）のidのみ受理、違反は `ArgumentError`
  - `setArchived(id, true)`: アクティブな内訳が残る親は `CategoryHierarchyError`（幽霊カテゴリ防止）。`archive()` は `setArchived(id, true)` へ委譲
  - `changeType`: 内訳自身／内訳を持つ親は `CategoryHierarchyError`（取引ありは従来どおり `CategoryInUseError`）
  - `CategoryDao.maxSortOrderWithin(int? parentId)`: 同スコープ内max（なければ-1）／`countChildrenOf(int)`・`countActiveChildrenOf(int)`

- [ ] **Step 1: 失敗するテストを書く**

`test/category_hierarchy_test.dart` を新規作成:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository repo;
  late int foodId;
  late int eatOutId;

  setUp(() async {
    db = newMemoryDb();
    repo = DriftCategoryRepository(db);
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
    eatOutId = all.firstWhere((c) => c.name == '外食').id;
  });
  tearDown(() => db.close());

  test('addCategory(parentId): 内訳が同スコープ末尾のsortOrderで追加される', () async {
    final superId = await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: foodId);
    final rows = await db.categoryDao.allCategories();
    final sup = rows.firstWhere((c) => c.id == superId);
    expect(sup.parentId, foodId);
    expect(sup.sortOrder, 1); // 外食=0 の次
  });

  test('内訳の下に内訳は作れない（2段まで）', () async {
    expect(
      () => repo.addCategory(
          name: 'ラーメン', type: CategoryType.expense, parentId: eatOutId),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('システムカテゴリには内訳を作れない', () async {
    final uncat = await db.categoryDao.uncategorizedId(CategoryType.expense);
    expect(
      () => repo.addCategory(
          name: 'x', type: CategoryType.expense, parentId: uncat),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('typeが親と不一致なら拒否', () async {
    expect(
      () => repo.addCategory(
          name: 'x', type: CategoryType.income, parentId: foodId),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('存在しない親は拒否', () async {
    expect(
      () => repo.addCategory(
          name: 'x', type: CategoryType.expense, parentId: 99999),
      throwsA(isA<CategoryHierarchyError>()),
    );
  });

  test('watchAll: 親の直後にその内訳が並ぶ（階層整列）', () async {
    await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: foodId);
    final list = await repo.watchAll().first;
    final foodIdx = list.indexWhere((c) => c.id == foodId);
    expect(list[foodIdx + 1].name, '外食');
    expect(list[foodIdx + 1].parentId, foodId);
    expect(list[foodIdx + 2].name, 'スーパー');
    // 親同士はsortOrder昇順を保つ
    final parents = list.where((c) => c.parentId == null).toList();
    final orders = parents.map((c) => c.sortOrder).toList();
    expect(orders, List.of(orders)..sort());
  });

  test('reorder: 異なるスコープの混在は拒否・同一スコープ（内訳同士）はOK', () async {
    final superId = await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: foodId);
    expect(() => repo.reorder([foodId, eatOutId]), throwsArgumentError);
    await repo.reorder([superId, eatOutId]);
    final rows = await db.categoryDao.allCategories();
    expect(rows.firstWhere((c) => c.id == superId).sortOrder, 0);
    expect(rows.firstWhere((c) => c.id == eatOutId).sortOrder, 1);
  });

  test('内訳のアーカイブは親と独立（内訳→親の順ならアーカイブ可）', () async {
    await repo.setArchived(eatOutId, true);
    final rows = await db.categoryDao.allCategories();
    expect(rows.firstWhere((c) => c.id == eatOutId).isArchived, isTrue);
    expect(rows.firstWhere((c) => c.id == foodId).isArchived, isFalse); // 親は無傷
    // アクティブな内訳が残っていないので親もアーカイブできる
    await repo.setArchived(foodId, true);
    final rows2 = await db.categoryDao.allCategories();
    expect(rows2.firstWhere((c) => c.id == foodId).isArchived, isTrue);
    expect(rows2.firstWhere((c) => c.id == eatOutId).isArchived, isTrue);
  });

  test('アクティブな内訳が残る親はアーカイブできない（幽霊カテゴリ防止）', () async {
    expect(() => repo.setArchived(foodId, true),
        throwsA(isA<CategoryHierarchyError>()));
    expect(() => repo.archive(foodId),
        throwsA(isA<CategoryHierarchyError>()));
  });

  test('changeType: 内訳自身も内訳を持つ親も拒否（不変条件: typeは親と一致）', () async {
    expect(() => repo.changeType(eatOutId, CategoryType.income),
        throwsA(isA<CategoryHierarchyError>()));
    expect(() => repo.changeType(foodId, CategoryType.income),
        throwsA(isA<CategoryHierarchyError>()));
  });
}
```

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/category_hierarchy_test.dart`
Expected: コンパイルエラー（`parentId` named引数なし／`CategoryHierarchyError` 未定義）

- [ ] **Step 3: エンティティとインターフェースを更新**

`lib/domain/entities.dart` の `CategoryEntity` を置換:

```dart
class CategoryEntity {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;
  final int? parentId; // 非null=内訳（階層は2段まで）
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    this.parentId,
  });
}
```

`lib/domain/repositories.dart` の `CategoryRepository` 内、`watchAll`・`addCategory`・`reorder` のdocと署名を更新:

```dart
  /// 階層整列で返す: 親をsortOrder順、各親の直後にその内訳をsortOrder順。
  Stream<List<CategoryEntity>> watchAll();

  /// 同一スコープ（同じ親）末尾のsortOrderで追加。name.trim()が空なら [ArgumentError]。
  /// parentId指定時は内訳として追加。親が存在しない／親自身が内訳（2段超）／
  /// 親がシステム／typeが親と不一致なら CategoryHierarchyError（実装参照）。
  Future<int> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
    int? parentId,
  });

  /// 渡した順に sortOrder = 0,1,2,... を振り直す。
  /// 同一スコープ（同じ親）のidのみ受理し、混在は [ArgumentError]。
  Future<void> reorder(List<int> orderedIds);
```

- [ ] **Step 4: DAOにスコープ付きmaxを実装（旧maxSortOrderは削除）**

`lib/data/db/daos.dart` の `CategoryDao.maxSortOrder` を置換:

```dart
  /// 同一スコープ（parentIdが同じ）内の最大sortOrder。行がなければ-1。
  Future<int> maxSortOrderWithin(int? parentId) async {
    final maxOrder = categories.sortOrder.max();
    final q = selectOnly(categories)
      ..addColumns([maxOrder])
      ..where(parentId == null
          ? categories.parentId.isNull()
          : categories.parentId.equals(parentId));
    final row = await q.getSingle();
    return row.read(maxOrder) ?? -1;
  }
```

`grep -rn "maxSortOrder" lib test` で呼び出し元を確認。リポジトリ以外に呼び出しがあれば `maxSortOrderWithin(null)` へ置換する。

同じく `CategoryDao` に内訳カウントを追加（changeType/アーカイブのガード用）:

```dart
  /// 内訳の数（アーカイブ込み）。
  Future<int> countChildrenOf(int categoryId) async {
    final cnt = categories.id.count();
    final q = selectOnly(categories)
      ..addColumns([cnt])
      ..where(categories.parentId.equals(categoryId));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
  }

  /// アクティブ（非アーカイブ）な内訳の数。
  Future<int> countActiveChildrenOf(int categoryId) async {
    final cnt = categories.id.count();
    final q = selectOnly(categories)
      ..addColumns([cnt])
      ..where(categories.parentId.equals(categoryId) &
          categories.isArchived.equals(false));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
  }
```

- [ ] **Step 5: リポジトリを実装**

`lib/data/repositories/drift_category_repository.dart`:

エラー型を追加（`SystemCategoryError` の下）:

```dart
/// 階層制約違反（2段超・システム親・type不一致・親不在）。
class CategoryHierarchyError implements Exception {
  final String message;
  const CategoryHierarchyError(this.message);
  @override
  String toString() => 'CategoryHierarchyError($message)';
}
```

`_toEntity` に parentId を追加:

```dart
  CategoryEntity _toEntity(CategoryRow r) => CategoryEntity(
        id: r.id,
        name: r.name,
        type: r.type,
        icon: r.icon,
        sortOrder: r.sortOrder,
        isArchived: r.isArchived,
        isSystem: r.isSystem,
        parentId: r.parentId,
      );
```

`watchAll` を階層整列に置換:

```dart
  @override
  Stream<List<CategoryEntity>> watchAll() =>
      _db.categoryDao.watchAllCategories().map(_hierarchical);

  /// 親をsortOrder順、各親の直後にその内訳をsortOrder順で並べる。
  List<CategoryEntity> _hierarchical(List<CategoryRow> rows) {
    final ents = rows.map(_toEntity).toList(); // DAOがsortOrder昇順で返す
    final byParent = <int, List<CategoryEntity>>{};
    for (final e in ents) {
      final p = e.parentId;
      if (p != null) byParent.putIfAbsent(p, () => []).add(e);
    }
    return [
      for (final e in ents)
        if (e.parentId == null) ...[e, ...byParent[e.id] ?? const []],
    ];
  }
```

`addCategory` を置換:

```dart
  @override
  Future<int> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
    int? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '空にできません');
    if (parentId != null) {
      final CategoryRow parent;
      try {
        parent = await _db.categoryDao.byId(parentId);
      } on StateError {
        throw CategoryHierarchyError('親カテゴリ $parentId が存在しません');
      }
      if (parent.parentId != null) {
        throw const CategoryHierarchyError('内訳の下に内訳は作れません（階層は2段まで）');
      }
      if (parent.isSystem) {
        throw const CategoryHierarchyError('システムカテゴリには内訳を作れません');
      }
      if (parent.type != type) {
        throw const CategoryHierarchyError('内訳のtypeは親と一致させる必要があります');
      }
    }
    final next = await _db.categoryDao.maxSortOrderWithin(parentId) + 1;
    return _db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: trimmed,
      type: type,
      icon: Value(icon),
      sortOrder: Value(next),
      parentId: Value(parentId),
    ));
  }
```

`reorder` を置換:

```dart
  @override
  Future<void> reorder(List<int> orderedIds) async {
    int? scope;
    var first = true;
    for (final id in orderedIds) {
      final row = await _db.categoryDao.byId(id);
      if (row.isSystem) throw SystemCategoryError(id);
      if (first) {
        scope = row.parentId;
        first = false;
      } else if (row.parentId != scope) {
        throw ArgumentError('並べ替えは同一スコープ（同じ親）内のみです');
      }
    }
    await _db.categoryDao.updateSortOrders({
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    });
  }
```

`changeType` を置換（階層ガードを先に。取引ガードは従来どおり）:

```dart
  @override
  Future<void> changeType(int categoryId, CategoryType type) async {
    final row = await _db.categoryDao.byId(categoryId);
    if (row.parentId != null) {
      throw const CategoryHierarchyError('内訳のtypeは変更できません（親と一致が必要）');
    }
    if (await _db.categoryDao.countChildrenOf(categoryId) > 0) {
      throw const CategoryHierarchyError('内訳を持つカテゴリのtypeは変更できません');
    }
    final count = await _db.categoryDao.countTransactionsFor(categoryId);
    if (count > 0) {
      throw CategoryInUseError(categoryId);
    }
    await _db.categoryDao.setType(categoryId, type);
  }
```

`archive` と `setArchived` を置換（幽霊カテゴリ防止ガード）:

```dart
  @override
  Future<void> archive(int categoryId) => setArchived(categoryId, true);

  @override
  Future<void> setArchived(int categoryId, bool archived) async {
    await _guardSystem(categoryId);
    if (archived) {
      final row = await _db.categoryDao.byId(categoryId);
      if (row.parentId == null &&
          await _db.categoryDao.countActiveChildrenOf(categoryId) > 0) {
        throw const CategoryHierarchyError(
            'アクティブな内訳が残っています（先に内訳をアーカイブしてください）');
      }
    }
    await _db.categoryDao.setArchived(categoryId, archived);
  }
```

- [ ] **Step 6: テストが通ることを確認**

Run: `flutter test test/category_hierarchy_test.dart`
Expected: PASS（10件）

- [ ] **Step 6.5: reorderスコープ検証・アーカイブガードに伴う既存テスト/ページの更新**

reorderのスコープ検証とアーカイブガードにより、**以下の3ファイルを直さないとStep 7のゲートが確実に赤になる**（外食が内訳化したため混在スコープになる）:

(a) `lib/features/settings/presentation/category_manage_page.dart` の `_CategoryTypeList` のactiveフィルタに親限定を追加（**暫定パッチ**。内訳のネスト表示UIはTask 12で全面書き換え時に実装。Task 3〜11の間、管理ページに外食が表示されないのは意図した中間状態）:

```dart
    final active = all
        .where((c) =>
            c.type == type && !c.isSystem && !c.isArchived && c.parentId == null)
        .toList();
```

(b) `test/category_crud_test.dart` のreorderテスト（「reorder: 渡した順で sortOrder=0.. が振られる」）の対象フィルタを親のみに変更（混在スコープはArgumentErrorになるため。混在拒否・内訳同士のreorderは category_hierarchy_test でカバー済み）:

```dart
    final exp = all
        .where((c) =>
            c.type == CategoryType.expense && !c.isSystem && c.parentId == null)
        .toList();
```

（reversed以降の検証ロジックはそのまま。変数名は既存に合わせる）

(c) `test/ui/category_manage_test.dart` の並べ替えテストの `expenseActive` フィルタに `&& x.parentId == null` を追加（外食(内訳スコープsortOrder 0)が混入するとindexがずれるため。このフィルタはTask 12の新ページでもそのまま正しい）:

```dart
    final expenseActive = cats
        .where((x) =>
            x.type == CategoryType.expense &&
            !x.isSystem &&
            !x.isArchived &&
            x.parentId == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
```

(d) `test/category_integrity_test.dart` の「active categories exclude archived」はアーカイブ対象が食費（アクティブな内訳持ち→新ガードで例外）なので、内訳を持たないカテゴリに変更:

```dart
  test('active categories exclude archived, include everything else', () async {
    final all = await db.categoryDao.allCategories();
    final dailyId = all.firstWhere((c) => c.name == '日用品').id;
    await catRepo.archive(dailyId);
    final active = await db.categoryDao.activeCategories();
    expect(active.any((c) => c.id == dailyId), isFalse);
    // 未分類システムを含む他は残る
    expect(active.any((c) => c.name == '外食'), isTrue);
  });
```

- [ ] **Step 7: 全テスト＋analyze**

Run: `flutter analyze && flutter test`
Expected: 全緑。落ちる場合はStep 6.5の4点が適用済みか確認（失敗モードはreorderのArgumentError／アーカイブガードのCategoryHierarchyErrorであり、watchAllの順序問題ではない）

- [ ] **Step 8: Commit**

```bash
git add lib/domain/entities.dart lib/domain/repositories.dart lib/data/db/daos.dart lib/data/repositories/drift_category_repository.dart lib/features/settings/presentation/category_manage_page.dart test/category_hierarchy_test.dart test/category_crud_test.dart test/ui/category_manage_test.dart test/category_integrity_test.dart
git commit -m "feat(category): two-level hierarchy with scope-guarded reorder and archive/type guards"
```

---

### Task 4: 集計ロールアップ（CategorySpendRow.parentId＋純関数）

**Files:**
- Modify: `lib/data/db/daos.dart`（CategorySpendRow・2つのspendingByCategoryクエリ）
- Create: `lib/domain/services/spending_rollup.dart`
- Test: `test/spending_rollup_test.dart`（新規）・`test/aggregation_test.dart`（不変条件を拡張）

**Interfaces:**
- Consumes: `CategoryEntity.parentId`（Task 3）
- Produces:
  - `CategorySpendRow` に `final int? parentId;`（required named）
  - `class SubSpend { int categoryId; String name; bool isArchived; int total; }`
  - `class CategorySpendGroup { int categoryId; String name; bool isArchived; int total; int directTotal; List<SubSpend> subs; bool get hasSubs; }`
  - `List<CategorySpendGroup> rollupSpending(List<CategorySpendRow> rows, List<CategoryEntity> categories)` — グループ降順・subs降順

- [ ] **Step 1: 失敗する純関数テストを書く**

`test/spending_rollup_test.dart` を新規作成:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/daos.dart' show CategorySpendRow;
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/services/spending_rollup.dart';

CategoryEntity cat(int id, String name, {int? parentId, bool archived = false}) =>
    CategoryEntity(
      id: id,
      name: name,
      type: CategoryType.expense,
      icon: null,
      sortOrder: id,
      isArchived: archived,
      isSystem: false,
      parentId: parentId,
    );

CategorySpendRow row(int id, String name, int total,
        {int? parentId, bool archived = false}) =>
    CategorySpendRow(
      categoryId: id,
      categoryName: name,
      isArchived: archived,
      parentId: parentId,
      total: total,
    );

void main() {
  final cats = [
    cat(1, '食費'),
    cat(2, '外食', parentId: 1),
    cat(3, 'スーパー', parentId: 1),
    cat(4, '日用品'),
  ];

  test('内訳は親にロールアップされ、直接分はdirectTotalに残る', () {
    final groups = rollupSpending([
      row(1, '食費', 1200),
      row(2, '外食', 800, parentId: 1),
      row(3, 'スーパー', 300, parentId: 1),
      row(4, '日用品', 500),
    ], cats);
    final food = groups.firstWhere((g) => g.categoryId == 1);
    expect(food.total, 2300);
    expect(food.directTotal, 1200);
    expect(food.subs.map((s) => s.name).toList(), ['外食', 'スーパー']); // 降順
    expect(food.hasSubs, isTrue);
    // INVARIANT: 内訳和 + 直接分 == 親計
    expect(food.subs.fold<int>(0, (a, s) => a + s.total) + food.directTotal,
        food.total);
    // INVARIANT: 親計和 == 全行合計
    expect(groups.fold<int>(0, (a, g) => a + g.total), 2800);
  });

  test('直接計上のない親（内訳にだけ支出）もグループになり名前はcategoriesから引く', () {
    final groups = rollupSpending([row(2, '外食', 800, parentId: 1)], cats);
    final food = groups.single;
    expect(food.categoryId, 1);
    expect(food.name, '食費');
    expect(food.directTotal, 0);
    expect(food.total, 800);
  });

  test('グループは合計の降順', () {
    final groups = rollupSpending([
      row(4, '日用品', 5000),
      row(1, '食費', 100),
      row(2, '外食', 200, parentId: 1),
    ], cats);
    expect(groups.map((g) => g.categoryId).toList(), [4, 1]);
  });

  test('防御: parentIdがcategoriesに解決できない行は自分自身が親', () {
    final groups = rollupSpending([row(9, '謎', 100, parentId: 999)], cats);
    expect(groups.single.categoryId, 9);
    expect(groups.single.name, '謎');
    expect(groups.single.total, 100);
  });

  test('アーカイブフラグが親・内訳それぞれに伝播する', () {
    final archivedCats = [
      cat(1, '食費', archived: true),
      cat(2, '外食', parentId: 1, archived: true),
    ];
    final groups = rollupSpending(
        [row(2, '外食', 800, parentId: 1, archived: true)], archivedCats);
    expect(groups.single.isArchived, isTrue);
    expect(groups.single.subs.single.isArchived, isTrue);
  });
}
```

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/spending_rollup_test.dart`
Expected: コンパイルエラー（`spending_rollup.dart` 不在／`CategorySpendRow` に parentId なし）

- [ ] **Step 3: DAOのCategorySpendRowにparentIdを追加**

`lib/data/db/daos.dart` の `CategorySpendRow` を置換:

```dart
class CategorySpendRow {
  final int categoryId;
  final String categoryName;
  final bool isArchived;
  final int? parentId; // 非null=このカテゴリは内訳
  final int total;
  const CategorySpendRow({
    required this.categoryId,
    required this.categoryName,
    required this.isArchived,
    required this.parentId,
    required this.total,
  });
}
```

`watchSpendingByCategory` と `spendingByCategory` の両方で、addColumns に `categories.parentId` を足し、構築時に渡す（2箇所とも同じ変更）:

```dart
      ..addColumns([
        categories.id, categories.name, categories.isArchived,
        categories.parentId, amountSum,
      ])
```

```dart
            CategorySpendRow(
              categoryId: row.read(categories.id)!,
              categoryName: row.read(categories.name)!,
              isArchived: row.read(categories.isArchived)!,
              parentId: row.read(categories.parentId),
              total: row.read(amountSum) ?? 0,
            ),
```

- [ ] **Step 4: 純関数を実装**

`lib/domain/services/spending_rollup.dart` を新規作成:

```dart
import '../../data/db/daos.dart' show CategorySpendRow;
import '../entities.dart';

/// サマリ用: 内訳ごとの支出。
class SubSpend {
  final int categoryId;
  final String name;
  final bool isArchived;
  final int total;
  const SubSpend({
    required this.categoryId,
    required this.name,
    required this.isArchived,
    required this.total,
  });
}

/// サマリ用: 親カテゴリ単位のロールアップ結果。
class CategorySpendGroup {
  final int categoryId;
  final String name;
  final bool isArchived;
  final int total; // directTotal + 内訳合計
  final int directTotal; // 親カテゴリへの直接計上分（UIでは「（内訳なし）」）
  final List<SubSpend> subs; // 金額降順
  const CategorySpendGroup({
    required this.categoryId,
    required this.name,
    required this.isArchived,
    required this.total,
    required this.directTotal,
    required this.subs,
  });
  bool get hasSubs => subs.isNotEmpty;
}

/// カテゴリ別支出行（parentId付き）を親カテゴリ単位にまとめる。
/// - グループは合計の降順、subsも降順
/// - 直接計上のない親（内訳にだけ支出がある）もグループとして現れる。
///   その名前/isArchivedは categories から引く
/// - 防御: parentIdがcategoriesに解決できない行は自分自身を親として扱う
List<CategorySpendGroup> rollupSpending(
    List<CategorySpendRow> rows, List<CategoryEntity> categories) {
  final catById = {for (final c in categories) c.id: c};
  final direct = <int, int>{};
  final subRows = <int, List<CategorySpendRow>>{};
  for (final r in rows) {
    final p = r.parentId;
    if (p == null || !catById.containsKey(p)) {
      direct[r.categoryId] = (direct[r.categoryId] ?? 0) + r.total;
    } else {
      subRows.putIfAbsent(p, () => []).add(r);
    }
  }
  final selfRowById = {for (final r in rows) r.categoryId: r};
  final groups = <CategorySpendGroup>[];
  for (final id in {...direct.keys, ...subRows.keys}) {
    final subs = [
      for (final r in subRows[id] ?? const <CategorySpendRow>[])
        SubSpend(
          categoryId: r.categoryId,
          name: r.categoryName,
          isArchived: r.isArchived,
          total: r.total,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    final subTotal = subs.fold<int>(0, (a, s) => a + s.total);
    final d = direct[id] ?? 0;
    final cat = catById[id];
    final selfRow = selfRowById[id];
    groups.add(CategorySpendGroup(
      categoryId: id,
      name: cat?.name ?? selfRow?.categoryName ?? '不明',
      isArchived: cat?.isArchived ?? selfRow?.isArchived ?? false,
      total: d + subTotal,
      directTotal: d,
      subs: subs,
    ));
  }
  groups.sort((a, b) => b.total.compareTo(a.total));
  return groups;
}
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/spending_rollup_test.dart`
Expected: PASS（5件）

- [ ] **Step 6: DBレベルの不変条件テストを拡張**

`test/aggregation_test.dart` にimportを追加:

```dart
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';
import 'package:kakeibo_app/domain/services/spending_rollup.dart';
```

末尾にテストを追加:

```dart
  test('INVARIANT: rollup後も 親グループ計の和==月次支出合計・内訳和+直接分==親計',
      () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3), foodId); // 直接
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20), eatOutId); // 内訳
    final rows = await db.transactionDao.spendingByCategory(2026, 7);
    // 外食の行はparentId付きで返る
    expect(rows.firstWhere((r) => r.categoryId == eatOutId).parentId, foodId);

    final cats = await DriftCategoryRepository(db).watchAll().first;
    final groups = rollupSpending(rows, cats);
    final food = groups.firstWhere((g) => g.categoryId == foodId);
    expect(food.total, 2000);
    expect(food.directTotal, 1200);
    expect(food.subs.single.categoryId, eatOutId);
    expect(food.subs.single.total, 800);

    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(groups.fold<int>(0, (a, g) => a + g.total),
        totals[TxnType.expense]);
  });
```

- [ ] **Step 7: 全テスト＋analyze**

Run: `flutter analyze && flutter test`
Expected: 全緑

- [ ] **Step 8: Commit**

```bash
git add lib/data/db/daos.dart lib/domain/services/spending_rollup.dart test/spending_rollup_test.dart test/aggregation_test.dart
git commit -m "feat(aggregation): roll breakdown spending up to parent categories"
```

---

### Task 5: バックアップ formatVersion 2＋CSV内訳列

**Files:**
- Modify: `lib/data/backup/backup_data.dart`（BackupCategory.parentId）
- Modify: `lib/data/backup/backup_codec.dart`（v2・階層検証・v1→v2）
- Modify: `lib/data/backup/backup_service.dart`（export parentId・FK defer）
- Modify: `lib/data/backup/csv_exporter.dart`（内訳列）
- Test: `test/backup/backup_codec_test.dart`・`test/backup/backup_restore_test.dart`・`test/backup/csv_exporter_test.dart`

**Interfaces:**
- Consumes: `CategoryRow.parentId`
- Produces:
  - `BackupCategory.parentId`（int?・**required** named — コーデック境界は明示を強制）
  - `BackupCodec.formatVersion == 2`
  - CSVヘッダ: `日付,種別,金額,カテゴリ,内訳,支払方法,メモ`（内訳取引はカテゴリ=親名・内訳=自名）

- [ ] **Step 1: 失敗するコーデックテストを書く**

**既存テストの更新（2件）**:
1. `test/backup/backup_codec_test.dart:41` の `expect(root['formatVersion'], 1);` を `expect(root['formatVersion'], 2);` に更新（samplePayloadは `BackupCodec.formatVersion` を参照するためbump後のencodeは2を出力する）
2. 「アプリより新しい版は拒否」テスト（同:92）は `formatVersion = 99` を使っており**変更不要**（99 > 2 のまま newerThanApp が立つ）

**フィクスチャ**: 既存のJSON構築ヘルパ `mutate` は `group('decode')` 内ローカルのため新設groupから参照できない。**`main()` 直下（group('decode')の外）へ移動して共用**し、以下のヘルパを追加する（samplePayloadの実構造 = cats[0]=id1食費expense・cats[1]=id19未分類expense(isSystem)・cats[2]=id20未分類income(isSystem) が前提）:

```dart
  String mutate(void Function(Map<String, dynamic> root) f) {
    final root =
        jsonDecode(codec.encode(samplePayload())) as Map<String, dynamic>;
    f(root);
    return jsonEncode(root);
  }

  // v1相当: formatVersionを1に落としparentIdキーを除去
  // （キー除去により _migrateV1toV2 の putIfAbsent が実際に補完することを検証できる）
  String validV1Json() => mutate((r) {
        r['formatVersion'] = 1;
        for (final c in r['categories'] as List) {
          (c as Map).remove('parentId');
        }
      });
  String jsonWithDanglingParent() =>
      mutate((r) => ((r['categories'] as List)[0] as Map)['parentId'] = 99);
  String jsonWithSelfParent() =>
      mutate((r) => ((r['categories'] as List)[0] as Map)['parentId'] = 1);
  String jsonWithGrandchild() => mutate((r) {
        final cats = r['categories'] as List;
        cats.add({'id': 2, 'name': '外食', 'type': 'expense', 'icon': null,
          'sortOrder': 1, 'isArchived': false, 'isSystem': false, 'parentId': 1});
        cats.add({'id': 3, 'name': 'ラーメン', 'type': 'expense', 'icon': null,
          'sortOrder': 0, 'isArchived': false, 'isSystem': false, 'parentId': 2});
      });
  String jsonWithTypeMismatch() => mutate((r) {
        (r['categories'] as List).add({'id': 5, 'name': 'x', 'type': 'income',
          'icon': null, 'sortOrder': 9, 'isArchived': false, 'isSystem': false,
          'parentId': 1}); // 親id=1はexpense
      });
  String jsonWithSystemChild() =>
      mutate((r) => ((r['categories'] as List)[1] as Map)['parentId'] = 1); // cats[1]=未分類(isSystem)
```

新設groupを追加（フィクスチャは**関数呼び出し**で使う）:

```dart
  group('formatVersion 2（内訳）', () {
    test('v1 JSON（parentIdなし）はmigrateされ全カテゴリparentId=null', () {
      final payload = codec.decode(validV1Json());
      expect(payload.formatVersion, 2); // decodeはマイグレーション後に現行版を返す
      expect(payload.categories.every((c) => c.parentId == null), isTrue);
    });

    test('v2: parentIdが同梱カテゴリに解決できないと拒否', () {
      expect(() => codec.decode(jsonWithDanglingParent()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: 3段（内訳の下の内訳）は拒否', () {
      expect(() => codec.decode(jsonWithGrandchild()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: 自己参照は拒否', () {
      expect(() => codec.decode(jsonWithSelfParent()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: typeが親と不一致は拒否', () {
      expect(() => codec.decode(jsonWithTypeMismatch()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: システムカテゴリのparentIdは拒否', () {
      expect(() => codec.decode(jsonWithSystemChild()),
          throwsA(isA<BackupValidationError>()));
    });

    test('encode→decodeのroundtripでparentIdが保存される', () {
      final json = mutate((r) {
        final cats = r['categories'] as List;
        cats.add({'id': 2, 'name': '外食', 'type': 'expense', 'icon': null,
          'sortOrder': 0, 'isArchived': false, 'isSystem': false, 'parentId': 1});
      });
      final payload = codec.decode(json);
      expect(payload.categories.firstWhere((c) => c.id == 2).parentId, 1);
      final reencoded = codec.decode(codec.encode(payload));
      expect(reencoded.categories.firstWhere((c) => c.id == 2).parentId, 1);
    });
  });
```

（`codec` / `samplePayload` の実際の変数名・関数名は既存ファイルの宣言に合わせる）

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/backup/backup_codec_test.dart`
Expected: コンパイルエラーまたはFAIL

- [ ] **Step 3: BackupCategoryとコーデックを実装**

`lib/data/backup/backup_data.dart` の `BackupCategory` を置換:

```dart
/// 行と1:1のバックアップ用カテゴリ。
class BackupCategory {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;
  final int? parentId; // 非null=内訳（formatVersion 2で追加）
  const BackupCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    required this.parentId,
  });
}
```

`grep -rn "BackupCategory(" lib test` で全構築箇所に `parentId:` を追加（既存テストは `parentId: null`）。

`lib/data/backup/backup_codec.dart`:

```dart
  /// バックアップ形式のバージョン。DBのschemaVersionとは独立に管理する。
  /// v2: categories[].parentId（内訳）を追加。
  static const int formatVersion = 2;
```

encodeのカテゴリmapに追加:

```dart
            'isSystem': c.isSystem,
            'parentId': c.parentId,
```

decodeのBackupCategory構築に追加:

```dart
        isSystem: req<bool>(raw, 'isSystem', ctx),
        parentId: opt<int>(raw, 'parentId', ctx),
```

categoriesループの**後**（システム未分類チェックの後）に階層検証を追加:

```dart
    // --- 階層検証（v2）: 2段まで・type一致・システムは親のみ ---
    final catById = {for (final c in categories) c.id: c};
    for (final c in categories) {
      final p = c.parentId;
      if (p == null) continue;
      if (c.isSystem) {
        throw BackupValidationError('システムカテゴリ ${c.id} に parentId は指定できません');
      }
      if (p == c.id) {
        throw BackupValidationError('カテゴリ ${c.id} が自分自身を親にしています');
      }
      final parent = catById[p];
      if (parent == null) {
        throw BackupValidationError(
            'カテゴリ ${c.id} の parentId $p が同梱カテゴリに解決できません');
      }
      if (parent.parentId != null) {
        throw BackupValidationError(
            'カテゴリ ${c.id}: 内訳の下に内訳は置けません（階層は2段まで）');
      }
      if (parent.type != c.type) {
        throw BackupValidationError(
            'カテゴリ ${c.id}: type が親 ${parent.id} と一致しません');
      }
    }
```

`_migrate` を更新（Dart 3のswitch文は暗黙break）:

```dart
  /// 古いバックアップを現行形式へ順送りに変換する。
  Map<String, dynamic> _migrate(Map<String, dynamic> root, {required int from}) {
    var v = from;
    var m = root;
    while (v < formatVersion) {
      switch (v) {
        case 1:
          m = _migrateV1toV2(m);
        default:
          throw BackupVersionError('formatVersion $v からの移行手順がありません');
      }
      v++;
    }
    return m;
  }

  /// v1→v2: categories に parentId を補完（v1は全て親＝null）。
  Map<String, dynamic> _migrateV1toV2(Map<String, dynamic> root) {
    final cats = root['categories'];
    if (cats is List) {
      for (final c in cats) {
        if (c is Map<String, dynamic>) c.putIfAbsent('parentId', () => null);
      }
    }
    return root;
  }
```

（`// ignore: dead_code` コメントは不要になるので削除）

- [ ] **Step 4: サービスとCSVを実装**

`lib/data/backup/backup_service.dart`:

`exportPayload` のBackupCategory構築に追加:

```dart
            isSystem: c.isSystem,
            parentId: c.parentId,
```

`applyRestore` のトランザクション先頭にFK deferを追加（**重要**: SQLiteの即時FK検査は各文の終了時点で行われるため、全行DELETE（単一文）は自己参照FKでも落ちない。deferが必要なのは**挿入側** — driftのbatchは行ごとに別文でINSERTするため、内訳が親より先に挿入されると即時FK検査で落ちる）:

```dart
  Future<void> applyRestore(BackupPayload payload) async {
    await _db.transaction(() async {
      // 自己参照FK（parentId）は行の削除/挿入順に依存するため、
      // このトランザクション内はFK検査をコミット時まで遅延する。
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');

      // FK RESTRICT を回避する順序: 取引 → カテゴリ の順に削除
      ...（以降は既存のまま。カテゴリのbatch insertに parentId: Value(c.parentId) を追加）
```

batch insertのカテゴリに追加:

```dart
              isSystem: Value(c.isSystem),
              parentId: Value(c.parentId),
```

`lib/data/backup/csv_exporter.dart` を置換:

```dart
String buildTransactionsCsv(BackupPayload payload) {
  final byId = {for (final c in payload.categories) c.id: c};
  final sb = StringBuffer('\uFEFF'); // BOMは必ずエスケープで書く（P2の学び）
  sb.write('日付,種別,金額,カテゴリ,内訳,支払方法,メモ\r\n');
  for (final t in payload.transactions) {
    final cat = byId[t.categoryId];
    final parent = cat?.parentId == null ? null : byId[cat!.parentId];
    final fields = [
      t.date.toIso(),
      t.type == TxnType.expense ? '支出' : '収入',
      t.amount.toString(),
      parent?.name ?? cat?.name ?? '',
      parent == null ? '' : (cat?.name ?? ''),
      _paymentLabel(t.paymentMethod),
      t.memo ?? '',
    ];
    sb.write(fields.map(_escape).join(','));
    sb.write('\r\n');
  }
  return sb.toString();
}
```

- [ ] **Step 5: 復元の順序テストを書く**

`test/backup/backup_restore_test.dart` に追加。**restoreFromJsonは使わない**: このファイルの既存セットアップは storeなしの `BackupService(db)` であり restoreFromJson は StateError（backup_service.dart:75-78）、かつ取引0件payloadは store以前に EmptyBackupError（同:70-73）で落ちる。既存テストと同じく `applyRestore` 直呼び＋`codec.decode(codec.encode(payload))` で門番も通す:

```dart
  test('restore: 内訳のidが親より小さくても復元できる（FK defer）', () async {
    const codec = BackupCodec();
    final payload = BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3),
      categories: const [
        BackupCategory(
            id: 2, name: '外食(旧)', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false,
            parentId: 50), // 子が親より小さいid → 挿入順が子先行になり即時FKなら落ちる
        BackupCategory(
            id: 50, name: '食費(旧)', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false,
            parentId: null),
        BackupCategory(
            id: 101, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 1, isArchived: false, isSystem: true,
            parentId: null),
        BackupCategory(
            id: 102, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 2, isArchived: false, isSystem: true,
            parentId: null),
      ],
      transactions: const [],
    );
    await service.applyRestore(codec.decode(codec.encode(payload)));
    final cats = await db.categoryDao.allCategories();
    expect(cats.map((c) => c.id).toSet(), {2, 50, 101, 102});
    expect(cats.firstWhere((c) => c.id == 2).parentId, 50);
  });

  test('restore: 内訳入りのシード済みDBを上書き復元できる（全行DELETEがFKで落ちない）',
      () async {
    // シード済みDB（外食が食費の内訳）に対し、既存の最小payloadを復元して成功すること
    await service.applyRestore(minimalPayload());
    final cats = await db.categoryDao.allCategories();
    expect(cats, isNotEmpty);
  });
```

（`service` / `minimalPayload` の実際の名前・構造は既存ファイルの宣言に合わせる。2本目の期待値は minimalPayload のカテゴリ数に合わせて具体化する）

- [ ] **Step 6: CSVテストを更新**

`test/backup/csv_exporter_test.dart`:
- ヘッダ期待値を `日付,種別,金額,カテゴリ,内訳,支払方法,メモ` に更新
- **既存テストのデータ行期待値も全て更新が必要**（列が1つ増えるため、カテゴリ列の直後にカンマ1個＝空の内訳列が入る。例: `2026-07-03,支出,1200,食費,,現金,`）
- 内訳取引のケースを1本追加: 内訳カテゴリ（parentId付き）の取引 → カテゴリ列=親名・内訳列=自名になること
- このファイルは `BackupCategory` を payload ヘルパ経由で作っているか直接構築かを確認し、直接構築があれば `parentId:` を追加

- [ ] **Step 7: 全テスト＋analyze**

Run: `flutter analyze && flutter test`
Expected: 全緑。`grep -rn "BackupCategory(" lib test` で全構築箇所を洗い出し、`parentId:` 未指定（requiredのためコンパイルエラーになる）を全て追加してから回すこと

- [ ] **Step 8: Commit**

```bash
git add lib/data/backup test/backup
git commit -m "feat(backup): formatVersion 2 with breakdown parentId, deferred FK restore, CSV column"
```

---

### Task 6: 万表記 manYen（compactYen置換）＋カレンダーセル

**Files:**
- Modify: `lib/core/format.dart`
- Modify: `lib/features/calendar/presentation/calendar_screen.dart:49-62`（markerBuilder）
- Test: `test/core/format_test.dart`・`test/ui/calendar_screen_test.dart`

**Interfaces:**
- Produces: `String manYen(int yen)` — `compactYen` は**削除**（呼び出し元はcalendar_screenのみ）

- [ ] **Step 1: 失敗するテストを書く**

`test/core/format_test.dart` の `compactYen` グループを置換:

```dart
  test('manYen: セル万表記（モック確定・四捨五入）', () {
    expect(manYen(0), '');
    expect(manYen(-100), '');
    expect(manYen(980), '980'); // <1000は生数字・¥なし
    expect(manYen(999), '999');
    expect(manYen(1000), '0.1万');
    expect(manYen(3449), '0.3万'); // 四捨五入（モックのMath.round準拠）
    expect(manYen(3500), '0.4万');
    expect(manYen(9999), '1万'); // 四捨五入で1.0万→.0トリム
    expect(manYen(10000), '1万');
    expect(manYen(12345), '1.2万');
    expect(manYen(285000), '28.5万');
    expect(manYen(999949), '99.9万');
    expect(manYen(999950), '100万'); // 繰り上がり境界
    expect(manYen(1000000), '100万'); // ≥100万は整数万
    expect(manYen(1235000), '124万'); // 整数万も四捨五入
    expect(manYen(9999999), '1000万'); // 入力上限相当
  });
```

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/core/format_test.dart`
Expected: コンパイルエラー（manYen未定義）

- [ ] **Step 3: manYenを実装（compactYen削除）**

`lib/core/format.dart` の `compactYen` を置換:

```dart
/// カレンダーセル用の万表記（モック確定: 980 / 0.3万 / 1.2万 / 28.5万 / 124万）。
/// <1000: 生数字（¥なし）／<100万: 万単位・小数1桁に四捨五入（.0はトリム）／
/// ≥100万: 整数万に四捨五入。0以下は空文字（セル非表示）。
String manYen(int yen) {
  if (yen <= 0) return '';
  if (yen < 1000) return '$yen';
  if (yen < 1000000) {
    final tenths = (yen / 1000).round(); // 0.1万（千円）単位に四捨五入
    final s = (tenths / 10).toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}万';
  }
  return '${(yen / 10000).round()}万';
}
```

`_oneDecimal` は compactYen 専用だったので **compactYen と一緒に削除**する（`grep -n "_oneDecimal" lib` で他に使用がないこと確認）。

- [ ] **Step 4: カレンダーセルを差し替える**

`lib/features/calendar/presentation/calendar_screen.dart` の markerBuilder 内:

```dart
                return Positioned(
                  bottom: 2,
                  child: Text(
                    manYen(events.first),
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.error),
                  ),
                );
```

（色はこの時点では `colorScheme.error` のまま。Task 7 で支出紅＋tabular figuresに差し替える）

- [ ] **Step 5: カレンダーUIテストの期待値を更新**

`test/ui/calendar_screen_test.dart` の「日セルに支出のみの略記マーカーが出る」:

```dart
    await seed(c, 12345, day: 20);
    await tester.pumpAndSettle();
    expect(find.text('1.2万'), findsOneWidget);
```

- [ ] **Step 6: テスト＋analyze**

Run: `flutter analyze && flutter test test/core/format_test.dart test/ui/calendar_screen_test.dart`
Expected: PASS（`compactYen` 参照が残っているとanalyzeで検出される→全て置換済みであること）

- [ ] **Step 7: Commit**

```bash
git add lib/core/format.dart lib/features/calendar/presentation/calendar_screen.dart test/core/format_test.dart test/ui/calendar_screen_test.dart
git commit -m "feat(format): man-unit cell notation replacing compactYen"
```

---

### Task 7: デザイントークンのテーマ移植

**Files:**
- Create: `lib/app/theme.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/features/entry/presentation/receipt_review_panel.dart:11-16`（confidenceTint）
- Modify: `lib/features/calendar/presentation/day_transaction_list.dart:77-84`（紅/藍・tabular）
- Modify: `lib/features/calendar/presentation/calendar_screen.dart`（セル色・月ヘッダtabular）
- Modify: `lib/features/entry/presentation/entry_screen.dart:93-96`（金額tabular）
- Test: `test/ui/theme_test.dart`（新規）

**Interfaces:**
- Produces（`lib/app/theme.dart`）:
  - トークン定数: `kPaper kCard kInk kMuted kLine kPrimary kPrimarySoft kExpense kExpenseSoft kIncome kIncomeSoft kConfidenceHighSoft kConfidenceMedium kConfidenceMediumSoft`
  - `const kSubScale = <Color>[...]`（5色）
  - `const kTabularFigures = <FontFeature>[FontFeature.tabularFigures()]`
  - `class KakeiboColors extends ThemeExtension<KakeiboColors>`（expense/expenseSoft/income/incomeSoft、`KakeiboColors.standard`）
  - `extension KakeiboColorsX on BuildContext { KakeiboColors get kakeiboColors; }`
  - `ThemeData buildKakeiboTheme()`

- [ ] **Step 1: 失敗するテーマテストを書く**

`test/ui/theme_test.dart` を新規作成:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/theme.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('生成りの背景・深緑primary・拡張色（紅/藍）が適用される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, kPaper);
    expect(theme.colorScheme.primary, kPrimary);
    expect(theme.colorScheme.error, kExpense);
    final ext = theme.extension<KakeiboColors>();
    expect(ext, isNotNull);
    expect(ext!.expense, kExpense);
    expect(ext.income, kIncome);
  });
}
```

**注意**: `pumpApp` はhome指定なしのとき `KakeiboApp` を使う（テーマが乗る）。home指定の単画面テストは `MaterialApp(home:)` でテーマなし → このテストではhomeを指定しない。

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/ui/theme_test.dart`
Expected: コンパイルエラー（theme.dart不在）

- [ ] **Step 3: theme.dartを実装**

`lib/app/theme.dart` を新規作成:

```dart
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

// デザイントークン（docs/phase45-handoff.md「デザイントークン」の正）
const kPaper = Color(0xFFF6F5F0);
const kCard = Color(0xFFFFFFFF);
const kInk = Color(0xFF20241F);
const kMuted = Color(0xFF6F756A);
const kLine = Color(0xFFE3E2D8);
const kPrimary = Color(0xFF1E6B5A);
const kPrimarySoft = Color(0xFFE4EFE9);
const kExpense = Color(0xFFB8433A);
const kExpenseSoft = Color(0xFFF7E9E7);
const kIncome = Color(0xFF2E6E93);
const kIncomeSoft = Color(0xFFE7EFF5);
const kConfidenceHighSoft = Color(0xFFE2F0E6);
const kConfidenceMedium = Color(0xFFA8741A);
const kConfidenceMediumSoft = Color(0xFFF6EDDC);

/// サマリ積み上げバーの深緑濃淡（5色循環）
const kSubScale = <Color>[
  Color(0xFF1E6B5A),
  Color(0xFF4E937E),
  Color(0xFF7BB3A0),
  Color(0xFFA8CFC0),
  Color(0xFFCFE4DB),
];

/// 金額表示は等幅数字（桁が揃う）
const kTabularFigures = <FontFeature>[FontFeature.tabularFigures()];

/// 支出/収入などアプリ固有のセマンティック色。
@immutable
class KakeiboColors extends ThemeExtension<KakeiboColors> {
  final Color expense;
  final Color expenseSoft;
  final Color income;
  final Color incomeSoft;
  const KakeiboColors({
    required this.expense,
    required this.expenseSoft,
    required this.income,
    required this.incomeSoft,
  });

  static const standard = KakeiboColors(
    expense: kExpense,
    expenseSoft: kExpenseSoft,
    income: kIncome,
    incomeSoft: kIncomeSoft,
  );

  @override
  KakeiboColors copyWith({
    Color? expense,
    Color? expenseSoft,
    Color? income,
    Color? incomeSoft,
  }) =>
      KakeiboColors(
        expense: expense ?? this.expense,
        expenseSoft: expenseSoft ?? this.expenseSoft,
        income: income ?? this.income,
        incomeSoft: incomeSoft ?? this.incomeSoft,
      );

  @override
  KakeiboColors lerp(KakeiboColors? other, double t) {
    if (other == null) return this;
    return KakeiboColors(
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
    );
  }
}

extension KakeiboColorsX on BuildContext {
  KakeiboColors get kakeiboColors => Theme.of(this).extension<KakeiboColors>()!;
}

ThemeData buildKakeiboTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
    primary: kPrimary,
    primaryContainer: kPrimarySoft,
    onPrimaryContainer: kInk,
    surface: kCard,
    onSurface: kInk,
    onSurfaceVariant: kMuted,
    outline: kLine,
    outlineVariant: kLine,
    error: kExpense,
    errorContainer: kExpenseSoft,
    onErrorContainer: kInk,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kPaper,
    dividerColor: kLine,
    appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk),
    cardTheme: const CardThemeData(color: kCard),
    extensions: const [KakeiboColors.standard],
  );
}
```

（`cardTheme:` の型はこのFlutterでは `CardThemeData` が正。`CardTheme` に読み替えてはいけない）

`lib/app/app.dart` を置換:

```dart
import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'theme.dart';

class KakeiboApp extends StatelessWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '家計簿',
        theme: buildKakeiboTheme(),
        home: const HomeShell(),
      );
}
```

- [ ] **Step 4: confidenceTintを新トークンに差し替える**

`lib/features/entry/presentation/receipt_review_panel.dart` の `confidenceTint` を置換（importに `../../../app/theme.dart` を追加）:

```dart
/// 確信度tier→ハイライト色（spec §7.5・モック確定soft色）。nullは無色（手修正済み等）。
Color? confidenceTint(ExtractionConfidence? c) => switch (c) {
      null => null,
      ExtractionConfidence.high => kConfidenceHighSoft,
      ExtractionConfidence.medium => kConfidenceMediumSoft,
      ExtractionConfidence.low => kExpenseSoft,
    };
```

- [ ] **Step 5: 支出紅/収入藍とtabular figuresを適用**

`lib/features/calendar/presentation/day_transaction_list.dart` のtrailing（importに `../../../app/theme.dart` 追加）:

```dart
            trailing: Text(
              signedYen(tx.type, tx.amountYen),
              style: TextStyle(
                color: tx.type == TxnType.expense
                    ? context.kakeiboColors.expense
                    : context.kakeiboColors.income,
                fontWeight: FontWeight.w600,
                fontFeatures: kTabularFigures,
              ),
            ),
```

`lib/features/calendar/presentation/calendar_screen.dart` markerBuilder（importに `../../../app/theme.dart` 追加）:

```dart
                  child: Text(
                    manYen(events.first),
                    style: TextStyle(
                        fontSize: 10,
                        fontFeatures: kTabularFigures,
                        color: context.kakeiboColors.expense),
                  ),
```

同ファイル `_MonthHeader` の合計行:

```dart
                Text(
                  '支出 ${formatYen(summary.expense)}　収入 ${formatYen(summary.income)}　差引 $netLabel',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFeatures: kTabularFigures),
                ),
```

`lib/features/entry/presentation/entry_screen.dart` の金額表示（importに `../../../app/theme.dart` 追加）:

```dart
                child: Text(
                  state.amountYen == 0 ? '¥0' : formatYen(state.amountYen),
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontFeatures: kTabularFigures),
                ),
```

- [ ] **Step 6: テスト＋analyze**

Run: `flutter analyze && flutter test`
Expected: 全緑。色を直接assertしている既存テストがあれば新トークンに合わせる（P4のUIテストはKey/文字列ベースなので原則影響なし）

- [ ] **Step 7: Commit**

```bash
git add lib/app/theme.dart lib/app/app.dart lib/features/entry/presentation/receipt_review_panel.dart lib/features/entry/presentation/entry_screen.dart lib/features/calendar/presentation/day_transaction_list.dart lib/features/calendar/presentation/calendar_screen.dart test/ui/theme_test.dart
git commit -m "feat(theme): port mock design tokens (paper/ink/crimson/indigo, tabular figures)"
```

---

### Task 8: 入力providerの階層対応（親のみグリッド＋内訳provider）

**Files:**
- Modify: `lib/features/entry/application/entry_category_providers.dart`
- Test: `test/providers/entry_category_providers_test.dart`（新規。既存に同providerのテストがあればそちらへ追記して重複させない）

**Interfaces:**
- Consumes: `CategoryEntity.parentId`・`allCategoriesProvider`（階層整列済み）
- Produces:
  - `entryCategoriesProvider(TxnType)`: **親のみ**（parentId==null・非システム・非アーカイブ）。「最近使った順」は自身＋内訳の利用実績のmaxで判定
  - `entrySubcategoriesProvider(int parentId)`: `AsyncValue<List<CategoryEntity>>` — アクティブな内訳をsortOrder順

- [ ] **Step 1: 失敗するproviderテストを書く**

`test/providers/entry_category_providers_test.dart` を新規作成:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_category_providers.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
  });

  Future<int> idOf(String name) async {
    final cats = await waitForData(c, allCategoriesProvider);
    return cats.firstWhere((x) => x.name == name).id;
  }

  Future<void> spend(int catId, CivilDate date) =>
      c.read(transactionRepositoryProvider).add(TransactionEntity(
          type: TxnType.expense,
          amountYen: 100,
          date: date,
          categoryId: catId,
          source: TxnSource.manual));

  test('グリッドは親のみ（内訳の外食は出ない・食費は出る）', () async {
    final grid =
        await waitForData(c, entryCategoriesProvider(TxnType.expense));
    expect(grid.any((x) => x.name == '食費'), isTrue);
    expect(grid.any((x) => x.name == '外食'), isFalse);
    expect(grid.every((x) => x.parentId == null), isTrue);
  });

  test('内訳の利用実績は親の「最近使った」に効く', () async {
    final eatOut = await idOf('外食');
    final daily = await idOf('日用品');
    await spend(daily, const CivilDate(2026, 7, 1));
    await spend(eatOut, const CivilDate(2026, 7, 10)); // 内訳の方が新しい
    // autoDispose対策: 購読を保持し、watchエッジ経由で categoryLastUsedProvider を生かす。
    // この購読がないと waitForData の購読クローズ後に lastUsed が破棄されうる。
    final sub = c.listen(entryCategoriesProvider(TxnType.expense), (_, __) {});
    addTearDown(sub.close);
    final lastUsed = await waitForData(c, categoryLastUsedProvider);
    expect(lastUsed[eatOut], const CivilDate(2026, 7, 10)); // 前提確認（空mapでの空振り防止）
    final grid = c.read(entryCategoriesProvider(TxnType.expense)).value!;
    final foodIdx = grid.indexWhere((x) => x.name == '食費');
    final dailyIdx = grid.indexWhere((x) => x.name == '日用品');
    expect(foodIdx, lessThan(dailyIdx)); // 食費（外食経由7/10）が日用品（7/1）より先
  });

  test('entrySubcategoriesProvider: 親の内訳をsortOrder順・アーカイブ除外', () async {
    final food = await idOf('食費');
    final repo = c.read(categoryRepositoryProvider);
    final superId = await repo.addCategory(
        name: 'スーパー', type: CategoryType.expense, parentId: food);
    await repo.setArchived(superId, true);
    await pumpEventQueue(); // drift streamの再emitを待つ（repository_watch_testと同型）
    final subs = c.read(entrySubcategoriesProvider(food)).value!;
    expect(subs.map((s) => s.name).toList(), ['外食']); // アーカイブは出ない
  });
}
```

**注意**: `entryCategoriesProvider` は `Provider<AsyncValue>` だが、`waitForData` は任意の `ProviderListenable<AsyncValue<T>>` を受けるため**そのまま使える**（内部実装が `listen(fireImmediately: true)` で `AsyncData` を待つ方式）。`selectAsync` は Future/Stream系provider専用なので使えない。`entrySubcategoriesProvider` の `.value!` が非nullなのは `allCategoriesProvider` が非autoDisposeで `idOf` 後もデータ保持されるため。

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/providers/entry_category_providers_test.dart`
Expected: コンパイルエラー（entrySubcategoriesProvider未定義）またはFAIL（外食がグリッドに出る／食費が日用品より後）

- [ ] **Step 3: providerを実装**

`lib/features/entry/application/entry_category_providers.dart` の `entryCategoriesProvider` を置換＋追加:

```dart
/// 高速入力のカテゴリグリッド: 親カテゴリのみ・最近使った順 → sortOrder順（spec §5.2）。
/// 内訳の利用実績は親の「最近使った」に取り込む（自身と内訳のmax）。
final entryCategoriesProvider = Provider.autoDispose
    .family<AsyncValue<List<CategoryEntity>>, TxnType>((ref, type) {
  final lastUsed =
      ref.watch(categoryLastUsedProvider).valueOrNull ?? const <int, CivilDate>{};
  return ref.watch(allCategoriesProvider).whenData((all) {
    final wanted = categoryTypeOf(type);
    final childToParent = {
      for (final c in all)
        if (c.parentId != null) c.id: c.parentId!,
    };
    final effectiveLastUsed = <int, CivilDate>{};
    lastUsed.forEach((id, date) {
      final target = childToParent[id] ?? id;
      final cur = effectiveLastUsed[target];
      if (cur == null || date.compareTo(cur) > 0) {
        effectiveLastUsed[target] = date;
      }
    });
    final list = all
        .where((c) =>
            c.parentId == null &&
            !c.isArchived &&
            !c.isSystem &&
            c.type == wanted)
        .toList();
    list.sort((a, b) {
      final ua = effectiveLastUsed[a.id];
      final ub = effectiveLastUsed[b.id];
      if (ua != null || ub != null) {
        if (ua == null) return 1;
        if (ub == null) return -1;
        final cmp = ub.compareTo(ua);
        if (cmp != 0) return cmp;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  });
});

/// 指定親のアクティブな内訳（sortOrder順）。チップ列とグリッドの▾判定に使う。
final entrySubcategoriesProvider = Provider.autoDispose
    .family<AsyncValue<List<CategoryEntity>>, int>((ref, parentId) =>
        ref.watch(allCategoriesProvider).whenData((all) => all
            .where((c) => c.parentId == parentId && !c.isArchived)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))));
```

- [ ] **Step 4: テスト＋analyze**

Run: `flutter analyze && flutter test test/providers/`
Expected: PASS

- [ ] **Step 5: 全テスト（グリッドから外食が消えた影響の確認）**

Run: `flutter test`
Expected: 全緑（entry系UIテストが外食タイルに依存していないことは確認済み。food選択系は親タイルのまま動く）

- [ ] **Step 6: Commit**

```bash
git add lib/features/entry/application/entry_category_providers.dart test/providers/entry_category_providers_test.dart
git commit -m "feat(entry): parent-only grid provider with breakdown-aware recency and subcategory provider"
```

---

### Task 9: EntryFormController（チップ開閉の状態機械）

**Files:**
- Modify: `lib/features/entry/application/entry_form_controller.dart`
- Test: `test/providers/entry_form_controller_test.dart`（追記）

**Interfaces:**
- Consumes: なし（純状態機械。カテゴリツリーの知識はUI側が渡す）
- Produces:
  - `EntryFormState.expandedParentId`（int?・チップ列を開いている親。copyWithは_unset方式）
  - `EntryFormController.tapCategory({required int categoryId, required bool hasSubs, required bool isSameGroup})`
  - `EntryFormController.toggleSubcategory(int subId)` — 選択中チップ再タップで親に戻す
  - `setType` は categoryId と expandedParentId の両方をクリア
  - 既存 `selectCategory` は互換のため残す

- [ ] **Step 1: 失敗するコントローラテストを書く**

`test/providers/entry_form_controller_test.dart` に追記。**既存ファイルのヘルパは関数形式**（例: `ctrl()` / `st()`。実名は既存ファイルの宣言に合わせて読み替える）:

```dart
  group('内訳チップの状態機械', () {
    test('内訳ありカテゴリのタップ: 選択＋チップ列が開く', () {
      ctrl().startCreate(const CivilDate(2026, 7, 15));
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      expect(st().categoryId, 1);
      expect(st().expandedParentId, 1);
    });

    test('内訳なしカテゴリのタップ: 選択のみ・チップ列は閉じる', () {
      ctrl().startCreate(const CivilDate(2026, 7, 15));
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().tapCategory(categoryId: 4, hasSubs: false, isSameGroup: false);
      expect(st().categoryId, 4);
      expect(st().expandedParentId, isNull);
    });

    test('同じ親の再タップ: チップ列の開閉のみ・選択は維持', () {
      ctrl().startCreate(const CivilDate(2026, 7, 15));
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().toggleSubcategory(2); // 内訳を選択
      expect(st().categoryId, 2);
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: true); // 格納
      expect(st().expandedParentId, isNull);
      expect(st().categoryId, 2); // 選択は維持（モック確定）
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: true); // 再展開
      expect(st().expandedParentId, 1);
      expect(st().categoryId, 2); // 再展開でも選択維持（実装中判断）
    });

    test('チップ再タップで親に戻る', () {
      ctrl().startCreate(const CivilDate(2026, 7, 15));
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().toggleSubcategory(2);
      expect(st().categoryId, 2);
      ctrl().toggleSubcategory(2); // 再タップ
      expect(st().categoryId, 1); // 親に計上する状態へ
    });

    test('setTypeで選択とチップ列が両方クリアされる', () {
      ctrl().startCreate(const CivilDate(2026, 7, 15));
      ctrl().tapCategory(categoryId: 1, hasSubs: true, isSameGroup: false);
      ctrl().setType(TxnType.income);
      expect(st().categoryId, isNull);
      expect(st().expandedParentId, isNull);
    });

    test('saveAndContinue後はチップ列が閉じる', () async {
      // 既存のsaveAndContinueテストと同じ実DBセットアップに合わせる。
      // カテゴリidは実DBから取得（食費=内訳ありをタップ）
      final all = await db.categoryDao.allCategories();
      final foodId = all.firstWhere((x) => x.name == '食費').id;
      ctrl().startCreate(const CivilDate(2026, 7, 15));
      ctrl().tapDigit(5);
      ctrl().tapCategory(categoryId: foodId, hasSubs: true, isSameGroup: false);
      expect(st().expandedParentId, foodId);
      await ctrl().saveAndContinue();
      expect(st().expandedParentId, isNull); // 再初期化でチップ列も閉じる
      expect(st().categoryId, isNull);
    });
  });
```

（`db` の入手方法・container構築は既存saveAndContinueテストのsetUpに合わせる。純状態機械テスト5本はDB不要なのでid=1,2,4の即値でよい）

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/providers/entry_form_controller_test.dart`
Expected: コンパイルエラー（tapCategory未定義）

- [ ] **Step 3: 状態とコントローラを実装**

`lib/features/entry/application/entry_form_controller.dart`:

`EntryFormState` にフィールド追加（`memoExpanded` の下）:

```dart
  /// 内訳チップ列を開いている親カテゴリ（null=閉）。選択とは独立。
  final int? expandedParentId;
```

コンストラクタに `this.expandedParentId,` を追加。

`copyWith` にパラメータ `Object? expandedParentId = _unset,` を追加し、本体に:

```dart
        expandedParentId: identical(expandedParentId, _unset)
            ? this.expandedParentId
            : expandedParentId as int?,
```

`setType` を置換:

```dart
  void setType(TxnType type) {
    // 編集では型不変: updateFieldsはtypeを書かないため、許すと型/カテゴリdesyncが
    // 永続化する（spec §4.3の不変条件を破る）
    if (_s.mode == EntryMode.edit) return;
    if (type == _s.type) return;
    // 候補再フィルタ＋選択クリア＋チップ列も閉じる
    state = _s.copyWith(type: type, categoryId: null, expandedParentId: null);
  }
```

`selectCategory` の下にメソッド追加:

```dart
  /// カテゴリボタンのタップ。isSameGroup=タップした親が現在の選択の属する
  /// グループと同じ（判定はグリッド側がカテゴリツリーから行う）。
  /// - 別グループ: 選択を切り替え、内訳があればチップ列を開く
  /// - 同グループ&内訳あり: チップ列の開閉のみ（選択は維持=モック確定挙動）
  void tapCategory({
    required int categoryId,
    required bool hasSubs,
    required bool isSameGroup,
  }) {
    if (isSameGroup && hasSubs) {
      state = _s.copyWith(
          expandedParentId: _s.expandedParentId == null ? categoryId : null);
      return;
    }
    state = _s.copyWith(
      categoryId: categoryId,
      expandedParentId: hasSubs ? categoryId : null,
    );
  }

  /// 内訳チップのタップ。選択中チップの再タップは親（チップ列の親）に戻す。
  void toggleSubcategory(int subId) {
    final parent = _s.expandedParentId;
    if (parent == null) return; // チップ列が閉じているときは呼ばれない
    state = _s.copyWith(categoryId: _s.categoryId == subId ? parent : subId);
  }
```

`saveAndContinue` の再初期化は新規 `EntryFormState` を作るため expandedParentId は自然にnull（変更不要・テストで固定するのみ）。

- [ ] **Step 4: テスト＋analyze**

Run: `flutter analyze && flutter test test/providers/entry_form_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/entry/application/entry_form_controller.dart test/providers/entry_form_controller_test.dart
git commit -m "feat(entry): breakdown chip state machine in entry form controller"
```

---

### Task 10: 入力UI（グリッド▾・ラベル差替・内訳チップ列）

**Files:**
- Modify: `lib/features/entry/presentation/category_grid.dart`（全面書き換え）
- Create: `lib/features/entry/presentation/subcategory_chips.dart`
- Modify: `lib/features/entry/presentation/entry_screen.dart`（チップ列配置・グリッド配線）
- Test: `test/ui/entry_screen_test.dart`（追記）

**Interfaces:**
- Consumes: `entryCategoriesProvider`・`entrySubcategoriesProvider`・`allCategoriesProvider`・`ctrl.tapCategory`・`ctrl.toggleSubcategory`・`state.expandedParentId`
- Produces:
  - `CategoryGrid({required TxnType type, required int? selectedId, required void Function({required int categoryId, required bool hasSubs, required bool isSameGroup}) onTapCategory})`
  - `SubcategoryChips({required int parentId, required int? selectedId, required void Function(int subId) onToggle})`
  - Key規約: グリッドタイル `Key('cat-tile-<id>')`／チップ `Key('sub-chip-<id>')`

- [ ] **Step 1: 失敗するUIテストを書く**

`test/ui/entry_screen_test.dart` に追記（既存のpump/harnessヘルパに合わせる。以下は自己完結形）:

```dart
  testWidgets('内訳: 親タップでチップ出現→内訳選択でラベル変化→再タップで格納→保存は内訳idに', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;

    // FABで入力画面へ
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 金額入力（500）
    await tester.tap(find.text('5'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.pump();

    // 食費タイル（▾付き）をタップ → チップ列が出る
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsOneWidget);

    // 外食チップを選択 → タイルのラベルが「外食 ▾」に変わる
    await tester.tap(find.byKey(Key('sub-chip-$eatOutId')));
    await tester.pumpAndSettle();
    final tileText = tester.widgetList<Text>(find.descendant(
        of: find.byKey(Key('cat-tile-$foodId')), matching: find.byType(Text)));
    expect(tileText.any((t) => t.data == '外食 ▾'), isTrue);

    // 同じタイルを再タップ → チップ列が格納（選択は維持）
    await tester.tap(find.byKey(Key('cat-tile-$foodId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sub-chip-$eatOutId')), findsNothing);

    // 保存 → categoryIdは外食のid
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();
    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.categoryId, eatOutId);
    expect(txs.single.amountYen, 500);
  });

  testWidgets('内訳未選択のまま保存すると親カテゴリに計上される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.byKey(Key('cat-tile-$foodId'))); // チップは開くが選ばない
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.categoryId, foodId); // 親に計上
  });
```

必要なimport（不足分）: `package:kakeibo_app/app/home_shell.dart`・`package:kakeibo_app/app/providers.dart`・`package:flutter_riverpod/flutter_riverpod.dart`。

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/ui/entry_screen_test.dart`
Expected: FAIL（`cat-tile-` Keyが存在しない）

- [ ] **Step 3: CategoryGridを書き換える**

`lib/features/entry/presentation/category_grid.dart` 全体を置換:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

class CategoryGrid extends ConsumerWidget {
  final TxnType type;
  final int? selectedId; // 保存されるid（親 or 内訳）
  final void Function({
    required int categoryId,
    required bool hasSubs,
    required bool isSameGroup,
  }) onTapCategory;

  const CategoryGrid({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(entryCategoriesProvider(type)).valueOrNull ?? const [];
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final byId = {for (final c in all) c.id: c};
    // 選択が内訳ならその親がグリッド上の「選択中」タイル
    final selected = selectedId == null ? null : byId[selectedId];
    final selectedGroupId = selected?.parentId ?? selected?.id;
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.4,
      children: [
        for (final c in cats)
          _tile(context, ref, c, scheme,
              isSelectedGroup: c.id == selectedGroupId,
              selectedSubName:
                  (c.id == selectedGroupId && selected?.parentId != null)
                      ? selected!.name
                      : null),
      ],
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, CategoryEntity c,
      ColorScheme scheme,
      {required bool isSelectedGroup, required String? selectedSubName}) {
    final subs =
        ref.watch(entrySubcategoriesProvider(c.id)).valueOrNull ?? const [];
    final hasSubs = subs.isNotEmpty;
    // 内訳選択中は親タイルのラベルが内訳名に変わる（食費→外食）
    final label = selectedSubName ?? c.name;
    return InkWell(
      key: Key('cat-tile-${c.id}'),
      onTap: () => onTapCategory(
          categoryId: c.id, hasSubs: hasSubs, isSameGroup: isSelectedGroup),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelectedGroup
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          border: isSelectedGroup
              ? Border.all(color: scheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(c.icon ?? '📁', style: const TextStyle(fontSize: 18)),
            Text(hasSubs ? '$label ▾' : label,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: SubcategoryChipsを作る**

`lib/features/entry/presentation/subcategory_chips.dart` を新規作成:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities.dart';
import '../application/entry_category_providers.dart';

/// 内訳チップ列（カテゴリグリッドの直上に出る）。
/// 選択中チップの再タップは onToggle 側で親選択へ戻す。
class SubcategoryChips extends ConsumerWidget {
  final int parentId;
  final int? selectedId;
  final void Function(int subId) onToggle;

  const SubcategoryChips({
    super.key,
    required this.parentId,
    required this.selectedId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(entrySubcategoriesProvider(parentId)).valueOrNull ??
        const <CategoryEntity>[];
    if (subs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final s in subs)
            ChoiceChip(
              key: Key('sub-chip-${s.id}'),
              label: Text(s.name),
              selected: s.id == selectedId,
              onSelected: (_) => onToggle(s.id),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: EntryScreenに配線する**

`lib/features/entry/presentation/entry_screen.dart` のimportに `subcategory_chips.dart` を追加し、`CategoryGrid(...)` の箇所を置換:

```dart
              // 内訳チップ列はグリッドの直上（モック確定）
              if (state.expandedParentId != null)
                SubcategoryChips(
                  parentId: state.expandedParentId!,
                  selectedId: state.categoryId,
                  onToggle: ctrl.toggleSubcategory,
                ),
              CategoryGrid(
                type: state.type,
                selectedId: state.categoryId,
                onTapCategory: ctrl.tapCategory,
              ),
```

- [ ] **Step 6: 既存テストのタイル参照を更新**

食費タイルのラベルが「食費 ▾」になるため、**`find.text('食費')` でタイルをタップしている既存テストは findsNothing で必ず落ちる**。`grep -n "find.text('食費')" test/ui/` で全箇所（entry_screen_test に3箇所の想定。他ファイルも念のため確認）を洗い出し、`find.textContaining('食費')` に置換する（「食費 ▾」にもマッチする。タップ後にチップ列が開くが、選択自体は従来どおり成立するので後続のフローは不変）。

- [ ] **Step 6.5: テスト＋analyze**

Run: `flutter analyze && flutter test test/ui/entry_screen_test.dart test/ui/receipt_review_test.dart`
Expected: PASS

- [ ] **Step 7: 全テスト**

Run: `flutter test`
Expected: 全緑

- [ ] **Step 8: Commit**

```bash
git add lib/features/entry/presentation test/ui/entry_screen_test.dart
git commit -m "feat(entry): breakdown chips above grid with label swap and collapse-on-retap"
```

---

### Task 11: サマリの積み上げバー＋内訳展開

**Files:**
- Create: `lib/features/summary/application/summary_providers.dart`
- Modify: `lib/features/summary/presentation/summary_screen.dart`
- Test: `test/ui/summary_screen_test.dart`（追記・既存expect調整）

**Interfaces:**
- Consumes: `rollupSpending`・`monthSpendingProvider`・`allCategoriesProvider`・`kSubScale`・`kTabularFigures`・`context.kakeiboColors`
- Produces:
  - `monthSpendingRollupProvider((int, int))`: `AsyncValue<List<CategorySpendGroup>>`
  - Key規約: 展開トグル `Key('expand-<parentId>')`

- [ ] **Step 1: 失敗するUIテストを書く**

`test/ui/summary_screen_test.dart` に追記。シェルのpump・シード・タブ切替は**既存テストのヘルパがあればそれを使い**、なければ以下の自己完結形で書く（タブ切替のfinderは既存テストの方法に合わせる）:

```dart
  testWidgets('内訳ありカテゴリ: 合計はロールアップ・▼内訳で展開して内訳と（内訳なし）が出る',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 1200,
        date: const CivilDate(2026, 7, 3), categoryId: foodId,
        source: TxnSource.manual));
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 800,
        date: const CivilDate(2026, 7, 20), categoryId: eatOutId,
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    await tester.tap(find.text('サマリ')); // タブ切替（既存テストの方法に合わせる）
    await tester.pumpAndSettle();

    expect(find.text('¥2,000'), findsOneWidget); // 食費グループ計（1200+800）
    expect(find.text('外食'), findsNothing); // 展開前は出ない

    await tester.tap(find.byKey(Key('expand-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('外食'), findsOneWidget);
    expect(find.text('¥800'), findsOneWidget);
    expect(find.text('（内訳なし）'), findsOneWidget); // 降順なので外食より上に出る
    expect(find.text('¥1,200'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget); // 外食の親内%
    expect(find.text('60%'), findsOneWidget); // 内訳なしの親内%

    // 再タップで畳む
    await tester.tap(find.byKey(Key('expand-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('外食'), findsNothing);
  });

  testWidgets('内訳のないカテゴリは従来の単色バー・expandトグルなし', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final dailyId = cats.firstWhere((x) => x.name == '日用品').id;
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense, amountYen: 500,
        date: const CivilDate(2026, 7, 3), categoryId: dailyId,
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('expand-$dailyId')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('内訳'), findsNothing); // ▼内訳トグルも出ない
  });
```

（不足importは calendar_screen_test を参考に追加: HomeShell / providers / flutter_riverpod / entities / civil_date / enums）

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/ui/summary_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: rollup providerを作る**

`lib/features/summary/application/summary_providers.dart` を新規作成:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/spending_rollup.dart';
import '../../calendar/application/calendar_providers.dart';

/// 月次のカテゴリ別支出を親カテゴリへロールアップ（内訳込み・降順）。
final monthSpendingRollupProvider = Provider.autoDispose
    .family<AsyncValue<List<CategorySpendGroup>>, (int, int)>((ref, key) {
  final List<CategoryEntity>? cats =
      ref.watch(allCategoriesProvider).valueOrNull;
  if (cats == null) {
    return const AsyncValue<List<CategorySpendGroup>>.loading();
  }
  return ref
      .watch(monthSpendingProvider(key))
      .whenData((rows) => rollupSpending(rows, cats));
});
```

- [ ] **Step 4: サマリ画面を書き換える**

`lib/features/summary/presentation/summary_screen.dart`:

importを更新:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/spending_rollup.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/summary_providers.dart';
```

buildの`spending`取得を置換:

```dart
    final groups =
        ref.watch(monthSpendingRollupProvider((year, month))).valueOrNull ??
            const <CategorySpendGroup>[];
```

合計カードの行を色付きに置換:

```dart
                          _totalRow(context, '収入', '+${formatYen(summary.income)}',
                              color: context.kakeiboColors.income),
                          _totalRow(context, '支出', '-${formatYen(summary.expense)}',
                              color: context.kakeiboColors.expense),
                          const Divider(),
                          _totalRow(
                            context,
                            '差引',
                            summary.net >= 0
                                ? '+${formatYen(summary.net)}'
                                : formatYen(summary.net),
                            emphasize: true,
                          ),
```

`_totalRow` を置換:

```dart
  Widget _totalRow(BuildContext context, String label, String value,
          {bool emphasize = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value,
                style: (emphasize
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyLarge)
                    ?.copyWith(color: color, fontFeatures: kTabularFigures)),
          ],
        ),
      );
```

カテゴリ別リストを置換:

```dart
                  for (final g in groups)
                    _GroupRow(group: g, grandTotal: summary.expense),
```

`_SpendRow` を削除し、以下を追加:

```dart
class _GroupRow extends StatefulWidget {
  final CategorySpendGroup group;
  final int grandTotal;
  const _GroupRow({required this.group, required this.grandTotal});

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow> {
  var _expanded = false; // 複数同時展開可（モックのまま）

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final ratio = widget.grandTotal == 0 ? 0.0 : g.total / widget.grandTotal;
    final name = g.isArchived ? '${g.name}（アーカイブ）' : g.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              Text(formatYen(g.total),
                  style: const TextStyle(fontFeatures: kTabularFigures)),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text('${(ratio * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (g.hasSubs)
            _StackedBar(group: g, widthFactor: ratio)
          else
            LinearProgressIndicator(value: ratio, minHeight: 6),
          if (g.hasSubs)
            InkWell(
              key: Key('expand-${g.categoryId}'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_expanded ? '▲ 内訳' : '▼ 内訳',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          if (_expanded)
            for (final (name, amount) in _expandedEntries(g))
              _subRow(context, name, amount, g.total),
        ],
      ),
    );
  }

  /// 内訳と直接分（（内訳なし））を同列・金額降順で並べる（モック準拠）。
  List<(String, int)> _expandedEntries(CategorySpendGroup g) => <(String, int)>[
        for (final s in g.subs)
          (s.isArchived ? '${s.name}（アーカイブ）' : s.name, s.total),
        if (g.directTotal > 0) ('（内訳なし）', g.directTotal),
      ]..sort((a, b) => b.$2.compareTo(a.$2));

  Widget _subRow(BuildContext context, String name, int amount, int parentTotal) {
    final pct = parentTotal == 0 ? 0 : (amount * 100 / parentTotal).round();
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      child: Row(
        children: [
          Expanded(
              child: Text(name, style: small, overflow: TextOverflow.ellipsis)),
          Text(formatYen(amount),
              style: small?.copyWith(fontFeatures: kTabularFigures)),
          SizedBox(
            width: 40,
            child: Text('$pct%', textAlign: TextAlign.right, style: small),
          ),
        ],
      ),
    );
  }
}

/// 深緑濃淡の積み上げバー。全体幅=月支出に対する比率、区間=内訳比率。
class _StackedBar extends StatelessWidget {
  final CategorySpendGroup group;
  final double widthFactor;
  const _StackedBar({required this.group, required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    if (group.total == 0) return const SizedBox(height: 6);
    // （内訳なし）も内訳と同列・金額降順に混ぜ、色は降順位置で割当（モック準拠）
    final amounts = <int>[
      for (final s in group.subs) s.total,
      if (group.directTotal > 0) group.directTotal,
    ]..sort((a, b) => b.compareTo(a));
    final segments = <(int, Color)>[
      for (final (i, a) in amounts.indexed) (a, kSubScale[i % kSubScale.length]),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor.clamp(0.0, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                for (final (amount, color) in segments)
                  if (amount > 0)
                    Expanded(flex: amount, child: ColoredBox(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**注意**: `Expanded(flex:)` はintで金額をそのまま使う（比率が正確・合計がintの範囲なら安全）。

- [ ] **Step 5: 既存サマリテストの調整**

既存テスト「サマリタブ: 合計と内訳（降順・アーカイブラベル）・空状態」は `_SpendRow` 前提。グループ行でも name / `formatYen(total)` / `%` / `LinearProgressIndicator`（内訳なしカテゴリ）は同じ形なので、**シードが親カテゴリのみなら期待値はそのまま通るはず**。落ちた場合のみ、表示文字列の期待をグループ行仕様に合わせて最小修正する。

- [ ] **Step 6: テスト＋analyze**

Run: `flutter analyze && flutter test test/ui/summary_screen_test.dart`
Expected: PASS

- [ ] **Step 7: 全テスト**

Run: `flutter test`
Expected: 全緑

- [ ] **Step 8: Commit**

```bash
git add lib/features/summary test/ui/summary_screen_test.dart
git commit -m "feat(summary): stacked breakdown bars with expandable sub rows"
```

---

### Task 12: カテゴリ管理（＋内訳・└表示・同スコープ並べ替え）

**Files:**
- Modify: `lib/features/settings/presentation/category_manage_page.dart`
- Test: `test/ui/category_manage_test.dart`（追記）

**Interfaces:**
- Consumes: `repo.addCategory({parentId})`・`allCategoriesProvider`（階層整列済み）
- Produces: Key規約: 親行の内訳追加 `Key('add-sub-<parentId>')`／内訳行 `ValueKey('sub-<id>')`／内訳ドラッグハンドル `Key('sub-drag-<id>')`。UI文言は「内訳を追加」

- [ ] **Step 1: 失敗するUIテストを書く**

`test/ui/category_manage_test.dart` に追記（既存のページpumpヘルパに合わせる。以下は自己完結形）:

```dart
  testWidgets('＋内訳で内訳を追加でき、└付きでネスト表示される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const CategoryManagePage());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(CategoryManagePage)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    // シード済みの外食がネスト表示されている
    expect(find.textContaining('└'), findsWidgets);
    expect(find.text('外食'), findsOneWidget);

    // ＋内訳 → ダイアログ → 追加
    await tester.tap(find.byKey(Key('add-sub-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('内訳を追加'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('category-name-field')), 'スーパー');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(find.text('スーパー'), findsOneWidget);
    final all = await waitForData(c, allCategoriesProvider);
    final sup = all.firstWhere((x) => x.name == 'スーパー');
    expect(sup.parentId, foodId);
  });

  testWidgets('内訳行にはさらに＋内訳が付かない（2段まで）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const CategoryManagePage());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(CategoryManagePage)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;
    expect(find.byKey(Key('add-sub-$eatOutId')), findsNothing);
  });

  testWidgets('内訳のアーカイブが親と独立に動く', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const CategoryManagePage());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(CategoryManagePage)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;

    await tester.tap(find.byKey(Key('archive-$eatOutId')));
    await tester.pumpAndSettle();
    // アクティブ一覧から消え、アーカイブ済みセクションに現れる
    await tester.tap(find.text('アーカイブ済み'));
    await tester.pumpAndSettle();
    expect(find.text('外食（アーカイブ）'), findsOneWidget);
    expect(find.text('食費'), findsOneWidget); // 親は無傷
  });

  testWidgets('アクティブな内訳が残る親のアーカイブはSnackBarで拒否される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const CategoryManagePage());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(CategoryManagePage)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;

    await tester.tap(find.byKey(Key('archive-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('内訳を先にアーカイブしてください'), findsOneWidget);
    final after = await waitForData(c, allCategoriesProvider);
    expect(after.firstWhere((x) => x.id == foodId).isArchived, isFalse);
    await tester.pump(const Duration(seconds: 5)); // SnackBarのpending timer回収
  });
```

- [ ] **Step 2: 実行して失敗を確認**

Run: `flutter test test/ui/category_manage_test.dart`
Expected: FAIL（`add-sub-` Keyなし）

- [ ] **Step 3: ページを実装する**

`lib/features/settings/presentation/category_manage_page.dart` を変更（**Task 3 Step 6.5の暫定フィルタ（内訳非表示）はこの書き換えで撤去**し、内訳を└行として表示する）:

`_showEditDialog` を置換（parentId対応）:

```dart
  /// category == null なら追加（parentId非nullなら内訳追加）、非nullなら改名。
  Future<void> _showEditDialog({CategoryEntity? category, int? parentId}) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CategoryEditDialog(category: category, isSub: parentId != null),
    );
    if (result == null) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (category == null) {
      await repo.addCategory(
        name: result.$1,
        type: _currentType,
        icon: result.$2.trim().isEmpty ? null : result.$2.trim(),
        parentId: parentId,
      );
    } else {
      await repo.rename(category.id, result.$1);
    }
  }
```

`_CategoryEditDialog` に `isSub` を追加:

```dart
class _CategoryEditDialog extends StatefulWidget {
  final CategoryEntity? category;
  final bool isSub;
  const _CategoryEditDialog({required this.category, this.isSub = false});
  ...
}
```

タイトル行を置換:

```dart
      title: Text(widget.category == null
          ? (widget.isSub ? '内訳を追加' : 'カテゴリを追加')
          : (widget.category!.parentId != null ? '内訳を改名' : 'カテゴリを改名')),
```

`_CategoryTypeList.build` を置換（親ブロック＋ネスト内訳＋内訳の並べ替えハンドル）:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final ofType = all.where((c) => c.type == type && !c.isSystem).toList();
    final parents = ofType
        .where((c) => c.parentId == null && !c.isArchived)
        .toList();
    final childrenByParent = <int, List<CategoryEntity>>{};
    for (final c in ofType.where((c) => c.parentId != null && !c.isArchived)) {
      childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
    }
    final archived = ofType.where((c) => c.isArchived).toList();
    final repo = ref.read(categoryRepositoryProvider);
    final pageState =
        context.findAncestorStateOfType<_CategoryManagePageState>()!;

    return Column(
      children: [
        Expanded(
          child: ReorderableListView(
            // 親ブロック（親行＋その内訳）ごと動かす。
            // onReorderItem: newIndexは「除去後」の調整済みインデックス
            onReorderItem: (oldIndex, newIndex) async {
              final ids = parents.map((c) => c.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await repo.reorder(ids);
            },
            children: [
              for (final p in parents)
                Column(
                  key: ValueKey('cat-${p.id}'),
                  children: [
                    ListTile(
                      leading: Text(p.icon ?? '📁',
                          style: const TextStyle(fontSize: 20)),
                      title: Text(p.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('add-sub-${p.id}'),
                            icon: const Icon(Icons.playlist_add),
                            tooltip: '内訳を追加',
                            onPressed: () =>
                                pageState._showEditDialog(parentId: p.id),
                          ),
                          IconButton(
                            key: Key('rename-${p.id}'),
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                pageState._showEditDialog(category: p),
                          ),
                          IconButton(
                            key: Key('archive-${p.id}'),
                            icon: const Icon(Icons.archive_outlined),
                            onPressed: () {
                              // アクティブな内訳が残る親は不可（リポジトリのガードと二重化。
                              // ここで弾かないと非同期例外がUIに漏れる）
                              if ((childrenByParent[p.id] ?? const []).isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('内訳を先にアーカイブしてください')));
                                return;
                              }
                              repo.setArchived(p.id, true);
                            },
                          ),
                        ],
                      ),
                    ),
                    _SubList(
                      parent: p,
                      subs: childrenByParent[p.id] ?? const [],
                      onRename: (c) => pageState._showEditDialog(category: c),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (archived.isNotEmpty)
          ExpansionTile(
            title: const Text('アーカイブ済み'),
            children: [
              for (final c in archived)
                ListTile(
                  leading: Text(c.parentId != null ? '└ ${c.icon ?? '📁'}' : (c.icon ?? '📁'),
                      style: const TextStyle(fontSize: 16)),
                  title: Text('${c.name}（アーカイブ）'),
                  trailing: IconButton(
                    key: Key('unarchive-${c.id}'),
                    icon: const Icon(Icons.unarchive_outlined),
                    onPressed: () => repo.setArchived(c.id, false),
                  ),
                ),
            ],
          ),
      ],
    );
  }
```

`_SubList` を同ファイルに追加:

```dart
/// 親の下にネスト表示する内訳リスト。並べ替えは同じ親の中だけ
/// （明示ハンドルで外側のブロック並べ替えと干渉させない）。
class _SubList extends ConsumerWidget {
  final CategoryEntity parent;
  final List<CategoryEntity> subs;
  final void Function(CategoryEntity) onRename;
  const _SubList({
    required this.parent,
    required this.subs,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subs.isEmpty) return const SizedBox.shrink();
    final repo = ref.read(categoryRepositoryProvider);
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) async {
        final ids = subs.map((c) => c.id).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        await repo.reorder(ids);
      },
      children: [
        for (final (i, s) in subs.indexed)
          ListTile(
            key: ValueKey('sub-${s.id}'),
            dense: true,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: Text('└ ${s.icon ?? '📁'}',
                style: const TextStyle(fontSize: 16)),
            title: Text(s.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('rename-${s.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onRename(s),
                ),
                IconButton(
                  key: Key('archive-${s.id}'),
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () => repo.setArchived(s.id, true),
                ),
                ReorderableDragStartListener(
                  key: Key('sub-drag-${s.id}'),
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

**注意**: Task 3 Step 6.5 の暫定フィルタ（`parentId == null` のみ表示・内訳非表示）は**この全面書き換えで撤去**され、内訳が親ブロック内の`└`行として復活する。既存の並べ替えテストは Task 3 Step 6.5 で親のみフィルタに更新済みなので、この書き換え後もそのまま正しい（親ブロックのみが並べ替え対象のため）。

- [ ] **Step 4: テスト＋analyze**

Run: `flutter analyze && flutter test test/ui/category_manage_test.dart`
Expected: PASS

- [ ] **Step 5: 全テスト**

Run: `flutter test`
Expected: 全緑

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/category_manage_page.dart test/ui/category_manage_test.dart
git commit -m "feat(settings): breakdown management with nested rows and sibling-scoped reorder"
```

---

### Task 13: 最終ゲート＋ドキュメント＋マージ

**Files:**
- Modify: `docs/phase45-handoff.md`（現在地の更新）
- Modify: `docs/superpowers/plans/2026-07-03-kakeibo-phase45-uchiwake.md`（実行結果・逸脱メモを冒頭に追記）

- [ ] **Step 1: フルゲート**

Run: `flutter analyze && flutter test`
Expected: analyze 0 / 全テスト緑（目安240本前後）

- [ ] **Step 2: UI文言の禁止語チェック**

Run: `grep -rn "サブカテゴリ\|親子" lib/`
Expected: ヒットなし（コメント内は許容するが、UI文字列にあれば「内訳」へ修正）

- [ ] **Step 3: ドキュメント更新**

- `docs/phase45-handoff.md`: 冒頭に「Phase 4.5 実装完了（日付）」と実際の逸脱を追記
- 本plan冒頭に実行結果メモ（P4の型に合わせる）

- [ ] **Step 4: mainへno-ffマージ**

```bash
git checkout main
git merge --no-ff phase45-uchiwake -m "merge: Phase 4.5 breakdown categories + mock theme + man-unit cells"
```

- [ ] **Step 5: マージ後の最終確認**

Run: `flutter test`
Expected: 全緑

## Self-Review記録

- スコープ照合: handoffのPhase 4.5スコープ6項目（parentId＋migration／backup v2／集計ロールアップ＋不変条件／repository・provider／UI5点／未分類制約）→ Task 1-12で全てカバー
- 追加判断: シードの外食内訳化（Task 2・理由は冒頭）／restoreのFK defer（自己参照FKのINSERT順問題への対処）／CSVの内訳列／changeType・アーカイブの階層ガード（検証で発見したプロダクト欠陥の対処）
- 型整合: `tapCategory({categoryId, hasSubs, isSameGroup})`（Task 9定義=Task 10使用）／`CategorySpendGroup`（Task 4定義=Task 11使用）／`entrySubcategoriesProvider`（Task 8定義=Task 10使用）／Key規約は各タスクのInterfacesに明記

## 敵対的検証の反映記録（2026-07-03）

5レンズ×19エージェントの検証workflowで blocker 1・major 12（実質7系統）・minor 23 を確定し、全て本planに反映済み:
- **blocker**: マイグレーションテストのv1 DDL（datetime列はTEXT。build.yamlの `store_date_time_values_as_text: true`）→ Task 1修正＋Global Constraints追記
- reorderスコープ検証・アーカイブガードの既存テスト/ページ回帰 → Task 3 Step 6.5（暫定パッチ4点）新設
- Task 8テストの `selectAsync` コンパイル不能＋lastUsedテストの空振り → waitForData直渡し＋購読保持＋前提assert方式へ差し替え
- backup_codec_testの実際の壊れ方（encode構造テスト==1→==2。「新しい版」テストは99で変更不要）＋mutateヘルパのトップレベル化とフィクスチャ実コード化 → Task 5修正
- restoreテストはstoreなし構成のため `applyRestore` 直呼びへ／deferの根拠をINSERT側に訂正 → Task 5修正
- `find.text('食費')` がラベル「食費 ▾」化で死ぬ既存3箇所 → Task 10 Step 6で textContaining へ
- プロダクト欠陥2件: changeTypeの階層不変条件素通し（自バックアップ復元不能化）→ changeTypeガード／親アーカイブでの内訳幽霊化 → setArchivedガード＋UI SnackBar（いずれもTask 3・12）
- モック忠実性: 万表記は四捨五入／（内訳なし）は降順同列＋色も降順割当 → Task 6・11修正。再展開時の選択維持は意図的逸脱として冒頭に記録
