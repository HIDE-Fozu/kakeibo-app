I have enough grounding (Riverpod 3.0, Sept 2025; feature-first + layered is the current idiom). The rest is standard platform-channel/table_calendar/image_picker knowledge. Here is the guidance.

---

# Idiomatic structure — Flutter iOS-first kakeibo app (Riverpod + table_calendar + OCR)

Target stack as of mid-2026: **Riverpod 3.0 with code generation** (`@riverpod` + `build_runner`), feature-first folders over a shared layered core, drift for persistence, Apple Vision OCR behind a `MethodChannel`. The legacy `StateProvider`/`StateNotifierProvider` are deprecated in 3.0 — do not use them for new code.

## 1. Top-level layout

```
lib/
  app/                      # composition root — no business logic
    app.dart                # MaterialApp.router, theme, localization
    bootstrap.dart          # runApp + ProviderScope + overrides + error zone
    router.dart             # go_router config (routes reference features/)
  data/                     # how data is stored/fetched (framework-facing)
    database/               # drift: AppDatabase, tables, DAOs
    repositories/           # concrete repo impls (drift-backed)
    dtos/                   # persistence/serialization models (if distinct)
  domain/                   # pure Dart — no Flutter, no platform, no drift
    models/                 # Transaction, Category, Money, ReceiptDraft...
    repositories/           # abstract repository interfaces
    services/               # abstract service interfaces (OcrService) + pure logic
      ocr/
        ocr_service.dart        # abstract class OcrService + OcrResult value type
        receipt_parser.dart     # pure-Dart ReceiptParser (Windows-testable)
  services/                 # concrete platform/infra services (impure)
    ocr/
      apple_vision_ocr_service.dart   # MethodChannel impl (iOS-only runtime)
      fake_ocr_service.dart           # deterministic test/dev double
    ocr_providers.dart              # provider wiring for the service
  features/
    calendar/  entry/  receipt/  summary/  settings/
  core/                     # cross-cutting: extensions, date utils, result types
```

Two deliberate choices to note:

- **`domain/services/` holds the *interface* + *pure logic* (`OcrService`, `ReceiptParser`); `services/` holds the *impure implementations* (`AppleVisionOcrService`, `FakeOcrService`).** This split is the whole trick that keeps parsing testable on Windows while iOS-only code stays isolated (§4).
- The requested `app / data / domain/services / features` maps cleanly onto Andrea Bizzotto's 4-layer model (data / domain / application / presentation), where your `services/` ≈ the application/service layer and `features/*/presentation` ≈ presentation.

**Dependency rule (enforce with import discipline / a lint):** `features → domain ← data`, `features → services → domain`. `domain/` imports nothing but Dart + its own models. `data/` and `services/` implement `domain/` interfaces. `features/` never import drift or `MethodChannel` directly — only providers and domain types.

## 2. Provider organization — by feature, keyed to layers

Rules of thumb:

- **Repositories and services are providers**, so features depend on interfaces and tests can override them.
- **List/mutation state → `AsyncNotifier`** (`@riverpod class`). Ephemeral derived/read-only values → plain `@riverpod` functions.
- **Co-locate providers with what they serve**: repository providers live next to the repo (`data/` or a `providers.dart`), screen-state notifiers live in `features/<x>/application/`.
- Name generated providers by intent: `transactionRepositoryProvider`, `dayTransactionsProvider`, `monthSummaryProvider`.

### 2a. Repository as a provider (with an override seam)

Keep the interface in `domain/`, the impl in `data/`, and expose it as a `keepAlive` provider that you can override in `bootstrap.dart` (real drift) and in tests (fake/in-memory).

```dart
// domain/repositories/transaction_repository.dart  (pure)
abstract interface class TransactionRepository {
  Stream<List<Transaction>> watchByDay(DateTime day);      // day-normalized
  Stream<List<Transaction>> watchByMonth(int year, int month);
  Future<void> add(Transaction tx);
  Future<void> update(Transaction tx);
  Future<void> delete(TransactionId id);
}

// data/repositories/transaction_repository_providers.dart
@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    throw UnimplementedError('override in bootstrap with DriftTransactionRepository');
```

```dart
// app/bootstrap.dart
final db = AppDatabase();               // drift
runApp(ProviderScope(
  overrides: [
    transactionRepositoryProvider.overrideWithValue(DriftTransactionRepository(db)),
  ],
  child: const MyApp(),
));
```

The `throw UnimplementedError` default is intentional: it forces a real binding at composition time and makes "you forgot to override in a test" fail loudly instead of silently touching a real DB.

### 2b. `AsyncNotifier` for the transaction list + mutations

Because drift exposes reactive `Stream`s, the cleanest form is a **stream-returning `build`** (codegen generates a `StreamNotifier`, which shares the `AsyncValue` surface and is what the request means by "async notifier for lists"). Mutations delegate to the repo; the drift stream re-emits, so you rarely invalidate manually.

```dart
// features/entry/application/day_transactions_notifier.dart
@riverpod
class DayTransactions extends _$DayTransactions {
  @override
  Stream<List<Transaction>> build(DateTime day) {
    // `day` MUST be date-normalized by the caller (see 2d).
    return ref.watch(transactionRepositoryProvider).watchByDay(day);
  }

  Future<void> add(Transaction tx) =>
      ref.read(transactionRepositoryProvider).add(tx);   // stream re-emits → UI updates
  Future<void> remove(TransactionId id) =>
      ref.read(transactionRepositoryProvider).delete(id);
}
```

If you must return a `Future` (e.g. a non-reactive source), use the true `AsyncNotifier` shape and refresh explicitly:

```dart
@riverpod
class DayTransactions extends _$DayTransactions {
  @override
  Future<List<Transaction>> build(DateTime day) =>
      ref.watch(transactionRepositoryProvider).fetchByDay(day);

  Future<void> add(Transaction tx) async {
    await ref.read(transactionRepositoryProvider).add(tx);
    ref.invalidateSelf();                 // or optimistic: state = AsyncData([...])
    await future;                         // await the rebuild so callers can await add()
  }
}
```

### 2c. Family providers keyed by day and by month

Codegen turns extra `build` parameters into a family automatically:

```dart
// keyed by day  → dayTransactionsProvider(day)
Future<List<Transaction>> build(DateTime day) => ...

// keyed by month → monthSummaryProvider(year, month)
@riverpod
Future<MonthSummary> monthSummary(Ref ref, int year, int month) async {
  final txs = await ref.watch(monthTransactionsProvider(year, month).future);
  return MonthSummary.from(txs);          // pure aggregation
}
```

- **Calendar cell dots** read `monthTransactionsProvider(y, m)` once and group locally (do **not** spawn one provider per visible day — 42 cells × families = churn).
- **The day detail sheet** reads `dayTransactionsProvider(selectedDay)`.
- `monthSummaryProvider` is derived (a plain `@riverpod` function `watch`ing the month list) so the summary tab and the calendar stay consistent with zero extra fetching.

### 2d. The non-obvious gotcha: **normalize family keys**

Family identity is by argument `==`. `table_calendar` hands you `DateTime`s that carry **time components and time-zone offset**. `DateTime(2026,7,3,14,05) != DateTime(2026,7,3,0,0)`, so if you feed the raw `selectedDay` into `dayTransactionsProvider`, every tap mints a brand-new provider, refetches, and leaks cache. **Always normalize before keying:**

```dart
// core/date_utils.dart
DateTime dayKey(DateTime d) => DateUtils.dateOnly(d);         // strips time
```

For the month family, prefer a **value key with structural equality** over a `DateTime`. Either two `int`s (`year, month`) as above, or a Dart 3 record `(int year, int month)` / a small `Month` value type — records have built-in value equality and are ideal family keys. Never key a month family by a `DateTime` unless you guarantee it's the normalized first-of-month.

## 3. `table_calendar` wiring (calendar feature)

Hold `focusedDay`/`selectedDay` in a tiny `@riverpod` notifier (or local `StatefulWidget` state); drive dots from the **month** provider; drive the detail sheet from the **day** provider.

```dart
final month = ref.watch(currentMonthProvider);              // (year, month)
final byDay = ref.watch(monthTransactionsProvider(month.$1, month.$2)); // AsyncValue

TableCalendar(
  focusedDay: focused,
  selectedDayPredicate: (d) => DateUtils.isSameDay(d, selected),
  onDaySelected: (sel, foc) => ref.read(selectedDayProvider.notifier)
      .set(dayKey(sel)),                                     // normalized!
  onPageChanged: (foc) => ref.read(currentMonthProvider.notifier)
      .set((foc.year, foc.month)),
  eventLoader: (d) => byDay.valueOrNull?[dayKey(d)] ?? const [],
  calendarBuilders: CalendarBuilders(markerBuilder: ...),   // spend dots
);
```

## 4. OCR: abstract service, Fake, Apple Vision behind a channel, pure parser

The design goal: **`ReceiptParser` is 100% pure Dart and runs in `flutter test` on Windows; only `AppleVisionOcrService` touches the platform, and it's swapped out everywhere except a real iOS device/sim.**

### 4a. Split "get pixels → text" (impure, platform) from "text → structured receipt" (pure)

```dart
// domain/services/ocr/ocr_service.dart  (pure interface + value type)
class OcrResult {                          // plain value object, no Flutter types
  final List<OcrLine> lines;               // text + bounding box + confidence
  const OcrResult(this.lines);
}
abstract interface class OcrService {
  Future<OcrResult> recognize(Uint8List imageBytes);   // bytes in, text out
}
```

```dart
// domain/services/ocr/receipt_parser.dart  (PURE — the part worth testing)
class ReceiptParser {
  ReceiptDraft parse(OcrResult ocr) {
    // total/date/merchant/line-item heuristics, regex, JP yen normalization…
    // No image_picker, no MethodChannel, no dart:ui. Just String/num logic.
  }
}
```

`ReceiptParser` never sees a `MethodChannel` or a `File` — only an `OcrResult`. That boundary is what lets you write dozens of fast unit tests on Windows against fixture text.

### 4b. FakeOcrService (tests + Windows/desktop dev)

```dart
// services/ocr/fake_ocr_service.dart
class FakeOcrService implements OcrService {
  final OcrResult canned;
  FakeOcrService(this.canned);
  @override
  Future<OcrResult> recognize(Uint8List _) async => canned;
}
```

Load canned `OcrResult`s from JSON fixtures captured off real receipts. Now the whole receipt pipeline (`recognize → parse → draft`) is exercisable with **zero platform code**, so you can develop the receipt feature on Windows before ever booting a Mac.

### 4c. AppleVisionOcrService behind a `MethodChannel` (iOS-only at runtime)

```dart
// services/ocr/apple_vision_ocr_service.dart
class AppleVisionOcrService implements OcrService {
  static const _ch = MethodChannel('app/ocr');
  @override
  Future<OcrResult> recognize(Uint8List bytes) async {
    final raw = await _ch.invokeMethod<Map>('recognizeText', {'image': bytes});
    return _decode(raw!);                  // Map → OcrResult (still pure Dart, testable)
  }
}
```

Swift side (`ios/Runner/`, VNRecognizeTextRequest) implements `recognizeText`. Keep the Dart↔native contract narrow: send bytes, receive a plain map of `{text, box, confidence}` — no custom classes across the channel.

### 4d. Provider wiring with a platform guard

```dart
// services/ocr/ocr_providers.dart
@riverpod
OcrService ocrService(Ref ref) {
  if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
    return AppleVisionOcrService();
  }
  return FakeOcrService(devFixture);       // Windows/Android dev + non-iOS fallback
}

@riverpod
ReceiptParser receiptParser(Ref ref) => const ReceiptParser();  // pure, no deps

// features/receipt/application/scan_receipt_notifier.dart
@riverpod
class ScanReceipt extends _$ScanReceipt {
  @override
  FutureOr<ReceiptDraft?> build() => null;

  Future<void> scan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final xfile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (xfile == null) return null;
      final bytes = await xfile.readAsBytes();
      final ocr = await ref.read(ocrServiceProvider).recognize(bytes);
      return ref.read(receiptParserProvider).parse(ocr);   // pure step
    });
  }
}
```

In tests, override just the seam: `ocrServiceProvider.overrideWithValue(FakeOcrService(fixture))`. You never instantiate `AppleVisionOcrService` off-device, so its `MethodChannel` is never touched during Windows test runs.

### 4e. What runs where

| Layer | Test type | Runs on Windows? |
|---|---|---|
| `ReceiptParser`, `OcrResult` decode, `MonthSummary.from` | pure `dart test` / `flutter test` | ✅ yes, fast, no binding |
| `AsyncNotifier`s + repo (with `FakeOcrService` / in-memory drift `NativeDatabase.memory()`) | `flutter test` + `ProviderContainer` | ✅ yes |
| `AppleVisionOcrService` real channel | integration test on device/sim | ❌ macOS/iOS only |

Optional: you can still test the **channel marshalling** on Windows with `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`, feeding a canned map and asserting `_decode` — but that's covering serialization, not Vision itself.

## 5. Per-feature folder convention

Every feature is a vertical slice with the same three subfolders (`presentation` = screens/widgets, `application` = Riverpod notifiers/state for that screen, `domain`/`data` only if the feature owns types nothing else needs — otherwise promote to top-level `domain/`).

```
features/
  calendar/
    presentation/  calendar_screen.dart, month_marker.dart
    application/   selected_day_provider.dart, current_month_provider.dart
  entry/                                   # add/edit a transaction
    presentation/  entry_form_screen.dart, amount_field.dart, category_picker.dart
    application/   entry_form_notifier.dart      # form state, validation
                   day_transactions_notifier.dart
  receipt/                                 # camera → OCR → draft → confirm
    presentation/  scan_screen.dart, receipt_review_screen.dart
    application/   scan_receipt_notifier.dart
    # NOTE: OcrService/ReceiptParser live in domain/ + services/, NOT here —
    #       this feature only orchestrates them.
  summary/                                 # monthly totals, category breakdown
    presentation/  summary_screen.dart, category_bar_chart.dart
    application/   month_summary is in domain aggregation; feature holds view state
  settings/
    presentation/  settings_screen.dart
    application/   settings_notifier.dart        # currency, first-day-of-week, theme
```

Convention notes:

- **Shared domain types stay in top-level `domain/`**, not inside a feature, the moment a second feature needs them (`Transaction`, `Category`, `Money` are shared → top-level). A type used by exactly one feature can live in that feature's own `domain/`.
- **`settings` often owns app-wide preference providers** (`firstDayOfWeek`, `currencyFormat`) that `calendar`, `entry`, and `summary` all `watch`. Put the provider in `settings/application/` and let others depend on it — that's a fine cross-feature read.
- **One barrel per feature is optional**; prefer explicit imports so the dependency rule stays visible in code review.

## 6. Setup checklist

- `flutter_riverpod`, `riverpod_annotation`; dev: `riverpod_generator`, `build_runner`, `custom_lint`, `riverpod_lint`. Run `dart run build_runner watch -d`.
- Enable `riverpod_lint` — it catches missing `ref.watch`, non-const provider misuse, and family-key mistakes.
- drift with `NativeDatabase.memory()` for tests; real DB constructed only in `bootstrap.dart`.
- Put `ProviderScope` overrides (repo impl, and on non-iOS the `ocrServiceProvider`) in `bootstrap.dart` so `main` stays a one-liner.

## Sources

- [What's new in Riverpod 3.0 — riverpod.dev](https://riverpod.dev/docs/whats_new)
- [Migrating from 2.0 to 3.0 — riverpod.dev](https://riverpod.dev/docs/3.0_migration)
- [Notifier & AsyncNotifier with the Riverpod Generator — codewithandrea.com](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/)
- [Flutter App Architecture with Riverpod — codewithandrea.com](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
- [Flutter Project Structure: Feature-first or Layer-first? — codewithandrea.com](https://codewithandrea.com/articles/flutter-project-structure/)
- [Clean Architecture in Flutter 2026 — dev.to](https://dev.to/techwithsam/clean-architecture-in-flutter-2026-practical-implementation-guide-1dfb)