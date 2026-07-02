# 家計簿アプリ Phase 1: データ基盤 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 家計簿アプリのデータ層（drift/SQLite）を、Windowsの`flutter test`で完全に自走検証できる形で構築する。カテゴリ・取引の保存/読み出し・月次集計・データ整合性の不変条件までを、UIやiOS依存なしにテスト済みで揃える。

**Architecture:** 純Dartドメイン（`CivilDate`値型・エンティティ・リポジトリ抽象）と、driftによる永続化（テーブル/DAO/DB）を分離。UI/ドメインはリポジトリ抽象にのみ依存し、driftの型は`data/`層に閉じ込める。日付はタイムゾーン非依存の`CivilDate`（`YYYY-MM-DD`保存）、金額は整数円、enumは`textEnum`。外部キーはPRAGMAで実効化。

**Tech Stack:** Flutter 3.44.4 / Dart 3.12.2（導入済み）、drift（SQLite ORM）、build_runner（コード生成）、`test`/`flutter_test`、sqlite3（Windowsホストテスト用）。

## Global Constraints

これらは**全タスク共通の暗黙要件**。各タスクの要件に必ず含まれる。

- Flutter 3.44.4 / Dart 3.12.2。プロジェクト名（dartパッケージ名）＝ `kakeibo_app`（ハイフン不可）。
- **金額は整数円**（`int`）。`double`/`real`を金額に使わない。`amount`は常に**非負**、収支は`type`で表す。
- **日付は`CivilDate`**（year/month/day のみ、時刻・タイムゾーンなし）。DBには`TEXT 'YYYY-MM-DD'`（ゼロ埋め）で保存。取引日に`DateTime.now()`の時刻成分を混ぜない。
- **永続enumは`textEnum`**（`.name`保存、並べ替え耐性）。`intEnum`は使わない。enum要素の**リネームはマイグレーション必須**。
- **`PRAGMA foreign_keys = ON`** を`beforeOpen`で必ず有効化。`categoryId`は`NOT NULL` FK・`ON DELETE RESTRICT`。
- **`updatedAt`は全ミューテーションでリポジトリの単一チョークポイントが更新**する。`source`は編集で不変。
- **タイムスタンプ（createdAt/updatedAt）はISO-8601テキスト保存**（`build.yaml`で`store_date_time_values_as_text: true`）。
- テストは**Windowsの`flutter test`でヘッドレスに全て通る**こと。1テスト＝`NativeDatabase.memory()`の新規DB。
- TDD（先に落ちるテスト→最小実装→通す→コミット）。DRY・YAGNI。タスクごとに独立してテスト可能な成果物で終わる。

---

## File Structure

```
kakeibo-app/
  pubspec.yaml                                  # 依存追加
  build.yaml                                    # drift codegen 設定（タイムスタンプをtext保存）
  test/flutter_test_config.dart                 # Windowsで sqlite3.dll を解決（フォールバック）
  lib/
    domain/
      money/civil_date.dart                     # CivilDate 値型（純Dart）
      entities.dart                             # TransactionEntity, MonthlySummary, CategorySpend, CategoryEntity
      repositories.dart                         # TransactionRepository, CategoryRepository（抽象）
    data/
      db/
        enums.dart                              # TxnType, CategoryType, PaymentMethod, TxnSource
        converters.dart                         # CivilDateConverter (CivilDate <-> String)
        tables.dart                             # Categories, Transactions
        database.dart                           # AppDatabase (+ database.g.dart 生成), seed, PRAGMA
        daos.dart                               # TransactionDao, CategoryDao (+ daos.g.dart 生成)
      repositories/
        drift_transaction_repository.dart       # TransactionRepository の drift 実装
        drift_category_repository.dart          # CategoryRepository の drift 実装
  test/
    support/test_db.dart                        # newMemoryDb() ファクトリ
    civil_date_test.dart
    converter_test.dart
    database_fk_test.dart
    seed_test.dart
    transaction_dao_test.dart
    aggregation_test.dart
    repository_test.dart
    category_integrity_test.dart
    updated_at_test.dart
```

各ファイルは単一責務。driftの型（`TransactionRow`/`Companion`/`Expression`）は`data/`層の外に漏らさない。

---

## Task 1: プロジェクト雛形と依存の用意

**Files:**
- Create: `pubspec.yaml`（`flutter create`が生成→編集）
- Create: `build.yaml`
- Create: `test/kakeibo_app_smoke_test.dart`
- Delete: `test/widget_test.dart`（`flutter create`が作るカウンタ用テスト）

**Interfaces:**
- Consumes: なし
- Produces: `flutter test`が緑で通る空のFlutterプロジェクト。以降の全タスクの土台。

- [ ] **Step 1: 既存の設計ファイルを保ったまま Flutter 雛形を生成**

`kakeibo-app/` には既に `.git` / `.gitignore` / `DESIGN.md` / `docs/` がある。非空ディレクトリに雛形を被せる。パッケージ名はハイフン不可なので明示する。

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
flutter create --project-name kakeibo_app --platforms=ios .
```
Expected: `ios/`, `lib/main.dart`, `pubspec.yaml`, `test/widget_test.dart` などが生成される（`--platforms=ios` でiOS先行、余計なandroid/web/desktopを増やさない）。

- [ ] **Step 2: 依存を追加**

`pubspec.yaml` の `dependencies:` と `dev_dependencies:` を以下に置き換える（バージョンは`flutter pub get`で解決される範囲の下限を指定）:

```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.20.0
  build_runner: ^2.4.0
  sqlite3: ^2.4.0
```

- [ ] **Step 3: drift の codegen 設定を作成**

Create `build.yaml`:
```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          # createdAt/updatedAt を ISO-8601 テキストで保存（タイムゾーン安全）
          store_date_time_values_as_text: true
```

- [ ] **Step 4: 依存を取得**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
flutter pub get
```
Expected: `Got dependencies!`（エラーなし）

- [ ] **Step 5: 既定のウィジェットテストを smoke テストに置換**

Delete `test/widget_test.dart`（カウンタアプリ依存で、`lib/main.dart`を作り替えると壊れるため）。

Create `test/kakeibo_app_smoke_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toolchain sanity', () {
    expect(1 + 1, 2);
  });
}
```

- [ ] **Step 6: テストが通ることを確認**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 7: コミット**

```bash
cd "C:/Users/wilsh/kakeibo-app"
git add -A
git commit -m "chore: scaffold Flutter (iOS) project with drift deps"
```

---

## Task 2: CivilDate 値型（純Dart・タイムゾーン非依存の日付）

**Files:**
- Create: `lib/domain/money/civil_date.dart`
- Test: `test/civil_date_test.dart`

**Interfaces:**
- Consumes: なし
- Produces:
  - `class CivilDate implements Comparable<CivilDate>` with:
    - `const CivilDate(int year, int month, int day)`
    - `factory CivilDate.parse(String iso)` — `'YYYY-MM-DD'`、不正は`FormatException`
    - `factory CivilDate.fromDateTime(DateTime dt)` — `dt`の`year/month/day`（**ローカル**日付部分）を採用
    - `String toIso()` — ゼロ埋め`'YYYY-MM-DD'`
    - `bool get isValid` — カレンダー上妥当（`2/30`等をfalse）
    - `int compareTo(CivilDate other)`
    - `operator ==` / `hashCode`
    - `static String firstOfMonthIso(int year, int month)` — 例`(2026,7)→'2026-07-01'`
    - `static String firstOfNextMonthIso(int year, int month)` — 例`(2026,12)→'2027-01-01'`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/civil_date_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

void main() {
  test('toIso zero-pads month and day', () {
    expect(const CivilDate(2026, 7, 3).toIso(), '2026-07-03');
    expect(const CivilDate(2026, 12, 31).toIso(), '2026-12-31');
  });

  test('parse round-trips a valid ISO date', () {
    final d = CivilDate.parse('2026-07-03');
    expect(d, const CivilDate(2026, 7, 3));
    expect(d.toIso(), '2026-07-03');
  });

  test('parse rejects malformed or impossible dates', () {
    expect(() => CivilDate.parse('2026-7-3'), throwsFormatException);
    expect(() => CivilDate.parse('2026-02-30'), throwsFormatException);
    expect(() => CivilDate.parse('not-a-date'), throwsFormatException);
  });

  test('fromDateTime takes the local calendar day only', () {
    final d = CivilDate.fromDateTime(DateTime(2026, 7, 3, 23, 59));
    expect(d, const CivilDate(2026, 7, 3));
  });

  test('equality and comparison', () {
    expect(const CivilDate(2026, 7, 3), const CivilDate(2026, 7, 3));
    expect(const CivilDate(2026, 7, 3).compareTo(const CivilDate(2026, 7, 4)), lessThan(0));
    expect(const CivilDate(2026, 8, 1).compareTo(const CivilDate(2026, 7, 31)), greaterThan(0));
  });

  test('lexicographic ISO order equals chronological order', () {
    final list = [
      CivilDate.parse('2026-12-31'),
      CivilDate.parse('2026-01-05'),
      CivilDate.parse('2026-07-03'),
    ]..sort();
    expect(list.map((d) => d.toIso()).toList(),
        ['2026-01-05', '2026-07-03', '2026-12-31']);
  });

  test('month range helpers (December wraps to next January)', () {
    expect(CivilDate.firstOfMonthIso(2026, 7), '2026-07-01');
    expect(CivilDate.firstOfNextMonthIso(2026, 7), '2026-08-01');
    expect(CivilDate.firstOfNextMonthIso(2026, 12), '2027-01-01');
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/civil_date_test.dart`
Expected: FAIL（`civil_date.dart` が存在しない / import 解決不可）

- [ ] **Step 3: 最小実装を書く**

Create `lib/domain/money/civil_date.dart`:
```dart
/// タイムゾーン・時刻を持たない暦日（civil date）。
/// 取引日はこの型で表し、DateTime の時刻/タイムゾーンに起因する日ズレを構造的に排除する。
class CivilDate implements Comparable<CivilDate> {
  final int year;
  final int month;
  final int day;

  const CivilDate(this.year, this.month, this.day);

  factory CivilDate.parse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) {
      throw FormatException('Not a YYYY-MM-DD date: $iso');
    }
    final d = CivilDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (!d.isValid) {
      throw FormatException('Not a valid calendar date: $iso');
    }
    return d;
  }

  factory CivilDate.fromDateTime(DateTime dt) =>
      CivilDate(dt.year, dt.month, dt.day);

  /// カレンダー上妥当か（例: 2026-02-30 は false）。
  bool get isValid {
    if (month < 1 || month > 12 || day < 1) return false;
    // DateTime.utc で正規化し、往復して一致するかで妥当性を判定。
    final normalized = DateTime.utc(year, month, day);
    return normalized.year == year &&
        normalized.month == month &&
        normalized.day == day;
  }

  String toIso() {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  static String firstOfMonthIso(int year, int month) =>
      CivilDate(year, month, 1).toIso();

  static String firstOfNextMonthIso(int year, int month) => month == 12
      ? CivilDate(year + 1, 1, 1).toIso()
      : CivilDate(year, month + 1, 1).toIso();

  @override
  int compareTo(CivilDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'CivilDate(${toIso()})';
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/civil_date_test.dart`
Expected: PASS（全7ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/domain/money/civil_date.dart test/civil_date_test.dart
git commit -m "feat: add CivilDate value type (tz-independent calendar date)"
```

---

## Task 3: enum 定義と CivilDateConverter

**Files:**
- Create: `lib/data/db/enums.dart`
- Create: `lib/data/db/converters.dart`
- Test: `test/converter_test.dart`

**Interfaces:**
- Consumes: `CivilDate`（Task 2）
- Produces:
  - `enum TxnType { expense, income }`
  - `enum CategoryType { expense, income }`
  - `enum PaymentMethod { cash, creditCard, eMoney, bankDraft, other }`
  - `enum TxnSource { manual, receiptOcr }`
  - `class CivilDateConverter extends TypeConverter<CivilDate, String>`（`fromSql`/`toSql`）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/converter_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/converters.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

void main() {
  const conv = CivilDateConverter();

  test('toSql serializes to YYYY-MM-DD', () {
    expect(conv.toSql(const CivilDate(2026, 7, 3)), '2026-07-03');
  });

  test('fromSql parses YYYY-MM-DD back to CivilDate', () {
    expect(conv.fromSql('2026-12-31'), const CivilDate(2026, 12, 31));
  });

  test('round-trip preserves the exact civil date (no tz drift)', () {
    for (final iso in ['2026-01-01', '2026-07-03', '2026-12-31']) {
      expect(conv.toSql(conv.fromSql(iso)), iso);
    }
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/converter_test.dart`
Expected: FAIL（`enums.dart`/`converters.dart` 未作成）

- [ ] **Step 3: 最小実装を書く**

Create `lib/data/db/enums.dart`:
```dart
/// 永続化される enum。順序変更に強い textEnum(.name) で保存する。
/// 要素の追加は末尾/任意位置に可（.name 保存のため既存行は壊れない）。
/// 要素の「リネーム」は既存データを壊すのでマイグレーション必須。
enum TxnType { expense, income }

enum CategoryType { expense, income }

enum PaymentMethod { cash, creditCard, eMoney, bankDraft, other }

enum TxnSource { manual, receiptOcr }
```

Create `lib/data/db/converters.dart`:
```dart
import 'package:drift/drift.dart';
import '../../domain/money/civil_date.dart';

/// CivilDate を TEXT 'YYYY-MM-DD' として保存する drift TypeConverter。
/// ゼロ埋めISOなので辞書順＝時系列順となり、月次範囲クエリを文字列比較で行える。
class CivilDateConverter extends TypeConverter<CivilDate, String> {
  const CivilDateConverter();

  @override
  CivilDate fromSql(String fromDb) => CivilDate.parse(fromDb);

  @override
  String toSql(CivilDate value) => value.toIso();
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/converter_test.dart`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/data/db/enums.dart lib/data/db/converters.dart test/converter_test.dart
git commit -m "feat: add persisted enums and CivilDate drift converter"
```

---

## Task 4: テーブル・DB・コード生成・外部キー実効化

**Files:**
- Create: `lib/data/db/tables.dart`
- Create: `lib/data/db/database.dart`
- Create: `lib/data/db/daos.dart`（この段では空のDAO骨格。中身はTask 6/7）
- Create: `test/support/test_db.dart`
- Create: `test/flutter_test_config.dart`
- Test: `test/database_fk_test.dart`

**Interfaces:**
- Consumes: enum（Task 3）、`CivilDateConverter`（Task 3）
- Produces:
  - drift テーブル `Categories`, `Transactions`（生成行クラス `CategoryRow`, `TransactionRow`）
  - `class AppDatabase`（`schemaVersion => 1`、`beforeOpen`で`PRAGMA foreign_keys=ON`、`categoryDao`/`transactionDao` アクセサ）
  - `class TransactionDao`, `class CategoryDao`（この段は空、後続タスクで拡張）
  - `AppDatabase newMemoryDb()`（テスト用インメモリDBファクトリ）

- [ ] **Step 1: テーブルを定義**

Create `lib/data/db/tables.dart`:
```dart
import 'package:drift/drift.dart';
import 'enums.dart';
import 'converters.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => textEnum<CategoryType>()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TxnType>()();
  IntColumn get amount => integer()(); // 整数円・非負（アプリ側で保証）
  TextColumn get date => text().map(const CivilDateConverter())();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get source => textEnum<TxnSource>()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

- [ ] **Step 2: 空のDAO骨格を定義**

Create `lib/data/db/daos.dart`:
```dart
import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);
  // 読み書き/集計は Task 6, 7 で追加する。
}

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);
  // 読み書きは Task 5, 9 で追加する。
}
```

- [ ] **Step 3: データベースを定義**

Create `lib/data/db/database.dart`:
```dart
import 'package:drift/drift.dart';
import 'tables.dart';
import 'daos.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // FK は接続ごとに有効化しないと SQLite が無視する。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

- [ ] **Step 4: Windowsホストで sqlite3 を解決する設定を作成**

`flutter test` はホストのDart VMで動くため、`NativeDatabase` がホストの `sqlite3` を必要とする。まず native-assets 無しで動く堅牢なフォールバック（DLLロード）を用意する。

Create `test/flutter_test_config.dart`:
```dart
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

/// Flutter はテストツリー実行前にこのファイルを自動的に呼ぶ。
/// Windows ではプロジェクト直下に置いた sqlite3.dll をロードする。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () {
      final dll = '${Directory.current.path}\\sqlite3.dll';
      return DynamicLibrary.open(dll);
    });
  }
  await testMain();
}
```

- [ ] **Step 5: sqlite3.dll をプロジェクト直下に配置（load-bearing・省略不可）**

`flutter test` はホストのDart VMで走るため、`NativeDatabase.memory()` は**ホスト上の`sqlite3.dll`**を必要とする。`sqlite3: ^2.4.0`（<3.x）は native-assets 自動同梱が効かないので、これを実際に置かないと Task 4〜10 の全DBテストが `Failed to load dynamic library sqlite3.dll` で落ちる。**コード生成物ではないので、必ずこのステップを実行すること。**

sqlite.org の公開ページから現行版のwin-x64 DLLを自動取得する（バージョン固定URLは404し得るので、ダウンロードページから現行パスを抽出する）:

```powershell
$ErrorActionPreference = 'Stop'
$page = Invoke-WebRequest -Uri 'https://sqlite.org/download.html' -UseBasicParsing
$rel = ([regex]'(\d{4}/sqlite-dll-win-x64-\d+\.zip)').Match($page.Content).Groups[1].Value
if (-not $rel) { throw 'could not find win-x64 dll on sqlite.org/download.html' }
$zip = "$env:TEMP\sqlite-dll-win-x64.zip"
Invoke-WebRequest -Uri "https://sqlite.org/$rel" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath 'C:/Users/wilsh/kakeibo-app' -Force
Test-Path 'C:/Users/wilsh/kakeibo-app/sqlite3.dll'   # -> True
```
Expected: `sqlite3.dll` がプロジェクト直下に存在（`True`）。

`.gitignore` に追記してコミット対象外にする:
```bash
cd "C:/Users/wilsh/kakeibo-app"
printf '\n# Local test-only native lib\n/sqlite3.dll\n' >> .gitignore
```

> 代替: drift 2.32+ かつ `sqlite3: ^3.x` に上げれば native-assets で DLL 不要になる場合がある（`flutter test --enable-experiment=native-assets`）。本計画は確実性を優先し DLL 配置で緑にする。

- [ ] **Step 6: テスト用DBファクトリを作成**

Create `test/support/test_db.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kakeibo_app/data/db/database.dart';

/// 1テスト＝新規インメモリDB。stream購読のタイマーがテスト間に漏れないよう
/// closeStreamsSynchronously を有効化する。
AppDatabase newMemoryDb() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
```

- [ ] **Step 7: コードを生成**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
dart run build_runner build --delete-conflicting-outputs
```
Expected: `database.g.dart` と `daos.g.dart` が生成され、`Succeeded` で終わる。

- [ ] **Step 8: 失敗するFKテストを書く**

Create `test/database_fk_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = newMemoryDb());
  tearDown(() => db.close());

  test('opening the database succeeds', () async {
    // ensureOpen 相当: 単純なクエリで接続を開く
    final count = await db.customSelect('SELECT 1 AS one').getSingle();
    expect(count.read<int>('one'), 1);
  });

  test('foreign_keys PRAGMA is enforced (insert with unknown categoryId fails)',
      () async {
    expect(
      () => db.into(db.transactions).insert(TransactionsCompanion.insert(
            type: TxnType.expense,
            amount: 1200,
            date: const CivilDate(2026, 7, 3),
            categoryId: 999, // 存在しないカテゴリ
            source: TxnSource.manual,
          )),
      throwsA(isA<SqliteException>()),
    );
  });
}
```

- [ ] **Step 9: FKテストが通ることを確認**

Run: `flutter test test/database_fk_test.dart`
Expected: PASS（FKが有効なので不正な`categoryId`挿入が`SqliteException`で弾かれる）。もし2件目が通ってしまう場合は`beforeOpen`のPRAGMAが効いていない。

- [ ] **Step 10: 全テスト確認とコミット**

Run: `flutter test`
Expected: `All tests passed!`

```bash
git add -A
git commit -m "feat: add drift tables, database with FK enforcement, test harness"
```

---

## Task 5: 初期シード（プリセットカテゴリ＋未分類sentinel）

**Files:**
- Modify: `lib/data/db/database.dart`（`onCreate`でシード呼び出し＋シード実装）
- Modify: `lib/data/db/daos.dart`（`CategoryDao`に読み出しメソッド追加）
- Test: `test/seed_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Categories`, enum（Task 3/4）
- Produces:
  - 新規DBに**プリセット14(支出)+4(収入)+システム2(未分類 支出/収入)＝計20カテゴリ**がシードされる
  - `CategoryDao.allCategories()` → `Future<List<CategoryRow>>`
  - `CategoryDao.uncategorizedId(CategoryType type)` → `Future<int>`（該当typeの`isSystem`カテゴリのid）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/seed_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'support/test_db.dart';

void main() {
  test('a fresh database is seeded with presets and system categories', () async {
    final db = newMemoryDb();
    addTearDown(db.close);

    final all = await db.categoryDao.allCategories();
    // 支出プリセット14 + 収入プリセット4 + 未分類システム2 = 20
    expect(all.length, 20);

    final systems = all.where((c) => c.isSystem).toList();
    expect(systems.length, 2);
    expect(systems.where((c) => c.type == CategoryType.expense).length, 1);
    expect(systems.where((c) => c.type == CategoryType.income).length, 1);

    // プリセットに「食費」と「給与」が含まれる
    expect(all.any((c) => c.name == '食費' && c.type == CategoryType.expense), isTrue);
    expect(all.any((c) => c.name == '給与' && c.type == CategoryType.income), isTrue);
  });

  test('uncategorizedId returns the system category id per type', () async {
    final db = newMemoryDb();
    addTearDown(db.close);

    final expUncat = await db.categoryDao.uncategorizedId(CategoryType.expense);
    final incUncat = await db.categoryDao.uncategorizedId(CategoryType.income);
    expect(expUncat, isNot(incUncat));

    final all = await db.categoryDao.allCategories();
    expect(all.firstWhere((c) => c.id == expUncat).isSystem, isTrue);
    expect(all.firstWhere((c) => c.id == expUncat).type, CategoryType.expense);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/seed_test.dart`
Expected: FAIL（`allCategories`/`uncategorizedId` 未定義、シードされていない）

- [ ] **Step 3: CategoryDao に読み出しを追加**

`lib/data/db/daos.dart` の `CategoryDao` に追加:
```dart
  Future<List<CategoryRow>> allCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

  Future<int> uncategorizedId(CategoryType type) async {
    final row = await (select(categories)
          ..where((c) => c.isSystem.equals(true) & c.type.equalsValue(type)))
        .getSingle();
    return row.id;
  }
```

- [ ] **Step 4: シードを実装して onCreate から呼ぶ**

`lib/data/db/database.dart` の `beforeOpen` を、初回作成時のみシードするよう置き換える（`onCreate` は `createAll` のまま。drift公式が推奨する `details.wasCreated` ガードで、DB内部の初期化完了後に安全に投入する）:
```dart
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated) {
            await _seedInitialCategories();
          }
        },
```
同じクラス内にシードメソッドを追加:
```dart
  Future<void> _seedInitialCategories() async {
    // 並び順は sortOrder に一致させる。システム「未分類」は末尾。
    const expensePresets = <String>[
      '食費', '外食', '日用品', '水道光熱費', '通信費', '交通費', '交際費',
      '趣味・娯楽', '衣服・美容', '医療・健康', '住居', '教育', '特別費', 'その他',
    ];
    const incomePresets = <String>['給与', '賞与', '副収入', 'その他'];

    await batch((b) {
      var order = 0;
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
      // システム「未分類」（削除不可・集計には含めるがピッカーで扱いを分ける）
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
`database.dart` の import に `enums.dart` を追加（`CategoryType`使用のため）:
```dart
import 'enums.dart';
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/seed_test.dart`
Expected: PASS（20カテゴリ、システム2、`uncategorizedId`が型別に返る）

- [ ] **Step 6: 全テスト確認とコミット**

Run: `flutter test`
Expected: `All tests passed!`

```bash
git add -A
git commit -m "feat: seed preset categories and per-type Uncategorized system categories"
```

---

## Task 6: TransactionDao — 書き込みと月次読み出し

**Files:**
- Modify: `lib/data/db/daos.dart`（`TransactionDao`に追加）
- Test: `test/transaction_dao_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Transactions`, `CivilDate`, enum
- Produces:
  - `TransactionDao.insertTransaction(TransactionsCompanion c)` → `Future<int>`
  - `TransactionDao.transactionsInMonth(int year, int month)` → `Future<List<TransactionRow>>`（日付降順）
  - private `Expression<bool> _inMonth(int year, int month)`（半開区間 `[firstOfMonth, firstOfNextMonth)` の文字列比較）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/transaction_dao_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int foodId;

  setUp(() async {
    db = newMemoryDb();
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
  });
  tearDown(() => db.close());

  Future<int> add(TxnType t, int yen, CivilDate d) =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: t,
        amount: yen,
        date: d,
        categoryId: foodId,
        source: TxnSource.manual,
      ));

  test('transactionsInMonth returns only that month, newest first', () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3));
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20));
    await add(TxnType.expense, 9999, const CivilDate(2026, 8, 1)); // 翌月・除外
    await add(TxnType.expense, 500, const CivilDate(2026, 6, 30)); // 前月・除外

    final rows = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(rows.map((r) => r.amount).toList(), [800, 1200]); // 日付降順
    expect(rows.every((r) => r.date.month == 7), isTrue);
  });

  test('December range does not leak into next year', () async {
    await add(TxnType.expense, 100, const CivilDate(2026, 12, 31));
    await add(TxnType.expense, 200, const CivilDate(2027, 1, 1)); // 除外

    final rows = await db.transactionDao.transactionsInMonth(2026, 12);
    expect(rows.map((r) => r.amount).toList(), [100]);
  });

  test('stored civil date round-trips exactly', () async {
    await add(TxnType.expense, 100, const CivilDate(2026, 12, 31));
    final rows = await db.transactionDao.transactionsInMonth(2026, 12);
    expect(rows.single.date, const CivilDate(2026, 12, 31));
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/transaction_dao_test.dart`
Expected: FAIL（`insertTransaction`/`transactionsInMonth` 未定義）

- [ ] **Step 3: 実装を追加**

`lib/data/db/daos.dart` の `TransactionDao` に追加。ファイル先頭 import に `../../domain/money/civil_date.dart` を足す:
```dart
import '../../domain/money/civil_date.dart';
```
`TransactionDao` 本体:
```dart
  /// 半開区間 [firstOfMonth, firstOfNextMonth) を ISO 文字列比較で表現。
  /// date 列はゼロ埋め YYYY-MM-DD なので辞書順比較＝日付順比較。
  Expression<bool> _inMonth(int year, int month) {
    final startIso = CivilDate.firstOfMonthIso(year, month);
    final endIso = CivilDate.firstOfNextMonthIso(year, month);
    return transactions.date.isBiggerOrEqualValue(startIso) &
        transactions.date.isSmallerThanValue(endIso);
  }

  Future<int> insertTransaction(TransactionsCompanion c) =>
      into(transactions).insert(c);

  Future<List<TransactionRow>> transactionsInMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
```

> 注: `transactions.date` は converter 列だが、`isBiggerOrEqualValue`/`isSmallerThanValue` はSQL型（String）で比較する。ゼロ埋めISOのため辞書順で正しく範囲判定できる。

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/transaction_dao_test.dart`
Expected: PASS（3ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/data/db/daos.dart test/transaction_dao_test.dart
git commit -m "feat: TransactionDao insert and month-range read (string range on civil date)"
```

---

## Task 7: 集計クエリ（type別合計・カテゴリ別支出）と不変条件

**Files:**
- Modify: `lib/data/db/daos.dart`（`TransactionDao`に集計＋`CategorySpendRow`）
- Test: `test/aggregation_test.dart`

**Interfaces:**
- Consumes: `TransactionDao`（Task 6）, `Categories`
- Produces:
  - `TransactionDao.totalsByType(int year, int month)` → `Future<Map<TxnType, int>>`
  - `TransactionDao.spendingByCategory(int year, int month)` → `Future<List<CategorySpendRow>>`（支出のみ、合計降順、**アーカイブ済みカテゴリも含む**）
  - `class CategorySpendRow { int categoryId; String categoryName; int total; }`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/aggregation_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int foodId;
  late int eatOutId;

  setUp(() async {
    db = newMemoryDb();
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
    eatOutId = all.firstWhere((c) => c.name == '外食').id;
  });
  tearDown(() => db.close());

  Future<void> add(TxnType t, int yen, CivilDate d, int catId) =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: t, amount: yen, date: d, categoryId: catId,
        source: TxnSource.manual,
      ));

  test('totalsByType sums income and expense within the month only', () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3), foodId);
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20), eatOutId);
    await add(TxnType.income, 300000, const CivilDate(2026, 7, 25), foodId);
    await add(TxnType.expense, 9999, const CivilDate(2026, 8, 1), foodId); // 翌月

    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(totals[TxnType.expense], 2000);
    expect(totals[TxnType.income], 300000);
  });

  test('INVARIANT: sum of per-category expense subtotals == month expense total',
      () async {
    await add(TxnType.expense, 1200, const CivilDate(2026, 7, 3), foodId);
    await add(TxnType.expense, 300, const CivilDate(2026, 7, 4), foodId);
    await add(TxnType.expense, 800, const CivilDate(2026, 7, 20), eatOutId);

    final byCat = await db.transactionDao.spendingByCategory(2026, 7);
    final byCatSum = byCat.fold<int>(0, (a, r) => a + r.total);
    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(byCatSum, totals[TxnType.expense]);
    // 食費 1500 が外食 800 より上（降順）
    expect(byCat.first.categoryName, '食費');
    expect(byCat.first.total, 1500);
  });

  test('archived category still counts in aggregation', () async {
    await add(TxnType.expense, 5000, const CivilDate(2026, 7, 3), eatOutId);
    // 外食をアーカイブ
    await (db.update(db.categories)..where((c) => c.id.equals(eatOutId)))
        .write(const CategoriesCompanion(isArchived: Value(true)));

    final byCat = await db.transactionDao.spendingByCategory(2026, 7);
    final totals = await db.transactionDao.totalsByType(2026, 7);
    // アーカイブしても集計から消えない
    expect(byCat.any((r) => r.categoryId == eatOutId && r.total == 5000), isTrue);
    expect(totals[TxnType.expense], 5000);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/aggregation_test.dart`
Expected: FAIL（`totalsByType`/`spendingByCategory`/`CategorySpendRow` 未定義）

- [ ] **Step 3: 集計を実装**

`lib/data/db/daos.dart` の `TransactionDao` に追加:
```dart
  Future<Map<TxnType, int>> totalsByType(int year, int month) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.type, amountSum])
      ..where(_inMonth(year, month))
      ..groupBy([transactions.type]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.readWithConverter(transactions.type)!: row.read(amountSum) ?? 0,
    };
  }

  Future<List<CategorySpendRow>> spendingByCategory(int year, int month) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId),
          useColumns: false),
    ])
      ..addColumns([categories.id, categories.name, amountSum])
      ..where(_inMonth(year, month) &
          transactions.type.equalsValue(TxnType.expense))
      ..groupBy([transactions.categoryId])
      ..orderBy([OrderingTerm.desc(amountSum)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        CategorySpendRow(
          categoryId: row.read(categories.id)!,
          categoryName: row.read(categories.name)!,
          total: row.read(amountSum) ?? 0,
        ),
    ];
  }
```
`daos.dart` 末尾（クラス外）に追加:
```dart
class CategorySpendRow {
  final int categoryId;
  final String categoryName;
  final int total;
  const CategorySpendRow({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });
}
```
`daos.dart` の import に `enums.dart` を追加（`TxnType`使用）:
```dart
import 'enums.dart';
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/aggregation_test.dart`
Expected: PASS（3ケース、不変条件含む）

- [ ] **Step 5: コミット**

```bash
git add lib/data/db/daos.dart test/aggregation_test.dart
git commit -m "feat: monthly aggregation (totalsByType, spendingByCategory) with subtotal invariant"
```

---

## Task 8: ドメインエンティティとリポジトリ（drift隠蔽）

**Files:**
- Create: `lib/domain/entities.dart`
- Create: `lib/domain/repositories.dart`
- Create: `lib/data/repositories/drift_transaction_repository.dart`
- Test: `test/repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `TransactionDao`, `CategorySpendRow`, `CivilDate`, enum
- Produces:
  - `class TransactionEntity {...}`（`id?`, `type`, `amountYen`, `date:CivilDate`, `categoryId`, `paymentMethod?`, `memo?`, `source`）
  - `class MonthlySummary { int income; int expense; int get net; }`
  - `abstract interface class TransactionRepository`（`add`, `forMonth`, `summary`, `spendingByCategory`）
  - `class DriftTransactionRepository implements TransactionRepository`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_transaction_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  test('MonthlySummary.net is income minus expense', () {
    const s = MonthlySummary(income: 300000, expense: 120000);
    expect(s.net, 180000);
  });

  test('repository add + forMonth + summary work over domain types', () async {
    final db = newMemoryDb();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;

    await repo.add(TransactionEntity(
      type: TxnType.expense,
      amountYen: 1200,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
    await repo.add(TransactionEntity(
      type: TxnType.income,
      amountYen: 300000,
      date: const CivilDate(2026, 7, 25),
      categoryId: foodId,
      source: TxnSource.manual,
    ));

    final month = await repo.forMonth(2026, 7);
    expect(month.length, 2);
    expect(month.every((t) => t is TransactionEntity), isTrue);

    final summary = await repo.summary(2026, 7);
    expect(summary.expense, 1200);
    expect(summary.income, 300000);
    expect(summary.net, 298800);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/repository_test.dart`
Expected: FAIL（エンティティ/リポジトリ未作成）

- [ ] **Step 3: ドメイン型を実装**

Create `lib/domain/entities.dart`:
```dart
import 'money/civil_date.dart';
import '../data/db/enums.dart';

class TransactionEntity {
  final int? id;
  final TxnType type;
  final int amountYen; // 非負
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? memo;
  final TxnSource source;

  const TransactionEntity({
    this.id,
    required this.type,
    required this.amountYen,
    required this.date,
    required this.categoryId,
    this.paymentMethod,
    this.memo,
    required this.source,
  });
}

class MonthlySummary {
  final int income;
  final int expense;
  const MonthlySummary({required this.income, required this.expense});
  int get net => income - expense;
}
```

Create `lib/domain/repositories.dart`:
```dart
import '../data/db/daos.dart' show CategorySpendRow;
import 'entities.dart';

abstract interface class TransactionRepository {
  Future<int> add(TransactionEntity tx);
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);
}
```

- [ ] **Step 4: drift 実装を書く**

Create `lib/data/repositories/drift_transaction_repository.dart`:
```dart
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/enums.dart';
import '../db/daos.dart' show CategorySpendRow;
import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class DriftTransactionRepository implements TransactionRepository {
  final AppDatabase _db;
  DriftTransactionRepository(this._db);

  @override
  Future<int> add(TransactionEntity tx) {
    assert(tx.amountYen >= 0, 'amount must be non-negative');
    return _db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: tx.type,
      amount: tx.amountYen,
      date: tx.date,
      categoryId: tx.categoryId,
      source: tx.source,
      paymentMethod: Value(tx.paymentMethod),
      memo: Value(tx.memo),
    ));
  }

  @override
  Future<List<TransactionEntity>> forMonth(int year, int month) async {
    final rows = await _db.transactionDao.transactionsInMonth(year, month);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<MonthlySummary> summary(int year, int month) async {
    final byType = await _db.transactionDao.totalsByType(year, month);
    return MonthlySummary(
      income: byType[TxnType.income] ?? 0,
      expense: byType[TxnType.expense] ?? 0,
    );
  }

  @override
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month) =>
      _db.transactionDao.spendingByCategory(year, month);

  TransactionEntity _toEntity(TransactionRow r) => TransactionEntity(
        id: r.id,
        type: r.type,
        amountYen: r.amount,
        date: r.date,
        categoryId: r.categoryId,
        paymentMethod: r.paymentMethod,
        memo: r.memo,
        source: r.source,
      );
}
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/repository_test.dart`
Expected: PASS

- [ ] **Step 6: コミット**

```bash
git add lib/domain/entities.dart lib/domain/repositories.dart lib/data/repositories/drift_transaction_repository.dart test/repository_test.dart
git commit -m "feat: domain entities + TransactionRepository (drift hidden behind interface)"
```

---

## Task 9: カテゴリ整合性ガード（FK制限・型変更ブロック・アーカイブ）

**Files:**
- Create: `lib/domain/repositories.dart` に `CategoryRepository` 追記
- Create: `lib/data/repositories/drift_category_repository.dart`
- Modify: `lib/data/db/daos.dart`（`CategoryDao`に`activeCategories`, 更新系）
- Test: `test/category_integrity_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `CategoryDao`, enum
- Produces:
  - `CategoryDao.activeCategories()` → `Future<List<CategoryRow>>`（`isArchived=false`のみ、sortOrder昇順）
  - `CategoryDao.countTransactionsFor(int categoryId)` → `Future<int>`
  - `CategoryDao.archive(int categoryId)` → `Future<void>`（`isArchived=true`）
  - `abstract interface class CategoryRepository`（`active`, `changeType`, `archive`）
  - `class DriftCategoryRepository implements CategoryRepository`
  - `class CategoryInUseError implements Exception`（取引がある型変更を拒否）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/category_integrity_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository catRepo;
  late int foodId;

  setUp(() async {
    db = newMemoryDb();
    catRepo = DriftCategoryRepository(db);
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
  });
  tearDown(() => db.close());

  Future<void> addExpense(int catId) =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: TxnType.expense,
        amount: 1000,
        date: const CivilDate(2026, 7, 3),
        categoryId: catId,
        source: TxnSource.manual,
      ));

  test('active categories exclude archived, include everything else', () async {
    await catRepo.archive(foodId);
    final active = await db.categoryDao.activeCategories();
    expect(active.any((c) => c.id == foodId), isFalse);
    // 未分類システムを含む他は残る
    expect(active.any((c) => c.name == '外食'), isTrue);
  });

  test('deleting a category with transactions is blocked by FK RESTRICT', () async {
    await addExpense(foodId);
    expect(
      () => (db.delete(db.categories)..where((c) => c.id.equals(foodId))).go(),
      throwsA(isA<SqliteException>()),
    );
  });

  test('changing a category type is blocked when it has transactions', () async {
    await addExpense(foodId);
    expect(
      () => catRepo.changeType(foodId, CategoryType.income),
      throwsA(isA<CategoryInUseError>()),
    );
  });

  test('changing a category type is allowed when it has no transactions', () async {
    final all = await db.categoryDao.allCategories();
    final special = all.firstWhere((c) => c.name == '特別費').id;
    await catRepo.changeType(special, CategoryType.income);
    final after = await db.categoryDao.allCategories();
    expect(after.firstWhere((c) => c.id == special).type, CategoryType.income);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/category_integrity_test.dart`
Expected: FAIL（`activeCategories`/`archive`/`changeType`/`CategoryInUseError` 未定義）

- [ ] **Step 3: CategoryDao に追加**

`lib/data/db/daos.dart` の `CategoryDao` に追加:
```dart
  Future<List<CategoryRow>> activeCategories() =>
      (select(categories)
            ..where((c) => c.isArchived.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Future<int> countTransactionsFor(int categoryId) async {
    final cnt = transactions.id.count();
    final q = selectOnly(transactions)
      ..addColumns([cnt])
      ..where(transactions.categoryId.equals(categoryId));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
  }

  Future<void> archive(int categoryId) async {
    await (update(categories)..where((c) => c.id.equals(categoryId)))
        .write(const CategoriesCompanion(isArchived: Value(true)));
  }

  Future<void> setType(int categoryId, CategoryType type) async {
    await (update(categories)..where((c) => c.id.equals(categoryId)))
        .write(CategoriesCompanion(type: Value(type)));
  }
```
`CategoryDao` は `transactions` テーブルも参照するので、アノテーションを更新:
```dart
@DriftAccessor(tables: [Categories, Transactions])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
```
`daos.dart` の import に `enums.dart` が無ければ追加（Task 7で追加済みなら不要）。

- [ ] **Step 4: CategoryRepository を実装**

`lib/domain/repositories.dart` に追記:
```dart
import '../data/db/enums.dart';

abstract interface class CategoryRepository {
  Future<List<CategoryEntity>> active();
  Future<void> archive(int categoryId);

  /// 取引が紐づく型変更は集計desyncを招くため [CategoryInUseError] を投げる。
  Future<void> changeType(int categoryId, CategoryType type);
}
```
`lib/domain/entities.dart` に `CategoryEntity` を追記:
```dart
class CategoryEntity {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
  });
}
```
（`entities.dart` の import に `CategoryType` 用の `../data/db/enums.dart` は既に Task 8 で入っている。）

Create `lib/data/repositories/drift_category_repository.dart`:
```dart
import '../db/database.dart';
import '../db/enums.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class CategoryInUseError implements Exception {
  final int categoryId;
  const CategoryInUseError(this.categoryId);
  @override
  String toString() => 'CategoryInUseError(category $categoryId has transactions)';
}

class DriftCategoryRepository implements CategoryRepository {
  final AppDatabase _db;
  DriftCategoryRepository(this._db);

  @override
  Future<List<CategoryEntity>> active() async {
    final rows = await _db.categoryDao.activeCategories();
    return rows
        .map((r) => CategoryEntity(
              id: r.id,
              name: r.name,
              type: r.type,
              icon: r.icon,
              sortOrder: r.sortOrder,
              isArchived: r.isArchived,
              isSystem: r.isSystem,
            ))
        .toList();
  }

  @override
  Future<void> archive(int categoryId) => _db.categoryDao.archive(categoryId);

  @override
  Future<void> changeType(int categoryId, CategoryType type) async {
    final count = await _db.categoryDao.countTransactionsFor(categoryId);
    if (count > 0) {
      throw CategoryInUseError(categoryId);
    }
    await _db.categoryDao.setType(categoryId, type);
  }
}
```

- [ ] **Step 5: コード生成（DAOアノテーション変更を反映）**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
dart run build_runner build --delete-conflicting-outputs
```
Expected: `daos.g.dart` が再生成され `Succeeded`。

- [ ] **Step 6: テストが通ることを確認**

Run: `flutter test test/category_integrity_test.dart`
Expected: PASS（4ケース）

- [ ] **Step 7: コミット**

```bash
git add -A
git commit -m "feat: category integrity guards (archive, FK restrict, type-change block)"
```

---

## Task 10: updatedAt チョークポイントと source 不変

**Files:**
- Modify: `lib/data/db/daos.dart`（`TransactionDao.updateTransaction`）
- Modify: `lib/domain/repositories.dart`（`TransactionRepository.update`）
- Modify: `lib/data/repositories/drift_transaction_repository.dart`（`update`実装）
- Test: `test/updated_at_test.dart`

**Interfaces:**
- Consumes: `TransactionDao`, `DriftTransactionRepository`
- Produces:
  - `TransactionDao.updateFields(int id, {required int amount, required CivilDate date, required int categoryId, PaymentMethod? paymentMethod, String? memo})` → `Future<void>`（`updatedAt`を現在時刻に、`source`/`type`/`createdAt`は触らない）
  - `TransactionRepository.update(TransactionEntity tx)`（`tx.id`必須）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/updated_at_test.dart`:
```dart
import 'package:drift/drift.dart';
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

  setUp(() async {
    db = newMemoryDb();
    repo = DriftTransactionRepository(db);
    final all = await db.categoryDao.allCategories();
    foodId = all.firstWhere((c) => c.name == '食費').id;
  });
  tearDown(() => db.close());

  test('update bumps updatedAt and preserves source and createdAt', () async {
    final id = await repo.add(TransactionEntity(
      type: TxnType.expense,
      amountYen: 1000,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      source: TxnSource.receiptOcr,
    ));

    final before = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    // updatedAt の差が観測できるよう少し待つ
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await repo.update(TransactionEntity(
      id: id,
      type: TxnType.expense, // 変更対象外（source と同様、type は編集で不変前提）
      amountYen: 2500, // 変更
      date: const CivilDate(2026, 7, 4), // 変更
      categoryId: foodId,
      source: TxnSource.manual, // ここを変えても無視され、source は不変であること
    ));

    final after = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    expect(after.amount, 2500);
    expect(after.date, const CivilDate(2026, 7, 4));
    expect(after.source, TxnSource.receiptOcr); // 不変
    expect(after.createdAt, before.createdAt); // 不変
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue); // 更新
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/updated_at_test.dart`
Expected: FAIL（`repo.update`/`updateFields` 未定義）

- [ ] **Step 3: DAO に更新メソッドを追加**

`lib/data/db/daos.dart` の `TransactionDao` に追加:
```dart
  /// 編集で変わりうるフィールドだけを更新し、updatedAt を現在時刻に。
  /// type / source / createdAt は触らない（source は由来として不変）。
  Future<void> updateFields(
    int id, {
    required int amount,
    required CivilDate date,
    required int categoryId,
    PaymentMethod? paymentMethod,
    String? memo,
  }) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amount: Value(amount),
        date: Value(date),
        categoryId: Value(categoryId),
        paymentMethod: Value(paymentMethod),
        memo: Value(memo),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
```
`daos.dart` の import に `PaymentMethod` 用 `enums.dart`（既存）と `civil_date.dart`（既存）があること。

- [ ] **Step 4: リポジトリに update を追加**

`lib/domain/repositories.dart` の `TransactionRepository` に追加:
```dart
  /// 既存取引を更新する（tx.id 必須）。updatedAt は実装が更新し、source は不変。
  Future<void> update(TransactionEntity tx);
```
`lib/data/repositories/drift_transaction_repository.dart` の `DriftTransactionRepository` に追加:
```dart
  @override
  Future<void> update(TransactionEntity tx) {
    final id = tx.id;
    if (id == null) {
      throw ArgumentError('update requires a persisted transaction (id != null)');
    }
    assert(tx.amountYen >= 0, 'amount must be non-negative');
    return _db.transactionDao.updateFields(
      id,
      amount: tx.amountYen,
      date: tx.date,
      categoryId: tx.categoryId,
      paymentMethod: tx.paymentMethod,
      memo: tx.memo,
    );
  }
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/updated_at_test.dart`
Expected: PASS

- [ ] **Step 6: 全テスト確認とコミット**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
flutter test
```
Expected: `All tests passed!`（全テストファイル緑）

```bash
git add -A
git commit -m "feat: single-chokepoint update that bumps updatedAt and keeps source immutable"
```

---

## Self-Review（この計画の点検結果）

**1. Spec coverage（spec Phase 1 相当の要件）:**
- §4.1 テーブル定義 → Task 4 ✅（textEnum・nullable paymentMethod/imagePath 含む）
- §4.2 civil date 保存（tz日ズレ回避）→ Task 2/3/6（CivilDate + converter + 文字列範囲）✅
- §4.3 アーカイブは集計に含める（小計和==月次合計 不変条件）→ Task 7 ✅
- §4.4 符号/net、amount非負 → Task 8（MonthlySummary.net、assert非負）✅（返品の`type=income`計上は集計で自然に正しく、UIタスクは後続plan）
- §4.5 FK ON・未分類sentinel・型変更ブロック・削除はアーカイブ → Task 4/5/9 ✅
- §4.6 プリセット＋未分類、復元時再シード無効 → Task 5 ✅（復元は後続のbackup planで扱う）
- §9 レイヤリング（driftをdata層に隔離、repo抽象）→ Task 8/9 ✅
- §12 テスト（Windowsヘッドレス・不変条件・境界）→ 全タスクのテスト ✅
- updatedAt単一チョークポイント・source不変 → Task 10 ✅

**この plan の範囲外（別 plan）:** BackupService/復元（spec §10）、ReceiptParser/正準TextBlock（§7）、features UI（§5）、iOS Apple Vision（§8）。それぞれ後続の plan で実装する。tz敵対テスト（§12）は CivilDate が構造的にtz非依存のため本 plan では日付往復テスト（Task 3/6）で担保し、実タイムゾーン切替を要するのは DateTime 系タイムスタンプを含む backup plan 側で扱う。

**2. Placeholder scan:** "TBD"/"後で実装"/"適切なエラー処理"等の空プレースホルダなし。各コードステップに実コードを記載。✅

**3. Type consistency（タスク間の型整合）:**
- enum名 `TxnType`/`CategoryType`/`PaymentMethod`/`TxnSource` は Task 3 定義、以降一貫使用。✅
- `CivilDate` API（`parse`/`toIso`/`firstOfMonthIso`/`firstOfNextMonthIso`）は Task 2 定義、Task 3/6 で一致使用。✅
- `CategorySpendRow`（`categoryId`/`categoryName`/`total`）Task 7 定義、Task 8 の repo/interface で一致。✅
- `TransactionEntity`/`MonthlySummary`/`CategoryEntity` は Task 8/9 で定義・使用一致。✅
- DAOメソッド名 `insertTransaction`/`transactionsInMonth`/`totalsByType`/`spendingByCategory`/`updateFields`、`allCategories`/`activeCategories`/`uncategorizedId`/`countTransactionsFor`/`archive`/`setType` は定義タスクと使用タスクで一致。✅

---

## 実装メモ（新規参画エンジニア向けの落とし穴）
- **build_runner はテーブル/DAOアノテーション変更のたびに再実行**（Task 4/9でDAOの`@DriftAccessor`を変えたら`dart run build_runner build --delete-conflicting-outputs`）。
- **converter列の範囲比較はSQL型（String）で行う**（`isBiggerOrEqualValue('2026-07-01')`）。enum等の等値は`equalsValue(TxnType.x)`、集計読み出しは`readWithConverter(col)`。
- **`selectOnly` + `sum()` + `groupBy`** が集計の基本形。`select`ではなく`selectOnly`（GROUP BYに必要）。
- Windowsで`NativeDatabase.memory()`が`sqlite3`を見つけられない場合は Task 4 Step 5 の `sqlite3.dll` 配置、または `flutter test --enable-experiment=native-assets`。
