# Drift Best Practices for a Headless-Testable Personal Finance App

Target: DB + aggregation logic that runs under `flutter test` on Windows desktop via `sqlite3` + `NativeDatabase.memory()`. Everything below is written so the query/aggregation layer is exercised headlessly with zero Flutter runtime.

---

## 1. Dependencies & codegen

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0   # bundles sqlite3 INTO the shipped app (device/desktop app runtime)

dev_dependencies:
  drift_dev: ^2.20.0
  build_runner: ^2.4.0
  test: ^1.24.0
  # sqlite3: only needed if you override the loader in tests (see §9)
```

```bash
dart run build_runner build --delete-conflicting-outputs
# watch mode while developing:
dart run build_runner watch --delete-conflicting-outputs
```

Key mental model that drives the whole test story: **`flutter test` runs on the host Dart VM, not inside a Flutter app.** So `sqlite3_flutter_libs` (which bundles the native lib into your *app*) does **not** help tests — the test process must resolve `sqlite3.dll` itself. That's the one non-obvious Windows detail, handled in §9.

---

## 2. Enums and the date-storage decision (do this first — it's hard to change later)

```dart
// lib/db/enums.dart
enum TransactionType { expense, income }
enum CategoryType { expense, income }
enum PaymentMethod { cash, creditCard, debitCard, eMoney, bankTransfer, other }
enum TransactionSource { manual, receiptOcr }
```

**Enum storage — `intEnum` vs `textEnum`:**

| | stores | pro | con |
|---|---|---|---|
| `intEnum<T>()` | the enum `.index` (int) | compact, fast | **reordering/inserting enum cases silently corrupts existing rows** (index shifts) |
| `textEnum<T>()` | the enum `.name` (string) | reorder-safe, self-documenting in DB, greppable | slightly larger; **renaming a case breaks reads** |

For a **persisted finance DB you will maintain for years, prefer `textEnum`.** The few extra bytes buy immunity to the most common real-world migration foot-gun (someone adds `debitCard` in the middle of the enum a year later). Just never *rename* a case without a migration. (`intEnum` is fine only if you commit to append-only enums forever.)

**Date storage — store the transaction `date` as a civil date (epoch-day int), not an instant.** A purchase happens on a *calendar day*, not at an instant. Drift's default `DateTimeColumn` stores a Unix timestamp and reads it back in **local** time, so an instant like midnight-UTC read on a negative-offset device rolls back to the previous day — a classic off-by-one that shifts a transaction between months. Options:

- **Recommended:** `IntColumn` storing **days since epoch** via a `TypeConverter`. Timezone/DST-proof (a given calendar day always maps to the same int), sortable, and month ranges become plain integer comparisons.
- Alternative: `TextColumn` holding `"YYYY-MM-DD"` (lexicographically sortable) — fine, just more bytes.
- For true instants (`createdAt`/`updatedAt`) a normal `DateTimeColumn` is correct — those *are* moments in time.

Drift can also store all `DateTime`s as ISO-8601 text (`store_date_time_values_as_text: true` in `build.yaml`), which preserves timezone. That's the right global default for timestamp columns if you have users across zones, but it still stores a *time-of-day*, so it does **not** replace the civil-date converter for `date`.

```dart
// lib/db/converters.dart
import 'package:drift/drift.dart';

/// Stores a civil date (no time, no zone) as days since the Unix epoch.
/// TZ/DST-safe: the same calendar day always maps to the same integer.
class DateAsEpochDay extends TypeConverter<DateTime, int> {
  const DateAsEpochDay();

  @override
  DateTime fromSql(int fromDb) => DateTime.utc(1970).add(Duration(days: fromDb));

  @override
  int toSql(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day)
          .difference(DateTime.utc(1970))
          .inDays;
}

/// Shared helper so DAO query code and the converter agree byte-for-byte.
int epochDay(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970)).inDays;
```

---

## 3. Table definitions

```dart
// lib/db/tables.dart
import 'package:drift/drift.dart';
import 'enums.dart';
import 'converters.dart';

@DataClassName('CategoryRow')          // generated row class name (avoids clashing with a domain `Category`)
class Categories extends Table {
  IntColumn  get id        => integer().autoIncrement()();
  TextColumn get name      => text().withLength(min: 1, max: 50)();
  TextColumn get type      => textEnum<CategoryType>()();
  TextColumn get icon      => text().nullable()();            // e.g. an icon key / codepoint name
  IntColumn  get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived=> boolean().withDefault(const Constant(false))();
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn  get id            => integer().autoIncrement()();
  TextColumn get type          => textEnum<TransactionType>()();
  IntColumn  get amount        => integer()();                 // yen: JPY has no minor unit, so a plain int is exact
  IntColumn  get date          => integer().map(const DateAsEpochDay())();   // civil date, day granularity
  IntColumn  get categoryId    => integer().references(Categories, #id,
                                       onDelete: KeyAction.restrict)();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();
  TextColumn get memo          => text().nullable()();
  TextColumn get source        => textEnum<TransactionSource>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

Notes:
- **Money as `integer` yen** is correct and exact — never use `real()` for money. (For a multi-currency app you'd store minor units; JPY needs none.)
- `references(..., onDelete: KeyAction.restrict)` declares the FK, but **SQLite ignores FKs unless you enable them per-connection** — see the `beforeOpen` PRAGMA in §5.
- `updatedAt` has a *default* but drift won't auto-bump it on UPDATE. Set it explicitly in the DAO write path (§7), or add an `AFTER UPDATE` trigger in a migration.

---

## 4. Database + DAOs wiring

```dart
// lib/db/database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables.dart';
import 'daos.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions],
  daos:   [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);                       // prod: pass NativeDatabase(file) / LazyDatabase
  // DatabaseConnection is accepted here too (it satisfies QueryExecutor) — used by tests.

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: stepByStep(
          // from1To2: (m, schema) async { ... }   // add steps as schemaVersion grows
        ),
        beforeOpen: (details) async {
          // MUST be enabled per connection for the FK above to be enforced.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

---

## 5. DAOs: typed month-range + aggregation queries

DAOs hold the drift-specific query code; the repository (§8) sits on top and maps to domain types.

```dart
// lib/db/daos.dart
import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';
import 'enums.dart';
import 'converters.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Half-open [start, nextMonthStart) range on the epoch-day int column.
  /// DateTime.utc(year, month+1, 1) auto-normalizes December → next January.
  Expression<bool> _inMonth(int year, int month) {
    final start = epochDay(DateTime.utc(year, month, 1));
    final end   = epochDay(DateTime.utc(year, month + 1, 1)); // exclusive
    return transactions.date.isBiggerOrEqualValue(start) &
           transactions.date.isSmallerThanValue(end);
  }

  // ---- plain reads --------------------------------------------------------

  Future<List<TransactionRow>> transactionsInMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Reactive variant for the UI — emits on every relevant write.
  Stream<List<TransactionRow>> watchMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(year, month))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // ---- writes (bump updatedAt explicitly) --------------------------------

  Future<int> insertTransaction(TransactionsCompanion c) =>
      into(transactions).insert(c);

  Future<bool> updateTransaction(TransactionRow row) =>
      update(transactions).replace(
        row.copyWith(updatedAt: DateTime.now()),
      );

  // ---- aggregation: SUM by type for a month ------------------------------

  Future<Map<TransactionType, int>> totalsByType(int year, int month) async {
    final amountSum = transactions.amount.sum();          // Expression<int>
    final query = selectOnly(transactions)
      ..addColumns([transactions.type, amountSum])
      ..where(_inMonth(year, month))
      ..groupBy([transactions.type]);

    final rows = await query.get();
    return {
      for (final row in rows)
        // converter columns: use readWithConverter to get the enum back
        row.readWithConverter(transactions.type)!: row.read(amountSum) ?? 0,
    };
  }

  // ---- aggregation: SUM per category (joined for the name) ---------------

  Future<List<CategorySpendRow>> spendingByCategory(int year, int month) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..addColumns([categories.id, categories.name, amountSum])
      ..where(
        _inMonth(year, month) &
        transactions.type.equalsValue(TransactionType.expense), // converter-aware equals
      )
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
}

class CategorySpendRow {
  final int categoryId;
  final String categoryName;
  final int total;
  CategorySpendRow({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });
}

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<CategoryRow>> activeCategories() =>
      (select(categories)
            ..where((c) => c.isArchived.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Future<int> insertCategory(CategoriesCompanion c) =>
      into(categories).insert(c);
}
```

Aggregation API cheat-sheet (the parts people get wrong):
- Use **`selectOnly(table)`** (not `select`) so the result contains *only* your aggregate columns — required for a valid `GROUP BY`. `selectOnly(...).join([...])` is valid; it returns a `JoinedSelectStatement`.
- Read aggregate expressions with `row.read(expr)`; read **converter/enum columns** with `row.readWithConverter(col)`.
- Compare enum columns with `col.equalsValue(MyEnum.x)`, and epoch-day int columns with `isBiggerOrEqualValue` / `isSmallerThanValue`.
- Keep the month filter in `where` here (it's an inner join over a mandatory FK, so no outer-join-null pitfall). If you ever switch to `leftOuterJoin` to include zero-spend categories, move the date filter **into the join condition**, or the `WHERE` will drop the null-joined rows and silently defeat the outer join.

---

## 6. Migration & schema-version strategy

- Start at `schemaVersion = 1`; **bump by exactly 1 per shipped schema change** and add one `stepByStep` handler per bump. Never mutate an already-released migration step — append new ones.
- `onCreate: (m) => m.createAll()` builds a fresh DB; `onUpgrade` walks existing users up.
- Keep `PRAGMA foreign_keys = ON` in `beforeOpen` (above). Do FK-sensitive bulk migrations inside `m.runCustom` while foreign keys are temporarily off if needed.
- **Verify migrations mechanically** using drift's schema tooling instead of eyeballing them:

```bash
# 1. Snapshot the current schema as a new version file (run after each bump):
dart run drift_dev schema dump lib/db/database.dart drift_schemas/

# 2. Generate versioned helper code for tests:
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

```dart
// test/migration_test.dart
import 'package:drift_dev/api/migrations.dart';
import 'package:test/test.dart';
import 'generated_migrations/schema.dart';
// ... plus your AppDatabase import

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('migrates v1 -> v2 and preserves/validates data', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    // migrateAndValidate opens at target version, runs migration, and asserts
    // the resulting schema exactly matches the generated v2 snapshot.
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });
}
```

This catches the "my hand-written migration and my table definitions drifted apart" class of bug before release.

If you later globalize timestamps: set `store_date_time_values_as_text: true` in `build.yaml`, bump `schemaVersion`, and in that step call the drift-provided one-time converters `migrateFromUnixTimestampsToText(...)` (or the reverse `migrateFromTextDateTimesToUnixTimestamps(...)`). Choose one strategy per column *before launch* if you can — flipping it mid-history is the sharpest edge here.

---

## 7. Repository pattern over the DAOs

DAOs already look repository-ish, so the extra layer only earns its keep when you want to (a) keep drift types (`TransactionRow`, `Companion`, `Expression`) out of your domain/UI, and (b) make the domain independently unit-testable / swappable. For a finance app that's worth it — your aggregation and month logic become plain functions over domain entities.

```dart
// lib/domain/entities.dart  (no drift imports here)
class TransactionEntity {
  final int? id;
  final TransactionType type;
  final int amountYen;
  final DateTime date;         // a civil date
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? memo;
  final TransactionSource source;
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
  int get net => income - expense;
  const MonthlySummary({required this.income, required this.expense});
}
```

```dart
// lib/domain/transaction_repository.dart  (interface — domain-only)
abstract interface class TransactionRepository {
  Future<void> add(TransactionEntity tx);
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);
}
```

```dart
// lib/data/drift_transaction_repository.dart  (drift lives ONLY here)
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/tables.dart';
import '../db/enums.dart';
import '../domain/entities.dart';
import '../domain/transaction_repository.dart';

class DriftTransactionRepository implements TransactionRepository {
  final AppDatabase _db;
  DriftTransactionRepository(this._db);
  TransactionDao get _dao => _db.transactionDao;

  @override
  Future<void> add(TransactionEntity tx) {
    return _dao.insertTransaction(TransactionsCompanion.insert(
      type: tx.type,
      amount: tx.amountYen,
      date: tx.date,                                   // converter turns it into epoch-day
      categoryId: tx.categoryId,
      source: tx.source,
      paymentMethod: Value(tx.paymentMethod),
      memo: Value(tx.memo),
    ));
  }

  @override
  Future<List<TransactionEntity>> forMonth(int year, int month) async {
    final rows = await _dao.transactionsInMonth(year, month);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<MonthlySummary> summary(int year, int month) async {
    final byType = await _dao.totalsByType(year, month);
    return MonthlySummary(
      income:  byType[TransactionType.income]  ?? 0,
      expense: byType[TransactionType.expense] ?? 0,
    );
  }

  @override
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month) =>
      _dao.spendingByCategory(year, month);

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

Now domain/UI code depends on `TransactionRepository`, never on drift.

---

## 8. In-memory test setup (the headless-on-Windows part)

**Shared factory + per-test lifecycle.** A fresh `NativeDatabase.memory()` per test gives you total isolation with no cleanup files. Wrap it in a `DatabaseConnection` with `closeStreamsSynchronously: true` so stream subscriptions don't leak timers across tests (mandatory if any test touches `.watch()`).

```dart
// test/support/test_db.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../../lib/db/database.dart';

AppDatabase newMemoryDb() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
```

```dart
// test/transaction_dao_test.dart
import 'package:drift/drift.dart';
import 'package:test/test.dart';
import '../lib/db/database.dart';
import '../lib/db/tables.dart';
import '../lib/db/enums.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newMemoryDb());
  tearDown(() => db.close());

  test('totalsByType sums income and expense within the month only', () async {
    final catId = await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(name: 'Food', type: CategoryType.expense),
    );

    Future<void> add(TransactionType t, int yen, DateTime d) =>
        db.transactionDao.insertTransaction(TransactionsCompanion.insert(
          type: t, amount: yen, date: d, categoryId: catId,
          source: TransactionSource.manual,
        ));

    await add(TransactionType.expense, 1200, DateTime(2026, 7, 3));
    await add(TransactionType.expense,  800, DateTime(2026, 7, 20));
    await add(TransactionType.income, 300000, DateTime(2026, 7, 25));
    await add(TransactionType.expense, 9999, DateTime(2026, 8, 1)); // next month, excluded

    final totals = await db.transactionDao.totalsByType(2026, 7);
    expect(totals[TransactionType.expense], 2000);
    expect(totals[TransactionType.income], 300000);
  });
}
```

### Making `sqlite3` load under `flutter test` on Windows

Because the test host is the Dart VM, not your bundled app, `NativeDatabase` needs to find `sqlite3.dll` on the *host*. Two eras:

**A. Modern (recommended, drift 2.32+ with `sqlite3` 3.x):** the `sqlite3` package uses **Dart build hooks / native assets**, so an up-to-date SQLite is compiled/bundled automatically for host tests too — usually **no DLL wrangling needed**. On some Dart/Flutter versions this still requires opting into the experiment:

```bash
flutter test --enable-experiment=native-assets
# (or `dart test --enable-experiment=native-assets` for pure-Dart packages)
```

**B. Robust fallback (any version, or when you don't want the experiment):** add a `dev_dependencies: sqlite3: ^2.4.0`, drop a Windows `sqlite3.dll` (from sqlite.org's "Precompiled Binaries for Windows") at the project root or on `PATH`, and point the loader at it from Flutter's special auto-discovered config file:

```dart
// test/flutter_test_config.dart  — Flutter runs this before any test in the tree.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () {
      // sqlite3.dll placed at the project root (Directory.current during tests).
      return DynamicLibrary.open('${Directory.current.path}\\sqlite3.dll');
    });
  } else if (Platform.isLinux || Platform.isMacOS) {
    // system libsqlite3 is normally already present on CI runners
  }
  await testMain();
}
```

(For pure `dart test` packages, put the same override in `setUpAll` instead of `flutter_test_config.dart`.) Start with **A**; keep **B** in your back pocket for CI images where the toolchain can't build native assets. Either way, the FFI target is `sqlite3` — nothing in the query/aggregation layer above changes between test and production.

---

## Summary of the load-bearing choices

- **`textEnum`** for all persisted domain enums (reorder-safe) — not `intEnum`.
- **`date` as an epoch-day `int` via `TypeConverter`** (civil-date, TZ/DST-proof); keep `createdAt/updatedAt` as real `DateTime`.
- **Month queries = half-open int range** `[epochDay(1st), epochDay(next-1st))`.
- **Aggregations via `selectOnly` + `sum()` + `groupBy`**, reading enums with `readWithConverter` and filtering with `equalsValue`.
- **`schemaVersion` + `stepByStep` + `drift_dev schema` verification**; `PRAGMA foreign_keys = ON` in `beforeOpen`.
- **Repository interface over DAOs** so drift types never leak into domain/UI.
- **Tests:** `NativeDatabase.memory()` in `DatabaseConnection(closeStreamsSynchronously: true)`, fresh per `setUp`; resolve `sqlite3` on Windows host via native-assets (modern) or an `open.overrideFor` DLL loader in `flutter_test_config.dart` (fallback).

---

**Sources:**
- [Testing – Drift (simonbinder.eu)](https://drift.simonbinder.eu/testing/)
- [DateTime Storage – Drift](https://drift.simonbinder.eu/guides/datetime-migrations/)
- [Migrations – Drift](https://drift.simonbinder.eu/migrations/)
- [Tables / Dart API – Drift](https://drift.simonbinder.eu/dart_api/tables/)
- [Supported platforms – Drift](https://drift.simonbinder.eu/platforms/)
- [sqlite3 package (pub.dev)](https://pub.dev/packages/sqlite3)
- [drift issue #418 — testing on Windows (sqlite dependency)](https://github.com/simolus3/drift/issues/418)
- [drift_dev changelog (pub.dev)](https://pub.dev/packages/drift_dev/changelog)