# 家計簿アプリ Phase 4: features UI + Riverpod Implementation Plan

> **ステータス: 完了（2026-07-03）** — 全14タスク実行済み。最終ゲート: **210テスト全緑 / flutter analyze 0 issues / BOM混入なし**。mainへno-ffマージ済み。
>
> **実行時の主な逸脱**（詳細は下の逸脱メモと各コミット）:
> 1. Riverpodはcodegen不可（drift_devのanalyzer ^13と衝突）→ **flutter_riverpod 2.6.1の手書きprovider**。riverpod_lint/custom_lintも不採用（lintゲートはflutter analyze）
> 2. BackupControllerのファイルIOは**同期API**（widgetテストのFakeAsyncでは非同期IOの完了イベントが配送されないため）
> 3. テストハーネスのAutoBackupStore時計は「1秒ずつ進む決定的時計」（完全固定だと世代ファイル名が衝突）
> 4. CSVのBOM検証はバイト列で行う（DartのreadAsStringはBOMを剥がす）
> 5. `ReorderableListView.onReorder`は3.44で非推奨→`onReorderItem`（newIndex調整済み仕様）へ移行
> 6. fullscreenDialogのpopは`pageBack()`でなく`CloseButton`タップ／containerOfは常時onstageのMaterialApp基準
> 7. ダイアログ内TextEditingControllerはダイアログ自身のStatefulWidgetに封じ込め（popアニメーション中dispose事故の防止）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** spec §5 の画面群（カレンダーホーム／高速入力／編集・削除＋Undo／レシート確認／月次サマリ／設定＝バックアップ・カテゴリ管理・オンボーディング）を Riverpod 3（codegen）で実装し、**Windows の `flutter test`（ウィジェットテスト＋ProviderContainerテスト）で全機能をヘッドレス自走検証**できる状態にする。実機仕上げ（カメラ・Apple Vision・共有シート）は Phase 5（Mac）。

**Architecture:** 既存のリポジトリ層（P1）に **drift の watch ストリーム**を追加し、UI は「stream family provider（月キー）→ 派生 provider（日別・セル合計）」で購読する。ミューテーションはすべてリポジトリ経由 → drift ストリームが自動再発火 → UI 更新（復元後も自動反映）。フォーム状態は `EntryFormController`（keepAlive Notifier、3モード=create/receiptConfirm/edit）。OCR・撮影・時計・ディレクトリ・SharedPreferences は **provider の override 縫い目**で差し替え（`throw UnimplementedError` 既定 → bootstrap/テストで注入）。一次資料: `docs/superpowers/research/flutter-riverpod-structure.md`。

**Tech Stack:** flutter_riverpod 3 + riverpod_annotation/riverpod_generator（codegen）、table_calendar、shared_preferences、path_provider（bootstrapのみ）、既存: drift / cryptography。

## Global Constraints

- Phase 1〜3 の Global Constraints を継承（TDD・Windowsヘッドレス・整数円・CivilDate・textEnum）。
- **Riverpod は codegen（`@riverpod` / `@Riverpod(keepAlive: true)`）で統一**。`StateProvider` / `StateNotifierProvider` / `ChangeNotifierProvider` は使用禁止（3.0で非推奨）。provider ファイルには `part '<file>.g.dart';` を置き、変更時は `dart run build_runner build --delete-conflicting-outputs` を実行。生成 `.g.dart` はコミット対象（P1からの慣行）。
- **presentation 層（`features/*/presentation/`）は drift の型（`AppDatabase`/Companion/Table）と `dart:io` を直接 import しない**。provider・entities・`CategorySpendRow` 経由のみ。application 層は `dart:io`（画像ファイル処理）可。
- **UI/application 層で `DateTime.now()` を直接呼ばない**（bootstrap.dart のみ例外）。「今日」は `clockProvider`（`CivilDate Function()`）、UTC現在時刻は `utcNowProvider`（`DateTime Function()`）経由。テストは固定時計 **2026-07-15** を注入。
- 金額表示は `core/format.dart` のヘルパ（`formatYen`/`signedYen`/`compactYen`）経由。手書きの桁区切り再実装禁止。
- ウィジェット／providerテストは `test/support/test_app.dart` のハーネスを使用（DB=`NativeDatabase.memory`、一時Dir、`SharedPreferences.setMockInitialValues`、`BackupCrypto(pbkdf2Iterations: 1000)`）。
- UI文言は日本語。BOM は `'\uFEFF'` エスケープのみ（生文字混入禁止・P2の教訓）。
- **各タスク末ゲート**: `flutter test` 全緑 → `flutter analyze` 0 issues（riverpod_lint 3.1+ は analysis_server_plugin 方式なので analyze に診断が出る。`dart run custom_lint` は使わない） → commit。ブランチ `phase-4-ui`、完了後 main へ no-ff マージ（従来の型）。

---

## 逸脱メモ（実行時確定 2026-07-03）— Riverpodはcodegenなしの手書きprovider

依存解決の結果、**drift_dev 2.34.1+1（analyzer ^13.0.0）と riverpod のコード生成系が共存不能**と判明（pub solverで確認済みの事実）:
- riverpod 3.x は全バージョンが `test ^1.0.0` に依存 → `test` の全解決可能バージョンが analyzer <13 を要求（Flutter 3.44 の test_api 0.7.11 固定下）→ 衝突
- riverpod_generator は全バージョンが analyzer <13（最新4.0.4系でも ^12.0.0）→ 衝突
- custom_lint / riverpod_lint も同様に analyzer ^8以下 → 衝突

**採用した構成**: `flutter_riverpod 2.6.1` の**手書きprovider（manual API）**。
- `@riverpod` / `part '*.g.dart'` / build_runner（riverpod分）/ riverpod_annotation は使わない。plan中の `@Riverpod(keepAlive: true)` は「非autoDisposeの手書きprovider」、`@riverpod` は「`.autoDispose` 付き手書きprovider」に読み替える
- **provider名はplanのまま**（`appDatabaseProvider` 等）→ 画面・テストコードは原則無変更
- Notifierクラスは `Notifier<T>` / `AutoDisposeNotifier<T>` + `NotifierProvider(...)` 宣言に読み替え
- **複数引数family（monthTransactions等）はレコード1引数**: `monthTransactionsProvider((year, month))` の呼び出し形になる（planの `(year, month)` 2引数呼び出しを読み替え）
- riverpod_lint/custom_lint は不採用 → lintゲートは `flutter analyze`（flutter_lints）のみ
- StateProvider/StateNotifierProvider 等のlegacy APIは引き続き使用禁止（3.x移行性の担保）
- 将来Flutter SDK更新でanalyzer制約が解消したら riverpod 3.x + codegen へ機械的に移行可能

---

## File Structure

```
kakeibo-app/
  lib/
    main.dart                 # 置換: bootstrap() を呼ぶだけ
    app/
      app.dart                # KakeiboApp（MaterialApp・テーマ）
      bootstrap.dart          # 実配線（path_provider・実DB・ProviderScope overrides）
      home_shell.dart         # 3タブ NavigationBar + IndexedStack + FAB + 起動フック
      providers.dart          # コアprovider（DB/repo/dirs/prefs/backup/parser/ocr/capture/clock）
    core/
      format.dart             # formatYen / signedYen / compactYen / backupAgeLabel
      dates.dart              # CivilDate <-> DateTime 変換
    domain/
      entities.dart           # 修正: TransactionEntity に imagePath 追加
      repositories.dart       # 修正: watch系 / delete / カテゴリCRUD を追加
      services/ocr/receipt_capture.dart  # ReceiptCapture 抽象 + UnavailableReceiptCapture
    data/db/
      enums.dart              # 修正: categoryTypeOf(TxnType) 追加
      daos.dart               # 修正: watch系・deleteById・lastUsed・カテゴリCRUD、CategorySpendRow.isArchived
    data/repositories/        # 修正: 上記インターフェースの実装
    features/
      calendar/
        application/calendar_providers.dart
        presentation/calendar_screen.dart
        presentation/day_transaction_list.dart
        presentation/backup_banner.dart
      entry/
        application/entry_form_controller.dart
        application/entry_category_providers.dart
        presentation/entry_screen.dart
        presentation/numpad.dart
        presentation/category_grid.dart
        presentation/receipt_review_panel.dart
      summary/presentation/summary_screen.dart
      settings/
        application/settings_controller.dart   # SettingsState / AppSettings（prefs）
        application/backup_controller.dart     # LastBackup / BackupController / RestoreSource
        presentation/settings_screen.dart
        presentation/restore_picker_page.dart
        presentation/category_manage_page.dart
        presentation/onboarding_dialog.dart
  test/
    support/test_app.dart     # TestHarness / pumpApp / waitForData / setPhoneSurface
    providers/  core_providers_test.dart, calendar_providers_test.dart,
                entry_form_controller_test.dart, receipt_flow_test.dart, backup_controller_test.dart
    repository_watch_test.dart, category_crud_test.dart
    core/format_test.dart
    ui/  home_shell_test.dart, entry_screen_test.dart, calendar_screen_test.dart,
         summary_screen_test.dart, receipt_review_test.dart, settings_screen_test.dart,
         restore_picker_test.dart, category_manage_test.dart, onboarding_test.dart
  （削除: test/kakeibo_app_smoke_test.dart ＝ 旧テンプレのカウンターテスト）
```

**購読設計（研究資料 §2 準拠）**: 月キー `monthTransactionsProvider(year, month)` を唯一のDB購読点にし、日別リスト・セル合計はそこから**派生**（42セル×family の乱造をしない）。集計（サマリ/内訳）はSQL集計の watch 版を購読（集計ロジックの単一情報源は P1 の DAO のまま）。family キーは `CivilDate`（値等価）と `(int year, int month)` の**正規化済みキーのみ**。`table_calendar` の `DateTime`（時刻成分つき）を直接キーにしない。

---

## Task 1: 依存導入・コアprovider・テストハーネス

**Files:**
- Modify: `pubspec.yaml`（`flutter pub add` 経由）
- Modify: `analysis_options.yaml`
- Create: `lib/app/providers.dart`
- Create: `lib/domain/services/ocr/receipt_capture.dart`
- Create: `lib/features/settings/application/settings_controller.dart`
- Create: `test/support/test_app.dart`
- Test: `test/providers/core_providers_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`（P1）、`DriftTransactionRepository`/`DriftCategoryRepository`（P1）、`AutoBackupStore`/`BackupService`/`BackupCrypto`（P2）、`ReceiptParser`/`OcrService`/`FakeOcrService`（P3）、`CivilDate`
- Produces（後続タスク全部がこれを使う）:
  - providers（`lib/app/providers.dart`、すべて keepAlive）:
    `appDatabaseProvider`(要override) / `transactionRepositoryProvider` / `categoryRepositoryProvider` /
    `backupDirProvider`(要override) / `exportsDirProvider`(要override) / `receiptImagesDirProvider`(要override) /
    `sharedPreferencesProvider`(要override) / `autoBackupStoreProvider` / `backupServiceProvider` /
    `backupCryptoProvider` / `clockProvider`(`CivilDate Function()`) / `utcNowProvider`(`DateTime Function()`) /
    `receiptParserProvider` / `ocrServiceProvider`(要override) / `receiptCaptureProvider`(要override) /
    `allCategoriesProvider`(`Stream<List<CategoryEntity>>`)
  - `abstract interface class ReceiptCapture { Future<String?> capture(); }`、`class UnavailableReceiptCapture implements ReceiptCapture`（常にnull）
  - `class SettingsState { final bool onboardingDone; final bool retainReceiptImages; }`
  - `@Riverpod(keepAlive: true) class AppSettings extends _$AppSettings`: `SettingsState build()` / `Future<void> markOnboardingDone()` / `Future<void> setRetainReceiptImages(bool value)` → `appSettingsProvider`
  - テストハーネス（`test/support/test_app.dart`）:
    `class TestHarness { AppDatabase db; Directory root; SharedPreferences prefs; List<Override> overrides({CivilDate Function()? clock, DateTime Function()? utcNow, OcrService? ocr, ReceiptCapture? capture}); Directory get backupDir; Directory get exportsDir; Directory get imagesDir; void dispose(); }`
    `Future<TestHarness> createHarness({Map<String, Object> prefs = const {'onboardingDone': true}})`
    `Future<void> pumpApp(WidgetTester tester, TestHarness h, {Widget? home, List<Override> extra = const []})`
    `Future<T> waitForData<T>(ProviderContainer c, ProviderListenable<AsyncValue<T>> p)`
    `void setPhoneSurface(WidgetTester tester)`（iPhone相当 390×844 logical）

- [ ] **Step 1: ブランチ作成**

```bash
git checkout -b phase-4-ui
```

- [ ] **Step 2: 依存導入**

```bash
flutter pub add flutter_riverpod riverpod_annotation table_calendar shared_preferences path_provider intl
flutter pub add --dev riverpod_generator riverpod_lint
```

（`intl` は table_calendar の曜日ラベル描画（`DateFormat.E`）が要求するため明示依存にする。`custom_lint` は追加**しない** — riverpod_lint 3.1+ は analysis_server_plugin 方式に移行済み。）

`analysis_options.yaml` に**トップレベル**で追記（`analyzer: plugins:` 配下ではない）:

```yaml
plugins:
  riverpod_lint: ^3.1.0
```

riverpod_lint の診断は `flutter analyze` の出力に含まれる。

- [ ] **Step 3: 失敗するテストを書く**

Create `test/providers/core_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer container;

  setUp(() async {
    h = await createHarness();
    container = ProviderContainer(overrides: h.overrides());
    addTearDown(container.dispose);
    addTearDown(h.dispose);
  });

  test('override無しのコアproviderはUnimplementedErrorで落ちる（配線忘れ検知）', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    expect(() => bare.read(appDatabaseProvider), throwsUnimplementedError);
    expect(() => bare.read(sharedPreferencesProvider), throwsUnimplementedError);
  });

  test('repo/backupの配線が解決し、exportJsonがformatVersionを含む', () async {
    expect(container.read(transactionRepositoryProvider), isNotNull);
    expect(container.read(categoryRepositoryProvider), isNotNull);
    final json = await container.read(backupServiceProvider).exportJson();
    expect(json, contains('formatVersion'));
  });

  test('clockは固定注入でき、既定harnessでは2026-07-15', () {
    expect(container.read(clockProvider)(), const CivilDate(2026, 7, 15));
  });

  test('AppSettingsの既定と永続化', () async {
    // harness既定は onboardingDone:true（UIテストでダイアログを抑止するため）
    expect(container.read(appSettingsProvider).onboardingDone, isTrue);
    expect(container.read(appSettingsProvider).retainReceiptImages, isFalse);
    await container.read(appSettingsProvider.notifier).setRetainReceiptImages(true);
    expect(container.read(appSettingsProvider).retainReceiptImages, isTrue);
  });

  test('allCategoriesProviderがシード済みカテゴリを流す', () async {
    final cats = await waitForData(container, allCategoriesProvider);
    expect(cats.map((c) => c.name), contains('食費'));
  });
}
```

- [ ] **Step 4: 赤を確認** — Run: `flutter test test/providers/core_providers_test.dart` → FAIL（providers.dart 未定義）

- [ ] **Step 5: 実装**

Create `lib/domain/services/ocr/receipt_capture.dart`:

```dart
/// レシート画像の取得（カメラ/ギャラリー）の抽象。
/// 戻り値はアプリ専用一時パス。キャンセル・未対応プラットフォームは null。
/// 実装: Phase 5 で image_picker + カメラ（iOS/Mac）。テストは Fake を注入。
abstract interface class ReceiptCapture {
  Future<String?> capture();
}

/// 撮影非対応環境（Windows開発・Vision未配線）用: 常に null。
class UnavailableReceiptCapture implements ReceiptCapture {
  const UnavailableReceiptCapture();
  @override
  Future<String?> capture() async => null;
}
```

Create `lib/app/providers.dart`:

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup/auto_backup_store.dart';
import '../data/backup/backup_crypto.dart';
import '../data/backup/backup_service.dart';
import '../data/db/database.dart';
import '../data/repositories/drift_category_repository.dart';
import '../data/repositories/drift_transaction_repository.dart';
import '../domain/entities.dart';
import '../domain/money/civil_date.dart';
import '../domain/repositories.dart';
import '../domain/services/ocr/ocr_types.dart';
import '../domain/services/ocr/receipt_capture.dart';
import '../domain/services/receipt/receipt_parser.dart';

part 'providers.g.dart';

// --- 縫い目（bootstrap/テストで必ずoverride） ---

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) =>
    throw UnimplementedError('appDatabaseProvider は bootstrap/テストで override する');

@Riverpod(keepAlive: true)
Directory backupDir(Ref ref) =>
    throw UnimplementedError('backupDirProvider は bootstrap/テストで override する');

@Riverpod(keepAlive: true)
Directory exportsDir(Ref ref) =>
    throw UnimplementedError('exportsDirProvider は bootstrap/テストで override する');

@Riverpod(keepAlive: true)
Directory receiptImagesDir(Ref ref) =>
    throw UnimplementedError('receiptImagesDirProvider は bootstrap/テストで override する');

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider は bootstrap/テストで override する');

@Riverpod(keepAlive: true)
OcrService ocrService(Ref ref) =>
    throw UnimplementedError('ocrServiceProvider は bootstrap/テストで override する');

@Riverpod(keepAlive: true)
ReceiptCapture receiptCapture(Ref ref) =>
    throw UnimplementedError('receiptCaptureProvider は bootstrap/テストで override する');

// --- 時計（決定的テストの要。UI層で DateTime.now() を直接呼ばない） ---

@Riverpod(keepAlive: true)
CivilDate Function() clock(Ref ref) => () => CivilDate.fromDateTime(DateTime.now());

@Riverpod(keepAlive: true)
DateTime Function() utcNow(Ref ref) => () => DateTime.now().toUtc();

// --- 派生配線（override不要） ---

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    DriftTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    DriftCategoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
AutoBackupStore autoBackupStore(Ref ref) =>
    AutoBackupStore(ref.watch(backupDirProvider));

@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) => BackupService(
      ref.watch(appDatabaseProvider),
      store: ref.watch(autoBackupStoreProvider),
    );

@Riverpod(keepAlive: true)
BackupCrypto backupCrypto(Ref ref) => BackupCrypto();

@Riverpod(keepAlive: true)
ReceiptParser receiptParser(Ref ref) =>
    ReceiptParser(today: ref.watch(clockProvider));

@Riverpod(keepAlive: true)
Stream<List<CategoryEntity>> allCategories(Ref ref) =>
    ref.watch(categoryRepositoryProvider).watchAll();
```

> 注: `allCategories` は Task 3 で追加する `CategoryRepository.watchAll()` に依存する。Task 1 の時点ではまだ存在しないため、**Task 1 では `allCategories` と対応するテストケースをコメントアウトせず、`watchAll()` の最小実装（下記）だけ先行追加する**:

Modify `lib/domain/repositories.dart` — `CategoryRepository` に1行追加:

```dart
  Stream<List<CategoryEntity>> watchAll();
```

Modify `lib/data/db/daos.dart` — `CategoryDao` に追加:

```dart
  Stream<List<CategoryRow>> watchAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();
```

Modify `lib/data/repositories/drift_category_repository.dart` — 実装追加:

```dart
  @override
  Stream<List<CategoryEntity>> watchAll() =>
      _db.categoryDao.watchAllCategories().map((rows) => rows
          .map((r) => CategoryEntity(
                id: r.id,
                name: r.name,
                type: r.type,
                icon: r.icon,
                sortOrder: r.sortOrder,
                isArchived: r.isArchived,
                isSystem: r.isSystem,
              ))
          .toList());
```

Create `lib/features/settings/application/settings_controller.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';

part 'settings_controller.g.dart';

class SettingsState {
  final bool onboardingDone;
  final bool retainReceiptImages;
  const SettingsState({
    required this.onboardingDone,
    required this.retainReceiptImages,
  });
}

/// SharedPreferences 由来のアプリ設定。書き込み後は invalidateSelf で再読込。
@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  static const kOnboardingDone = 'onboardingDone';
  static const kRetainReceiptImages = 'retainReceiptImages';

  @override
  SettingsState build() {
    final p = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      onboardingDone: p.getBool(kOnboardingDone) ?? false,
      retainReceiptImages: p.getBool(kRetainReceiptImages) ?? false,
    );
  }

  Future<void> markOnboardingDone() async {
    await ref.read(sharedPreferencesProvider).setBool(kOnboardingDone, true);
    ref.invalidateSelf();
  }

  Future<void> setRetainReceiptImages(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(kRetainReceiptImages, value);
    ref.invalidateSelf();
  }
}
```

Create `test/support/test_app.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_crypto.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/ocr/receipt_capture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_db.dart';

/// UI/providerテスト共通ハーネス。
/// 固定時計 2026-07-15（月中日でmonth境界フレークを回避）。
class TestHarness {
  final AppDatabase db;
  final Directory root;
  final SharedPreferences prefs;
  TestHarness({required this.db, required this.root, required this.prefs});

  Directory get backupDir => Directory('${root.path}${Platform.pathSeparator}backups');
  Directory get exportsDir => Directory('${root.path}${Platform.pathSeparator}exports');
  Directory get imagesDir => Directory('${root.path}${Platform.pathSeparator}images');

  List<Override> overrides({
    CivilDate Function()? clock,
    DateTime Function()? utcNow,
    DateTime Function()? storeNow,
    OcrService? ocr,
    ReceiptCapture? capture,
  }) =>
      [
        appDatabaseProvider.overrideWith((ref) => db),
        backupDirProvider.overrideWith((ref) => backupDir),
        exportsDirProvider.overrideWith((ref) => exportsDir),
        receiptImagesDirProvider.overrideWith((ref) => imagesDir),
        // 自動バックアップ世代のタイムスタンプも固定時計に（決定性の担保）
        autoBackupStoreProvider.overrideWith((ref) => AutoBackupStore(
              backupDir,
              now: storeNow ?? utcNow ?? () => DateTime.utc(2026, 7, 15, 3, 0),
            )),
        sharedPreferencesProvider.overrideWith((ref) => prefs),
        clockProvider.overrideWith((ref) => clock ?? () => const CivilDate(2026, 7, 15)),
        utcNowProvider.overrideWith((ref) => utcNow ?? () => DateTime.utc(2026, 7, 15, 3, 0)),
        ocrServiceProvider.overrideWith((ref) => ocr ?? const FakeOcrService([])),
        receiptCaptureProvider.overrideWith((ref) => capture ?? const UnavailableReceiptCapture()),
        backupCryptoProvider.overrideWith((ref) => BackupCrypto(pbkdf2Iterations: 1000)),
      ];

  void dispose() {
    db.close();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

Future<TestHarness> createHarness({
  Map<String, Object> prefs = const {'onboardingDone': true},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // table_calendarの曜日ラベル(DateFormat.E)に必須
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final root = Directory.systemTemp.createTempSync('kakeibo_ui_test');
  return TestHarness(db: newMemoryDb(), root: root, prefs: p);
}

/// アプリ全体（KakeiboApp）または単一画面（home指定）をポンプする。
Future<void> pumpApp(
  WidgetTester tester,
  TestHarness h, {
  Widget? home,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [...h.overrides(), ...extra],
    child: home != null ? MaterialApp(home: home) : const KakeiboAppPlaceholder(),
  ));
  await tester.pumpAndSettle();
}

/// Task 2 で app.dart の KakeiboApp に差し替えるまでの仮ルート。
/// （Task 2 完了時に pumpApp から本物の KakeiboApp を参照させ、この widget は削除）
class KakeiboAppPlaceholder extends StatelessWidget {
  const KakeiboAppPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: Scaffold(body: SizedBox()));
}

/// AsyncValue系providerの最初のデータ到達を待つ。
Future<T> waitForData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final completer = Completer<T>();
  final sub = container.listen<AsyncValue<T>>(provider, (prev, next) {
    if (next is AsyncData<T> && !completer.isCompleted) {
      completer.complete(next.value);
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}

/// iPhone相当の論理サイズ（390x844）。縦長フォームのoverflow検知のため必ず使う。
void setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
```

- [ ] **Step 6: codegen 実行**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `providers.g.dart` / `settings_controller.g.dart` 生成、エラーなし

- [ ] **Step 7: 緑を確認** — Run: `flutter test test/providers/core_providers_test.dart` → PASS。続けて全体: `flutter test` → 既存134テストも緑

- [ ] **Step 8: analyze ゲート** — Run: `flutter analyze` → 0 issues（riverpod_lint診断含む）

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat(ui): add riverpod core providers, seams, and UI test harness"
```

---

## Task 2: アプリシェル（3タブ・main置換・bootstrap）

**Files:**
- Create: `lib/app/app.dart`, `lib/app/home_shell.dart`, `lib/app/bootstrap.dart`
- Modify: `lib/main.dart`（全置換）, `test/support/test_app.dart`（KakeiboAppPlaceholder削除→本物参照）
- Delete: `test/kakeibo_app_smoke_test.dart`（旧テンプレのカウンターテスト）
- Test: `test/ui/home_shell_test.dart`

**Interfaces:**
- Consumes: Task 1 の providers / ハーネス
- Produces:
  - `class KakeiboApp extends StatelessWidget` — `MaterialApp(title: '家計簿', theme: ..., home: HomeShell())`
  - `class HomeShell extends ConsumerStatefulWidget` — `IndexedStack` ＋ `NavigationBar`（カレンダー/サマリ/設定）。タブ本体は当面プライベートな `_PlaceholderTab`（Task 8/9/12 で実画面に差し替え）。FAB は Task 8 で追加。
  - `Future<void> bootstrap()` — 実配線（テスト対象外。ロジックを持たせない）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/ui/home_shell_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('3タブが表示され、タップで切り替わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.text('カレンダー'), findsOneWidget); // NavigationBarラベル
    expect(find.text('(カレンダー 準備中)'), findsOneWidget);

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();
    expect(find.text('(サマリ 準備中)'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('(設定 準備中)'), findsOneWidget);
  });
}
```

同時に `test/support/test_app.dart` を修正: `KakeiboAppPlaceholder` クラスを削除し、

```dart
import 'package:kakeibo_app/app/app.dart';
```

を追加、`pumpApp` の該当行を `child: home != null ? MaterialApp(home: home) : const KakeiboApp(),` に変更。

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/home_shell_test.dart` → FAIL（app.dart 未定義）

- [ ] **Step 3: 実装**

Create `lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';

import 'home_shell.dart';

class KakeiboApp extends StatelessWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '家計簿',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D6B),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      );
}
```

Create `lib/app/home_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            _PlaceholderTab('(カレンダー 準備中)'), // Task 8 で CalendarScreen に差し替え
            _PlaceholderTab('(サマリ 準備中)'),     // Task 9 で SummaryScreen に差し替え
            _PlaceholderTab('(設定 準備中)'),       // Task 12 で SettingsScreen に差し替え
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'カレンダー'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'サマリ'),
            NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
          ],
        ),
      );
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab(this.label);

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
```

Create `lib/app/bootstrap.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/database.dart';
import '../domain/services/ocr/ocr_types.dart';
import '../domain/services/ocr/receipt_capture.dart';
import 'app.dart';
import 'providers.dart';

/// 実行時の実配線。ロジックを持たない（テストはハーネスの override で代替）。
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // table_calendarの曜日ラベル(DateFormat.E)に必須
  final support = await getApplicationSupportDirectory();
  final docs = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();

  final sep = Platform.pathSeparator;
  final db = AppDatabase(
    NativeDatabase.createInBackground(File('${support.path}${sep}kakeibo.sqlite')),
  );

  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      backupDirProvider.overrideWith((ref) => Directory('${support.path}${sep}backups')),
      exportsDirProvider.overrideWith((ref) => Directory('${docs.path}${sep}exports')),
      receiptImagesDirProvider.overrideWith((ref) => Directory('${support.path}${sep}receipt_images')),
      sharedPreferencesProvider.overrideWith((ref) => prefs),
      // Phase 5（Mac）で AppleVisionOcrService / 実カメラ capture に差し替える
      ocrServiceProvider.overrideWith((ref) => const FakeOcrService([])),
      receiptCaptureProvider.overrideWith((ref) => const UnavailableReceiptCapture()),
    ],
    child: const KakeiboApp(),
  ));
}
```

Replace `lib/main.dart`（全置換）:

```dart
import 'app/bootstrap.dart';

void main() => bootstrap();
```

Delete `test/kakeibo_app_smoke_test.dart`（旧カウンターテスト。削除前に中身を確認し、独自内容があれば home_shell_test に移す）。

- [ ] **Step 4: 緑を確認** — Run: `flutter test` → 全緑

- [ ] **Step 5: analyze/lint ゲート** — `flutter analyze` 0 issues
- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(ui): app shell with 3-tab navigation, bootstrap wiring"
```

---

## Task 3: データ層拡張（watch・delete・imagePath・カテゴリCRUD・lastUsed）

**Files:**
- Modify: `lib/domain/entities.dart`, `lib/domain/repositories.dart`, `lib/data/db/daos.dart`,
  `lib/data/repositories/drift_transaction_repository.dart`, `lib/data/repositories/drift_category_repository.dart`
- Test: `test/repository_watch_test.dart`, `test/category_crud_test.dart`

**Interfaces:**
- Consumes: P1 の DAO/repo、`CivilDate`
- Produces:
  - `TransactionEntity` に `final String? imagePath;`（コンストラクタ末尾に `this.imagePath,`）
  - `CategorySpendRow` に `final bool isArchived;`（required named）
  - `TransactionRepository` 追加メソッド:
    ```dart
    Stream<List<TransactionEntity>> watchMonth(int year, int month);
    Stream<MonthlySummary> watchSummary(int year, int month);
    Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month);
    Stream<Map<int, CivilDate>> watchLastUsedByCategory(); // categoryId -> 最終利用日(取引date基準)
    Future<void> delete(int id);
    ```
  - `CategoryRepository` 追加メソッド（`watchAll()` は Task 1 で導入済み）:
    ```dart
    Future<int> addCategory({required String name, required CategoryType type, String? icon});
    Future<void> rename(int categoryId, String name);
    Future<void> setArchived(int categoryId, bool archived);
    Future<void> reorder(List<int> orderedIds); // index順に sortOrder を振り直す（同一typeのアクティブ列を想定）
    ```
  - `class SystemCategoryError implements Exception`（`drift_category_repository.dart` に定義）— isSystem 行への rename/setArchived/reorder で throw
  - 挙動契約: `delete` 済みIDの再deleteは黙って成功（冪等）。`addCategory` は name.trim() 空で `ArgumentError`。`reorder` は渡した順に `sortOrder = 0,1,2,...` を振る。

- [ ] **Step 1: 失敗するテストを書く（watch系＋delete）**

Create `test/repository_watch_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_transaction_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftTransactionRepository repo;
  late int foodId;

  TransactionEntity tx(int yen, {int day = 10, TxnType type = TxnType.expense}) =>
      TransactionEntity(
        type: type,
        amountYen: yen,
        date: CivilDate(2026, 7, day),
        categoryId: foodId,
        source: TxnSource.manual,
      );

  setUp(() async {
    db = newMemoryDb();
    repo = DriftTransactionRepository(db);
    final cats = await db.categoryDao.allCategories();
    foodId = cats.firstWhere((c) => c.name == '食費').id;
  });

  tearDown(() => db.close());

  test('watchMonth: 追加/削除で再発火し月外は含まない', () async {
    final emissions = <List<TransactionEntity>>[];
    final sub = repo.watchMonth(2026, 7).listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    final id = await repo.add(tx(500));
    await repo.add(TransactionEntity(
      type: TxnType.expense, amountYen: 999,
      date: const CivilDate(2026, 8, 1), categoryId: foodId,
      source: TxnSource.manual,
    )); // 月外
    await pumpEventQueue();
    expect(emissions.last.map((t) => t.amountYen), [500]);

    await repo.delete(id);
    await pumpEventQueue();
    expect(emissions.last, isEmpty);
  });

  test('delete は冪等（存在しないIDでも例外なし）', () async {
    await repo.delete(99999);
  });

  test('watchSummary: income/expense/netが追う', () async {
    await repo.add(tx(300));
    await repo.add(tx(1000, type: TxnType.income));
    final s = await repo.watchSummary(2026, 7).first;
    expect(s.expense, 300);
    expect(s.income, 1000);
    expect(s.net, 700);
  });

  test('watchSpendingByCategory: isArchivedが載る', () async {
    await repo.add(tx(300));
    final rows = await repo.watchSpendingByCategory(2026, 7).first;
    expect(rows.single.categoryName, '食費');
    expect(rows.single.isArchived, isFalse);
    expect(rows.single.total, 300);
  });

  test('watchLastUsedByCategory: カテゴリごとの最終利用日(date基準)', () async {
    await repo.add(tx(100, day: 3));
    await repo.add(tx(200, day: 20));
    final map = await repo.watchLastUsedByCategory().first;
    expect(map[foodId], const CivilDate(2026, 7, 20));
  });

  test('imagePath が add で保存され entity に戻る', () async {
    await repo.add(TransactionEntity(
      type: TxnType.expense, amountYen: 100,
      date: const CivilDate(2026, 7, 10), categoryId: foodId,
      source: TxnSource.receiptOcr, imagePath: '/tmp/r.jpg',
    ));
    final list = await repo.forMonth(2026, 7);
    expect(list.single.imagePath, '/tmp/r.jpg');
  });
}
```

Create `test/category_crud_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository repo;

  setUp(() {
    db = newMemoryDb();
    repo = DriftCategoryRepository(db);
  });

  tearDown(() => db.close());

  test('addCategory: 末尾sortOrderで追加され watchAll に現れる', () async {
    final id = await repo.addCategory(name: 'ペット', type: CategoryType.expense, icon: '🐈');
    final all = await repo.watchAll().first;
    final added = all.firstWhere((c) => c.id == id);
    expect(added.name, 'ペット');
    expect(added.sortOrder, greaterThan(all.where((c) => c.id != id).map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) - 1));
  });

  test('addCategory: 空白名はArgumentError', () async {
    expect(() => repo.addCategory(name: '  ', type: CategoryType.expense),
        throwsArgumentError);
  });

  test('rename が反映され、システムカテゴリはSystemCategoryError', () async {
    final all = await repo.watchAll().first;
    final food = all.firstWhere((c) => c.name == '食費');
    final system = all.firstWhere((c) => c.isSystem);
    await repo.rename(food.id, '食料品');
    expect((await repo.watchAll().first).any((c) => c.name == '食料品'), isTrue);
    expect(() => repo.rename(system.id, 'x'), throwsA(isA<SystemCategoryError>()));
  });

  test('setArchived の往復とシステム保護', () async {
    final all = await repo.watchAll().first;
    final food = all.firstWhere((c) => c.name == '食費');
    final system = all.firstWhere((c) => c.isSystem);
    await repo.setArchived(food.id, true);
    expect((await repo.watchAll().first).firstWhere((c) => c.id == food.id).isArchived, isTrue);
    await repo.setArchived(food.id, false);
    expect((await repo.watchAll().first).firstWhere((c) => c.id == food.id).isArchived, isFalse);
    expect(() => repo.setArchived(system.id, true), throwsA(isA<SystemCategoryError>()));
  });

  test('reorder: 渡した順で sortOrder=0.. が振られる', () async {
    final all = await repo.watchAll().first;
    final exp = all
        .where((c) => c.type == CategoryType.expense && !c.isSystem)
        .toList();
    final reversed = exp.reversed.map((c) => c.id).toList();
    await repo.reorder(reversed);
    final after = await repo.watchAll().first;
    final byId = {for (final c in after) c.id: c};
    for (var i = 0; i < reversed.length; i++) {
      expect(byId[reversed[i]]!.sortOrder, i);
    }
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/repository_watch_test.dart test/category_crud_test.dart` → FAIL

- [ ] **Step 3: 実装**

Modify `lib/domain/entities.dart` — `TransactionEntity` に `imagePath` を追加:

```dart
class TransactionEntity {
  final int? id;
  final TxnType type;
  final int amountYen; // 非負
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? memo;
  final TxnSource source;
  final String? imagePath; // §14-C: 保持設定ON時のみ非null

  const TransactionEntity({
    this.id,
    required this.type,
    required this.amountYen,
    required this.date,
    required this.categoryId,
    this.paymentMethod,
    this.memo,
    required this.source,
    this.imagePath,
  });
}
```

Modify `lib/domain/repositories.dart` — import に `../domain/money/civil_date.dart` 相当（`'money/civil_date.dart'`）を追加し、Interfaces 節のメソッドをそのまま追加。

Modify `lib/data/db/daos.dart` — `TransactionDao` に追加:

```dart
  Stream<List<TransactionRow>> watchTransactionsInMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Stream<Map<TxnType, int>> watchTotalsByType(int year, int month) {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.type, amountSum])
      ..where(_inMonth(year, month))
      ..groupBy([transactions.type]);
    return query.watch().map((rows) => {
          for (final row in rows)
            row.readWithConverter(transactions.type)!: row.read(amountSum) ?? 0,
        });
  }

  Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month) {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId),
          useColumns: false),
    ])
      ..addColumns([categories.id, categories.name, categories.isArchived, amountSum])
      ..where(_inMonth(year, month) &
          transactions.type.equalsValue(TxnType.expense))
      ..groupBy([transactions.categoryId])
      ..orderBy([OrderingTerm.desc(amountSum)]);
    return query.watch().map((rows) => [
          for (final row in rows)
            CategorySpendRow(
              categoryId: row.read(categories.id)!,
              categoryName: row.read(categories.name)!,
              isArchived: row.read(categories.isArchived)!,
              total: row.read(amountSum) ?? 0,
            ),
        ]);
  }

  /// カテゴリ別の最終利用日。取引date（YYYY-MM-DD、辞書順=時系列順）のMAX。
  Stream<Map<int, String>> watchLastUsedIsoByCategory() {
    final maxDate = transactions.date.max();
    final query = selectOnly(transactions)
      ..addColumns([transactions.categoryId, maxDate])
      ..groupBy([transactions.categoryId]);
    return query.watch().map((rows) => {
          for (final row in rows)
            row.read(transactions.categoryId)!: row.read(maxDate)!,
        });
  }

  Future<void> deleteById(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
```

同ファイルの `CategorySpendRow` を修正（`isArchived` 追加）:

```dart
class CategorySpendRow {
  final int categoryId;
  final String categoryName;
  final bool isArchived;
  final int total;
  const CategorySpendRow({
    required this.categoryId,
    required this.categoryName,
    required this.isArchived,
    required this.total,
  });
}
```

既存の `spendingByCategory`（Future版）の `CategorySpendRow(...)` 構築にも `isArchived: row.read(categories.isArchived)!,` を追加し、`addColumns` に `categories.isArchived` を足す。

`CategoryDao` に追加:

```dart
  Future<int> insertCategory(CategoriesCompanion c) => into(categories).insert(c);

  Future<void> renameCategory(int id, String name) async {
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(name)));
  }

  Future<void> setArchived(int id, bool archived) async {
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(isArchived: Value(archived)));
  }

  Future<int> maxSortOrder() async {
    final maxOrder = categories.sortOrder.max();
    final q = selectOnly(categories)..addColumns([maxOrder]);
    final row = await q.getSingle();
    return row.read(maxOrder) ?? -1;
  }

  Future<void> updateSortOrders(Map<int, int> orderById) => batch((b) {
        orderById.forEach((id, order) {
          b.update(
            categories,
            CategoriesCompanion(sortOrder: Value(order)),
            where: (c) => c.id.equals(id),
          );
        });
      });

  Future<CategoryRow> byId(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingle();
```

（既存 `archive(categoryId)` は `setArchived(categoryId, true)` に委譲する形へ書き換えてよい。）

Modify `lib/data/repositories/drift_transaction_repository.dart` — 追加実装:

```dart
  @override
  Stream<List<TransactionEntity>> watchMonth(int year, int month) =>
      _db.transactionDao
          .watchTransactionsInMonth(year, month)
          .map((rows) => rows.map(_toEntity).toList());

  @override
  Stream<MonthlySummary> watchSummary(int year, int month) =>
      _db.transactionDao.watchTotalsByType(year, month).map((byType) =>
          MonthlySummary(
            income: byType[TxnType.income] ?? 0,
            expense: byType[TxnType.expense] ?? 0,
          ));

  @override
  Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month) =>
      _db.transactionDao.watchSpendingByCategory(year, month);

  @override
  Stream<Map<int, CivilDate>> watchLastUsedByCategory() =>
      _db.transactionDao.watchLastUsedIsoByCategory().map((m) =>
          m.map((id, iso) => MapEntry(id, CivilDate.parse(iso))));

  @override
  Future<void> delete(int id) => _db.transactionDao.deleteById(id);
```

`add()` に `imagePath: Value(tx.imagePath),` を追加し、`_toEntity` に `imagePath: r.imagePath,` を追加。import に `'../../domain/money/civil_date.dart'` を追加。

Modify `lib/data/repositories/drift_category_repository.dart`:

```dart
class SystemCategoryError implements Exception {
  final int categoryId;
  const SystemCategoryError(this.categoryId);
  @override
  String toString() => 'SystemCategoryError(category $categoryId is protected)';
}
```

```dart
  Future<void> _guardSystem(int categoryId) async {
    final row = await _db.categoryDao.byId(categoryId);
    if (row.isSystem) throw SystemCategoryError(categoryId);
  }

  @override
  Future<int> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '空にできません');
    final next = await _db.categoryDao.maxSortOrder() + 1;
    return _db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: trimmed,
      type: type,
      icon: Value(icon),
      sortOrder: Value(next),
    ));
  }

  @override
  Future<void> rename(int categoryId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '空にできません');
    await _guardSystem(categoryId);
    await _db.categoryDao.renameCategory(categoryId, trimmed);
  }

  @override
  Future<void> setArchived(int categoryId, bool archived) async {
    await _guardSystem(categoryId);
    await _db.categoryDao.setArchived(categoryId, archived);
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    for (final id in orderedIds) {
      await _guardSystem(id);
    }
    await _db.categoryDao.updateSortOrders({
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    });
  }
```

（`CategoriesCompanion.insert` の `icon` が `Value<String?>` を要求するため import `package:drift/drift.dart` を追加。）

- [ ] **Step 4: build_runner 再生成**（`@DriftAccessor(tables:)` は不変だが安全のため）

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: 緑を確認** — Run: `flutter test` → 全緑（`CategorySpendRow` の required 追加で既存テストがコンパイルエラーになったら、その構築箇所に `isArchived: false` を追加）

- [ ] **Step 6: analyze/lint ゲート** — `flutter analyze` 0 issues
- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(data): watch streams, delete, imagePath, category CRUD, last-used"
```

## Task 4: 表示フォーマッタ・日付変換・enumマッピング（純Dart）

**Files:**
- Create: `lib/core/format.dart`, `lib/core/dates.dart`
- Modify: `lib/data/db/enums.dart`（`categoryTypeOf` 追加）
- Test: `test/core/format_test.dart`

**Interfaces:**
- Produces:
  ```dart
  // lib/core/format.dart
  String formatYen(int yen);                        // 1234567 -> '¥1,234,567'
  String signedYen(TxnType type, int amountYen);    // expense -> '-¥1,234' / income -> '+¥1,234'
  String compactYen(int yen);                       // カレンダーセル用: 0->'' / 980->'¥980' / 9800->'¥9.8k' / 12345->'¥12k' / 1200000->'¥1.2M'
  String backupAgeLabel(DateTime? lastUtc, DateTime nowUtc); // null->'バックアップ未作成' / 当日->'前回バックアップ: 今日' / N日->'前回バックアップ: N日前'
  // lib/core/dates.dart
  DateTime dateTimeOfCivil(CivilDate d);            // 時刻00:00のローカルDateTime（table_calendar連携用）
  CivilDate civilOfDateTime(DateTime dt);           // 時刻/タイムゾーンを捨てる正規化（family キーは必ずこれを通す）
  // lib/data/db/enums.dart
  CategoryType categoryTypeOf(TxnType t);
  ```

- [ ] **Step 1: 失敗するテストを書く**

Create `test/core/format_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/dates.dart';
import 'package:kakeibo_app/core/format.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

void main() {
  test('formatYen: 桁区切り', () {
    expect(formatYen(0), '¥0');
    expect(formatYen(999), '¥999');
    expect(formatYen(1000), '¥1,000');
    expect(formatYen(1234567), '¥1,234,567');
  });

  test('signedYen: typeで符号', () {
    expect(signedYen(TxnType.expense, 1234), '-¥1,234');
    expect(signedYen(TxnType.income, 1234), '+¥1,234');
  });

  test('compactYen: セル略記', () {
    expect(compactYen(0), '');
    expect(compactYen(980), '¥980');
    expect(compactYen(1000), '¥1k');
    expect(compactYen(9840), '¥9.8k');
    expect(compactYen(12345), '¥12k');
    expect(compactYen(999999), '¥999k');
    expect(compactYen(1200000), '¥1.2M');
  });

  test('backupAgeLabel', () {
    final now = DateTime.utc(2026, 7, 15, 3);
    expect(backupAgeLabel(null, now), 'バックアップ未作成');
    expect(backupAgeLabel(DateTime.utc(2026, 7, 15, 1), now), '前回バックアップ: 今日');
    expect(backupAgeLabel(DateTime.utc(2026, 7, 12, 1), now), '前回バックアップ: 3日前');
  });

  test('dates: CivilDate <-> DateTime 正規化', () {
    expect(dateTimeOfCivil(const CivilDate(2026, 7, 3)), DateTime(2026, 7, 3));
    expect(civilOfDateTime(DateTime(2026, 7, 3, 14, 5)), const CivilDate(2026, 7, 3));
  });

  test('categoryTypeOf', () {
    expect(categoryTypeOf(TxnType.expense), CategoryType.expense);
    expect(categoryTypeOf(TxnType.income), CategoryType.income);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/core/format_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/core/format.dart`:

```dart
import '../data/db/enums.dart';

String formatYen(int yen) {
  final digits = yen.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${yen < 0 ? '-' : ''}¥$buf';
}

String signedYen(TxnType type, int amountYen) =>
    (type == TxnType.expense ? '-' : '+') + formatYen(amountYen);

/// カレンダーセル用の略記（45px幅で潰れないように）。実機での最終調整はspec §13の宿題。
String compactYen(int yen) {
  if (yen <= 0) return '';
  if (yen < 1000) return '¥$yen';
  if (yen < 10000) return '¥${_oneDecimal(yen / 1000)}k';
  if (yen < 1000000) return '¥${yen ~/ 1000}k';
  return '¥${_oneDecimal(yen / 1000000)}M';
}

String _oneDecimal(double v) {
  final s = ((v * 10).floor() / 10).toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String backupAgeLabel(DateTime? lastUtc, DateTime nowUtc) {
  if (lastUtc == null) return 'バックアップ未作成';
  final days = nowUtc.difference(lastUtc).inDays;
  if (days <= 0) return '前回バックアップ: 今日';
  return '前回バックアップ: $days日前';
}
```

Create `lib/core/dates.dart`:

```dart
import '../domain/money/civil_date.dart';

DateTime dateTimeOfCivil(CivilDate d) => DateTime(d.year, d.month, d.day);

CivilDate civilOfDateTime(DateTime dt) => CivilDate(dt.year, dt.month, dt.day);
```

Modify `lib/data/db/enums.dart` — 末尾に追加:

```dart
CategoryType categoryTypeOf(TxnType t) =>
    t == TxnType.expense ? CategoryType.expense : CategoryType.income;
```

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → `flutter analyze` 0 issues →

```bash
git add -A
git commit -m "feat(core): yen formatters, civil-date conversion, enum mapping"
```

---

## Task 5: カレンダー/カテゴリ application providers

**Files:**
- Create: `lib/features/calendar/application/calendar_providers.dart`
- Create: `lib/features/entry/application/entry_category_providers.dart`
- Test: `test/providers/calendar_providers_test.dart`

**Interfaces:**
- Consumes: Task 1 providers、Task 3 の watch系repo、Task 4 の `categoryTypeOf`
- Produces（生成名）:
  - `selectedDayProvider` — `@riverpod class SelectedDay`: `CivilDate build()`（既定=今日） / `void select(CivilDate day)`
  - `currentMonthProvider` — `@riverpod class CurrentMonth`: `(int, int) build()`（既定=今月） / `void set(int year, int month)` / `void next()` / `void prev()`（年跨ぎwrap）
  - `monthTransactionsProvider(year, month)` — `Stream<List<TransactionEntity>>`
  - `monthSummaryProvider(year, month)` — `Stream<MonthlySummary>`
  - `monthSpendingProvider(year, month)` — `Stream<List<CategorySpendRow>>`
  - `dayTransactionsProvider(CivilDate day)` — `AsyncValue<List<TransactionEntity>>`（月streamから派生・当日分のみ）
  - `dayExpenseTotalsProvider(year, month)` — `AsyncValue<Map<CivilDate, int>>`（支出のみ日別合計）
  - `categoryLastUsedProvider` — `Stream<Map<int, CivilDate>>`
  - `entryCategoriesProvider(TxnType type)` — `AsyncValue<List<CategoryEntity>>`（!archived・!system・type一致。並び=最終利用日降順→sortOrder昇順）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/providers/calendar_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/calendar/application/calendar_providers.dart';
import 'package:kakeibo_app/features/entry/application/entry_category_providers.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late int foodId;
  late int hobbyId;

  Future<void> addTx(int yen, {int day = 15, TxnType type = TxnType.expense, int? categoryId}) =>
      c.read(transactionRepositoryProvider).add(TransactionEntity(
            type: type,
            amountYen: yen,
            date: CivilDate(2026, 7, day),
            categoryId: categoryId ?? foodId,
            source: TxnSource.manual,
          ));

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
    hobbyId = cats.firstWhere((x) => x.name == '趣味・娯楽').id;
  });

  test('selectedDay/currentMonth の既定は固定時計に従う', () {
    expect(c.read(selectedDayProvider), const CivilDate(2026, 7, 15));
    expect(c.read(currentMonthProvider), (2026, 7));
  });

  test('currentMonth.next/prev は年を跨いでwrapする', () {
    final m = c.read(currentMonthProvider.notifier);
    m.set(2026, 12);
    m.next();
    expect(c.read(currentMonthProvider), (2027, 1));
    m.set(2026, 1);
    m.prev();
    expect(c.read(currentMonthProvider), (2025, 12));
  });

  test('dayTransactions は月streamから当日分だけ派生し、追加に反応する', () async {
    final sub = c.listen(dayTransactionsProvider(const CivilDate(2026, 7, 15)), (_, __) {});
    addTearDown(sub.close);
    await addTx(500);
    await addTx(999, day: 16);
    await pumpEventQueue();
    final list = sub.read().requireValue;
    expect(list.single.amountYen, 500);
  });

  test('dayExpenseTotals は支出のみを日別合計する', () async {
    final sub = c.listen(dayExpenseTotalsProvider(2026, 7), (_, __) {});
    addTearDown(sub.close);
    await addTx(300);
    await addTx(200);
    await addTx(10000, type: TxnType.income);
    await pumpEventQueue();
    final totals = sub.read().requireValue;
    expect(totals[const CivilDate(2026, 7, 15)], 500);
  });

  test('entryCategories: type一致のみ・最終利用日降順→sortOrder順', () async {
    final sub = c.listen(entryCategoriesProvider(TxnType.expense), (_, __) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final before = sub.read().requireValue;
    expect(before.any((x) => x.isSystem), isFalse);
    expect(before.any((x) => x.type == CategoryType.income), isFalse);
    // 「趣味・娯楽」を最近使う → 先頭に来る
    await addTx(100, day: 14, categoryId: hobbyId);
    await pumpEventQueue();
    final after = sub.read().requireValue;
    expect(after.first.id, hobbyId);
  });

  test('entryCategories: アーカイブ済みは出ない', () async {
    await c.read(categoryRepositoryProvider).setArchived(foodId, true);
    final sub = c.listen(entryCategoriesProvider(TxnType.expense), (_, __) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(sub.read().requireValue.any((x) => x.id == foodId), isFalse);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/providers/calendar_providers_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/calendar/application/calendar_providers.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/db/daos.dart' show CategorySpendRow;
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';

part 'calendar_providers.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  CivilDate build() => ref.watch(clockProvider)();

  void select(CivilDate day) => state = day;
}

@riverpod
class CurrentMonth extends _$CurrentMonth {
  @override
  (int, int) build() {
    final today = ref.watch(clockProvider)();
    return (today.year, today.month);
  }

  void set(int year, int month) => state = (year, month);

  void next() {
    final (y, m) = state;
    state = m == 12 ? (y + 1, 1) : (y, m + 1);
  }

  void prev() {
    final (y, m) = state;
    state = m == 1 ? (y - 1, 12) : (y, m - 1);
  }
}

@riverpod
Stream<List<TransactionEntity>> monthTransactions(Ref ref, int year, int month) =>
    ref.watch(transactionRepositoryProvider).watchMonth(year, month);

@riverpod
Stream<MonthlySummary> monthSummary(Ref ref, int year, int month) =>
    ref.watch(transactionRepositoryProvider).watchSummary(year, month);

@riverpod
Stream<List<CategorySpendRow>> monthSpending(Ref ref, int year, int month) =>
    ref.watch(transactionRepositoryProvider).watchSpendingByCategory(year, month);

/// 日別リストは月streamからの派生（42セル×familyの乱造をしない。研究資料 §2c/2d）
@riverpod
AsyncValue<List<TransactionEntity>> dayTransactions(Ref ref, CivilDate day) =>
    ref
        .watch(monthTransactionsProvider(day.year, day.month))
        .whenData((txs) => txs.where((t) => t.date == day).toList());

@riverpod
AsyncValue<Map<CivilDate, int>> dayExpenseTotals(Ref ref, int year, int month) =>
    ref.watch(monthTransactionsProvider(year, month)).whenData((txs) {
      final map = <CivilDate, int>{};
      for (final t in txs) {
        if (t.type != TxnType.expense) continue;
        map[t.date] = (map[t.date] ?? 0) + t.amountYen;
      }
      return map;
    });
```

Create `lib/features/entry/application/entry_category_providers.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';

part 'entry_category_providers.g.dart';

@riverpod
Stream<Map<int, CivilDate>> categoryLastUsed(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watchLastUsedByCategory();

/// 高速入力のカテゴリグリッド: 最近使った順 → sortOrder順（spec §5.2）
@riverpod
AsyncValue<List<CategoryEntity>> entryCategories(Ref ref, TxnType type) {
  final lastUsed = ref.watch(categoryLastUsedProvider).valueOrNull ?? const <int, CivilDate>{};
  return ref.watch(allCategoriesProvider).whenData((all) {
    final wanted = categoryTypeOf(type);
    final list = all
        .where((c) => !c.isArchived && !c.isSystem && c.type == wanted)
        .toList();
    list.sort((a, b) {
      final ua = lastUsed[a.id];
      final ub = lastUsed[b.id];
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
}
```

- [ ] **Step 4: codegen** — Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(ui): calendar month/day providers and entry category ordering"
```

---

## Task 6: EntryFormController（フォーム状態機械）

**Files:**
- Create: `lib/features/entry/application/entry_form_controller.dart`
- Test: `test/providers/entry_form_controller_test.dart`

**Interfaces:**
- Consumes: `transactionRepositoryProvider`、`appSettingsProvider`、`receiptImagesDirProvider`、`ParsedReceipt`/`AmountCandidate`/`DateCandidate`（P3）
- Produces:
  ```dart
  enum EntryMode { create, receiptConfirm, edit }

  class EntryFormState {
    final EntryMode mode;
    final int? editingId;         // editのみ
    final TxnType type;
    final int amountYen;          // 0 = 未入力
    final int? categoryId;
    final CivilDate date;
    final String memo;
    final TxnSource source;
    final ParsedReceipt? receipt; // receiptConfirmのみ
    final String? imagePath;      // レシート一時画像
    final bool memoExpanded;
    bool get canSave;             // amountYen > 0 && categoryId != null
    AmountCandidate? get matchedTotalCandidate; // 現amountと一致する候補（手修正後はnull）
    DateCandidate? get matchedDateCandidate;
  }

  @Riverpod(keepAlive: true)
  class EntryFormController extends _$EntryFormController {
    EntryFormState? build();                      // 初期null（フォーム未表示）
    void startCreate(CivilDate date);
    void startEdit(TransactionEntity tx);
    void startReceipt(ParsedReceipt parsed, {String? imagePath});
    void tapDigit(int digit);                     // 上限 9,999,999
    void tapDoubleZero();
    void backspace();
    void setType(TxnType type);                   // 切替時 categoryId をクリア（spec §4.5）。編集モードでは無効（型不変。updateFieldsはtypeを書かないため）
    void selectCategory(int categoryId);
    void setDate(CivilDate date);
    void setMemo(String memo);
    void toggleMemoExpanded();
    void selectTotalCandidate(AmountCandidate c);
    void selectDateCandidate(DateCandidate c);
    Future<void> save();                          // add or update。receipt画像の破棄/保持もここ
    Future<void> saveAndContinue();               // date/memo/type維持、amount/categoryクリア
    Future<void> deleteEditing();
  }
  ```
  → `entryFormControllerProvider`
- 契約: `save()` は `canSave == false` なら `StateError`。edit の `save()` は `source`/`id` を変えない（P1 の `updateFields` 契約に乗る）。receiptConfirm の保存は `source = receiptOcr`。画像は保持設定OFF→削除・ON→`receiptImagesDir` へ移動しそのパスを保存（ファイル操作失敗は保存を止めない）。

- [ ] **Step 1: 失敗するテストを書く**

Create `test/providers/entry_form_controller_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

ParsedReceipt receiptOf({int? yen, required CivilDate date}) {
  final total = yen == null
      ? null
      : AmountCandidate(
          yen: yen,
          confidence: ExtractionConfidence.high,
          sourceText: '合計 ¥$yen',
          reason: 'total-label');
  final d = DateCandidate(
      date: date,
      confidence: ExtractionConfidence.high,
      sourceText: date.toIso(),
      reason: 'issue-date');
  return ParsedReceipt(
    total: total,
    totalCandidates: [if (total != null) total],
    date: d,
    dateCandidates: [d],
  );
}

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late int foodId;
  const day = CivilDate(2026, 7, 15);

  EntryFormController ctrl() => c.read(entryFormControllerProvider.notifier);
  EntryFormState st() => c.read(entryFormControllerProvider)!;

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
  });

  test('startCreate: 既定値とcanSave遷移', () {
    ctrl().startCreate(day);
    expect(st().mode, EntryMode.create);
    expect(st().type, TxnType.expense);
    expect(st().amountYen, 0);
    expect(st().canSave, isFalse);
    ctrl().tapDigit(5);
    expect(st().canSave, isFalse); // カテゴリ未選択
    ctrl().selectCategory(foodId);
    expect(st().canSave, isTrue);
  });

  test('テンキー: 累積・00・backspace・上限', () {
    ctrl().startCreate(day);
    ctrl().tapDigit(1);
    ctrl().tapDigit(2);
    ctrl().tapDoubleZero();
    expect(st().amountYen, 1200);
    ctrl().backspace();
    expect(st().amountYen, 120);
    for (var i = 0; i < 10; i++) {
      ctrl().tapDigit(9);
    }
    expect(st().amountYen, lessThanOrEqualTo(9999999));
    // amount=0 のとき00は無効
    ctrl().startCreate(day);
    ctrl().tapDoubleZero();
    expect(st().amountYen, 0);
  });

  test('setType でカテゴリ選択がクリアされる（spec §4.5）', () {
    ctrl().startCreate(day);
    ctrl().selectCategory(foodId);
    ctrl().setType(TxnType.income);
    expect(st().categoryId, isNull);
    expect(st().type, TxnType.income);
  });

  test('編集モードでは setType が無効（型/カテゴリdesync防止）', () async {
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 100, date: day,
        categoryId: foodId, source: TxnSource.manual));
    final tx = (await repo.forMonth(2026, 7)).single;
    ctrl().startEdit(tx);
    ctrl().setType(TxnType.income);
    expect(st().type, TxnType.expense);
    expect(st().categoryId, foodId);
  });

  test('save: 手入力が保存される（memo空はnull）', () async {
    ctrl().startCreate(day);
    ctrl().tapDigit(8);
    ctrl().selectCategory(foodId);
    await ctrl().save();
    final list = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(list.single.amountYen, 8);
    expect(list.single.source, TxnSource.manual);
    expect(list.single.memo, isNull);
  });

  test('canSave=false の save は StateError', () {
    ctrl().startCreate(day);
    expect(() => ctrl().save(), throwsStateError);
  });

  test('saveAndContinue: date/memo/type維持・amount/categoryクリア', () async {
    ctrl().startCreate(day);
    ctrl().tapDigit(5);
    ctrl().selectCategory(foodId);
    ctrl().setMemo('スーパーA');
    await ctrl().saveAndContinue();
    expect(st().mode, EntryMode.create);
    expect(st().amountYen, 0);
    expect(st().categoryId, isNull);
    expect(st().memo, 'スーパーA');
    expect(st().date, day);
  });

  test('startEdit -> save は update（id/source不変）', () async {
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 100, date: day,
        categoryId: foodId, source: TxnSource.receiptOcr));
    final tx = (await repo.forMonth(2026, 7)).single;
    ctrl().startEdit(tx);
    expect(st().mode, EntryMode.edit);
    expect(st().amountYen, 100);
    ctrl().backspace();
    ctrl().tapDigit(5); // 100 -> 10 -> 105
    await ctrl().save();
    final after = (await repo.forMonth(2026, 7)).single;
    expect(after.id, tx.id);
    expect(after.amountYen, 105);
    expect(after.source, TxnSource.receiptOcr);
  });

  test('deleteEditing で行が消える', () async {
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 100, date: day,
        categoryId: foodId, source: TxnSource.manual));
    final tx = (await repo.forMonth(2026, 7)).single;
    ctrl().startEdit(tx);
    await ctrl().deleteEditing();
    expect(await repo.forMonth(2026, 7), isEmpty);
  });

  test('startReceipt: プリフィルと候補切替・手修正でmatched解除', () {
    final parsed = receiptOf(yen: 1080, date: const CivilDate(2026, 7, 14));
    ctrl().startReceipt(parsed);
    expect(st().mode, EntryMode.receiptConfirm);
    expect(st().amountYen, 1080);
    expect(st().date, const CivilDate(2026, 7, 14));
    expect(st().source, TxnSource.receiptOcr);
    expect(st().matchedTotalCandidate, isNotNull);
    ctrl().tapDigit(0); // 手修正 10800
    expect(st().matchedTotalCandidate, isNull);
    ctrl().selectTotalCandidate(parsed.totalCandidates.single);
    expect(st().amountYen, 1080);
  });

  test('startReceipt: 合計なし→amount 0（空フォームフォールバック）', () {
    ctrl().startReceipt(receiptOf(yen: null, date: day));
    expect(st().amountYen, 0);
    expect(st().receipt!.total, isNull);
  });

  test('レシート保存: 保持OFFで一時画像が消える', () async {
    final tmp = File('${h.root.path}${Platform.pathSeparator}r1.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    ctrl().startReceipt(receiptOf(yen: 500, date: day), imagePath: tmp.path);
    ctrl().selectCategory(foodId);
    await ctrl().save();
    expect(tmp.existsSync(), isFalse);
    final tx = (await c.read(transactionRepositoryProvider).forMonth(2026, 7)).single;
    expect(tx.imagePath, isNull);
    expect(tx.source, TxnSource.receiptOcr);
  });

  test('レシート保存: 保持ONで画像がimagesDirへ移動しパスが残る', () async {
    await c.read(appSettingsProvider.notifier).setRetainReceiptImages(true);
    final tmp = File('${h.root.path}${Platform.pathSeparator}r2.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    ctrl().startReceipt(receiptOf(yen: 500, date: day), imagePath: tmp.path);
    ctrl().selectCategory(foodId);
    await ctrl().save();
    expect(tmp.existsSync(), isFalse);
    final tx = (await c.read(transactionRepositoryProvider).forMonth(2026, 7)).single;
    expect(tx.imagePath, isNotNull);
    expect(File(tx.imagePath!).existsSync(), isTrue);
    expect(tx.imagePath!, contains(h.imagesDir.path));
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/providers/entry_form_controller_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/entry/application/entry_form_controller.dart`:

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/receipt/receipt_parser.dart';
import '../../settings/application/settings_controller.dart';

part 'entry_form_controller.g.dart';

enum EntryMode { create, receiptConfirm, edit }

class EntryFormState {
  final EntryMode mode;
  final int? editingId;
  final TxnType type;
  final int amountYen;
  final int? categoryId;
  final CivilDate date;
  final String memo;
  final TxnSource source;
  final ParsedReceipt? receipt;
  final String? imagePath;
  final bool memoExpanded;

  const EntryFormState({
    required this.mode,
    this.editingId,
    required this.type,
    required this.amountYen,
    this.categoryId,
    required this.date,
    required this.memo,
    required this.source,
    this.receipt,
    this.imagePath,
    this.memoExpanded = false,
  });

  bool get canSave => amountYen > 0 && categoryId != null;

  AmountCandidate? get matchedTotalCandidate {
    final r = receipt;
    if (r == null) return null;
    for (final cand in r.totalCandidates) {
      if (cand.yen == amountYen) return cand;
    }
    return null;
  }

  DateCandidate? get matchedDateCandidate {
    final r = receipt;
    if (r == null) return null;
    for (final cand in r.dateCandidates) {
      if (cand.date == date) return cand;
    }
    return null;
  }

  static const _unset = Object();

  EntryFormState copyWith({
    EntryMode? mode,
    Object? editingId = _unset,
    TxnType? type,
    int? amountYen,
    Object? categoryId = _unset,
    CivilDate? date,
    String? memo,
    TxnSource? source,
    Object? receipt = _unset,
    Object? imagePath = _unset,
    bool? memoExpanded,
  }) =>
      EntryFormState(
        mode: mode ?? this.mode,
        editingId: identical(editingId, _unset) ? this.editingId : editingId as int?,
        type: type ?? this.type,
        amountYen: amountYen ?? this.amountYen,
        categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as int?,
        date: date ?? this.date,
        memo: memo ?? this.memo,
        source: source ?? this.source,
        receipt: identical(receipt, _unset) ? this.receipt : receipt as ParsedReceipt?,
        imagePath: identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
        memoExpanded: memoExpanded ?? this.memoExpanded,
      );
}

/// 入力フォームの状態機械。keepAlive: 画面push前のstart*()と画面buildの間で
/// autoDisposeされないようにする（画面は同時に1つしか開かない前提）。
@Riverpod(keepAlive: true)
class EntryFormController extends _$EntryFormController {
  static const int maxAmount = 9999999;

  @override
  EntryFormState? build() => null;

  void startCreate(CivilDate date) {
    state = EntryFormState(
      mode: EntryMode.create,
      type: TxnType.expense,
      amountYen: 0,
      date: date,
      memo: '',
      source: TxnSource.manual,
    );
  }

  void startEdit(TransactionEntity tx) {
    state = EntryFormState(
      mode: EntryMode.edit,
      editingId: tx.id,
      type: tx.type,
      amountYen: tx.amountYen,
      categoryId: tx.categoryId,
      date: tx.date,
      memo: tx.memo ?? '',
      source: tx.source,
      imagePath: tx.imagePath,
      memoExpanded: (tx.memo ?? '').isNotEmpty,
    );
  }

  void startReceipt(ParsedReceipt parsed, {String? imagePath}) {
    state = EntryFormState(
      mode: EntryMode.receiptConfirm,
      type: TxnType.expense,
      amountYen: parsed.total?.yen ?? 0,
      date: parsed.date.date,
      memo: '',
      source: TxnSource.receiptOcr,
      receipt: parsed,
      imagePath: imagePath,
    );
  }

  EntryFormState get _s => state!;

  void tapDigit(int digit) {
    assert(digit >= 0 && digit <= 9);
    final next = _s.amountYen * 10 + digit;
    if (next > maxAmount) return;
    state = _s.copyWith(amountYen: next);
  }

  void tapDoubleZero() {
    if (_s.amountYen == 0) return;
    final next = _s.amountYen * 100;
    if (next > maxAmount) return;
    state = _s.copyWith(amountYen: next);
  }

  void backspace() => state = _s.copyWith(amountYen: _s.amountYen ~/ 10);

  void setType(TxnType type) {
    // 編集では型不変: updateFieldsはtypeを書かないため、許すと型/カテゴリdesyncが永続化する（spec §4.3の不変条件を破る）
    if (_s.mode == EntryMode.edit) return;
    if (type == _s.type) return;
    state = _s.copyWith(type: type, categoryId: null); // 候補再フィルタ＋選択クリア
  }

  void selectCategory(int categoryId) => state = _s.copyWith(categoryId: categoryId);

  void setDate(CivilDate date) => state = _s.copyWith(date: date);

  void setMemo(String memo) => state = _s.copyWith(memo: memo);

  void toggleMemoExpanded() =>
      state = _s.copyWith(memoExpanded: !_s.memoExpanded);

  void selectTotalCandidate(AmountCandidate c) =>
      state = _s.copyWith(amountYen: c.yen);

  void selectDateCandidate(DateCandidate c) => state = _s.copyWith(date: c.date);

  Future<void> save() async {
    final s = _s;
    if (!s.canSave) throw StateError('金額とカテゴリが必要です');
    final repo = ref.read(transactionRepositoryProvider);
    final memo = s.memo.trim();
    if (s.mode == EntryMode.edit) {
      await repo.update(TransactionEntity(
        id: s.editingId,
        type: s.type,
        amountYen: s.amountYen,
        date: s.date,
        categoryId: s.categoryId!,
        memo: memo.isEmpty ? null : memo,
        source: s.source,
        imagePath: s.imagePath,
      ));
      return;
    }
    final storedImage = _finalizeReceiptImage(s);
    await repo.add(TransactionEntity(
      type: s.type,
      amountYen: s.amountYen,
      date: s.date,
      categoryId: s.categoryId!,
      memo: memo.isEmpty ? null : memo,
      source: s.source,
      imagePath: storedImage,
    ));
  }

  Future<void> saveAndContinue() async {
    await save();
    final s = _s;
    state = EntryFormState(
      mode: EntryMode.create,
      type: s.type,
      amountYen: 0,
      date: s.date,
      memo: s.memo,
      source: TxnSource.manual,
      memoExpanded: s.memoExpanded,
    );
  }

  Future<void> deleteEditing() async {
    final id = _s.editingId;
    if (id == null) throw StateError('編集中の取引がありません');
    await ref.read(transactionRepositoryProvider).delete(id);
  }

  /// レシート一時画像の後始末（spec §7.6 / §14-C）。
  /// 保持OFF: 削除して null。保持ON: receiptImagesDir へ移動してそのパス。
  /// ファイル操作の失敗は保存をブロックしない（null にフォールバック）。
  String? _finalizeReceiptImage(EntryFormState s) {
    final path = s.imagePath;
    if (s.mode != EntryMode.receiptConfirm || path == null) return null;
    final file = File(path);
    try {
      if (!file.existsSync()) return null;
      if (!ref.read(appSettingsProvider).retainReceiptImages) {
        file.deleteSync();
        return null;
      }
      final dir = ref.read(receiptImagesDirProvider)..createSync(recursive: true);
      final dest =
          '${dir.path}${Platform.pathSeparator}${file.uri.pathSegments.last}';
      file.renameSync(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: codegen** — Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(entry): entry form state machine with 3 modes and receipt image lifecycle"
```

## Task 7: 高速入力UI（テンキー・カテゴリグリッド・EntryScreen）

**Files:**
- Create: `lib/features/entry/presentation/numpad.dart`, `lib/features/entry/presentation/category_grid.dart`, `lib/features/entry/presentation/entry_screen.dart`
- Test: `test/ui/entry_screen_test.dart`

**Interfaces:**
- Consumes: `entryFormControllerProvider`（Task 6）、`entryCategoriesProvider`（Task 5）、`formatYen`/`dateTimeOfCivil`/`civilOfDateTime`（Task 4）
- Produces:
  - `class Numpad extends StatelessWidget` — `Numpad({required void Function(int) onDigit, required VoidCallback onDoubleZero, required VoidCallback onBackspace})`。キー配列 1..9 / 00 / 0 / ⌫（`Key('np-00')` `Key('np-0')` `Key('np-back')`）
  - `class CategoryGrid extends ConsumerWidget` — `CategoryGrid({required TxnType type, required int? selectedId, required void Function(int) onSelect})`
  - `class EntryScreen extends ConsumerWidget` — `entryFormControllerProvider` の state を描画。state==null なら空Scaffold。AppBarタイトル: create='入力' / receiptConfirm='レシート確認' / edit='編集'。editではAppBarに削除ボタン（`Key('delete-entry')`、確認ダイアログ→`deleteEditing()`→pop）
  - UI仕様（spec §5.2/5.3/5.4）: 必須は金額＋カテゴリのみ。日付タイルは**常に表示**（`Key('date-tile')`、タップで `showDatePicker`）。memoは折りたたみ（`Key('memo-toggle')`→`Key('memo-field')`）。ボタンは `Key('save-btn')`='保存'（成功でpop）と、create・receiptConfirmモードで `Key('save-continue-btn')`='保存して続ける'（画面に留まりSnackBar'保存しました'。spec §7.4: レシート分割入力のため日付/メモを引き継いでcreateへ戻る）。編集では型トグル（SegmentedButton）を表示しない（型不変）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/ui/entry_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

/// EntryScreen はpushして開く（popの検証のため）。
class Host extends ConsumerWidget {
  final void Function(WidgetRef ref) onOpen;
  const Host({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              onOpen(ref);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EntryScreen()));
            },
            child: const Text('open'),
          ),
        ),
      );
}

void main() {
  testWidgets('新規入力: テンキー→カテゴリ→保存でpopし、DBに入る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(onOpen: (ref) =>
            ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    final container = ProviderScope.containerOf(
        tester.element(find.byType(Host)), listen: false);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('入力'), findsOneWidget);
    expect(find.text('2026/07/15'), findsOneWidget); // 日付は常に表示

    // 保存はamount+categoryが揃うまで無効
    expect(tester.widget<FilledButton>(
        find.byKey(const Key('save-btn'))).onPressed, isNull);

    await tester.tap(find.text('5'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();
    expect(find.text('¥500'), findsOneWidget);

    await tester.tap(find.text('食費'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget); // popして戻った
    final list = await container.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(list.single.amountYen, 500);
  });

  testWidgets('収入へ切替でカテゴリ候補が変わり選択がクリアされる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(onOpen: (ref) =>
            ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('食費'));
    await tester.pump();
    await tester.tap(find.text('収入'));
    await tester.pumpAndSettle();
    expect(find.text('給与'), findsOneWidget);
    expect(find.text('食費'), findsNothing);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(Host)), listen: false);
    expect(container.read(entryFormControllerProvider)!.categoryId, isNull);
  });

  testWidgets('メモは折りたたみ→展開で入力できる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(onOpen: (ref) =>
            ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memo-field')), findsNothing);
    await tester.tap(find.byKey(const Key('memo-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('memo-field')), 'スーパーA');
    final container = ProviderScope.containerOf(
        tester.element(find.byType(Host)), listen: false);
    expect(container.read(entryFormControllerProvider)!.memo, 'スーパーA');
  });

  testWidgets('保存して続ける: 画面に留まり金額リセット・日付維持', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(onOpen: (ref) =>
            ref.read(entryFormControllerProvider.notifier).startCreate(day)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('8'));
    await tester.tap(find.text('食費'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-continue-btn')));
    await tester.pumpAndSettle();

    expect(find.text('入力'), findsOneWidget); // 留まっている
    expect(find.text('保存しました'), findsOneWidget); // SnackBar
    expect(find.text('¥0'), findsOneWidget); // 金額リセット
    expect(find.text('2026/07/15'), findsOneWidget); // 日付維持

    // SnackBarの自動消滅Timer(既定4s)をFakeAsyncで消化（pending timer検出での失敗を回避）
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('編集モード: 値ロード・削除ボタン（確認つき）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    late TransactionEntity seeded;
    await pumpApp(tester, h,
        home: Host(onOpen: (ref) =>
            ref.read(entryFormControllerProvider.notifier).startEdit(seeded)));
    final container = ProviderScope.containerOf(
        tester.element(find.byType(Host)), listen: false);
    final repo = container.read(transactionRepositoryProvider);
    final cats = await waitForData(container, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 1200, date: day,
        categoryId: foodId, source: TxnSource.manual, memo: '弁当'));
    seeded = (await repo.forMonth(2026, 7)).single;

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('編集'), findsOneWidget);
    expect(find.text('¥1,200'), findsOneWidget);
    expect(find.byKey(const Key('memo-field')), findsOneWidget); // memoありは展開済み

    await tester.tap(find.byKey(const Key('delete-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(await repo.forMonth(2026, 7), isEmpty);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/entry_screen_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/entry/presentation/numpad.dart`:

```dart
import 'package:flutter/material.dart';

class Numpad extends StatelessWidget {
  final void Function(int digit) onDigit;
  final VoidCallback onDoubleZero;
  final VoidCallback onBackspace;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onDoubleZero,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child, VoidCallback onTap, {Key? key}) => Expanded(
          child: InkWell(
            key: key,
            onTap: onTap,
            child: SizedBox(height: 56, child: Center(child: child)),
          ),
        );
    Widget digit(int d, {Key? key}) => cell(
        Text('$d', style: const TextStyle(fontSize: 24)), () => onDigit(d),
        key: key);

    return Column(children: [
      Row(children: [digit(1), digit(2), digit(3)]),
      Row(children: [digit(4), digit(5), digit(6)]),
      Row(children: [digit(7), digit(8), digit(9)]),
      Row(children: [
        cell(const Text('00', style: TextStyle(fontSize: 24)), onDoubleZero,
            key: const Key('np-00')),
        digit(0, key: const Key('np-0')),
        cell(const Icon(Icons.backspace_outlined), onBackspace,
            key: const Key('np-back')),
      ]),
    ]);
  }
}
```

Create `lib/features/entry/presentation/category_grid.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/enums.dart';
import '../application/entry_category_providers.dart';

class CategoryGrid extends ConsumerWidget {
  final TxnType type;
  final int? selectedId;
  final void Function(int categoryId) onSelect;

  const CategoryGrid({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(entryCategoriesProvider(type)).valueOrNull ?? const [];
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
          InkWell(
            onTap: () => onSelect(c.id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: c.id == selectedId
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                border: c.id == selectedId
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.icon ?? '📁', style: const TextStyle(fontSize: 18)),
                  Text(c.name,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

Create `lib/features/entry/presentation/entry_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../data/db/enums.dart';
import '../application/entry_form_controller.dart';
import 'category_grid.dart';
import 'numpad.dart';

class EntryScreen extends ConsumerWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryFormControllerProvider);
    if (state == null) return const Scaffold(body: SizedBox());
    final ctrl = ref.read(entryFormControllerProvider.notifier);

    final title = switch (state.mode) {
      EntryMode.create => '入力',
      EntryMode.receiptConfirm => 'レシート確認',
      EntryMode.edit => '編集',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (state.mode == EntryMode.edit)
            IconButton(
              key: const Key('delete-entry'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 編集では型不変（DBのupdateFieldsがtypeを書かない。返品はspec §4.4の運用で表現）
              if (state.mode != EntryMode.edit)
                SegmentedButton<TxnType>(
                  segments: const [
                    ButtonSegment(value: TxnType.expense, label: Text('支出')),
                    ButtonSegment(value: TxnType.income, label: Text('収入')),
                  ],
                  selected: {state.type},
                  onSelectionChanged: (s) => ctrl.setType(s.single),
                ),
              ListTile(
                key: const Key('date-tile'),
                dense: true,
                leading: const Icon(Icons.event),
                title: Text(_dateLabel(state.date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateTimeOfCivil(state.date),
                    firstDate: DateTime(2000, 1, 1),
                    lastDate: DateTime(2100, 12, 31),
                  );
                  if (picked != null) ctrl.setDate(civilOfDateTime(picked));
                },
              ),
              Container(
                key: const Key('amount-display'),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                alignment: Alignment.centerRight,
                child: Text(
                  state.amountYen == 0 ? '¥0' : formatYen(state.amountYen),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Numpad(
                onDigit: ctrl.tapDigit,
                onDoubleZero: ctrl.tapDoubleZero,
                onBackspace: ctrl.backspace,
              ),
              const SizedBox(height: 8),
              CategoryGrid(
                type: state.type,
                selectedId: state.categoryId,
                onSelect: ctrl.selectCategory,
              ),
              const SizedBox(height: 8),
              if (state.memoExpanded)
                TextFormField(
                  key: const Key('memo-field'),
                  initialValue: state.memo,
                  decoration: const InputDecoration(
                    labelText: 'メモ・店名',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: ctrl.setMemo,
                )
              else
                TextButton.icon(
                  key: const Key('memo-toggle'),
                  onPressed: ctrl.toggleMemoExpanded,
                  icon: const Icon(Icons.notes),
                  label: const Text('メモを追加'),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('save-btn'),
                    onPressed: state.canSave
                        ? () async {
                            await ctrl.save();
                            if (context.mounted) Navigator.pop(context);
                          }
                        : null,
                    child: const Text('保存'),
                  ),
                ),
                if (state.mode != EntryMode.edit) ...[ // create + receiptConfirm（spec §7.4 分割入力）
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('save-continue-btn'),
                      onPressed: state.canSave
                          ? () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await ctrl.saveAndContinue();
                              messenger.showSnackBar(
                                  const SnackBar(content: Text('保存しました')));
                            }
                          : null,
                      child: const Text('保存して続ける'),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この取引を削除します。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(entryFormControllerProvider.notifier).deleteEditing();
    if (context.mounted) Navigator.pop(context);
  }
}
```

（`_dateLabel` の引数型は `CivilDate` を明示: `String _dateLabel(CivilDate date)`。import 済み `domain/money/civil_date.dart` を追加。）

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(entry): quick-entry screen with numpad, category grid, 3-mode form"
```

---

## Task 8: カレンダー画面（table_calendar・日別リスト・FAB）

**Files:**
- Create: `lib/features/calendar/presentation/calendar_screen.dart`, `lib/features/calendar/presentation/day_transaction_list.dart`
- Modify: `lib/app/home_shell.dart`（タブ0を `CalendarScreen` に差し替え、FAB追加）
- Test: `test/ui/calendar_screen_test.dart`

**Interfaces:**
- Consumes: Task 5 providers、`EntryScreen`/`entryFormControllerProvider`、`compactYen`/`formatYen`/`signedYen`、`dateTimeOfCivil`/`civilOfDateTime`
- Produces:
  - `class CalendarScreen extends ConsumerWidget` — 月ヘッダ（`Key('prev-month')`/`Key('next-month')`、`'$year年$month月'`、支出/収入/差引）＋ `TableCalendar`（`headerVisible: false`、`outsideDaysVisible: false`、markerBuilderで `compactYen` を日セルに表示）＋ 選択日の `DayTransactionList`
  - `class DayTransactionList extends ConsumerWidget` — `DayTransactionList({required CivilDate day})`。tap=編集（`startEdit`→push EntryScreen）、swipe(endToStart)=削除＋SnackBar『元に戻す』（Undo=同内容を再add。**注: idとcreatedAtは新規になる。v1の既知の限界**）。空状態=『この日の記録はありません』＋`Key('add-on-day')`『この日に追加』
  - HomeShell: タブ0で `Key('fab-entry')` のFAB表示。タップで `startCreate(selectedDay)`→push EntryScreen（spec §5.3: 選択日が既定）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/ui/calendar_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;

  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    setPhoneSurface(tester);
    h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    return ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
  }

  Future<int> seed(ProviderContainer c, int yen,
      {int day = 15, TxnType type = TxnType.expense, String? memo}) async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    return c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: type, amountYen: yen, date: CivilDate(2026, 7, day),
        categoryId: foodId, source: TxnSource.manual, memo: memo));
  }

  testWidgets('月ヘッダ: 年月と支出/収入/差引、chevronで月移動', (tester) async {
    final c = await pumpShell(tester);
    await seed(c, 500);
    await seed(c, 2000, type: TxnType.income);
    await tester.pumpAndSettle();

    expect(find.text('2026年7月'), findsOneWidget);
    expect(find.textContaining('支出 ¥500'), findsOneWidget);
    expect(find.textContaining('収入 ¥2,000'), findsOneWidget);
    expect(find.textContaining('差引 +¥1,500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026年8月'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prev-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026年7月'), findsOneWidget);
  });

  testWidgets('日セルに支出のみの略記マーカーが出る', (tester) async {
    final c = await pumpShell(tester);
    await seed(c, 12345, day: 20);
    await tester.pumpAndSettle();
    expect(find.text('¥12k'), findsOneWidget);
  });

  testWidgets('日タップでその日のリスト、tap=編集・swipe=削除+Undo', (tester) async {
    final c = await pumpShell(tester);
    await seed(c, 800, day: 16, memo: 'コンビニ');
    await tester.pumpAndSettle();

    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    expect(find.text('コンビニ'), findsOneWidget);
    expect(find.text('-¥800'), findsOneWidget);

    // tap -> 編集画面
    await tester.tap(find.text('コンビニ'));
    await tester.pumpAndSettle();
    expect(find.text('編集'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // swipe -> 削除 + Undo
    await tester.drag(find.text('コンビニ'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('削除しました'), findsOneWidget);
    expect(await c.read(transactionRepositoryProvider).forMonth(2026, 7), isEmpty);
    await tester.tap(find.text('元に戻す'));
    await tester.pumpAndSettle();
    final restored = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(restored.single.amountYen, 800);
  });

  testWidgets('空の日: 「この日に追加」から選択日既定で入力が開く', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    expect(find.textContaining('記録はありません'), findsOneWidget);
    expect(find.text('右下の＋から最初の記録を追加できます'), findsOneWidget); // 空カレンダーCTA（spec §5.5）
    await tester.tap(find.byKey(const Key('add-on-day')));
    await tester.pumpAndSettle();
    expect(find.text('入力'), findsOneWidget);
    expect(find.text('2026/07/20'), findsOneWidget); // 選択日が既定（spec §5.3）
  });

  testWidgets('FAB: 選択日を既定に入力を開く', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fab-entry')));
    await tester.pumpAndSettle();
    expect(find.text('入力'), findsOneWidget);
    expect(find.text('2026/07/18'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/calendar_screen_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/calendar/presentation/day_transaction_list.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../entry/application/entry_form_controller.dart';
import '../../entry/presentation/entry_screen.dart';
import '../application/calendar_providers.dart';

class DayTransactionList extends ConsumerWidget {
  final CivilDate day;
  const DayTransactionList({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(dayTransactionsProvider(day)).valueOrNull ?? const [];
    final cats = ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final byId = {for (final c in cats) c.id: c};
    final scheme = Theme.of(context).colorScheme;
    // 月全体が空＝初回/空カレンダー状態。FABへの誘導CTAを足す（spec §5.5）
    final monthEmpty =
        (ref.watch(monthTransactionsProvider(day.year, day.month)).valueOrNull ??
                const [])
            .isEmpty;

    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${day.month}月${day.day}日の記録はありません'),
            TextButton.icon(
              key: const Key('add-on-day'),
              icon: const Icon(Icons.add),
              label: const Text('この日に追加'),
              onPressed: () => _openCreate(context, ref),
            ),
            if (monthEmpty)
              Text('右下の＋から最初の記録を追加できます',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (context, i) {
        final tx = txs[i];
        final cat = byId[tx.categoryId];
        final name = cat == null
            ? '不明'
            : cat.isArchived
                ? '${cat.name}（アーカイブ）'
                : cat.name;
        return Dismissible(
          key: ValueKey('tx-${tx.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: scheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: scheme.onError),
          ),
          onDismissed: (_) => _deleteWithUndo(context, ref, tx),
          child: ListTile(
            leading: Text(cat?.icon ?? '📁', style: const TextStyle(fontSize: 20)),
            title: Text(name),
            subtitle:
                (tx.memo != null && tx.memo!.isNotEmpty) ? Text(tx.memo!) : null,
            trailing: Text(
              signedYen(tx.type, tx.amountYen),
              style: TextStyle(
                color: tx.type == TxnType.expense ? scheme.error : scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              ref.read(entryFormControllerProvider.notifier).startEdit(tx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    fullscreenDialog: true, builder: (_) => const EntryScreen()),
              );
            },
          ),
        );
      },
    );
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    ref.read(entryFormControllerProvider.notifier).startCreate(day);
    Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => const EntryScreen()),
    );
  }

  /// Undo は同内容の再add（id/createdAtは新規になる: v1の既知の限界）
  void _deleteWithUndo(
      BuildContext context, WidgetRef ref, TransactionEntity tx) {
    final repo = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    repo.delete(tx.id!);
    messenger.showSnackBar(SnackBar(
      content: const Text('削除しました'),
      action: SnackBarAction(label: '元に戻す', onPressed: () => repo.add(tx)),
    ));
  }
}
```

Create `lib/features/calendar/presentation/calendar_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../application/calendar_providers.dart';
import 'day_transaction_list.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (year, month) = ref.watch(currentMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final summary = ref.watch(monthSummaryProvider(year, month)).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final totals = ref.watch(dayExpenseTotalsProvider(year, month)).valueOrNull ??
        const <CivilDate, int>{};

    return SafeArea(
      child: Column(
        children: [
          _MonthHeader(year: year, month: month, summary: summary),
          TableCalendar<int>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: dateTimeOfCivil(CivilDate(year, month, 1)),
            headerVisible: false,
            rowHeight: 56,
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            selectedDayPredicate: (d) => civilOfDateTime(d) == selected,
            onDaySelected: (sel, _) =>
                ref.read(selectedDayProvider.notifier).select(civilOfDateTime(sel)),
            onPageChanged: (focused) => ref
                .read(currentMonthProvider.notifier)
                .set(focused.year, focused.month),
            eventLoader: (d) {
              final t = totals[civilOfDateTime(d)] ?? 0;
              return t > 0 ? [t] : const [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 2,
                  child: Text(
                    compactYen(events.first),
                    style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.error),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: DayTransactionList(day: selected)),
        ],
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  final int year;
  final int month;
  final MonthlySummary summary;
  const _MonthHeader(
      {required this.year, required this.month, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = summary.net;
    final netLabel = net >= 0 ? '+${formatYen(net)}' : formatYen(net);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('prev-month'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(currentMonthProvider.notifier).prev(),
          ),
          Expanded(
            child: Column(
              children: [
                Text('$year年$month月',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '支出 ${formatYen(summary.expense)}　収入 ${formatYen(summary.income)}　差引 $netLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('next-month'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(currentMonthProvider.notifier).next(),
          ),
        ],
      ),
    );
  }
}
```

Modify `lib/app/home_shell.dart` — import を追加し、タブ0とFABを差し替え:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/calendar/application/calendar_providers.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/entry/application/entry_form_controller.dart';
import '../features/entry/presentation/entry_screen.dart';
```

`IndexedStack` の children 先頭を `const CalendarScreen(),` に変更し、`Scaffold` に追加:

```dart
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                key: const Key('fab-entry'),
                onPressed: () {
                  ref
                      .read(entryFormControllerProvider.notifier)
                      .startCreate(ref.read(selectedDayProvider));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const EntryScreen()),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
```

`test/ui/home_shell_test.dart` の `(カレンダー 準備中)` の期待は `CalendarScreen` の実表示（例: `find.text('2026年7月')`）に更新する。

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(calendar): calendar home with day markers, day list, swipe-delete undo, FAB"
```

---

## Task 9: サマリ画面（月次合計＋カテゴリ別内訳）

**Files:**
- Create: `lib/features/summary/presentation/summary_screen.dart`
- Modify: `lib/app/home_shell.dart`（タブ1を `SummaryScreen` に差し替え）, `test/ui/home_shell_test.dart`（`(サマリ 準備中)` 期待が陳腐化するため実画面の検証に更新）
- Test: `test/ui/summary_screen_test.dart`

**Interfaces:**
- Consumes: `currentMonthProvider`（カレンダーと共有＝タブ間で月が一致）、`monthSummaryProvider`、`monthSpendingProvider`、`formatYen`
- Produces: `class SummaryScreen extends ConsumerWidget` — ヘッダ（`Key('summary-prev')`/`Key('summary-next')`・`'$year年$month月'`）、合計カード（収入/支出/差引）、カテゴリ別内訳（降順・構成比%・`LinearProgressIndicator`・アーカイブ済みは『（アーカイブ）』を付す）、空状態『この月のデータはまだありません』

- [ ] **Step 1: 失敗するテストを書く**

Create `test/ui/summary_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('サマリタブ: 合計と内訳（降順・アーカイブラベル）・空状態', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);

    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final hobbyId = cats.firstWhere((x) => x.name == '趣味・娯楽').id;
    final salaryId = cats.firstWhere((x) => x.name == '給与').id;
    final repo = c.read(transactionRepositoryProvider);
    Future<void> add(int yen, int catId, TxnType type) => repo.add(
        TransactionEntity(type: type, amountYen: yen,
            date: const CivilDate(2026, 7, 10), categoryId: catId,
            source: TxnSource.manual));
    await add(3000, foodId, TxnType.expense);
    await add(1000, hobbyId, TxnType.expense);
    await add(50000, salaryId, TxnType.income);
    await c.read(categoryRepositoryProvider).setArchived(hobbyId, true);

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();

    expect(find.text('2026年7月'), findsOneWidget);
    expect(find.text('+¥50,000'), findsOneWidget);   // 収入
    expect(find.text('-¥4,000'), findsOneWidget);    // 支出
    expect(find.text('+¥46,000'), findsOneWidget);   // 差引
    expect(find.text('食費'), findsOneWidget);
    expect(find.text('趣味・娯楽（アーカイブ）'), findsOneWidget); // §4.3: 集計には残す
    expect(find.text('75%'), findsOneWidget); // 3000/4000

    // 内訳は金額降順: 食費が趣味より上
    final foodY = tester.getTopLeft(find.text('食費')).dy;
    final hobbyY = tester.getTopLeft(find.text('趣味・娯楽（アーカイブ）')).dy;
    expect(foodY, lessThan(hobbyY));

    // 空月へ移動すると空状態
    await tester.tap(find.byKey(const Key('summary-next')));
    await tester.pumpAndSettle();
    expect(find.text('この月のデータはまだありません'), findsOneWidget);
    expect(find.text('カレンダーの＋から入力できます'), findsOneWidget); // 入力導線（spec §5.5）
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/summary_screen_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/summary/presentation/summary_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../data/db/daos.dart' show CategorySpendRow;
import '../../../domain/entities.dart';
import '../../calendar/application/calendar_providers.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (year, month) = ref.watch(currentMonthProvider);
    final summary = ref.watch(monthSummaryProvider(year, month)).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final spending =
        ref.watch(monthSpendingProvider(year, month)).valueOrNull ??
            const <CategorySpendRow>[];
    final isEmpty = summary.income == 0 && summary.expense == 0;

    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('summary-prev'),
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    ref.read(currentMonthProvider.notifier).prev(),
              ),
              Expanded(
                child: Text('$year年$month月',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                key: const Key('summary-next'),
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    ref.read(currentMonthProvider.notifier).next(),
              ),
            ],
          ),
          if (isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('この月のデータはまだありません'),
                    const SizedBox(height: 4),
                    Text('カレンダーの＋から入力できます', // spec §5.5 空サマリの入力導線
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _totalRow(context, '収入', '+${formatYen(summary.income)}'),
                          _totalRow(context, '支出', '-${formatYen(summary.expense)}'),
                          const Divider(),
                          _totalRow(
                            context,
                            '差引',
                            summary.net >= 0
                                ? '+${formatYen(summary.net)}'
                                : formatYen(summary.net),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('カテゴリ別支出',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final row in spending)
                    _SpendRow(row: row, grandTotal: summary.expense),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, String value,
          {bool emphasize = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value,
                style: emphasize
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}

class _SpendRow extends StatelessWidget {
  final CategorySpendRow row;
  final int grandTotal;
  const _SpendRow({required this.row, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    final ratio = grandTotal == 0 ? 0.0 : row.total / grandTotal;
    final name = row.isArchived ? '${row.categoryName}（アーカイブ）' : row.categoryName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              Text(formatYen(row.total)),
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
          LinearProgressIndicator(value: ratio, minHeight: 6),
        ],
      ),
    );
  }
}
```

Modify `lib/app/home_shell.dart` — import `../features/summary/presentation/summary_screen.dart` を追加し、`IndexedStack` の2番目を `const SummaryScreen(),` に差し替え。

`test/ui/home_shell_test.dart` — `expect(find.text('(サマリ 準備中)'), findsOneWidget);` を `expect(find.byKey(const Key('summary-next')), findsOneWidget);` に置き換える（プレースホルダが消えるため。Task 8のカレンダー分と同じ手当て）。

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(summary): monthly summary tab with category breakdown"
```

## Task 10: レシート確認フロー（撮影→OCR→プリフィル→候補切替）

**Files:**
- Create: `lib/features/entry/presentation/receipt_review_panel.dart`
- Modify: `lib/features/entry/presentation/entry_screen.dart`（スキャンボタン＋パネル＋確信度ハイライト）
- Modify: `test/support/test_app.dart`（`FakeReceiptCapture` 追加）
- Test: `test/ui/receipt_review_test.dart`

**Interfaces:**
- Consumes: `receiptCaptureProvider`/`ocrServiceProvider`/`receiptParserProvider`（Task 1）、`entryFormControllerProvider.startReceipt / selectTotalCandidate / selectDateCandidate / matchedTotalCandidate / matchedDateCandidate`（Task 6）
- Produces:
  - `class ReceiptReviewPanel extends ConsumerWidget` — `ReceiptReviewPanel({required EntryFormState state})`。画像プレビュー（パスが実在すれば `Image.file`、なければ「画像なし」プレート）／読み取り失敗注記（`Key('ocr-fallback-note')`、spec §6.2の空フォームフォールバック）／金額候補 `ChoiceChip` 列（`formatYen`表示、タップで `selectTotalCandidate`）／日付候補 `ChoiceChip` 列（ISO表示、`selectDateCandidate`）
  - `Color? confidenceTint(ExtractionConfidence? c)` — high=緑 / medium=琥珀 / low=赤 の淡色。null（手修正済み・非receiptモード）は無色。EntryScreen の金額表示と日付タイルの背景に適用（spec §7.5の欄ハイライト）
  - EntryScreen: createモードのAppBarに `Key('scan-receipt')` ボタン。ハンドラ: `capture()` null→SnackBar『この端末ではレシート撮影を利用できません』／成功→ `recognize(path)`→`parse(blocks)`→`startReceipt(parsed, imagePath: path)`。例外はSnackBar『読み取りに失敗しました』でcreateに留まる
  - `class FakeReceiptCapture implements ReceiptCapture`（test_app.dart）— `FakeReceiptCapture(String? path)` 固定パスを返す
- **Global Constraints の例外**: `receipt_review_panel.dart` のみ presentation 層での `dart:io` import を許可（`Image.file` の `File` 生成のため）。

- [ ] **Step 1: 失敗するテストを書く**

`test/support/test_app.dart` に追加:

```dart
class FakeReceiptCapture implements ReceiptCapture {
  final String? path;
  const FakeReceiptCapture(this.path);
  @override
  Future<String?> capture() async => path;
}
```

Create `test/ui/receipt_review_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

const day = CivilDate(2026, 7, 15);

/// 「合計 ¥1,080」「2026/07/14 12:34」を含む正準ブロック列（P3のパーサが抽出できる形）
const goodBlocks = [
  OcrBlock(text: 'スーパーA', rect: OcrRect(0.1, 0.05, 0.5, 0.03), confidence: 0.9),
  OcrBlock(text: '2026/07/14 12:34', rect: OcrRect(0.1, 0.12, 0.5, 0.03), confidence: 0.95),
  OcrBlock(text: '合計 ¥1,080', rect: OcrRect(0.1, 0.5, 0.8, 0.03), confidence: 0.99),
];

void main() {
  testWidgets('スキャン成功: レシート確認モードでプリフィルされる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final img = File('${h.root.path}${Platform.pathSeparator}cap.jpg')
      ..writeAsBytesSync([1]);
    await pumpApp(tester, h,
        home: const EntryScreen(),
        extra: [
          receiptCaptureProvider.overrideWith((ref) => FakeReceiptCapture(img.path)),
          ocrServiceProvider.overrideWith((ref) => const FakeOcrService(goodBlocks)),
        ]);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(EntryScreen)), listen: false);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-receipt')));
    await tester.pumpAndSettle();

    expect(find.text('レシート確認'), findsOneWidget);
    expect(find.text('¥1,080'), findsWidgets); // 金額表示＋候補chip
    expect(find.text('2026/07/14'), findsOneWidget); // 日付プリフィル
  });

  testWidgets('候補切替: chipタップで金額・日付が変わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen());
    final c = ProviderScope.containerOf(
        tester.element(find.byType(EntryScreen)), listen: false);

    const cand1 = AmountCandidate(
        yen: 1080, confidence: ExtractionConfidence.high,
        sourceText: '合計 ¥1,080', reason: 'total');
    const cand2 = AmountCandidate(
        yen: 980, confidence: ExtractionConfidence.medium,
        sourceText: '¥980', reason: 'max-fallback');
    const d1 = DateCandidate(
        date: CivilDate(2026, 7, 14), confidence: ExtractionConfidence.high,
        sourceText: '2026/07/14', reason: 'issue');
    const d2 = DateCandidate(
        date: CivilDate(2026, 7, 13), confidence: ExtractionConfidence.medium,
        sourceText: '2026/07/13', reason: 'other');
    const parsed = ParsedReceipt(
        total: cand1, totalCandidates: [cand1, cand2],
        date: d1, dateCandidates: [d1, d2]);
    c.read(entryFormControllerProvider.notifier).startReceipt(parsed);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '¥980'));
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.amountYen, 980);

    await tester.tap(find.widgetWithText(ChoiceChip, '2026-07-13'));
    await tester.pumpAndSettle();
    expect(c.read(entryFormControllerProvider)!.date, const CivilDate(2026, 7, 13));
  });

  testWidgets('OCR空: 金額0＋注記＋今日既定（空フォームフォールバック）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final img = File('${h.root.path}${Platform.pathSeparator}cap2.jpg')
      ..writeAsBytesSync([1]);
    await pumpApp(tester, h,
        home: const EntryScreen(),
        extra: [
          receiptCaptureProvider.overrideWith((ref) => FakeReceiptCapture(img.path)),
          // 既定harness = FakeOcrService(const []) → 候補なし
        ]);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(EntryScreen)), listen: false);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-receipt')));
    await tester.pumpAndSettle();
    expect(find.text('レシート確認'), findsOneWidget);
    expect(find.text('¥0'), findsOneWidget);
    expect(find.byKey(const Key('ocr-fallback-note')), findsOneWidget);
    expect(find.text('2026/07/15'), findsOneWidget); // 今日既定（固定時計）
  });

  testWidgets('撮影未対応: SnackBarでcreateに留まる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const EntryScreen()); // 既定=Unavailable
    final c = ProviderScope.containerOf(
        tester.element(find.byType(EntryScreen)), listen: false);
    c.read(entryFormControllerProvider.notifier).startCreate(day);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-receipt')));
    await tester.pumpAndSettle();
    expect(find.text('この端末ではレシート撮影を利用できません'), findsOneWidget);
    expect(find.text('入力'), findsOneWidget);

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/receipt_review_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/entry/presentation/receipt_review_panel.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../domain/services/receipt/receipt_parser.dart';
import '../application/entry_form_controller.dart';

/// 確信度tier→ハイライト色（spec §7.5）。nullは無色（手修正済み等）。
Color? confidenceTint(ExtractionConfidence? c) => switch (c) {
      null => null,
      ExtractionConfidence.high => const Color(0x2632A854),
      ExtractionConfidence.medium => const Color(0x33FFB300),
      ExtractionConfidence.low => const Color(0x26E53935),
    };

class ReceiptReviewPanel extends ConsumerWidget {
  final EntryFormState state;
  const ReceiptReviewPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = state.receipt;
    if (receipt == null) return const SizedBox.shrink();
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final path = state.imagePath;
    final hasImage = path != null && File(path).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path),
                height: 140, width: double.infinity, fit: BoxFit.cover),
          )
        else
          Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('画像なし'),
          ),
        if (receipt.total == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '金額を読み取れませんでした。手入力してください',
              key: const Key('ocr-fallback-note'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (receipt.totalCandidates.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final cand in receipt.totalCandidates)
                ChoiceChip(
                  label: Text(formatYen(cand.yen)),
                  selected: identical(state.matchedTotalCandidate, cand),
                  onSelected: (_) => ctrl.selectTotalCandidate(cand),
                ),
            ],
          ),
        ],
        if (receipt.dateCandidates.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final cand in receipt.dateCandidates)
                ChoiceChip(
                  label: Text(cand.date.toIso()),
                  selected: identical(state.matchedDateCandidate, cand),
                  onSelected: (_) => ctrl.selectDateCandidate(cand),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
```

Modify `lib/features/entry/presentation/entry_screen.dart`:

1. import 追加: `receipt_review_panel.dart`、`../../../app/providers.dart`
2. AppBar `actions` の先頭に:

```dart
          if (state.mode == EntryMode.create)
            IconButton(
              key: const Key('scan-receipt'),
              icon: const Icon(Icons.receipt_long),
              onPressed: () => _scanReceipt(context, ref),
            ),
```

3. 日付 `ListTile` の直後（金額表示の前）に:

```dart
              if (state.mode == EntryMode.receiptConfirm)
                ReceiptReviewPanel(state: state),
```

4. 金額表示 `Container` に確信度ハイライトを追加（`decoration` として）:

```dart
                decoration: BoxDecoration(
                  color: state.mode == EntryMode.receiptConfirm
                      ? confidenceTint(state.matchedTotalCandidate?.confidence)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
```

同様に日付 `ListTile` に `tileColor: state.mode == EntryMode.receiptConfirm ? confidenceTint(state.matchedDateCandidate?.confidence) : null,` を追加。

5. クラス末尾にハンドラを追加:

```dart
  Future<void> _scanReceipt(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await ref.read(receiptCaptureProvider).capture();
    if (path == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('この端末ではレシート撮影を利用できません')));
      return;
    }
    try {
      final blocks = await ref.read(ocrServiceProvider).recognize(path);
      final parsed = ref.read(receiptParserProvider).parse(blocks);
      ref
          .read(entryFormControllerProvider.notifier)
          .startReceipt(parsed, imagePath: path);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('読み取りに失敗しました: $e')));
    }
  }
```

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(receipt): scan flow with confidence highlight and candidate switching"
```

---

## Task 11: バックアップ application（BackupController・LastBackup・起動時ポリシー）

**Files:**
- Create: `lib/features/settings/application/backup_controller.dart`
- Test: `test/providers/backup_controller_test.dart`

**Interfaces:**
- Consumes: `backupServiceProvider`/`autoBackupStoreProvider`/`backupCryptoProvider`/`exportsDirProvider`/`utcNowProvider`（Task 1）、`BackupCodec`（`backup_codec.dart`）、`EmptyBackupError`/`BackupDecryptionError`（**`backup_data.dart` に定義。使用ファイルで直接import**）
- Produces:
  ```dart
  class RestoreSource {
    final File file;
    final String label;       // 自動: '自動バックアップ YYYY/MM/DD HH:mm' / エクスポート: ファイル名
    final bool encrypted;     // .kkbk
    final bool isAutoBackup;
  }
  class PassphraseRequiredError implements Exception {}

  @riverpod class LastBackup extends _$LastBackup { DateTime? build(); } // → lastBackupProvider

  @Riverpod(keepAlive: true)
  class BackupController extends _$BackupController {
    void build() {}
    Future<void> backupNow();                       // exportJson→writeVerified→lastBackup invalidate
    Future<bool> runStartupBackupIfStale();         // 取引>0 かつ (未作成 or 24h超) で実行。実行したらtrue
    Future<File> exportJson({String? passphrase});  // 平文.json / 暗号化.kkbk（ファイル名 kakeibo-export-<utc stamp>.<ext>）
    Future<File> exportCsv();                       // .csv（BOMはP2のCsvExporterが内蔵）
    List<RestoreSource> listRestoreSources();       // 自動世代（新しい順）→ exports（名前降順）
    Future<void> restoreFrom(RestoreSource src, {String? passphrase, bool allowEmpty = false});
  }  // → backupControllerProvider
  ```
- 契約: `restoreFrom` は encrypted でパスフレーズ空なら `PassphraseRequiredError`。復元成功後 `lastBackupProvider` を invalidate（restoreFromJson が復元前スナップショットを書くため世代が増えている）。すべてのDB反映は drift stream 経由でUIに自動伝播。

- [ ] **Step 1: 失敗するテストを書く**

Create `test/providers/backup_controller_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/backup_controller.dart';

import '../support/test_db.dart';
import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;

  BackupController ctrl() => c.read(backupControllerProvider.notifier);

  /// storeNow: 自動バックアップ世代のタイムスタンプを固定する
  Future<void> setUpWith({DateTime? storeNow}) async {
    h = await createHarness();
    // 同一providerの二重overrideを避け、ハーネスのstoreNowパラメータで注入する
    c = ProviderContainer(
        overrides: h.overrides(
            storeNow: storeNow == null ? null : () => storeNow));
    addTearDown(c.dispose);
    addTearDown(h.dispose);
  }

  Future<void> seedTx() async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense, amountYen: 500,
        date: const CivilDate(2026, 7, 10), categoryId: foodId,
        source: TxnSource.manual));
  }

  test('backupNow: 世代が増え lastBackup が更新される', () async {
    await setUpWith();
    final sub = c.listen(lastBackupProvider, (_, __) {});
    addTearDown(sub.close);
    expect(sub.read(), isNull);
    await seedTx();
    await ctrl().backupNow();
    expect(c.read(autoBackupStoreProvider).listGenerations(), hasLength(1));
    expect(c.read(lastBackupProvider), isNotNull);
  });

  test('起動時ポリシー: 空DBは何もしない', () async {
    await setUpWith();
    expect(await ctrl().runStartupBackupIfStale(), isFalse);
    expect(c.read(autoBackupStoreProvider).listGenerations(), isEmpty);
  });

  test('起動時ポリシー: 未作成なら実行、24h以内ならスキップ、超えたら実行', () async {
    // utcNow(固定)=2026-07-15T03:00。世代タイムスタンプは storeNow で制御。
    await setUpWith(storeNow: DateTime.utc(2026, 7, 15, 2)); // 1時間前
    await seedTx();
    expect(await ctrl().runStartupBackupIfStale(), isTrue); // 未作成→実行
    expect(await ctrl().runStartupBackupIfStale(), isFalse); // 1h前→スキップ
    // 世代を27時間前に置き直す
    for (final f in c.read(autoBackupStoreProvider).listGenerations()) {
      f.deleteSync();
    }
    final stale = AutoBackupStore(h.backupDir,
        now: () => DateTime.utc(2026, 7, 14, 0)); // 27時間前
    await stale.writeVerified(
        await c.read(backupServiceProvider).exportJson());
    expect(await ctrl().runStartupBackupIfStale(), isTrue);
  });

  test('exportJson 平文: デコード可能なJSONがexportsに書かれる', () async {
    await setUpWith();
    await seedTx();
    final file = await ctrl().exportJson();
    expect(file.path, endsWith('.json'));
    expect(file.path, contains('20260715-0300')); // utcNow固定
    final payload = const BackupCodec().decode(file.readAsStringSync());
    expect(payload.transactions, hasLength(1));
  });

  test('exportJson 暗号化: .kkbk がdecryptで復号できる', () async {
    await setUpWith();
    await seedTx();
    final file = await ctrl().exportJson(passphrase: 'himitsu');
    expect(file.path, endsWith('.kkbk'));
    final json = await c
        .read(backupCryptoProvider)
        .decrypt(file.readAsBytesSync(), 'himitsu');
    expect(json, contains('formatVersion'));
  });

  test('exportCsv: BOM付きCSVが書かれる', () async {
    await setUpWith();
    await seedTx();
    final file = await ctrl().exportCsv();
    expect(file.path, endsWith('.csv'));
    expect(file.readAsStringSync().codeUnitAt(0), 0xFEFF);
  });

  test('listRestoreSources: 自動世代とexportsがマージされ暗号化フラグが立つ', () async {
    await setUpWith();
    await seedTx();
    await ctrl().backupNow();
    await ctrl().exportJson();
    await ctrl().exportJson(passphrase: 'x');
    final sources = ctrl().listRestoreSources();
    expect(sources.where((s) => s.isAutoBackup), hasLength(1));
    expect(sources.where((s) => s.encrypted), hasLength(1));
    expect(sources.first.label, contains('自動バックアップ'));
  });

  test('restoreFrom: 置換復元＋復元前スナップショットが残る', () async {
    await setUpWith();
    await seedTx();
    await ctrl().backupNow(); // 1件時点の世代
    await seedTx(); // 2件に
    final src = ctrl().listRestoreSources().first;
    await ctrl().restoreFrom(src);
    final after =
        await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(after, hasLength(1)); // 1件時点に戻った
    // 復元前スナップショット（2件時点）が自動退避されている
    expect(c.read(autoBackupStoreProvider).listGenerations().length,
        greaterThanOrEqualTo(2));
  });

  test('restoreFrom: 暗号化はパスフレーズ必須・誤りは復号エラー', () async {
    await setUpWith();
    await seedTx();
    await ctrl().exportJson(passphrase: 'correct');
    final src =
        ctrl().listRestoreSources().firstWhere((s) => s.encrypted);
    expect(() => ctrl().restoreFrom(src),
        throwsA(isA<PassphraseRequiredError>()));
    await expectLater(
        ctrl().restoreFrom(src, passphrase: 'wrong'), throwsA(anything));
    await ctrl().restoreFrom(src, passphrase: 'correct'); // 成功
  });

  test('restoreFrom: 空バックアップは EmptyBackupError、allowEmptyで通る', () async {
    await setUpWith();
    await seedTx();
    // 別の空DBから正当な空エクスポートを作る
    final other = newMemoryDb();
    addTearDown(other.close);
    final emptyJson = await BackupService(other).exportJson();
    h.exportsDir.createSync(recursive: true);
    final f = File(
        '${h.exportsDir.path}${Platform.pathSeparator}kakeibo-export-empty.json')
      ..writeAsStringSync(emptyJson);
    final src = ctrl()
        .listRestoreSources()
        .firstWhere((s) => s.file.path == f.path);
    await expectLater(
        ctrl().restoreFrom(src), throwsA(isA<EmptyBackupError>()));
    await ctrl().restoreFrom(src, allowEmpty: true);
    expect(await c.read(transactionRepositoryProvider).forMonth(2026, 7),
        isEmpty);
  });
}
```

（`EmptyBackupError`/`BackupDecryptionError`/`AutoBackupWriteError` は `lib/data/backup/backup_data.dart` に定義（検証済み）。re-exportは無いので使用ファイルで直接importする。）

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/providers/backup_controller_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/settings/application/backup_controller.dart`:

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/backup/backup_codec.dart';

part 'backup_controller.g.dart';

class RestoreSource {
  final File file;
  final String label;
  final bool encrypted;
  final bool isAutoBackup;
  const RestoreSource({
    required this.file,
    required this.label,
    required this.encrypted,
    required this.isAutoBackup,
  });
}

class PassphraseRequiredError implements Exception {
  const PassphraseRequiredError();
  @override
  String toString() => '暗号化バックアップにはパスフレーズが必要です';
}

@riverpod
class LastBackup extends _$LastBackup {
  @override
  DateTime? build() => ref.watch(autoBackupStoreProvider).latestTimestamp();
}

@Riverpod(keepAlive: true)
class BackupController extends _$BackupController {
  static final _genRe = RegExp(r'^backup-(\d{19})\.json$');

  @override
  void build() {}

  Future<void> backupNow() async {
    final json = await ref.read(backupServiceProvider).exportJson();
    await ref.read(autoBackupStoreProvider).writeVerified(json);
    ref.invalidate(lastBackupProvider);
  }

  /// 起動時ポリシー（spec §2.1「定期」の実装）:
  /// 取引が1件以上あり、前回バックアップが無い/24時間超なら世代を書く。
  Future<bool> runStartupBackupIfStale() async {
    final service = ref.read(backupServiceProvider);
    final payload = await service.exportPayload();
    if (payload.transactions.isEmpty) return false;
    final store = ref.read(autoBackupStoreProvider);
    final last = store.latestTimestamp();
    final now = ref.read(utcNowProvider)();
    if (last != null && now.difference(last) < const Duration(hours: 24)) {
      return false;
    }
    await store.writeVerified(const BackupCodec().encode(payload));
    ref.invalidate(lastBackupProvider);
    return true;
  }

  Future<File> exportJson({String? passphrase}) async {
    final json = await ref.read(backupServiceProvider).exportJson();
    if (passphrase == null || passphrase.isEmpty) {
      return _writeExport(
          'json', (f) async => f.writeAsString(json, flush: true));
    }
    final bytes =
        await ref.read(backupCryptoProvider).encrypt(json, passphrase);
    return _writeExport(
        'kkbk', (f) async => f.writeAsBytes(bytes, flush: true));
  }

  Future<File> exportCsv() async {
    final csv = await ref.read(backupServiceProvider).exportCsv();
    return _writeExport('csv', (f) async => f.writeAsString(csv, flush: true));
  }

  List<RestoreSource> listRestoreSources() {
    final sources = <RestoreSource>[];
    for (final f in ref.read(autoBackupStoreProvider).listGenerations()) {
      sources.add(RestoreSource(
        file: f,
        label: '自動バックアップ ${_genLabel(f)}',
        encrypted: false,
        isAutoBackup: true,
      ));
    }
    final dir = ref.read(exportsDirProvider);
    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') || f.path.endsWith('.kkbk'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final f in files) {
        sources.add(RestoreSource(
          file: f,
          label: f.uri.pathSegments.last,
          encrypted: f.path.endsWith('.kkbk'),
          isAutoBackup: false,
        ));
      }
    }
    return sources;
  }

  Future<void> restoreFrom(RestoreSource src,
      {String? passphrase, bool allowEmpty = false}) async {
    String json;
    if (src.encrypted) {
      if (passphrase == null || passphrase.isEmpty) {
        throw const PassphraseRequiredError();
      }
      json = await ref
          .read(backupCryptoProvider)
          .decrypt(await src.file.readAsBytes(), passphrase);
    } else {
      json = await src.file.readAsString();
    }
    await ref
        .read(backupServiceProvider)
        .restoreFromJson(json, allowEmpty: allowEmpty);
    ref.invalidate(lastBackupProvider);
  }

  Future<File> _writeExport(
      String ext, Future<void> Function(File) write) async {
    final dir = ref.read(exportsDirProvider)..createSync(recursive: true);
    final now = ref.read(utcNowProvider)();
    final base =
        '${dir.path}${Platform.pathSeparator}kakeibo-export-${_stamp(now)}';
    var file = File('$base.$ext');
    for (var n = 2; file.existsSync(); n++) {
      file = File('$base-$n.$ext'); // 同秒内の連続エクスポートを上書きしない
    }
    await write(file);
    return file;
  }

  String _stamp(DateTime utc) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        '-${two(utc.hour)}${two(utc.minute)}${two(utc.second)}';
  }

  String _genLabel(File f) {
    final m = _genRe.firstMatch(f.uri.pathSegments.last);
    if (m == null) return f.uri.pathSegments.last;
    final dt = DateTime.fromMicrosecondsSinceEpoch(int.parse(m.group(1)!),
            isUtc: true)
        .toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
```

- [ ] **Step 4: codegen → 緑・ゲート・Commit** — `dart run build_runner build --delete-conflicting-outputs` → `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(backup): backup controller with startup policy, export, restore sources"
```

---

## Task 12: 設定画面・復元ピッカー・バックアップバナー・起動時配線

**Files:**
- Create: `lib/features/settings/presentation/settings_screen.dart`, `lib/features/settings/presentation/restore_picker_page.dart`, `lib/features/calendar/presentation/backup_banner.dart`
- Modify: `lib/app/home_shell.dart`（タブ2差し替え＋起動時 `runStartupBackupIfStale` 呼び出し）, `lib/features/calendar/presentation/calendar_screen.dart`（バナー挿入）, `test/ui/home_shell_test.dart`（プレースホルダ期待の撤去）
- Test: `test/ui/settings_screen_test.dart`, `test/ui/restore_picker_test.dart`

**Interfaces:**
- Consumes: Task 11 の `backupControllerProvider`/`lastBackupProvider`/`RestoreSource`/`PassphraseRequiredError`、`appSettingsProvider`、`backupAgeLabel`、`EmptyBackupError`（P2）
- Produces:
  - `class SettingsScreen extends ConsumerWidget` — ListView:
    ステータス行（`backupAgeLabel(last, now)`＋世代数）／`Key('backup-now')`『今すぐバックアップ』／`Key('export-json')`『JSONエクスポート』（パスフレーズダイアログ: `Key('passphrase-field')`・『そのまま保存』・『暗号化して保存』）／`Key('export-csv')`『CSVエクスポート』（subtitle『閲覧用（復元には使えません）』）／`Key('restore-tile')`『復元』→ RestorePickerPage／Divider／`Key('retain-images-switch')` SwitchListTile『レシート画像をローカル保持』／`Key('category-manage-tile')`『カテゴリ管理』（Task 13 でページ接続。本タスクではonTapでSnackBar『準備中』を出さず、**Task 13で作るページへのpushをコメントアウトなしで実装できるよう、本タスクではタイル自体を追加しない**）／`Key('about-data-tile')`『データの取り扱いについて』→ 説明ダイアログ
  - `class RestorePickerPage extends ConsumerStatefulWidget` — `listRestoreSources()` を列挙。タップ→破壊的確認ダイアログ（`Key('confirm-restore')`『復元』）→（encryptedなら `Key('restore-passphrase-field')` ダイアログ）→ `restoreFrom`。`EmptyBackupError` は追加確認（`Key('confirm-empty-restore')`）→ `allowEmpty: true` で再試行。成功: pop＋SnackBar『復元しました』。失敗: SnackBar『復元に失敗しました: ...』
  - `class BackupBanner extends ConsumerWidget` — `backupAgeLabel` の常時表示スリムバナー（spec §2.1-2: ホーム/設定に常時表示）。CalendarScreen 最上部に挿入
  - HomeShell: `initState` の postFrame で `runStartupBackupIfStale()` を fire-and-forget（`catchError` で握りつぶし、起動を妨げない）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/ui/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

void main() {
  Future<ProviderContainer> openSettings(WidgetTester tester,
      {required TestHarness h}) async {
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> seed(ProviderContainer c) async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense, amountYen: 500,
        date: const CivilDate(2026, 7, 10), categoryId: foodId,
        source: TxnSource.manual));
  }

  testWidgets('ステータス→今すぐバックアップで「今日」に変わる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final c = await openSettings(tester, h: h);
    await seed(c);
    expect(find.text('バックアップ未作成'), findsWidgets); // 設定＋カレンダーバナー
    await tester.tap(find.byKey(const Key('backup-now')));
    await tester.pumpAndSettle();
    expect(find.textContaining('前回バックアップ'), findsWidgets);

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('JSONエクスポート: 暗号化選択で.kkbkが作られる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final c = await openSettings(tester, h: h);
    await seed(c);
    await tester.tap(find.byKey(const Key('export-json')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('passphrase-field')), 'pw');
    await tester.tap(find.text('暗号化して保存'));
    await tester.pumpAndSettle();
    expect(find.textContaining('保存しました'), findsOneWidget);
    expect(
        h.exportsDir.listSync().where((f) => f.path.endsWith('.kkbk')),
        hasLength(1));

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('CSVエクスポートとレシート画像トグルの永続化', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    final c = await openSettings(tester, h: h);
    await seed(c);
    await tester.tap(find.byKey(const Key('export-csv')));
    await tester.pumpAndSettle();
    expect(h.exportsDir.listSync().where((f) => f.path.endsWith('.csv')),
        hasLength(1));

    await tester.tap(find.byKey(const Key('retain-images-switch')));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).retainReceiptImages, isTrue);

    // CSVエクスポートのSnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
```

Create `test/ui/restore_picker_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/backup_controller.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('復元ピッカー: 確認ダイアログ→復元→SnackBar、UIも自動更新', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 500,
        date: const CivilDate(2026, 7, 15), categoryId: foodId,
        source: TxnSource.manual));
    await c.read(backupControllerProvider.notifier).backupNow(); // 1件時点
    await repo.add(TransactionEntity(
        type: TxnType.expense, amountYen: 999,
        date: const CivilDate(2026, 7, 15), categoryId: foodId,
        source: TxnSource.manual)); // 2件に

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restore-tile')));
    await tester.pumpAndSettle();
    expect(find.textContaining('自動バックアップ'), findsOneWidget);

    await tester.tap(find.textContaining('自動バックアップ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-restore')));
    await tester.pumpAndSettle();

    expect(find.text('復元しました'), findsOneWidget);
    expect(await repo.forMonth(2026, 7), hasLength(1)); // 1件時点に戻った

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/settings_screen_test.dart test/ui/restore_picker_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/calendar/presentation/backup_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format.dart';
import '../../settings/application/backup_controller.dart';

/// spec §2.1-2: 「前回バックアップ: N日前」をホームに常時表示（通知の代替）。
class BackupBanner extends ConsumerWidget {
  const BackupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastBackupProvider);
    final now = ref.watch(utcNowProvider)();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.backup_outlined, size: 14),
          const SizedBox(width: 6),
          Text(backupAgeLabel(last, now),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
```

Modify `lib/features/calendar/presentation/calendar_screen.dart` — `Column` の先頭（`_MonthHeader` の前）に `const BackupBanner(),` を挿入し import を追加。

Create `lib/features/settings/presentation/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format.dart';
import '../application/backup_controller.dart';
import '../application/settings_controller.dart';
import 'restore_picker_page.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastBackupProvider);
    final now = ref.watch(utcNowProvider)();
    final settings = ref.watch(appSettingsProvider);
    final generations =
        ref.watch(autoBackupStoreProvider).listGenerations().length;

    return SafeArea(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(backupAgeLabel(last, now)),
            subtitle: Text('自動バックアップ $generations世代（端末内）'),
          ),
          ListTile(
            key: const Key('backup-now'),
            leading: const Icon(Icons.save_alt),
            title: const Text('今すぐバックアップ'),
            onTap: () => _backupNow(context, ref),
          ),
          ListTile(
            key: const Key('export-json'),
            leading: const Icon(Icons.upload_file),
            title: const Text('JSONエクスポート'),
            subtitle: const Text('任意でパスフレーズ暗号化（復元に使えます）'),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            key: const Key('export-csv'),
            leading: const Icon(Icons.table_view),
            title: const Text('CSVエクスポート'),
            subtitle: const Text('閲覧用（復元には使えません）'),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            key: const Key('restore-tile'),
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('復元'),
            subtitle: const Text('全データを置き換えます'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RestorePickerPage()),
            ),
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('retain-images-switch'),
            title: const Text('レシート画像をローカル保持'),
            subtitle: const Text('既定では保存後に破棄します'),
            value: settings.retainReceiptImages,
            onChanged: (v) => ref
                .read(appSettingsProvider.notifier)
                .setRetainReceiptImages(v),
          ),
          const Divider(),
          ListTile(
            key: const Key('about-data-tile'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('データの取り扱いについて'),
            onTap: () => showDataPolicyDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupControllerProvider.notifier).backupNow();
      messenger.showSnackBar(
          const SnackBar(content: Text('バックアップを作成しました')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('バックアップに失敗しました: $e')));
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => const _ExportPassphraseDialog(),
    );
    if (choice == null) return; // キャンセル
    try {
      final file = await ref
          .read(backupControllerProvider.notifier)
          .exportJson(passphrase: choice.isEmpty ? null : choice);
      messenger.showSnackBar(
          SnackBar(content: Text('保存しました: ${file.uri.pathSegments.last}')));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file =
          await ref.read(backupControllerProvider.notifier).exportCsv();
      messenger.showSnackBar(
          SnackBar(content: Text('保存しました: ${file.uri.pathSegments.last}')));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    }
  }
}

/// オンボーディングと共通の説明（Task 13 で初回起動ダイアログからも使う）
Future<void> showDataPolicyDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('データの取り扱いについて'),
        content: const Text(
          '・記録は端末の中だけに保存されます。自動で外部に送信されることはありません。\n'
          '・端末内で自動バックアップを取りますが、機種変更や端末の故障に備えて、'
          '設定からエクスポートを保存してください。',
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('閉じる')),
        ],
      ),
    );

class _ExportPassphraseDialog extends StatefulWidget {
  const _ExportPassphraseDialog();

  @override
  State<_ExportPassphraseDialog> createState() =>
      _ExportPassphraseDialogState();
}

class _ExportPassphraseDialogState extends State<_ExportPassphraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('JSONエクスポート'),
        content: TextField(
          key: const Key('passphrase-field'),
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'パスフレーズ（暗号化する場合）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('そのまま保存')),
          FilledButton(
              onPressed: () {
                final t = _controller.text;
                if (t.isNotEmpty) Navigator.pop(context, t);
              },
              child: const Text('暗号化して保存')),
        ],
      );
}
```

Create `lib/features/settings/presentation/restore_picker_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/backup/backup_data.dart';
import '../application/backup_controller.dart';

class RestorePickerPage extends ConsumerStatefulWidget {
  const RestorePickerPage({super.key});

  @override
  ConsumerState<RestorePickerPage> createState() => _RestorePickerPageState();
}

class _RestorePickerPageState extends ConsumerState<RestorePickerPage> {
  @override
  Widget build(BuildContext context) {
    final sources =
        ref.read(backupControllerProvider.notifier).listRestoreSources();
    return Scaffold(
      appBar: AppBar(title: const Text('復元')),
      body: sources.isEmpty
          ? const Center(child: Text('復元できるバックアップがありません'))
          : ListView(
              children: [
                for (final s in sources)
                  ListTile(
                    leading: Icon(
                        s.isAutoBackup ? Icons.history : Icons.file_present),
                    title: Text(s.label),
                    trailing: s.encrypted ? const Icon(Icons.lock) : null,
                    onTap: () => _restore(s),
                  ),
              ],
            ),
    );
  }

  Future<void> _restore(RestoreSource src) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('復元しますか？'),
        content: const Text('現在のデータはすべて置き換えられます。'
            '直前の状態は自動退避され、あとで取り出せます。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          FilledButton(
              key: const Key('confirm-restore'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('復元')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    String? pass;
    if (src.encrypted) {
      pass = await _askPassphrase();
      if (pass == null || !mounted) return;
    }

    final ctrl = ref.read(backupControllerProvider.notifier);
    try {
      await ctrl.restoreFrom(src, passphrase: pass);
    } on EmptyBackupError {
      if (!mounted) return;
      final okEmpty = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('取引が0件のバックアップです'),
          content: const Text('復元するとすべての取引が消えます。それでも復元しますか？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('キャンセル')),
            FilledButton(
                key: const Key('confirm-empty-restore'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('復元する')),
          ],
        ),
      );
      if (okEmpty != true || !mounted) return;
      try {
        await ctrl.restoreFrom(src, passphrase: pass, allowEmpty: true);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('復元に失敗しました: $e')));
        return;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('復元に失敗しました: $e')));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('復元しました')));
  }

  Future<String?> _askPassphrase() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('パスフレーズを入力'),
        content: TextField(
          key: const Key('restore-passphrase-field'),
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(ctx, controller.text);
                }
              },
              child: const Text('復元')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
```

Modify `lib/app/home_shell.dart`:

1. import 追加: `../features/settings/presentation/settings_screen.dart`、`../features/settings/application/backup_controller.dart`
2. `IndexedStack` の3番目を `const SettingsScreen(),` に差し替え（`_PlaceholderTab` クラスと残る参照を削除）
3. `_HomeShellState` に `initState` を追加:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 起動時バックアップ（spec §2.1「定期」）。失敗しても起動を妨げない。
      ref
          .read(backupControllerProvider.notifier)
          .runStartupBackupIfStale()
          .catchError((_) => false);
    });
  }
```

`test/ui/home_shell_test.dart` の `(設定 準備中)` 期待を実画面の表示（設定=`find.byKey(const Key('backup-now'))`）に更新（サマリ分はTask 9で更新済み）。

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(settings): backup UI, restore picker, banner, startup auto-backup"
```

---

## Task 13: カテゴリ管理・オンボーディング

**Files:**
- Create: `lib/features/settings/presentation/category_manage_page.dart`, `lib/features/settings/presentation/onboarding_dialog.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`（『カテゴリ管理』タイル追加）, `lib/app/home_shell.dart`（初回オンボーディング表示）
- Test: `test/ui/category_manage_test.dart`, `test/ui/onboarding_test.dart`

**Interfaces:**
- Consumes: `allCategoriesProvider`、`categoryRepositoryProvider`（addCategory/rename/setArchived/reorder、`CategoryInUseError`は本画面では発生しない）、`appSettingsProvider`（onboardingDone）、`showDataPolicyDialog`（Task 12）
- Produces:
  - `class CategoryManagePage extends ConsumerStatefulWidget` — `DefaultTabController` 2タブ（支出/収入）。各タブ: アクティブ（非system）を `ReorderableListView`（key=`ValueKey('cat-<id>')`、`onReorder`→`repo.reorder(そのタブのアクティブid列)`）、下部に『アーカイブ済み』`ExpansionTile`（復帰ボタン `Key('unarchive-<id>')`）。**systemカテゴリ（未分類）は表示しない**（内部sentinel）。AppBar右の `Key('add-category')` → 追加ダイアログ（`Key('category-name-field')`名前・`Key('category-icon-field')`絵文字任意・typeは現在タブ）。行の `Key('rename-<id>')` → 改名ダイアログ、`Key('archive-<id>')` → アーカイブ
  - `class OnboardingDialog extends ConsumerWidget` — 初回のみ（`onboardingDone == false`）HomeShellのpostFrameで表示。内容は `showDataPolicyDialog` と同じ方針文＋『はじめる』（`markOnboardingDone()`→pop）。`barrierDismissible: false`
  - SettingsScreen: 『レシート画像』Switchの下に `Key('category-manage-tile')`『カテゴリ管理』→ push CategoryManagePage

- [ ] **Step 1: 失敗するテストを書く**

Create `test/ui/category_manage_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/features/settings/presentation/category_manage_page.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    setPhoneSurface(tester);
    h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const CategoryManagePage());
    return ProviderScope.containerOf(
        tester.element(find.byType(CategoryManagePage)), listen: false);
  }

  testWidgets('追加: ダイアログから新カテゴリが現在タブのtypeで入る', (tester) async {
    final c = await pumpPage(tester);
    await tester.tap(find.byKey(const Key('add-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), 'ペット');
    await tester.enterText(find.byKey(const Key('category-icon-field')), '🐈');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.text('ペット'), findsOneWidget);
    final cats = await waitForData(c, allCategoriesProvider);
    final added = cats.firstWhere((x) => x.name == 'ペット');
    expect(added.type, CategoryType.expense);
    expect(added.icon, '🐈');
  });

  testWidgets('改名とアーカイブ→復帰、systemは出ない', (tester) async {
    final c = await pumpPage(tester);
    expect(find.text('未分類'), findsNothing); // sentinel非表示
    final cats = await waitForData(c, allCategoriesProvider);
    final food = cats.firstWhere((x) => x.name == '食費');

    await tester.tap(find.byKey(Key('rename-${food.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), '食料品');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('食料品'), findsOneWidget);

    await tester.tap(find.byKey(Key('archive-${food.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('アーカイブ済み'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('unarchive-${food.id}')));
    await tester.pumpAndSettle();
    final after = await waitForData(c, allCategoriesProvider);
    expect(after.firstWhere((x) => x.id == food.id).isArchived, isFalse);
  });

  testWidgets('並べ替え: onReorderがsortOrderを振り直す', (tester) async {
    final c = await pumpPage(tester);
    final rlv = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView).first);
    rlv.onReorder(0, 3); // 先頭（食費）を3番目へ
    await tester.pumpAndSettle();
    final cats = await waitForData(c, allCategoriesProvider);
    final expenseActive = cats
        .where((x) =>
            x.type == CategoryType.expense && !x.isSystem && !x.isArchived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(expenseActive[2].name, '食費');
  });
}
```

Create `test/ui/onboarding_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('初回のみオンボーディング表示→はじめるで永続化', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(prefs: {}); // onboardingDone未設定=false
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.text('データの取り扱いについて'), findsOneWidget);

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(find.text('データの取り扱いについて'), findsNothing);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    expect(c.read(appSettingsProvider).onboardingDone, isTrue);
  });

  testWidgets('2回目以降は出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(); // 既定 onboardingDone:true
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.text('データの取り扱いについて'), findsNothing);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/ui/category_manage_test.dart test/ui/onboarding_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/features/settings/presentation/onboarding_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';

/// 初回起動時の軽量オンボーディング（spec §5.5）。
class OnboardingDialog extends ConsumerWidget {
  const OnboardingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
        title: const Text('データの取り扱いについて'),
        content: const Text(
          '・記録は端末の中だけに保存されます。自動で外部に送信されることはありません。\n'
          '・端末内で自動バックアップを取りますが、機種変更や端末の故障に備えて、'
          '設定からエクスポートを保存してください。',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).markOnboardingDone();
              Navigator.pop(context);
            },
            child: const Text('はじめる'),
          ),
        ],
      );
}
```

Create `lib/features/settings/presentation/category_manage_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';

class CategoryManagePage extends ConsumerStatefulWidget {
  const CategoryManagePage({super.key});

  @override
  ConsumerState<CategoryManagePage> createState() =>
      _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  CategoryType get _currentType =>
      _tab.index == 0 ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリ管理'),
        actions: [
          IconButton(
            key: const Key('add-category'),
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '支出'), Tab(text: '収入')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CategoryTypeList(type: CategoryType.expense),
          _CategoryTypeList(type: CategoryType.income),
        ],
      ),
    );
  }

  /// category == null なら追加、非nullなら改名。
  Future<void> _showEditDialog({CategoryEntity? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? 'カテゴリを追加' : 'カテゴリを改名'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('category-name-field'),
              controller: nameController,
              decoration: const InputDecoration(labelText: '名前'),
            ),
            if (category == null)
              TextField(
                key: const Key('category-icon-field'),
                controller: iconController,
                decoration: const InputDecoration(labelText: 'アイコン（絵文字・任意）'),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(
                  ctx, (nameController.text, iconController.text));
            },
            child: Text(category == null ? '追加' : '保存'),
          ),
        ],
      ),
    );
    nameController.dispose();
    iconController.dispose();
    if (result == null) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (category == null) {
      await repo.addCategory(
        name: result.$1,
        type: _currentType,
        icon: result.$2.trim().isEmpty ? null : result.$2.trim(),
      );
    } else {
      await repo.rename(category.id, result.$1);
    }
  }
}

class _CategoryTypeList extends ConsumerWidget {
  final CategoryType type;
  const _CategoryTypeList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final active = all
        .where((c) => c.type == type && !c.isSystem && !c.isArchived)
        .toList();
    final archived = all
        .where((c) => c.type == type && !c.isSystem && c.isArchived)
        .toList();
    final repo = ref.read(categoryRepositoryProvider);
    final pageState =
        context.findAncestorStateOfType<_CategoryManagePageState>()!;

    return Column(
      children: [
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final ids = active.map((c) => c.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await repo.reorder(ids);
            },
            children: [
              for (final c in active)
                ListTile(
                  key: ValueKey('cat-${c.id}'),
                  leading: Text(c.icon ?? '📁',
                      style: const TextStyle(fontSize: 20)),
                  title: Text(c.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('rename-${c.id}'),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            pageState._showEditDialog(category: c),
                      ),
                      IconButton(
                        key: Key('archive-${c.id}'),
                        icon: const Icon(Icons.archive_outlined),
                        onPressed: () => repo.setArchived(c.id, true),
                      ),
                    ],
                  ),
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
                  leading: Text(c.icon ?? '📁',
                      style: const TextStyle(fontSize: 20)),
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
}
```

Modify `lib/features/settings/presentation/settings_screen.dart` — Switch の下に追加（import も追加）:

```dart
          ListTile(
            key: const Key('category-manage-tile'),
            leading: const Icon(Icons.category_outlined),
            title: const Text('カテゴリ管理'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryManagePage()),
            ),
          ),
```

Modify `lib/app/home_shell.dart` — `initState` の postFrame コールバックに追記（バックアップ呼び出しの前）:

```dart
      if (!ref.read(appSettingsProvider).onboardingDone && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingDialog(),
        );
      }
```

（import: `../features/settings/application/settings_controller.dart`、`../features/settings/presentation/onboarding_dialog.dart`）

- [ ] **Step 4: 緑・ゲート・Commit** — `flutter test` 全緑 → analyze 0 →

```bash
git add -A
git commit -m "feat(settings): category management page and first-run onboarding"
```

---

## Task 14: 最終ゲートとマージ

**Files:**
- Modify: なし（検証とマージのみ）

- [ ] **Step 1: フルゲート**

```bash
flutter test          # 全テスト緑（P1〜P3の134 + Phase 4新規）
flutter analyze       # 0 issues（riverpod_lint診断含む）
```

- [ ] **Step 2: BOM混入チェック（P2の教訓）**

```powershell
Get-ChildItem -Recurse lib,test -Include *.dart | Select-String -Pattern ([string][char]0xFEFF)
```
Expected: 出力なし（`csv_exporter.dart` の `'﻿'` エスケープはヒットしない）

- [ ] **Step 3: spec突合の目視**

spec §5（画面構成）・§2.1（バックアップバナー/自動バックアップ）・§4.5（型トグル）・§7.5（確信度ハイライト/候補切替）・§11（エラー処理）を読み直し、未実装項目がないか確認。Phase 5送り（カメラ・Vision・共有シート・実機セル視認性）を除いて残があればタスク追加。

- [ ] **Step 4: main へ no-ff マージ（従来の型）**

```bash
git checkout main
git merge --no-ff phase-4-ui -m "merge: Phase 4 features UI + Riverpod (calendar/entry/receipt/summary/settings)"
flutter test   # マージ後の最終確認
git branch -d phase-4-ui
```

- [ ] **Step 5:（任意・ベストエフォート）Windowsデスクトップで起動確認**

VS C++ toolchain がある場合のみ:

```bash
flutter create --platforms=windows .
flutter run -d windows
```

起動して3タブ・入力・バックアップが動くことを目視。toolchain が無ければスキップ（ヘッドレステストが正）。`windows/` を追加した場合は別コミット。

---

## Self-Review チェック結果（計画作成時）

1. **Spec coverage**: §5.1 カレンダー=Task 8／§5.2 高速入力=Task 6-7／§5.3 日付既定=Task 7-8／§5.4 3モード=Task 6・7・10／§5.5 空状態・オンボーディング=Task 8・9・13／§2.1 自動バックアップ・バナー・暗号化エクスポート=Task 11-12／§4.5 型トグル副作用=Task 6／§4.3 アーカイブ集計包含=Task 3・9／§7.5 確信度・候補切替=Task 10／§6.2 フォールバック=Task 10／§11 エラー処理=Task 7-13 各所。**Phase 5送り（spec明記）**: カメラ/image_picker・Apple Vision実配線・共有シート＋**iOSのFiles公開キー（`UIFileSharingEnabled`/`LSSupportsOpeningDocumentsInPlace`）**（これが無いとDocuments/exportsのエクスポートを端末外に取り出せず§2.1-3の目的を失う）・実機セル視認性チューニング・実レシートフィクスチャ。
2. **意図的な設計判断**: go_router不採用（3タブ+pushのみ、YAGNI）／Undo=再add（id/createdAt変わる。v1限界としてUI無害）／共有シートはPhase 5（エクスポートはアプリDocuments/exportsへ書き出し。iOSでFilesアプリから見せるにはInfo.plistの`UIFileSharingEnabled`/`LSSupportsOpeningDocumentsInPlace`が必要＝Phase 5要件に含める）／`(設定 準備中)` 等のプレースホルダタブはTask 8/9/12で完全に消える。
3. **型整合**: providers名・EntryFormState・RestoreSource等はInterfaces節で固定。CategorySpendRow.isArchived追加はP1既存テストの構築箇所修正が必要（Task 3 Step 5に明記）。

## 実行メモ（従来の型）

計画実行前に**敵対的検証**（エージェントによるAPI裏取り: Riverpod 3 codegen構文・table_calendar・drift watch・ReorderableListView。および本plan内コードのDartプローブ）→修正→実行、の順で進める（P1〜P3と同じ進め方）。

