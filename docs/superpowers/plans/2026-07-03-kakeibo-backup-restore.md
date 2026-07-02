# 家計簿アプリ Phase 2: バックアップ／復元 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** データ喪失防止の核心であるバックアップ／復元層（spec §10）を、Windowsの`flutter test`で完全に自走検証できる形で構築する。JSON往復・validate-then-swapのアトミック復元・サイレント自動退避（世代管理）・CSVエクスポート・パスフレーズ暗号化までを、UIなしのサービス層として揃える。

**Architecture:** `BackupCodec`（純粋なJSON直列化＋厳格検証＝復元の門番）、`BackupService`（DB⇄payloadの読み書きとアトミックswap）、`AutoBackupStore`（注入された`Directory`上のローリング世代管理。path_provider等のプラグインには依存せず、UIフェーズで配線）、`CsvExporter`（閲覧用・エクスポート専用）、`BackupCrypto`（AES-GCM＋PBKDF2）を分離。**検証はcodecに集約し、swapはcodecを通過したpayloadだけを信頼する**（この分離により、swapのロールバックを「codecを迂回した不正payload」でテストできる）。

**Tech Stack:** Phase 1の成果（drift/AppDatabase/CivilDate/enum）、`dart:convert`/`dart:io`（VMテスト可）、`cryptography`パッケージ（純Dart AES-GCM/PBKDF2）。

## Global Constraints

これらは**全タスク共通の暗黙要件**。各タスクの要件に必ず含まれる。

- Phase 1のGlobal Constraintsをすべて継承（整数円・CivilDate・textEnum・FK ON・updatedAtチョークポイント・Windowsヘッドレステスト・TDD）。
- **JSONが唯一の復元フォーマット**。CSVはエクスポート専用（UTF-8 with BOM・CRLF・RFC-4180エスケープ）で、復元パスに置かない。
- **復元は validate-then-swap**: ファイル全体をメモリでパース・完全検証してから、**単一driftトランザクション内で** delete-all → insert-all。新データが挿入可能と証明されるまで既存を消さない。
- **IDは逐語的に保存**（カテゴリ・取引とも元IDのまま復元。再割当しない）。
- **復元前スナップショット（自動退避）**: 共有シート不要のサイレント書き込み。書き込み後に**再読込＋再パース検証**してから初めて削除に進む。タイムスタンプ付き・上書きしない（ローリング世代）。
- **復元時にプリセット再シードは走らない**ことを保証（シードは`wasCreated`時のみ＝既存DBへの復元では発火しない。テストで担保）。
- バックアップの`formatVersion`は**範囲検証**: 欠落/0は不正、アプリより新しい版は拒否、古い版は前方マイグレーション（v1時点では変換なし・機構のみ）。
- タイムスタンプ（createdAt/updatedAt/exportedAt）はJSON上 **UTC ISO-8601 文字列**、取引日は **`YYYY-MM-DD`文字列**。tz安全性は構造で担保（後述の逸脱メモ参照）。
- プラグイン（path_provider等）に依存しない。ファイル置き場は`Directory`をコンストラクタ注入（テスト＝一時ディレクトリ、アプリ配線はUIフェーズ）。

> **specからの意図的な逸脱（記録）**: spec §12の「複数TZ設定でテストを実行」は、WindowsのDart VMが`TZ`環境変数を尊重しないため実行不可能。代わりに (a) 取引日はCivilDate文字列＝構造的にtz非依存、(b) createdAt/updatedAtはUTC ISO文字列で直列化し「瞬間の同一性」を`toUtc()`等値でテスト、で同じリスクを塞ぐ。

---

## File Structure

```
kakeibo-app/
  lib/data/backup/
    backup_data.dart        # BackupPayload / BackupCategory / BackupTxn（行と1:1の純モデル）+ BackupException階層
    backup_codec.dart       # encode/decode＋厳格検証＋formatVersion＋前方マイグレーション機構
    backup_service.dart     # exportPayload/exportJson/exportCsv/applyRestore/restoreFromJson
    auto_backup_store.dart  # ローリング世代の自動退避（Directory注入・clock注入）
    csv_exporter.dart       # 取引CSV文字列の生成（BOM/CRLF/RFC-4180）
    backup_crypto.dart      # パスフレーズ暗号化（AES-GCM 256 + PBKDF2）
  test/backup/
    backup_codec_test.dart
    backup_export_test.dart
    backup_restore_test.dart
    auto_backup_store_test.dart
    backup_service_flow_test.dart
    csv_exporter_test.dart
    backup_crypto_test.dart
```

なぜエンティティを再利用しないか: `TransactionEntity`は`imagePath`/`createdAt`/`updatedAt`を持たない（UI用の形）。バックアップは**行の完全な忠実度**が要件なので、行と1:1の専用モデルを持つ。境界が明確になり、エンティティの将来変更がバックアップ形式を壊さない。

---

## Task 1: バックアップモデルと encode（直列化）

**Files:**
- Create: `lib/data/backup/backup_data.dart`
- Create: `lib/data/backup/backup_codec.dart`（この段はencodeのみ。decodeはTask 2）
- Test: `test/backup/backup_codec_test.dart`（encode分）

**Interfaces:**
- Consumes: `CivilDate`, enum（Phase 1）
- Produces:
  - `class BackupCategory { int id; String name; CategoryType type; String? icon; int sortOrder; bool isArchived; bool isSystem; }`
  - `class BackupTxn { int id; TxnType type; int amount; CivilDate date; int categoryId; PaymentMethod? paymentMethod; String? memo; TxnSource source; String? imagePath; DateTime createdAt; DateTime updatedAt; }`
  - `class BackupPayload { int formatVersion; DateTime? exportedAt; List<BackupCategory> categories; List<BackupTxn> transactions; }`
  - `abstract class BackupException implements Exception { String get message; }`
  - `class BackupCodec { static const int formatVersion = 1; String encode(BackupPayload p); }`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/backup/backup_codec_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

BackupPayload samplePayload() => BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3, 12, 0),
      categories: [
        const BackupCategory(
            id: 1, name: '食費', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false),
        const BackupCategory(
            id: 19, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 18, isArchived: false, isSystem: true),
        const BackupCategory(
            id: 20, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 19, isArchived: false, isSystem: true),
      ],
      transactions: [
        BackupTxn(
          id: 10, type: TxnType.expense, amount: 1200,
          date: const CivilDate(2026, 7, 3), categoryId: 1,
          paymentMethod: PaymentMethod.cash, memo: 'スーパー, "特売"',
          source: TxnSource.manual, imagePath: null,
          createdAt: DateTime.utc(2026, 7, 3, 1, 2, 3),
          updatedAt: DateTime.utc(2026, 7, 3, 1, 2, 3),
        ),
      ],
    );

void main() {
  const codec = BackupCodec();

  test('encode produces the documented JSON structure', () {
    final json = codec.encode(samplePayload());
    final root = jsonDecode(json) as Map<String, dynamic>;

    expect(root['formatVersion'], 1);
    expect(root['exportedAt'], '2026-07-03T12:00:00.000Z');

    final cats = root['categories'] as List;
    expect(cats.length, 3);
    expect((cats[0] as Map)['name'], '食費');
    expect((cats[0] as Map)['type'], 'expense');
    expect((cats[1] as Map)['isSystem'], true);

    final txs = root['transactions'] as List;
    final tx = txs.single as Map;
    expect(tx['amount'], 1200);
    expect(tx['date'], '2026-07-03'); // civil date文字列
    expect(tx['paymentMethod'], 'cash');
    expect(tx['createdAt'], '2026-07-03T01:02:03.000Z'); // UTC ISO
    expect(tx['memo'], 'スーパー, "特売"'); // JSONは任意文字を安全に運ぶ
  });

  test('null optionals serialize as JSON null', () {
    final json = codec.encode(samplePayload());
    final root = jsonDecode(json) as Map<String, dynamic>;
    final tx = (root['transactions'] as List).single as Map;
    expect(tx.containsKey('imagePath'), isTrue);
    expect(tx['imagePath'], isNull);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/backup_codec_test.dart`
Expected: FAIL（`backup_codec.dart`/`backup_data.dart` 未作成）

- [ ] **Step 3: モデルとencodeを実装**

Create `lib/data/backup/backup_data.dart`:
```dart
import '../db/enums.dart';
import '../../domain/money/civil_date.dart';

/// バックアップ関連の例外の基底。message は人間向け（UI表示は後続フェーズ）。
abstract class BackupException implements Exception {
  String get message;
  @override
  String toString() => '$runtimeType: $message';
}

/// JSONとして壊れている／型が違う（構造の問題）。
class BackupFormatError extends BackupException {
  @override
  final String message;
  BackupFormatError(this.message);
}

/// formatVersion が欠落・不正・アプリより新しい。
class BackupVersionError extends BackupException {
  @override
  final String message;
  final bool newerThanApp;
  BackupVersionError(this.message, {this.newerThanApp = false});
}

/// 構造は正しいが内容が制約違反（負の金額・未知enum・FK不解決など）。
class BackupValidationError extends BackupException {
  @override
  final String message;
  BackupValidationError(this.message);
}

/// 取引ゼロのバックアップを（明示許可なしに）復元しようとした。
class EmptyBackupError extends BackupException {
  @override
  final String message;
  EmptyBackupError(this.message);
}

/// 復元前の自動退避の書き込み/検証に失敗（復元は中止される）。
class AutoBackupWriteError extends BackupException {
  @override
  final String message;
  AutoBackupWriteError(this.message);
}

/// 行と1:1のバックアップ用カテゴリ。
class BackupCategory {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;
  const BackupCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
  });
}

/// 行と1:1のバックアップ用取引。
class BackupTxn {
  final int id;
  final TxnType type;
  final int amount;
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? memo;
  final TxnSource source;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BackupTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.paymentMethod,
    required this.memo,
    required this.source,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
}

class BackupPayload {
  final int formatVersion;
  final DateTime? exportedAt;
  final List<BackupCategory> categories;
  final List<BackupTxn> transactions;
  const BackupPayload({
    required this.formatVersion,
    required this.exportedAt,
    required this.categories,
    required this.transactions,
  });
}
```

Create `lib/data/backup/backup_codec.dart`:
```dart
import 'dart:convert';
import 'backup_data.dart';

/// バックアップJSONの直列化と（Task 2で）厳格検証。復元の唯一の門番。
class BackupCodec {
  /// バックアップ形式のバージョン。DBのschemaVersionとは独立に管理する。
  static const int formatVersion = 1;

  const BackupCodec();

  String encode(BackupPayload p) {
    final root = <String, dynamic>{
      'formatVersion': p.formatVersion,
      'exportedAt': p.exportedAt?.toUtc().toIso8601String(),
      'categories': [
        for (final c in p.categories)
          {
            'id': c.id,
            'name': c.name,
            'type': c.type.name,
            'icon': c.icon,
            'sortOrder': c.sortOrder,
            'isArchived': c.isArchived,
            'isSystem': c.isSystem,
          },
      ],
      'transactions': [
        for (final t in p.transactions)
          {
            'id': t.id,
            'type': t.type.name,
            'amount': t.amount,
            'date': t.date.toIso(),
            'categoryId': t.categoryId,
            'paymentMethod': t.paymentMethod?.name,
            'memo': t.memo,
            'source': t.source.name,
            'imagePath': t.imagePath,
            'createdAt': t.createdAt.toUtc().toIso8601String(),
            'updatedAt': t.updatedAt.toUtc().toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/backup_codec_test.dart`
Expected: PASS（2ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/data/backup/backup_data.dart lib/data/backup/backup_codec.dart test/backup/backup_codec_test.dart
git commit -m "feat: backup payload models and JSON encode"
```

---

## Task 2: decode＋厳格検証（復元の門番）

**Files:**
- Modify: `lib/data/backup/backup_codec.dart`（decode追加）
- Test: `test/backup/backup_codec_test.dart`（decode分を追記）

**Interfaces:**
- Consumes: Task 1 のモデル・例外
- Produces:
  - `BackupPayload BackupCodec.decode(String json)` — 以下すべてを検証し、違反は型付き例外:
    - 構造: ルートがobject／各フィールドの型（`BackupFormatError`）
    - バージョン: 欠落・非int・`< 1` → `BackupVersionError`／`> formatVersion` → `BackupVersionError(newerThanApp: true)`／`< formatVersion` → 前方マイグレーション（v1では変換なし・機構のみ）
    - 内容（`BackupValidationError`）: name非空／カテゴリID重複なし／**typeごとに`isSystem`カテゴリが1つ以上**（未分類sentinel保証）／取引ID重複なし／amountは非負int／enumは既知値／dateは妥当なcivil date／**全`categoryId`が同梱カテゴリに解決**
  - 注意: **取引typeとカテゴリtypeの一致は検証しない**（DB自体が強制しない不変条件であり、正当なエクスポートの復元を壊すため）。空の取引配列はdecodeでは許容（新規DBの自動退避が正当に空のため）。空拒否は復元API側の責務（Task 6）。

- [ ] **Step 1: 失敗するテストを追記**

`test/backup/backup_codec_test.dart` の `main()` 内に追記:
```dart
  group('decode', () {
    test('round-trips an encoded payload exactly', () {
      final original = samplePayload();
      final decoded = codec.decode(codec.encode(original));
      // 忠実度はエンコード結果の同値で比較（フィールド網羅かつ簡潔）
      expect(codec.encode(decoded), codec.encode(original));
    });

    test('malformed JSON -> BackupFormatError', () {
      expect(() => codec.decode('{not json'), throwsA(isA<BackupFormatError>()));
      expect(() => codec.decode('[1,2,3]'), throwsA(isA<BackupFormatError>()));
    });

    String mutate(void Function(Map<String, dynamic> root) f) {
      final root = jsonDecode(codec.encode(samplePayload())) as Map<String, dynamic>;
      f(root);
      return jsonEncode(root);
    }

    test('missing / invalid / newer formatVersion -> BackupVersionError', () {
      expect(() => codec.decode(mutate((r) => r.remove('formatVersion'))),
          throwsA(isA<BackupVersionError>()));
      expect(() => codec.decode(mutate((r) => r['formatVersion'] = 0)),
          throwsA(isA<BackupVersionError>()));
      expect(
        () => codec.decode(mutate((r) => r['formatVersion'] = 99)),
        throwsA(isA<BackupVersionError>()
            .having((e) => e.newerThanApp, 'newerThanApp', isTrue)),
      );
    });

    test('negative amount -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate(
            (r) => ((r['transactions'] as List).first as Map)['amount'] = -1)),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('unknown enum value -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate(
            (r) => ((r['transactions'] as List).first as Map)['type'] = 'loan')),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('invalid civil date -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate((r) =>
            ((r['transactions'] as List).first as Map)['date'] = '2026-02-30')),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('unresolvable categoryId -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate((r) =>
            ((r['transactions'] as List).first as Map)['categoryId'] = 777)),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('duplicate transaction / category ids -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate((r) {
          final txs = r['transactions'] as List;
          txs.add(Map<String, dynamic>.from(txs.first as Map)); // 同じid
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          final cats = r['categories'] as List;
          cats.add(Map<String, dynamic>.from(cats.first as Map)); // 同じid
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('missing system (未分類) category for a type -> BackupValidationError',
        () {
      expect(
        () => codec.decode(mutate((r) {
          (r['categories'] as List)
              .removeWhere((c) => (c as Map)['isSystem'] == true);
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('empty transactions decode fine (empty-reject is the restore API job)',
        () {
      final p = codec.decode(mutate((r) => r['transactions'] = <dynamic>[]));
      expect(p.transactions, isEmpty);
    });
  });
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/backup_codec_test.dart`
Expected: FAIL（`decode` 未定義）

- [ ] **Step 3: decodeを実装**

`lib/data/backup/backup_codec.dart` に追記（import に `../db/enums.dart` と `../../domain/money/civil_date.dart` を追加）:
```dart
  BackupPayload decode(String json) {
    Object? parsed;
    try {
      parsed = jsonDecode(json);
    } on FormatException catch (e) {
      throw BackupFormatError('JSONとして解釈できません: ${e.message}');
    }
    if (parsed is! Map<String, dynamic>) {
      throw BackupFormatError('ルートはオブジェクトである必要があります');
    }
    var root = parsed;

    // --- バージョン検証（範囲） ---
    final version = root['formatVersion'];
    if (version is! int || version < 1) {
      throw BackupVersionError('formatVersion が欠落または不正です: $version');
    }
    if (version > formatVersion) {
      throw BackupVersionError(
          'このバックアップ($version)はアプリの対応形式($formatVersion)より新しいため復元できません',
          newerThanApp: true);
    }
    root = _migrate(root, from: version);

    // --- 構造ヘルパ ---
    T req<T>(Map<String, dynamic> m, String key, String ctx) {
      final v = m[key];
      if (v is! T) {
        throw BackupFormatError('$ctx.$key が不正です（$T が必要）: $v');
      }
      return v;
    }

    T? opt<T>(Map<String, dynamic> m, String key, String ctx) {
      final v = m[key];
      if (v == null) return null;
      if (v is! T) {
        throw BackupFormatError('$ctx.$key が不正です（$T か null が必要）: $v');
      }
      return v;
    }

    E enumByName<E extends Enum>(List<E> values, String name, String ctx) {
      try {
        return values.byName(name);
      } on ArgumentError {
        throw BackupValidationError('$ctx: 未知の値 "$name"');
      }
    }

    DateTime instant(String iso, String ctx) {
      try {
        return DateTime.parse(iso).toUtc();
      } on FormatException {
        throw BackupFormatError('$ctx: 日時として解釈できません "$iso"');
      }
    }

    // --- exportedAt（任意・情報） ---
    final exportedAtRaw = opt<String>(root, 'exportedAt', 'root');
    final exportedAt =
        exportedAtRaw == null ? null : instant(exportedAtRaw, 'exportedAt');

    // --- categories ---
    final catsRaw = req<List<dynamic>>(root, 'categories', 'root');
    final categories = <BackupCategory>[];
    final catIds = <int>{};
    for (final (i, raw) in catsRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('categories[$i] がオブジェクトではありません');
      }
      final ctx = 'categories[$i]';
      final c = BackupCategory(
        id: req<int>(raw, 'id', ctx),
        name: req<String>(raw, 'name', ctx),
        type: enumByName(CategoryType.values, req<String>(raw, 'type', ctx),
            '$ctx.type'),
        icon: opt<String>(raw, 'icon', ctx),
        sortOrder: req<int>(raw, 'sortOrder', ctx),
        isArchived: req<bool>(raw, 'isArchived', ctx),
        isSystem: req<bool>(raw, 'isSystem', ctx),
      );
      if (c.name.isEmpty) {
        throw BackupValidationError('$ctx.name が空です');
      }
      if (!catIds.add(c.id)) {
        throw BackupValidationError('カテゴリID ${c.id} が重複しています');
      }
      categories.add(c);
    }
    for (final type in CategoryType.values) {
      if (!categories.any((c) => c.isSystem && c.type == type)) {
        throw BackupValidationError(
            'システム「未分類」(${type.name}) がバックアップに含まれていません');
      }
    }

    // --- transactions ---
    final txsRaw = req<List<dynamic>>(root, 'transactions', 'root');
    final transactions = <BackupTxn>[];
    final txIds = <int>{};
    for (final (i, raw) in txsRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('transactions[$i] がオブジェクトではありません');
      }
      final ctx = 'transactions[$i]';
      final amount = req<int>(raw, 'amount', ctx);
      if (amount < 0) {
        throw BackupValidationError('$ctx.amount が負です: $amount');
      }
      final dateRaw = req<String>(raw, 'date', ctx);
      final CivilDate date;
      try {
        date = CivilDate.parse(dateRaw);
      } on FormatException {
        throw BackupValidationError('$ctx.date が不正な日付です: "$dateRaw"');
      }
      final pmRaw = opt<String>(raw, 'paymentMethod', ctx);
      final t = BackupTxn(
        id: req<int>(raw, 'id', ctx),
        type: enumByName(TxnType.values, req<String>(raw, 'type', ctx),
            '$ctx.type'),
        amount: amount,
        date: date,
        categoryId: req<int>(raw, 'categoryId', ctx),
        paymentMethod: pmRaw == null
            ? null
            : enumByName(PaymentMethod.values, pmRaw, '$ctx.paymentMethod'),
        memo: opt<String>(raw, 'memo', ctx),
        source: enumByName(TxnSource.values, req<String>(raw, 'source', ctx),
            '$ctx.source'),
        imagePath: opt<String>(raw, 'imagePath', ctx),
        createdAt: instant(req<String>(raw, 'createdAt', ctx), '$ctx.createdAt'),
        updatedAt: instant(req<String>(raw, 'updatedAt', ctx), '$ctx.updatedAt'),
      );
      if (!txIds.add(t.id)) {
        throw BackupValidationError('取引ID ${t.id} が重複しています');
      }
      if (!catIds.contains(t.categoryId)) {
        throw BackupValidationError(
            '$ctx.categoryId ${t.categoryId} が同梱カテゴリに解決できません');
      }
      transactions.add(t);
    }

    return BackupPayload(
      formatVersion: formatVersion, // マイグレーション後は常に現行
      exportedAt: exportedAt,
      categories: categories,
      transactions: transactions,
    );
  }

  /// 古いバックアップを現行形式へ順送りに変換する。v1が初版のため現状は素通し。
  /// 形式をv2に上げるときは case 1 に v1→v2 変換を追加する。
  Map<String, dynamic> _migrate(Map<String, dynamic> root, {required int from}) {
    var v = from;
    var m = root;
    while (v < formatVersion) {
      switch (v) {
        // case 1: m = _migrateV1toV2(m); break;
        default:
          throw BackupVersionError('formatVersion $v からの移行手順がありません');
      }
      // ignore: dead_code
      v++;
    }
    return m;
  }
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/backup_codec_test.dart`
Expected: PASS（encode 2 + decode 10 ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/data/backup/backup_codec.dart test/backup/backup_codec_test.dart
git commit -m "feat: backup decode with strict validation (version range, integrity, sentinel)"
```

---

## Task 3: DB→payload 読み出しとJSONエクスポート

**Files:**
- Create: `lib/data/backup/backup_service.dart`
- Test: `test/backup/backup_export_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`（Phase 1）、Task 1/2 のモデル・codec
- Produces:
  - `class BackupService { BackupService(AppDatabase db, {BackupCodec codec = const BackupCodec()}); }`
  - `Future<BackupPayload> exportPayload()` — 全カテゴリ・全取引をID昇順で読み出し（決定的な出力）
  - `Future<String> exportJson()` — `encode(await exportPayload())`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/backup/backup_export_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newMemoryDb();
    service = BackupService(db);
  });
  tearDown(() => db.close());

  test('exportPayload carries all seeded categories and inserted transactions',
      () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    final txId = await db.transactionDao
        .insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 1200,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      source: TxnSource.receiptOcr,
      memo: const Value('コンビニ'),
    ));

    final p = await service.exportPayload();
    expect(p.formatVersion, BackupCodec.formatVersion);
    expect(p.exportedAt, isNotNull);
    expect(p.categories.length, 20); // プリセット18 + 未分類2
    expect(p.categories.where((c) => c.isSystem).length, 2);

    final tx = p.transactions.single;
    expect(tx.id, txId); // IDが逐語的に載る
    expect(tx.amount, 1200);
    expect(tx.date, const CivilDate(2026, 7, 3));
    expect(tx.categoryId, foodId);
    expect(tx.source, TxnSource.receiptOcr);
    expect(tx.memo, 'コンビニ');
  });

  test('exportJson decodes back to an identical payload (round-trip)', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.income,
      amount: 300000,
      date: const CivilDate(2026, 7, 25),
      categoryId: foodId,
      source: TxnSource.manual,
    ));

    const codec = BackupCodec();
    final json = await service.exportJson();
    final decoded = codec.decode(json);
    expect(codec.encode(decoded), json); // decode→encode が恒等＝完全な忠実度
    // createdAt はUTC瞬間として往復で不変
    final row = (await db.select(db.transactions).get()).single;
    expect(decoded.transactions.single.createdAt, row.createdAt.toUtc());
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/backup_export_test.dart`
Expected: FAIL（`backup_service.dart` 未作成）

- [ ] **Step 3: BackupService（エクスポート側）を実装**

Create `lib/data/backup/backup_service.dart`:
```dart
import 'package:drift/drift.dart';
import '../db/database.dart';
import 'backup_codec.dart';
import 'backup_data.dart';

/// バックアップ／復元のオーケストレーション。
/// 検証は BackupCodec に集約されており、本クラスはDBとの読み書きに徹する。
class BackupService {
  final AppDatabase _db;
  final BackupCodec _codec;

  BackupService(this._db, {BackupCodec codec = const BackupCodec()})
      : _codec = codec;

  Future<BackupPayload> exportPayload() async {
    final cats = await (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.id)]))
        .get();
    final txs = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.now().toUtc(),
      categories: [
        for (final c in cats)
          BackupCategory(
            id: c.id,
            name: c.name,
            type: c.type,
            icon: c.icon,
            sortOrder: c.sortOrder,
            isArchived: c.isArchived,
            isSystem: c.isSystem,
          ),
      ],
      transactions: [
        for (final t in txs)
          BackupTxn(
            id: t.id,
            type: t.type,
            amount: t.amount,
            date: t.date,
            categoryId: t.categoryId,
            paymentMethod: t.paymentMethod,
            memo: t.memo,
            source: t.source,
            imagePath: t.imagePath,
            createdAt: t.createdAt.toUtc(),
            updatedAt: t.updatedAt.toUtc(),
          ),
      ],
    );
  }

  Future<String> exportJson() async => _codec.encode(await exportPayload());
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/backup_export_test.dart`
Expected: PASS（2ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/data/backup/backup_service.dart test/backup/backup_export_test.dart
git commit -m "feat: BackupService export (DB -> payload -> JSON, id-faithful)"
```

---

## Task 4: アトミック復元（validate-then-swap・ID保存）

**Files:**
- Modify: `lib/data/backup/backup_service.dart`（`applyRestore`追加）
- Test: `test/backup/backup_restore_test.dart`

**Interfaces:**
- Consumes: Task 3 の `BackupService`、Phase 1 の FK ON
- Produces:
  - `Future<void> BackupService.applyRestore(BackupPayload payload)` — **単一トランザクション内で** 取引全削除 → カテゴリ全削除 →（この順でFK RESTRICTを回避）→ カテゴリ挿入（ID保存）→ 取引挿入（ID保存）→ 件数一致アサート。途中の`SqliteException`等は自動ロールバックし、既存データは無傷。
  - 前提: `payload`は`codec.decode`を通過済み（＝検証済み）であること。**この分離により、codecを迂回した不正payloadでロールバックを直接テストできる。**

- [ ] **Step 1: 失敗するテストを書く**

Create `test/backup/backup_restore_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

/// 最小の正当payload: システム未分類2 + 通常カテゴリ1 + 取引1（任意ID）
BackupPayload minimalPayload() => BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3),
      categories: const [
        BackupCategory(
            id: 100, name: '食費(旧端末)', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false),
        BackupCategory(
            id: 101, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 1, isArchived: false, isSystem: true),
        BackupCategory(
            id: 102, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 2, isArchived: false, isSystem: true),
      ],
      transactions: [
        BackupTxn(
          id: 500, type: TxnType.expense, amount: 4980,
          date: const CivilDate(2026, 6, 15), categoryId: 100,
          paymentMethod: null, memo: '旧端末の記録',
          source: TxnSource.manual, imagePath: null,
          createdAt: DateTime.utc(2026, 6, 15, 3),
          updatedAt: DateTime.utc(2026, 6, 15, 3),
        ),
      ],
    );

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newMemoryDb();
    service = BackupService(db);
  });
  tearDown(() => db.close());

  Future<int> seedOneTx() async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    return db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 999,
      date: const CivilDate(2026, 7, 1),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
  }

  test('applyRestore replaces everything and preserves ids verbatim', () async {
    await seedOneTx(); // 既存データ（プリセット20カテゴリ + 取引1）

    await service.applyRestore(minimalPayload());

    final cats = await db.categoryDao.allCategories();
    // プリセットの残骸なし＝payloadのカテゴリだけ（再シードも走らない）
    expect(cats.length, 3);
    expect(cats.map((c) => c.id).toSet(), {100, 101, 102});

    final txs = await db.select(db.transactions).get();
    final tx = txs.single;
    expect(tx.id, 500); // ID逐語保存
    expect(tx.categoryId, 100); // FKも逐語（再割当なし）
    expect(tx.amount, 4980);
    expect(tx.createdAt.toUtc(), DateTime.utc(2026, 6, 15, 3)); // 瞬間保存
  });

  test('export -> restore -> export is byte-identical (full fidelity)', () async {
    await seedOneTx();
    const codec = BackupCodec();
    final before = await service.exportJson();

    await service.applyRestore(codec.decode(before));
    final after = await service.exportJson();

    // exportedAt だけは現在時刻で変わるため、それ以外を比較
    String stripExportedAt(String s) =>
        s.replaceFirst(RegExp('"exportedAt": "[^"]*"'), '"exportedAt": "X"');
    expect(stripExportedAt(after), stripExportedAt(before));
  });

  test('mid-swap failure rolls back everything (atomicity)', () async {
    final keepId = await seedOneTx();

    // codecを迂回して不正payload（取引ID重複=PK衝突）を直接swapに流す
    final bad = minimalPayload();
    final dup = BackupPayload(
      formatVersion: bad.formatVersion,
      exportedAt: bad.exportedAt,
      categories: bad.categories,
      transactions: [...bad.transactions, ...bad.transactions], // id 500 が2回
    );

    await expectLater(service.applyRestore(dup), throwsA(anything));

    // 既存データが無傷（delete-allはロールバックされた）
    final cats = await db.categoryDao.allCategories();
    expect(cats.length, 20);
    final txs = await db.select(db.transactions).get();
    expect(txs.single.id, keepId);
    expect(txs.single.amount, 999);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/backup_restore_test.dart`
Expected: FAIL（`applyRestore` 未定義）

- [ ] **Step 3: applyRestoreを実装**

`lib/data/backup/backup_service.dart` の `BackupService` に追記（import に `../db/enums.dart` は不要、Companionは`database.dart`経由）:
```dart
  /// 検証済みpayloadでDB全体を置換する。単一トランザクション＝途中失敗は全ロールバック。
  /// 呼び出し前に codec.decode を通すこと（検証はcodecの責務）。
  Future<void> applyRestore(BackupPayload payload) async {
    await _db.transaction(() async {
      // FK RESTRICT を回避する順序: 取引 → カテゴリ の順に削除
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.categories).go();

      // カテゴリ → 取引 の順に、IDを明示して挿入（逐語保存）
      await _db.batch((b) {
        for (final c in payload.categories) {
          b.insert(
            _db.categories,
            CategoriesCompanion(
              id: Value(c.id),
              name: Value(c.name),
              type: Value(c.type),
              icon: Value(c.icon),
              sortOrder: Value(c.sortOrder),
              isArchived: Value(c.isArchived),
              isSystem: Value(c.isSystem),
            ),
          );
        }
        for (final t in payload.transactions) {
          b.insert(
            _db.transactions,
            TransactionsCompanion(
              id: Value(t.id),
              type: Value(t.type),
              amount: Value(t.amount),
              date: Value(t.date),
              categoryId: Value(t.categoryId),
              paymentMethod: Value(t.paymentMethod),
              memo: Value(t.memo),
              source: Value(t.source),
              imagePath: Value(t.imagePath),
              createdAt: Value(t.createdAt),
              updatedAt: Value(t.updatedAt),
            ),
          );
        }
      });

      // 事後アサート（防御的・トランザクション内なので失敗すればロールバック）
      final catCount = await _count(_db.categories);
      final txCount = await _count(_db.transactions);
      if (catCount != payload.categories.length ||
          txCount != payload.transactions.length) {
        throw StateError(
            '復元の件数が一致しません: cats=$catCount/${payload.categories.length}, '
            'txs=$txCount/${payload.transactions.length}');
      }
    });
  }

  Future<int> _count(TableInfo<Table, dynamic> table) async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM ${table.actualTableName}')
        .getSingle();
    return row.read<int>('c');
  }
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/backup_restore_test.dart`
Expected: PASS（3ケース。特にロールバックテストで既存データ無傷を確認）

- [ ] **Step 5: コミット**

```bash
git add lib/data/backup/backup_service.dart test/backup/backup_restore_test.dart
git commit -m "feat: atomic validate-then-swap restore with verbatim id preservation"
```

---

## Task 5: AutoBackupStore（サイレント自動退避・ローリング世代）

**Files:**
- Create: `lib/data/backup/auto_backup_store.dart`
- Test: `test/backup/auto_backup_store_test.dart`

**Interfaces:**
- Consumes: `BackupCodec`（書き込み検証に使用）、`dart:io`
- Produces:
  - `class AutoBackupStore { AutoBackupStore(Directory dir, {BackupCodec codec = const BackupCodec(), DateTime Function() now = DateTime.now, int maxGenerations = 10}); }`
  - `Future<File> writeVerified(String json)` — `backup-<epochMicros 19桁ゼロ埋め>.json`へ書き込み→**読み戻し＋codec.decodeで検証**（失敗時はファイルを削除して`AutoBackupWriteError`）→古い世代をprune→Fileを返す
  - `List<File> listGenerations()` — 新しい順
  - `File? latest()` / `DateTime? latestTimestamp()` — 「前回バックアップ: N日前」バナー用の素材
  - ファイル名を19桁ゼロ埋めエポックマイクロ秒にする理由: **辞書順＝時系列順**になり、pruneとlatestがソートだけで正しくなる

- [ ] **Step 1: 失敗するテストを書く**

Create `test/backup/auto_backup_store_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/db/enums.dart';

/// 検証を通る最小の正当JSON
String validJson() {
  const codec = BackupCodec();
  return codec.encode(BackupPayload(
    formatVersion: BackupCodec.formatVersion,
    exportedAt: DateTime.utc(2026, 7, 3),
    categories: const [
      BackupCategory(
          id: 1, name: '未分類', type: CategoryType.expense,
          icon: null, sortOrder: 0, isArchived: false, isSystem: true),
      BackupCategory(
          id: 2, name: '未分類', type: CategoryType.income,
          icon: null, sortOrder: 1, isArchived: false, isSystem: true),
    ],
    transactions: const [],
  ));
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kakeibo_backup_test_');
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// 呼ぶたびに1秒進む注入クロック
  DateTime Function() ticker() {
    var t = DateTime.utc(2026, 7, 3, 12, 0, 0);
    return () {
      t = t.add(const Duration(seconds: 1));
      return t;
    };
  }

  test('writeVerified persists, and latest()/listGenerations() order newest-first',
      () async {
    final store = AutoBackupStore(tmp, now: ticker());
    final f1 = await store.writeVerified(validJson());
    final f2 = await store.writeVerified(validJson());

    expect(f1.existsSync(), isTrue);
    expect(f2.existsSync(), isTrue);
    final gens = store.listGenerations();
    expect(gens.length, 2);
    expect(gens.first.path, f2.path); // 新しい順
    expect(store.latest()!.path, f2.path);
    expect(store.latestTimestamp(), DateTime.utc(2026, 7, 3, 12, 0, 2));
  });

  test('invalid json is rejected, file removed, AutoBackupWriteError thrown',
      () async {
    final store = AutoBackupStore(tmp, now: ticker());
    await expectLater(
      store.writeVerified('{"broken": true}'),
      throwsA(isA<AutoBackupWriteError>()),
    );
    expect(store.listGenerations(), isEmpty); // 失敗ファイルは残らない
  });

  test('prunes beyond maxGenerations, deleting the oldest', () async {
    final store = AutoBackupStore(tmp, now: ticker(), maxGenerations: 3);
    final files = <File>[];
    for (var i = 0; i < 5; i++) {
      files.add(await store.writeVerified(validJson()));
    }
    final gens = store.listGenerations();
    expect(gens.length, 3);
    // 最新3つ＝最後に書いた3つ
    expect(gens.map((f) => f.path).toSet(),
        files.sublist(2).map((f) => f.path).toSet());
    expect(files[0].existsSync(), isFalse); // 最古は削除済み
    expect(files[1].existsSync(), isFalse);
  });

  test('empty dir -> latest() and latestTimestamp() are null', () {
    final store = AutoBackupStore(tmp);
    expect(store.latest(), isNull);
    expect(store.latestTimestamp(), isNull);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/auto_backup_store_test.dart`
Expected: FAIL（`auto_backup_store.dart` 未作成）

- [ ] **Step 3: AutoBackupStoreを実装**

Create `lib/data/backup/auto_backup_store.dart`:
```dart
import 'dart:io';
import 'backup_codec.dart';
import 'backup_data.dart';

/// 復元前スナップショット等の「サイレント自動退避」置き場。
/// - 共有シート不要（アプリ専用ディレクトリへの直接書き込み）
/// - 上書きしないローリング世代（タイムスタンプ名・辞書順＝時系列順）
/// - 書き込み後に読み戻し＋decode検証してから成功とみなす
///
/// Directoryは注入（テスト=一時Dir、アプリ=UIフェーズでpath_provider配線）。
class AutoBackupStore {
  final Directory dir;
  final BackupCodec _codec;
  final DateTime Function() _now;
  final int maxGenerations;

  AutoBackupStore(
    this.dir, {
    BackupCodec codec = const BackupCodec(),
    DateTime Function() now = DateTime.now,
    this.maxGenerations = 10,
  })  : _codec = codec,
        _now = now;

  static final _nameRe = RegExp(r'^backup-(\d{19})\.json$');

  Future<File> writeVerified(String json) async {
    dir.createSync(recursive: true);
    final micros = _now().toUtc().microsecondsSinceEpoch;
    final name = 'backup-${micros.toString().padLeft(19, '0')}.json';
    final file = File('${dir.path}${Platform.pathSeparator}$name');

    try {
      file.writeAsStringSync(json, flush: true);
      // 読み戻して完全検証。ここを通らない退避は「無い」のと同じなので失敗扱い。
      final readBack = file.readAsStringSync();
      _codec.decode(readBack);
    } catch (e) {
      if (file.existsSync()) file.deleteSync();
      throw AutoBackupWriteError('自動退避の書き込み/検証に失敗しました: $e');
    }

    _prune();
    return file;
  }

  List<File> listGenerations() {
    if (!dir.existsSync()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _nameRe.hasMatch(_basename(f)))
        .toList()
      ..sort((a, b) => _basename(b).compareTo(_basename(a))); // 新しい順
    return files;
  }

  File? latest() {
    final gens = listGenerations();
    return gens.isEmpty ? null : gens.first;
  }

  DateTime? latestTimestamp() {
    final f = latest();
    if (f == null) return null;
    final micros = int.parse(_nameRe.firstMatch(_basename(f))!.group(1)!);
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }

  void _prune() {
    final gens = listGenerations();
    for (final f in gens.skip(maxGenerations)) {
      f.deleteSync();
    }
  }

  String _basename(File f) => f.uri.pathSegments.last;
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/auto_backup_store_test.dart`
Expected: PASS（4ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/data/backup/auto_backup_store.dart test/backup/auto_backup_store_test.dart
git commit -m "feat: AutoBackupStore (silent rolling-generation snapshots with write-verify)"
```

---

## Task 6: 復元フローの統合（decode→空チェック→退避→swap）

**Files:**
- Modify: `lib/data/backup/backup_service.dart`（コンストラクタに`store`追加、`restoreFromJson`追加）
- Test: `test/backup/backup_service_flow_test.dart`

**Interfaces:**
- Consumes: Task 1〜5 のすべて
- Produces:
  - コンストラクタ最終形: `BackupService(AppDatabase db, {BackupCodec codec = const BackupCodec(), AutoBackupStore? store})`
  - `Future<void> restoreFromJson(String json, {bool allowEmpty = false})`:
    1. `codec.decode(json)` — 不正なら型付き例外で**ここで終了（DB・退避とも無傷）**
    2. 取引ゼロ && `!allowEmpty` → `EmptyBackupError`（スナップショットも書かない）
    3. `store.writeVerified(await exportJson())` — 現在のDBをスナップショット。失敗＝`AutoBackupWriteError`で**復元中止（DB無傷）**。`store`未設定なら`StateError`
    4. `applyRestore(payload)` — アトミックswap
  - `allowEmpty: true` の用途: 「自動退避から復元」（＝直前の空DBスナップショットへ戻す一発Undo）で必要

- [ ] **Step 1: 失敗するテストを書く**

Create `test/backup/backup_service_flow_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

/// writeVerified が必ず失敗するストア（退避不能シナリオの注入）
class FailingStore extends AutoBackupStore {
  FailingStore(super.dir);
  @override
  Future<File> writeVerified(String json) async {
    throw AutoBackupWriteError('simulated disk failure');
  }
}

void main() {
  late AppDatabase db;
  late Directory tmp;
  late AutoBackupStore store;
  late BackupService service;
  const codec = BackupCodec();

  setUp(() {
    db = newMemoryDb();
    tmp = Directory.systemTemp.createTempSync('kakeibo_flow_test_');
    store = AutoBackupStore(tmp);
    service = BackupService(db, store: store);
  });
  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> seedTx(int amount) async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: amount,
      date: const CivilDate(2026, 7, 1),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
  }

  /// 別DB相当のpayload JSON（このDBの現在の中身とは無関係な正当データ）
  Future<String> foreignJson() async {
    final other = newMemoryDb();
    addTearDown(other.close);
    final all = await other.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await other.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 7777,
      date: const CivilDate(2026, 5, 5),
      categoryId: foodId,
      source: TxnSource.manual,
    ));
    return BackupService(other).exportJson();
  }

  test('successful restore snapshots the OLD data first, then swaps', () async {
    await seedTx(999); // 旧データ
    final incoming = await foreignJson();

    await service.restoreFromJson(incoming);

    // DBは新データ
    final txs = await db.select(db.transactions).get();
    expect(txs.single.amount, 7777);

    // 退避には旧データ(999)のスナップショットが残っている
    final snapshot = codec.decode(store.latest()!.readAsStringSync());
    expect(snapshot.transactions.single.amount, 999);
  });

  test('empty payload without allowEmpty -> EmptyBackupError, nothing touched',
      () async {
    await seedTx(999);
    final other = newMemoryDb();
    addTearDown(other.close);
    final emptyJson = await BackupService(other).exportJson(); // 取引ゼロの正当JSON

    await expectLater(
      service.restoreFromJson(emptyJson),
      throwsA(isA<EmptyBackupError>()),
    );
    // DB無傷・スナップショットも書かれていない
    expect((await db.select(db.transactions).get()).single.amount, 999);
    expect(store.listGenerations(), isEmpty);
  });

  test('empty payload WITH allowEmpty=true restores (one-tap undo path)',
      () async {
    await seedTx(999);
    final other = newMemoryDb();
    addTearDown(other.close);
    final emptyJson = await BackupService(other).exportJson();

    await service.restoreFromJson(emptyJson, allowEmpty: true);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect((await db.categoryDao.allCategories()).length, 20);
  });

  test('snapshot failure aborts restore, DB untouched', () async {
    await seedTx(999);
    final failing = BackupService(db, store: FailingStore(tmp));
    final incoming = await foreignJson();

    await expectLater(
      failing.restoreFromJson(incoming),
      throwsA(isA<AutoBackupWriteError>()),
    );
    expect((await db.select(db.transactions).get()).single.amount, 999);
  });

  test('invalid json aborts before any side effect', () async {
    await seedTx(999);
    await expectLater(
      service.restoreFromJson('{"garbage": 1}'),
      throwsA(isA<BackupException>()),
    );
    expect((await db.select(db.transactions).get()).single.amount, 999);
    expect(store.listGenerations(), isEmpty);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/backup_service_flow_test.dart`
Expected: FAIL（`restoreFromJson`/`store`パラメータ未定義）

- [ ] **Step 3: restoreFromJsonを実装**

`lib/data/backup/backup_service.dart` を修正。import追加:
```dart
import 'auto_backup_store.dart';
```
コンストラクタを最終形に変更:
```dart
  final AppDatabase _db;
  final BackupCodec _codec;
  final AutoBackupStore? _store;

  BackupService(this._db,
      {BackupCodec codec = const BackupCodec(), AutoBackupStore? store})
      : _codec = codec,
        _store = store;
```
メソッド追加:
```dart
  /// バックアップJSONからの復元（置換）。順序が生命線:
  /// 1) 完全検証 → 2) 空チェック → 3) 現在DBのスナップショット(検証付き) → 4) アトミックswap
  /// 1〜3のどこで失敗してもDBは無傷。4は単一トランザクションで途中失敗は全ロールバック。
  Future<void> restoreFromJson(String json, {bool allowEmpty = false}) async {
    final payload = _codec.decode(json); // 不正ならここで型付き例外

    if (payload.transactions.isEmpty && !allowEmpty) {
      throw EmptyBackupError(
          '取引が0件のバックアップです。本当に復元する場合は明示的な確認が必要です');
    }

    final store = _store;
    if (store == null) {
      throw StateError('復元には AutoBackupStore の設定が必要です');
    }
    await store.writeVerified(await exportJson()); // 失敗=AutoBackupWriteError→中止

    await applyRestore(payload);
  }
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/backup_service_flow_test.dart`
Expected: PASS（5ケース）

- [ ] **Step 5: 全テスト確認とコミット**

Run: `flutter test`
Expected: `All tests passed!`

```bash
git add lib/data/backup/backup_service.dart test/backup/backup_service_flow_test.dart
git commit -m "feat: restore flow (decode -> empty-guard -> verified snapshot -> atomic swap)"
```

---

## Task 7: CSVエクスポート（閲覧用・エクスポート専用）

**Files:**
- Create: `lib/data/backup/csv_exporter.dart`
- Modify: `lib/data/backup/backup_service.dart`（`exportCsv`追加）
- Test: `test/backup/csv_exporter_test.dart`

**Interfaces:**
- Consumes: `BackupPayload`（カテゴリ名解決に使用）
- Produces:
  - `String buildTransactionsCsv(BackupPayload payload)` — 純関数。**先頭にBOM(`U+FEFF`)**、改行は**CRLF**、ヘッダ `日付,種別,金額,カテゴリ,支払方法,メモ`。種別は`支出`/`収入`、支払方法は日本語ラベル（null→空欄）。カンマ・引用符・改行・絵文字を含むフィールドはRFC-4180でクオート（`"`→`""`）
  - `Future<String> BackupService.exportCsv()` — `buildTransactionsCsv(await exportPayload())`
  - **復元パスには置かない**（CSVのパースAPIは作らない）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/backup/csv_exporter_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newMemoryDb();
    service = BackupService(db);
  });
  tearDown(() => db.close());

  test('CSV has BOM, CRLF, header, and localized values', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 1200,
      date: const CivilDate(2026, 7, 3),
      categoryId: foodId,
      paymentMethod: const Value(PaymentMethod.eMoney),
      source: TxnSource.manual,
      memo: const Value('コンビニ'),
    ));

    final csv = await service.exportCsv();
    expect(csv.startsWith('\uFEFF'), isTrue); // Excel(日本語)向けBOM
    final lines = csv.substring(1).split('\r\n');
    expect(lines[0], '日付,種別,金額,カテゴリ,支払方法,メモ');
    expect(lines[1], '2026-07-03,支出,1200,食費,電子マネー,コンビニ');
  });

  test('fields with comma / quote / newline are RFC-4180 escaped', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 500,
      date: const CivilDate(2026, 7, 4),
      categoryId: foodId,
      source: TxnSource.manual,
      memo: const Value('セブン-イレブン, 渋谷店 "改装中"\n2行目🍙'),
    ));

    final csv = await service.exportCsv();
    // カンマ・引用符・改行を含むmemoは全体をクオートし、内部の"は""に
    expect(
      csv,
      contains('"セブン-イレブン, 渋谷店 ""改装中""\n2行目🍙"'),
    );
  });

  test('null paymentMethod and null memo render as empty fields', () async {
    final all = await db.categoryDao.allCategories();
    final foodId = all.firstWhere((c) => c.name == '食費').id;
    await db.transactionDao.insertTransaction(TransactionsCompanion.insert(
      type: TxnType.income,
      amount: 300000,
      date: const CivilDate(2026, 7, 25),
      categoryId: foodId,
      source: TxnSource.manual,
    ));

    final csv = await service.exportCsv();
    final lines = csv.substring(1).split('\r\n');
    expect(lines[1], '2026-07-25,収入,300000,食費,,');
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/backup/csv_exporter_test.dart`
Expected: FAIL（`csv_exporter.dart`/`exportCsv` 未定義）

- [ ] **Step 3: CSVエクスポータを実装**

Create `lib/data/backup/csv_exporter.dart`:
```dart
import '../db/enums.dart';
import 'backup_data.dart';

/// 取引の閲覧用CSV（エクスポート専用）。復元には使わない。
/// - 先頭BOM(U+FEFF): 日本語Excelでの文字化け回避
/// - CRLF: RFC-4180 準拠
/// - カンマ/引用符/改行を含むフィールドはクオートし、" は "" にエスケープ
String buildTransactionsCsv(BackupPayload payload) {
  final categoryNames = {for (final c in payload.categories) c.id: c.name};
  final sb = StringBuffer('\uFEFF');
  sb.write('日付,種別,金額,カテゴリ,支払方法,メモ\r\n');
  for (final t in payload.transactions) {
    final fields = [
      t.date.toIso(),
      t.type == TxnType.expense ? '支出' : '収入',
      t.amount.toString(),
      categoryNames[t.categoryId] ?? '',
      _paymentLabel(t.paymentMethod),
      t.memo ?? '',
    ];
    sb.write(fields.map(_escape).join(','));
    sb.write('\r\n');
  }
  return sb.toString();
}

String _paymentLabel(PaymentMethod? m) => switch (m) {
      null => '',
      PaymentMethod.cash => '現金',
      PaymentMethod.creditCard => 'クレジットカード',
      PaymentMethod.eMoney => '電子マネー',
      PaymentMethod.bankDraft => '口座引落',
      PaymentMethod.other => 'その他',
    };

String _escape(String v) {
  if (v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}
```

`lib/data/backup/backup_service.dart` に追記（import に `csv_exporter.dart` を追加）:
```dart
  /// 閲覧用CSV（エクスポート専用・復元不可）。
  Future<String> exportCsv() async => buildTransactionsCsv(await exportPayload());
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/backup/csv_exporter_test.dart`
Expected: PASS（3ケース）

- [ ] **Step 5: コミット**

```bash
git add lib/data/backup/csv_exporter.dart lib/data/backup/backup_service.dart test/backup/csv_exporter_test.dart
git commit -m "feat: view-only CSV export (BOM + CRLF + RFC-4180 escaping)"
```

---

## Task 8: パスフレーズ暗号化（AES-GCM 256 + PBKDF2）

**Files:**
- Modify: `pubspec.yaml`（`cryptography`追加）
- Create: `lib/data/backup/backup_crypto.dart`
- Test: `test/backup/backup_crypto_test.dart`

**Interfaces:**
- Consumes: なし（純粋なバイト変換。BackupServiceへの配線＝共有シートはUIフェーズ）
- Produces:
  - `class BackupDecryptionError extends BackupException`（`backup_data.dart`に追記）
  - `class BackupCrypto { BackupCrypto({int pbkdf2Iterations = 200000}); }`
  - `Future<Uint8List> encrypt(String plaintext, String passphrase)` — 出力形式: `magic "KKBK1"(5バイト) + salt(16) + nonce(12) + ciphertext + mac(16)`
  - `Future<String> decrypt(Uint8List data, String passphrase)` — magic不一致/短すぎ→`BackupDecryptionError`、パスフレーズ誤り・改ざん→`BackupDecryptionError`
  - テストでは`pbkdf2Iterations: 1000`で高速化（既定20万は実運用値）

- [ ] **Step 1: 依存を追加**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
flutter pub add cryptography
```
Expected: `cryptography` が dependencies に追加され解決成功。

- [ ] **Step 2: 失敗するテストを書く**

Create `test/backup/backup_crypto_test.dart`:
```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_crypto.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';

void main() {
  final crypto = BackupCrypto(pbkdf2Iterations: 1000); // テスト高速化

  test('encrypt -> decrypt round-trips the plaintext', () async {
    const plain = '{"formatVersion":1,"日本語":"含む🍙"}';
    final bytes = await crypto.encrypt(plain, 'correct horse battery');
    final back = await crypto.decrypt(bytes, 'correct horse battery');
    expect(back, plain);
  });

  test('same plaintext encrypts to different bytes (random salt/nonce)', () async {
    final a = await crypto.encrypt('secret', 'pass');
    final b = await crypto.encrypt('secret', 'pass');
    expect(a, isNot(equals(b)));
  });

  test('wrong passphrase -> BackupDecryptionError', () async {
    final bytes = await crypto.encrypt('secret', 'right');
    await expectLater(
      crypto.decrypt(bytes, 'wrong'),
      throwsA(isA<BackupDecryptionError>()),
    );
  });

  test('tampered ciphertext -> BackupDecryptionError', () async {
    final bytes = await crypto.encrypt('secret', 'pass');
    final tampered = Uint8List.fromList(bytes);
    tampered[tampered.length - 20] ^= 0xFF; // ciphertext末尾付近を反転
    await expectLater(
      crypto.decrypt(tampered, 'pass'),
      throwsA(isA<BackupDecryptionError>()),
    );
  });

  test('not an encrypted backup (bad magic / too short) -> BackupDecryptionError',
      () async {
    await expectLater(
      crypto.decrypt(Uint8List.fromList([1, 2, 3]), 'pass'),
      throwsA(isA<BackupDecryptionError>()),
    );
  });
}
```

- [ ] **Step 3: テストが失敗することを確認**

Run: `flutter test test/backup/backup_crypto_test.dart`
Expected: FAIL（`backup_crypto.dart` 未作成）

- [ ] **Step 4: BackupCryptoを実装**

`lib/data/backup/backup_data.dart` に追記:
```dart
/// パスフレーズ誤り・データ改ざん・暗号化バックアップでないファイル。
class BackupDecryptionError extends BackupException {
  @override
  final String message;
  BackupDecryptionError(this.message);
}
```

Create `lib/data/backup/backup_crypto.dart`:
```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'backup_data.dart';

/// バックアップJSONのパスフレーズ暗号化。
/// 形式: "KKBK1"(5) + salt(16) + nonce(12) + ciphertext(n) + mac(16)
/// 鍵導出: PBKDF2-HMAC-SHA256 / 暗号: AES-256-GCM（MACで改ざん検知）
class BackupCrypto {
  static const _magic = 'KKBK1';
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  final int pbkdf2Iterations;
  BackupCrypto({this.pbkdf2Iterations = 200000});

  AesGcm get _aes => AesGcm.with256bits();

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  Future<Uint8List> encrypt(String plaintext, String passphrase) async {
    // salt(16バイト)を毎回ランダム生成。nonceは _aes.encrypt が自動生成し box.nonce に入る。
    final saltBytes = SecretKeyData.random(length: _saltLength).bytes;
    final key = await _deriveKey(passphrase, saltBytes);
    final box = await _aes.encrypt(utf8.encode(plaintext), secretKey: key);
    // box.concatenation() = nonce + cipherText + mac
    final out = BytesBuilder();
    out.add(ascii.encode(_magic));
    out.add(saltBytes);
    out.add(box.concatenation());
    return out.toBytes();
  }

  Future<String> decrypt(Uint8List data, String passphrase) async {
    final headerLen = _magic.length + _saltLength;
    final minLen = headerLen + _nonceLength + _macLength;
    if (data.length < minLen) {
      throw BackupDecryptionError('暗号化バックアップとして短すぎます');
    }
    final magic = ascii.decode(data.sublist(0, _magic.length), allowInvalid: true);
    if (magic != _magic) {
      throw BackupDecryptionError('暗号化バックアップのファイルではありません');
    }
    final salt = data.sublist(_magic.length, headerLen);
    final body = data.sublist(headerLen);
    final key = await _deriveKey(passphrase, salt);
    final box = SecretBox.fromConcatenation(
      body,
      nonceLength: _nonceLength,
      macLength: _macLength,
    );
    try {
      final clear = await _aes.decrypt(box, secretKey: key);
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw BackupDecryptionError('パスフレーズが違うか、データが破損しています');
    }
  }
}
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/backup/backup_crypto_test.dart`
Expected: PASS（5ケース）

- [ ] **Step 6: 全テスト・analyze確認とコミット**

Run:
```bash
cd "C:/Users/wilsh/kakeibo-app"
flutter test
flutter analyze
```
Expected: `All tests passed!` / `No issues found!`

```bash
git add -A
git commit -m "feat: passphrase encryption for backup export (AES-256-GCM + PBKDF2)"
```

---

## Self-Review（この計画の点検結果）

**1. Spec coverage（spec §10・§2.1のPhase 2相当）:**
- §10.1 アトミック復元（validate-then-swap・単一トランザクション・削除前に挿入可能性証明）→ Task 2（検証）+ Task 4（swap）✅
- §10.2 復元前自動退避（サイレント・検証後に削除・タイムスタンプ・非上書き・復元UI用API）→ Task 5 + Task 6 ✅（「自動退避から復元」は`store.latest()`+`restoreFromJson(allowEmpty:true)`で成立、UIは後続）
- §10.3 検証（バージョン範囲・前方マイグレーション機構・新しい版拒否・内容検証・空の明示確認）→ Task 2 + Task 6 ✅
- §10.4 ID保存・復元後アサート・プリセット再シード無効 → Task 4 ✅（再シード無効はアーキテクチャ上自動: シードは`wasCreated`時のみ。Task 4のテストで残骸ゼロを担保）
- §10.5 CSVエクスポート専用（RFC-4180・UTF-8 BOM）→ Task 7 ✅（復元パスに置かない=パースAPI自体を作らない）
- §2.1 任意パスフレーズ暗号化（AES-GCM）→ Task 8 ✅／定期自動バックアップのスケジューリングと「前回N日前」バナー→ **UIフェーズ**（素材`latestTimestamp()`はTask 5で用意）✅
- §12 tz敵対テスト → Global Constraintsの逸脱メモの通り構造的担保に置換（理由明記）✅

**Phase 2の範囲外（後続plan）:** 共有シート配線・path_provider配線・バックアップ設定UI・ReceiptParser・features UI・iOS。

**2. Placeholder scan:** 空プレースホルダなし。全ステップに実コード（初稿にあったTask 6の`..let`とTask 8の`newNonce()`の下書きコードは、注記でなくコード自体を修正済み）。

**3. Type consistency:**
- `BackupPayload`/`BackupCategory`/`BackupTxn`/例外階層: Task 1定義、Task 2〜8で一貫使用 ✅
- `BackupCodec.formatVersion`/`encode`/`decode`: Task 1-2定義、Task 3-6で使用一致 ✅
- `BackupService`コンストラクタ進化（T3: dbのみ → T6: `{codec, store}`）を各タスクのInterfacesに明記 ✅
- `AutoBackupStore.writeVerified/listGenerations/latest/latestTimestamp`: Task 5定義、Task 6で使用一致 ✅
- Phase 1との整合: `db.categoryDao.allCategories()`/`db.transactionDao.insertTransaction`/`TransactionsCompanion.insert`/`newMemoryDb()` は実装済みAPIと一致 ✅

---

## 実装メモ（落とし穴）
- **削除順は 取引→カテゴリ、挿入順は カテゴリ→取引**（FK RESTRICT・FK ON環境での唯一の正順）。
- autoIncrement列への明示ID挿入は、`.insert`コンストラクタでなく**全指定`Companion()`＋`Value(id)`**で行う。
- `batch`は`transaction`内で使用可（外側のトランザクションに参加する）。
- drift `store_date_time_values_as_text: true` によりDateTimeはISO文字列保存。UTCで入れればUTCで出る（テストは`toUtc()`等値で瞬間を比較）。
- `SecretBox.fromConcatenation(bytes, nonceLength: 12, macLength: 16)`と`box.concatenation()`が対になる。復号失敗は`SecretBoxAuthenticationError`。
- テストの一時ディレクトリは`Directory.systemTemp.createTempSync`＋`tearDown`で確実に削除。
