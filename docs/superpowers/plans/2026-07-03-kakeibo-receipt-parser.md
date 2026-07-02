# 家計簿アプリ Phase 3: ReceiptParser（レシート抽出） Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** レシートOCR出力（正準TextBlock列）から**税込合計とレシート発行日**を抽出する純Dartパーサ（spec §7）を、Windowsの`flutter test`で完全に自走検証できる形で構築する。正準TextBlock空間・OcrService抽象・FakeOcrService・確信度tier・候補リスト（UI切替用）・JSONフィクスチャ形式（Mac実機ブリッジ互換）・摂動ロバストネステストまで。

**Architecture:** パイプライン＝ **正規化 → 行復元(bbox) → 日付抽出 → 合計抽出(キーワード+行) → フォールバック → クロス検証**。各段を**独立にユニットテスト可能な純関数**として分離（`normalize` / `rows` / `amounts` / `total` / `date` / `receipt_parser`）。座標は**正準空間（左上原点・y下向き・0..1正規化・行粒度・per-block確信度）**で受け、エンジン依存の変換は将来の`OcrService`実装（AppleVision等）の責務。時計は注入（`today`）し全テストを決定的にする。一次資料: `docs/superpowers/research/jp-receipt-parsing.md`（規則・regex・フィクスチャ20ケースの根拠）。

**Tech Stack:** 純Dart（`lib/domain/services/`配下は flutter/drift import 禁止）。既存の`CivilDate`（Phase 1）を日付型に使用。

## Global Constraints

- Phase 1/2 の Global Constraints を継承（TDD・Windowsヘッドレス・整数円・CivilDate）。
- **`lib/domain/services/` 配下は純Dart**: `package:flutter/...`・`package:drift/...` をimportしない（`dart:core`/`dart:math`等のみ）。
- **決定的**: `DateTime.now()`を抽出ロジック内で直接呼ばない。`ReceiptParser`は`today`（`CivilDate Function()`）をコンストラクタ注入。乱数不使用（摂動も決定的変換）。
- **正準TextBlock空間**: 左上原点・y下向き・**0..1正規化**・行粒度・per-block confidence。この規約はテストで固定し、`OcrService`実装（Mac/AppleVision）はこの空間へ変換して返す契約。
- **regexは`static final`で一度だけコンパイル**。Dartの`\d`はASCIIのみ → 全角は正規化で潰してからマッチ。
- 金額の妥当域: `1 ≤ yen ≤ 9,999,999`。合計は**非負**（負値は割引/返品マーカーであり総額候補にしない）。
- 確信度は**離散tier**（`high`/`medium`/`low`）＝規則ベースで説明可能に（spec §7.5）。
- 日付が見つからない場合は **`today`を既定・low確信度**で返す（spec §7.3）。
- パーサは**候補リスト**（金額・日付とも、選択理由つき）を返し、確認画面の切替UIの素材にする。

---

## File Structure

```
kakeibo-app/
  lib/domain/services/
    ocr/ocr_types.dart              # OcrRect, OcrBlock（正準空間）, OcrService(抽象), FakeOcrService
    receipt/
      normalize.dart                # 全角→半角・ダッシュ統一・数字文脈のOCR誤読修復・数トークン内空白除去
      rows.dart                     # ReceiptRow, groupRows（中央値行高×0.6のtoleranceでクラスタ）
      amounts.dart                  # AmountToken抽出（tier A/B/C）＋ 除外ガード（TEL/〒/T13/数量/%/時刻/日付…）
      total.dart                    # 行分類（P1..P4/税抜降格/除外行）→スコアリング→フォールバック→クロス検証
      date.dart                     # 和暦/西暦/2桁年+時代推定/MM-DD、検証（未来・古すぎ・暦妥当）、選択
      receipt_parser.dart           # ParsedReceipt, AmountCandidate, DateCandidate, ReceiptParser（統括）
  test/receipt/
    normalize_test.dart
    rows_test.dart
    amounts_test.dart
    total_test.dart
    date_test.dart
    receipt_parser_test.dart        # 合成フル・フィクスチャ（研究ブリーフの20ケース）
    perturbation_test.dart          # 決定的摂動でロバストネス検証
  test/support/receipt_fixtures.dart # JSONフィクスチャのloader＋ブロック生成ヘルパ
  test/fixtures/receipts/sample_supermarket.json  # JSON形式の見本（Mac実機ブリッジ互換）
```

---

## Task 1: 正準OCR型と FakeOcrService

**Files:**
- Create: `lib/domain/services/ocr/ocr_types.dart`
- Test: `test/receipt/rows_test.dart`（この段は型のsmokeのみ。行復元テストはTask 3で追記）

**Interfaces:**
- Produces:
  - `class OcrRect { final double x, y, w, h; const OcrRect(this.x, this.y, this.w, this.h); double get centerY; double get right; double get bottom; }` — **正準空間: 左上原点・y下向き・0..1正規化**
  - `class OcrBlock { final String text; final OcrRect rect; final double confidence; }`
  - `abstract interface class OcrService { Future<List<OcrBlock>> recognize(String imagePath); }`
  - `class FakeOcrService implements OcrService` — コンストラクタで固定ブロック列を受け、`recognize`が常にそれを返す（テスト/開発用）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/receipt/rows_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

void main() {
  test('OcrRect exposes derived edges in canonical space', () {
    const r = OcrRect(0.1, 0.2, 0.3, 0.05);
    expect(r.centerY, closeTo(0.225, 1e-9));
    expect(r.right, closeTo(0.4, 1e-9));
    expect(r.bottom, closeTo(0.25, 1e-9));
  });

  test('FakeOcrService returns the injected blocks for any path', () async {
    const blocks = [
      OcrBlock(text: '合計 ¥1,080', rect: OcrRect(0.1, 0.5, 0.8, 0.03), confidence: 0.99),
    ];
    final fake = FakeOcrService(blocks);
    expect(await fake.recognize('whatever.jpg'), blocks);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/rows_test.dart` → FAIL（型未定義）

- [ ] **Step 3: 実装**

Create `lib/domain/services/ocr/ocr_types.dart`:
```dart
/// OCR結果の正準空間モデル。
/// 規約: 左上原点・y下向き・0..1正規化・「行」粒度・per-block確信度。
/// Apple Vision(左下原点・正規化)や ML Kit(左上原点・ピクセル)からの変換は
/// 各 OcrService 実装の責務。パーサはこの空間だけを仮定する。
class OcrRect {
  final double x;
  final double y;
  final double w;
  final double h;
  const OcrRect(this.x, this.y, this.w, this.h);

  double get centerY => y + h / 2;
  double get right => x + w;
  double get bottom => y + h;
}

class OcrBlock {
  final String text;
  final OcrRect rect;
  final double confidence;
  const OcrBlock({required this.text, required this.rect, required this.confidence});
}

/// OCRエンジンの抽象。実装: AppleVisionOcrService(iOS/Mac, 後続Phase), FakeOcrService(テスト)。
abstract interface class OcrService {
  Future<List<OcrBlock>> recognize(String imagePath);
}

/// テスト・開発用: 固定のブロック列を返す。
class FakeOcrService implements OcrService {
  final List<OcrBlock> blocks;
  const FakeOcrService(this.blocks);

  @override
  Future<List<OcrBlock>> recognize(String imagePath) async => blocks;
}
```

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/rows_test.dart` → PASS

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/ocr/ocr_types.dart test/receipt/rows_test.dart
git commit -m "feat: canonical OCR block types, OcrService abstraction, FakeOcrService"
```

---

## Task 2: テキスト正規化

**Files:**
- Create: `lib/domain/services/receipt/normalize.dart`
- Test: `test/receipt/normalize_test.dart`

**Interfaces:**
- Produces:
  - `String normalizeOcrText(String s)` — 全角数字/英字→半角、`，．：／￥　％`→半角、**全ダッシュ族→`-`**（FF0D/2010/2011/2013/2014/30FC/2212）、`▲△`は保持（負値マーカー）。最後に**数トークン内空白を除去**（`¥ 1, 234`→`¥1,234`）。
  - `String repairDigitConfusions(String s)` — **数字文脈のみ**のOCR誤読修復: 数字に隣接する `O/o→0` `l/I→1` `B→8` `S→5`。数字文脈外の文字（例: 店名の"Book"）は触らない。

- [ ] **Step 1: 失敗するテストを書く**

Create `test/receipt/normalize_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';

void main() {
  group('normalizeOcrText', () {
    test('full-width digits and letters to ASCII', () {
      expect(normalizeOcrText('１２３４５'), '12345');
      expect(normalizeOcrText('Ｒ６年'), 'R6年');
    });

    test('full-width punctuation to ASCII', () {
      expect(normalizeOcrText('￥３，８５０'), '¥3,850');
      expect(normalizeOcrText('１４：３０'), '14:30');
      expect(normalizeOcrText('２０２４／０１／１５'), '2024/01/15');
      expect(normalizeOcrText('１０％'), '10%');
    });

    test('all dash variants unify to hyphen', () {
      // FF0D, 2010, 2013, 2014, 30FC(長音), 2212(minus)
      expect(normalizeOcrText('０３－１２３４'), '03-1234');
      expect(normalizeOcrText('03‐1234'), '03-1234');
      expect(normalizeOcrText('03–1234'), '03-1234');
      expect(normalizeOcrText('03—1234'), '03-1234');
      expect(normalizeOcrText('03ー1234'), '03-1234');
      expect(normalizeOcrText('03−1234'), '03-1234');
    });

    test('keeps ▲ and △ (negative markers)', () {
      expect(normalizeOcrText('▲１００'), '▲100');
      expect(normalizeOcrText('△100'), '△100');
    });

    test('collapses spaces inside number tokens', () {
      expect(normalizeOcrText('¥ 1, 234'), '¥1,234');
      expect(normalizeOcrText('合計 ¥ 3,850'), '合計 ¥3,850'); // ラベル境界の空白は保持
    });

    test('full-width space becomes normal space', () {
      expect(normalizeOcrText('合計　３８５０'), '合計 3850');
    });
  });

  group('repairDigitConfusions', () {
    test('repairs O/l/I/B/S adjacent to digits', () {
      expect(repairDigitConfusions('¥1,O80'), '¥1,080');
      expect(repairDigitConfusions('l,200'), '1,200');
      expect(repairDigitConfusions('12B'), '128');
      expect(repairDigitConfusions('5S0'), '550');
    });

    test('does not touch letters outside numeric context', () {
      expect(repairDigitConfusions('BOOK Store'), 'BOOK Store');
      expect(repairDigitConfusions('POINT'), 'POINT');
    });
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/normalize_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/domain/services/receipt/normalize.dart`:
```dart
/// OCRテキストの正規化。Dartの \d はASCIIのみ＝全角はここで潰してからregexへ。
/// ▲/△ は負値マーカーとして意図的に保持する。
String normalizeOcrText(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xFF10 && r <= 0xFF19) {
      sb.writeCharCode(r - 0xFEE0); // 全角数字
      continue;
    }
    if (r >= 0xFF21 && r <= 0xFF5A) {
      sb.writeCharCode(r - 0xFEE0); // 全角英字（Ａ-Ｚａ-ｚ、間の記号も同オフセットで無害）
      continue;
    }
    switch (r) {
      case 0xFF0C: sb.write(','); break; // ，
      case 0xFF0E: sb.write('.'); break; // ．
      case 0xFF1A: sb.write(':'); break; // ：
      case 0xFF0F: sb.write('/'); break; // ／
      case 0xFFE5: sb.write('¥'); break; // ￥
      case 0x3000: sb.write(' '); break; // 全角スペース
      case 0xFF05: sb.write('%'); break; // ％
      case 0xFF0D: // －
      case 0x2010: // ‐
      case 0x2011: // ‑
      case 0x2013: // –
      case 0x2014: // —
      case 0x30FC: // ー(長音。サーマルはダッシュと混用)
      case 0x2212: // −
        sb.write('-');
        break;
      default:
        sb.writeCharCode(r);
    }
  }
  // 数トークン内の空白を潰す: 「¥ 1, 234」→「¥1,234」
  // （カンマ/¥ の直後の空白列で、次が数字/カンマのもの。
  //  左辺に \d を入れると「12/28 18:05」の日付-時刻間まで接着して
  //  日付抽出を壊すため、¥ と , のみ）
  var out = sb.toString();
  out = out.replaceAllMapped(
    _numGap,
    (m) => m.group(1)!,
  );
  return out;
}

final _numGap = RegExp(r'([¥,])[ \t]+(?=[\d,])');

/// 数字文脈のOCR誤読修復（O→0, l/I→1, B→8, S→5）。
/// 数字に隣接する1文字だけを直し、単語中の文字は触らない。
String repairDigitConfusions(String s) {
  var out = s;
  // 数字の直後にある誤読文字
  out = out.replaceAllMapped(_confAfterDigit, (m) => _mapConfusion(m.group(1)!));
  // 数字(またはカンマ)の直前にある誤読文字
  out = out.replaceAllMapped(_confBeforeDigit, (m) => _mapConfusion(m.group(1)!));
  return out;
}

final _confAfterDigit = RegExp(r'(?<=\d)([OolIBS])(?![A-Za-z])');
final _confBeforeDigit = RegExp(r'(?<![A-Za-z])([OolIBS])(?=[\d,]*\d)');

String _mapConfusion(String c) => switch (c) {
      'O' || 'o' => '0',
      'l' || 'I' => '1',
      'B' => '8',
      'S' => '5',
      _ => c,
    };
```

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/normalize_test.dart` → PASS

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/receipt/normalize.dart test/receipt/normalize_test.dart
git commit -m "feat: OCR text normalization (zenkaku, dashes, in-number gaps, digit confusions)"
```

---

## Task 3: 行復元（bounding box クラスタリング）

**Files:**
- Create: `lib/domain/services/receipt/rows.dart`
- Modify: `test/receipt/rows_test.dart`（行復元テストを追記）

**Interfaces:**
- Consumes: `OcrBlock`/`OcrRect`（Task 1）
- Produces:
  - `class ReceiptRow { final List<OcrBlock> blocks; String get text; double get centerY; OcrBlock get rightmost; }`（blocksはx昇順）
  - `List<ReceiptRow> groupRows(List<OcrBlock> blocks)` — 行高中央値`lineH`、tolerance `τ = 0.6 * lineH`。**同一行判定 = |centerY差| ≤ τ かつ 垂直重なり > 0**。y順に走査してクラスタ、行内はx昇順。`text`は`' '`結合。

- [ ] **Step 1: 失敗するテストを追記**

`test/receipt/rows_test.dart` の `main()` に追記（importに `package:kakeibo_app/domain/services/receipt/rows.dart` を追加）:
```dart
  group('groupRows', () {
    OcrBlock b(String t, double x, double y, {double w = 0.3, double h = 0.03}) =>
        OcrBlock(text: t, rect: OcrRect(x, y, w, h), confidence: 0.9);

    test('label and amount as separate blocks on one physical row cluster together',
        () {
      final rows = groupRows([
        b('合計', 0.05, 0.600),
        b('¥3,850', 0.65, 0.602), // わずかにずれた同一行
        b('お預り', 0.05, 0.650),
        b('¥5,000', 0.65, 0.649),
      ]);
      expect(rows.length, 2);
      expect(rows[0].text, '合計 ¥3,850');
      expect(rows[0].rightmost.text, '¥3,850');
      expect(rows[1].text, 'お預り ¥5,000');
    });

    test('slight skew within 0.6*lineH tolerance stays one row', () {
      final rows = groupRows([
        b('ラベル', 0.05, 0.500, h: 0.030),
        b('999', 0.70, 0.514, h: 0.030), // centerY差 0.014 < 0.6*0.03
      ]);
      expect(rows.length, 1);
    });

    test('distinct lines split into separate rows', () {
      final rows = groupRows([
        b('1行目', 0.05, 0.10),
        b('2行目', 0.05, 0.15),
        b('3行目', 0.05, 0.20),
      ]);
      expect(rows.length, 3);
      expect(rows.map((r) => r.text).toList(), ['1行目', '2行目', '3行目']);
    });

    test('rows are ordered top-to-bottom, blocks left-to-right', () {
      final rows = groupRows([
        b('右', 0.60, 0.30),
        b('左', 0.05, 0.30),
        b('上', 0.05, 0.10),
      ]);
      expect(rows.first.text, '上');
      expect(rows.last.text, '左 右');
    });

    test('empty input -> empty rows', () {
      expect(groupRows(const []), isEmpty);
    });
  });
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/rows_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/domain/services/receipt/rows.dart`:
```dart
import '../ocr/ocr_types.dart';

/// 物理行（ラベル左・金額右の2カラムを1行に束ねる）。blocksはx昇順。
class ReceiptRow {
  final List<OcrBlock> blocks;
  ReceiptRow(this.blocks);

  String get text => blocks.map((b) => b.text).join(' ');
  double get centerY =>
      blocks.map((b) => b.rect.centerY).reduce((a, c) => a + c) / blocks.length;
  double get top => blocks.map((b) => b.rect.y).reduce((a, c) => a < c ? a : c);
  double get bottom =>
      blocks.map((b) => b.rect.bottom).reduce((a, c) => a > c ? a : c);
  OcrBlock get rightmost =>
      blocks.reduce((a, c) => c.rect.right >= a.rect.right ? c : a);
}

/// bounding box から物理行を復元する。
/// 行高中央値 lineH、tolerance τ = 0.6 * lineH。
/// 同一行 = |centerY差| ≤ τ かつ 垂直重なり > 0。
List<ReceiptRow> groupRows(List<OcrBlock> blocks) {
  if (blocks.isEmpty) return const [];

  final hs = blocks.map((b) => b.rect.h).toList()..sort();
  final lineH = hs[hs.length ~/ 2];
  final tau = 0.6 * lineH;

  final sorted = [...blocks]..sort((a, b) => a.rect.centerY.compareTo(b.rect.centerY));
  final rows = <ReceiptRow>[];

  for (final block in sorted) {
    ReceiptRow? home;
    for (final row in rows) {
      final dy = (block.rect.centerY - row.centerY).abs();
      final overlap =
          _min(block.rect.bottom, row.bottom) - _max(block.rect.y, row.top);
      if (dy <= tau && overlap > 0) {
        home = row;
        break;
      }
    }
    if (home != null) {
      home.blocks.add(block);
    } else {
      rows.add(ReceiptRow([block]));
    }
  }

  for (final row in rows) {
    row.blocks.sort((a, b) => a.rect.x.compareTo(b.rect.x));
  }
  rows.sort((a, b) => a.centerY.compareTo(b.centerY));
  return rows;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;
```

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/rows_test.dart` → PASS

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/receipt/rows.dart test/receipt/rows_test.dart
git commit -m "feat: physical row reconstruction from OCR bounding boxes"
```

---

## Task 4: 金額トークン抽出＋除外ガード

**Files:**
- Create: `lib/domain/services/receipt/amounts.dart`
- Test: `test/receipt/amounts_test.dart`

**Interfaces:**
- Consumes: `ReceiptRow`（Task 3）、`normalize.dart`（Task 2。呼び出し側で適用済み前提だが、`repairDigitConfusions`は本モジュールが金額走査前にブロック単位で適用）
- Produces:
  - `enum AmountTier { currency, comma, bare }`（A=通貨アンカー / B=カンマ区切り / C=裸数字）
  - `class AmountToken { final int yen; final bool negative; final AmountTier tier; final String raw; final OcrBlock block; }`
  - `List<AmountToken> extractAmounts(ReceiptRow row)` — 行内の各ブロックから金額トークンを抽出。**事前にブロックテキスト内の 日付/時刻/TEL/〒/T13/数量(×@)/税率% にマッチする範囲を空白でマスク**してから金額regexを走査。行レベルガード（行に`TEL/電話/FAX`→裸の10-11桁を除外、`No/レジ/責/取引/伝票/会員`→カンマ無し6桁以上を除外 等）を適用。妥当域 `1..9,999,999` 外は破棄。負値（`- ▲ △`前置）は`negative: true`で保持（割引検出用。総額候補からは除外される）。

- [ ] **Step 1: 失敗するテストを書く**

Create `test/receipt/amounts_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/amounts.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

ReceiptRow rowOf(String text, {double y = 0.5}) => groupRows([
      OcrBlock(text: text, rect: OcrRect(0.05, y, 0.9, 0.03), confidence: 0.9),
    ]).single;

List<int> yensOf(String text) =>
    extractAmounts(rowOf(text)).where((t) => !t.negative).map((t) => t.yen).toList();

void main() {
  group('tiers', () {
    test('currency-anchored: ¥ prefix, 円 suffix, backslash misread, starred', () {
      expect(yensOf('¥3,850'), [3850]);
      expect(yensOf(r'\3,850'), [3850]); // ¥の\誤読
      expect(yensOf('3850円'), [3850]);
      expect(yensOf('*¥3,850*'), [3850]);
      final t = extractAmounts(rowOf('¥3,850')).single;
      expect(t.tier, AmountTier.currency);
    });

    test('comma-grouped bare number is tier B', () {
      final t = extractAmounts(rowOf('3,850')).single;
      expect(t.yen, 3850);
      expect(t.tier, AmountTier.comma);
    });

    test('bare integer is tier C', () {
      final t = extractAmounts(rowOf('合計 3850')).single;
      expect(t.yen, 3850);
      expect(t.tier, AmountTier.bare);
    });

    test('negative markers produce negative tokens (discounts)', () {
      final t = extractAmounts(rowOf('値引 ▲100')).single;
      expect(t.yen, 100);
      expect(t.negative, isTrue);
      expect(yensOf('値引 -100'), isEmpty); // 非負のみ返すヘルパでは空
    });
  });

  group('guards: these must NOT be amounts', () {
    test('phone numbers', () {
      expect(yensOf('TEL 03-1234-5678'), isEmpty);
      expect(yensOf('電話 0312345678'), isEmpty);
    });

    test('postal codes', () {
      expect(yensOf('〒123-4567 東京都'), isEmpty);
    });

    test('invoice registration number T+13', () {
      expect(yensOf('登録番号 T1234567890123'), isEmpty);
    });

    test('dates and times', () {
      expect(yensOf('2024/01/15 14:30'), isEmpty);
      expect(yensOf('2024年1月15日'), isEmpty);
    });

    test('quantity and unit price markers', () {
      expect(yensOf('数量 3'), isEmpty);
      expect(yensOf('＠150 ×2'), isEmpty);
    });

    test('tax rate percent', () {
      expect(yensOf('10%'), isEmpty);
      expect(yensOf('消費税(10%)'), isEmpty); // %はマスク、税額は別行
    });

    test('register/transaction ids (long bare digit runs on id rows)', () {
      expect(yensOf('レジNo 123456'), isEmpty);
      expect(yensOf('取引 20240115001'), isEmpty);
    });

    test('implausible magnitude', () {
      expect(yensOf('99999999円'), isEmpty); // > 9,999,999
    });

    test('digit-confusion repair inside amounts', () {
      expect(yensOf('¥1,O80'), [1080]);
    });
  });

  test('multiple amounts in one block: all extracted, order preserved', () {
    expect(yensOf('小計 3,500 外税 350'), [3500, 350]);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/amounts_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/domain/services/receipt/amounts.dart`:
```dart
import '../ocr/ocr_types.dart';
import 'normalize.dart';
import 'rows.dart';

/// 金額トークンの確信度tier。
/// currency: ¥/円/星囲みアンカー / comma: 3,850形式 / bare: 裸数字（文脈必須）
enum AmountTier { currency, comma, bare }

class AmountToken {
  final int yen;
  final bool negative;
  final AmountTier tier;
  final String raw;
  final OcrBlock block;
  const AmountToken({
    required this.yen,
    required this.negative,
    required this.tier,
    required this.raw,
    required this.block,
  });
}

const int maxPlausibleYen = 9999999;

// --- マスク対象（金額として拾ってはならない数値文脈） ---
final _maskPatterns = <RegExp>[
  RegExp(r'T\d{13}'), // インボイス登録番号
  RegExp(r'〒\s*\d{3}-?\d{4}'), // 郵便番号
  RegExp(r'0\d{1,4}-\d{1,4}-\d{3,4}'), // 電話（ハイフン形式）
  RegExp(r'\d{4}\s*[/\-.年]\s*\d{1,2}\s*[/\-.月]\s*\d{1,2}\s*日?'), // 日付(4桁年)
  RegExp(r'(?<![\d/\-.])\d{1,2}[/\-.]\d{1,2}[/\-.]\d{1,2}(?![\d/\-.])'), // 日付(短)
  RegExp(r'\d{1,2}\s*[:時]\s*\d{2}'), // 時刻
  RegExp(r'[×xX＠@]\s*\d+'), // 数量・単価マーカー
  RegExp(r'\d+(?:\.\d+)?\s*%'), // 税率
];

// --- 金額regex（正規化済みテキスト前提） ---
const _grp = r'\d{1,3}(?:,\d{3})+'; // カンマ区切り必須
const _bare = r'\d{1,7}';

final _reYenPrefix = RegExp(r'[¥\\]\s*([-▲△]?(?:' + _grp + r'|' + _bare + r'))');
final _reYenSuffix =
    RegExp(r'(?<![\d,])([-▲△]?(?:' + _grp + r'|' + _bare + r'))\s*円');
final _reStarred = RegExp(r'\*\s*¥?\s*(' + _grp + r')\s*\*');
final _reComma = RegExp(r'(?<![\d,.¥\\])([-▲△]?' + _grp + r')(?![\d,])');
final _reBare = RegExp(r'(?<![\d,.\-¥\\])([-▲△]?' + _bare + r')(?![\d,%])');

final _reNeg = RegExp(r'^\s*[-▲△]');

// --- 行レベルガードの語彙 ---
final _rePhoneRow = RegExp(r'TEL|電話|FAX', caseSensitive: false);
final _reIdRow = RegExp(r'No|レジ|責|取引|伝票|会員', caseSensitive: false);
final _reQtyRow = RegExp(r'数量|単価|点数');
final _reLongBareDigits = RegExp(r'^\d{6,}$');
final _rePhoneLike = RegExp(r'^0\d{9,10}$');

int? _parseYen(String tok) {
  final digits = tok.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty || digits.length > 8) return null;
  final v = int.parse(digits);
  if (v < 1 || v > maxPlausibleYen) return null;
  return v;
}

String _mask(String text) {
  var out = text;
  for (final re in _maskPatterns) {
    out = out.replaceAllMapped(re, (m) => ' ' * (m.end - m.start));
  }
  return out;
}

/// 行から金額トークンを抽出する。呼び出し側は normalizeOcrText 適用済みテキストを前提。
List<AmountToken> extractAmounts(ReceiptRow row) {
  final rowText = row.text;
  final phoneRow = _rePhoneRow.hasMatch(rowText);
  final idRow = _reIdRow.hasMatch(rowText);
  final qtyRow = _reQtyRow.hasMatch(rowText);

  final tokens = <AmountToken>[];
  for (final block in row.blocks) {
    final repaired = repairDigitConfusions(block.text);
    final masked = _mask(repaired);

    // マッチ範囲の重複を避けるため tier 順に走査し、採用済み範囲はスキップ
    final taken = <(int, int)>[];
    bool overlaps(int s, int e) =>
        taken.any((r) => s < r.$2 && e > r.$1);

    void scan(RegExp re, AmountTier tier) {
      for (final m in re.allMatches(masked)) {
        final s = m.start, e = m.end;
        if (overlaps(s, e)) continue;
        final raw = m.group(1) ?? m.group(0)!;
        final yen = _parseYen(raw);
        if (yen == null) continue;
        final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
        final hasComma = raw.contains(',');

        // 行レベルガード
        if (phoneRow && !hasComma && digits.length >= 6) continue;
        if (_rePhoneLike.hasMatch(digits)) continue;
        if (idRow && !hasComma && _reLongBareDigits.hasMatch(digits)) continue;
        if (qtyRow && tier == AmountTier.bare) continue;

        taken.add((s, e));
        tokens.add(AmountToken(
          yen: yen,
          negative: _reNeg.hasMatch(raw),
          tier: tier,
          raw: raw,
          block: block,
        ));
      }
    }

    scan(_reStarred, AmountTier.currency);
    scan(_reYenPrefix, AmountTier.currency);
    scan(_reYenSuffix, AmountTier.currency);
    scan(_reComma, AmountTier.comma);
    scan(_reBare, AmountTier.bare);
  }
  return tokens;
}
```

> **実装ノート**: tokensは「ブロックのx昇順（rowが保証）→ tier走査順 → 同tier内は`allMatches`の左→右」で自然に整列するため、**sortしない**（Dartの`List.sort`は不安定でcomparatorが0を返すペアの順序を壊しうる）。「小計 3,500 外税 350」は同tier(B)なので左→右が保たれる。

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/amounts_test.dart` → PASS

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/receipt/amounts.dart test/receipt/amounts_test.dart
git commit -m "feat: tiered amount tokenization with pitfall guards (tel/postal/invoice/qty/rate/id)"
```

---

## Task 5: 合計（税込）選択 — スコアリング・フォールバック・クロス検証

**Files:**
- Create: `lib/domain/services/receipt/total.dart`
- Test: `test/receipt/total_test.dart`

**Interfaces:**
- Consumes: `ReceiptRow`/`extractAmounts`/`AmountTier`
- Produces:
  - `enum ExtractionConfidence { high, medium, low }`（date.dart/receipt_parser.dartと共有するため本ファイルで定義）
  - `class AmountCandidate { final int yen; final ExtractionConfidence confidence; final String sourceText; final String reason; }`
  - `class TotalExtraction { final AmountCandidate? best; final List<AmountCandidate> candidates; }`
  - `TotalExtraction extractTotal(List<ReceiptRow> rows)`
  - ロジック（研究ブリーフ§3準拠）:
    - 行分類: **P1** `合計/お会計/御会計/ご請求/お支払/領収` **P2** `税込/総額/総合計/総計` **P3** `お買上げ/お買い上げ/お買上/買上/お買物` **P4** 裸の`計`（`(?<![小中抜外合会総課])計`）
    - **税抜バリアント降格**: 行に `税抜/本体/外税対象` → -1000
    - **除外行**（絶対に合計にしない）: `預り/預/お預/現金/キャッシュ/釣/つり/返金/お返し/ポイント/残高/クレジット/カード/電子マネー/チャージ/差引/利用額/値引/割引/クーポン/非課税/課税対象額`
    - スコア = tierWeight(P1=100,P2=110,P3=80,P4=30) + 税込マーカー+25 + 下半分+10 + カンマ/¥形式+10 + **現金恒等式一致+40**
    - 同点は**より下の行**を採用
    - **税抜合計+消費税 の合成**: 税込系候補ゼロ かつ `税抜合計`と`消費税`行があるなら `total = 税抜 + Σ税`（medium）
    - **フォールバック**: キーワード候補ゼロなら、除外行以外の Tier A/B 非負トークンの**最大値**（medium）。`小計`があれば `小計+Σ税` に最近傍の候補を優先
    - **現金恒等式**: `お預り T`と`お釣り C`があれば `T−C` を検証に使い、キーワード候補ゼロなら `T−C` 自体を候補に（recovery, medium）
    - 確信度: キーワード行 high（**ただし金額が裸数字トークンなら low**）／ フォールバック・合成・recovery medium
    - `candidates` はスコア降順（UI切替用、最大5件、重複円値は除去）

- [ ] **Step 1: 失敗するテストを書く**

Create `test/receipt/total_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/services/receipt/total.dart';

/// 1行1ブロックの合成レシート。yは行順で自動採番。
List<ReceiptRow> receipt(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (final (i, line) in lines.indexed) {
    blocks.add(OcrBlock(
      text: normalizeOcrText(line),
      rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
      confidence: 0.9,
    ));
  }
  return groupRows(blocks);
}

void main() {
  test('picks 合計 over 小計 (tax-inclusive over subtotal)', () {
    final r = extractTotal(receipt(['小計 3,500', '消費税(10%) 350', '合計 3,850']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.high);
  });

  test('tendered/change rows never win; cash identity boosts the total', () {
    final r = extractTotal(receipt(['合計 3,850', 'お預り 10,000', 'お釣り 6,150']));
    expect(r.best!.yen, 3850);
  });

  test('points balance trap: 残高 must not be chosen', () {
    final r = extractTotal(receipt(['ポイント 385', 'ポイント残高 12,340', '合計 3,850']));
    expect(r.best!.yen, 3850);
  });

  test('credit line does not shadow the total', () {
    final r = extractTotal(receipt(['合計 3,850', 'クレジット 3,850', 'カード ****1234']));
    expect(r.best!.yen, 3850);
  });

  test('picks 税込合計 over 税抜合計', () {
    final r = extractTotal(receipt(['税抜合計 3,500', '税込合計 3,850']));
    expect(r.best!.yen, 3850);
  });

  test('内税 note does not confuse: 合計 wins', () {
    final r = extractTotal(receipt(['合計 3,850', '(内消費税 350)']));
    expect(r.best!.yen, 3850);
  });

  test('fallback: no keyword -> max plausible excluding tendered/change', () {
    final r = extractTotal(receipt(['ネギ 128', '牛乳 258', '3,850', 'お預り 5,000']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('¥ misread as backslash still anchors', () {
    final r = extractTotal(receipt([r'合計 \3,850']));
    expect(r.best!.yen, 3850);
  });

  test('full-width text works end-to-end', () {
    final r = extractTotal(receipt(['合計　￥３，８５０']));
    expect(r.best!.yen, 3850);
  });

  test('discount rows are never the total', () {
    final r = extractTotal(receipt(['小計 3,950', '値引 ▲100', '合計 3,850']));
    expect(r.best!.yen, 3850);
  });

  test('starred grand total', () {
    final r = extractTotal(receipt(['お買上げ *¥3,850*']));
    expect(r.best!.yen, 3850);
  });

  test('reduced tax rate receipt: 8%/10% breakdown rows do not win', () {
    final r = extractTotal(receipt([
      '8%対象 1,080',
      '10%対象 2,770',
      '合計 3,850',
    ]));
    expect(r.best!.yen, 3850);
  });

  test('税抜合計+消費税 synthesis when no tax-inclusive total printed', () {
    final r = extractTotal(receipt(['税抜合計 3,500', '消費税 350']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('cash identity recovers total when 合計 row is unreadable', () {
    final r = extractTotal(receipt(['お預り 10,000', 'お釣り 6,150']));
    expect(r.best!.yen, 3850);
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('candidates are exposed for UI switching, best first, deduped', () {
    final r = extractTotal(receipt(['小計 3,500', '合計 3,850']));
    expect(r.candidates.first.yen, 3850);
    expect(r.candidates.map((c) => c.yen).toSet().length, r.candidates.length);
  });

  test('no amounts at all -> best is null', () {
    final r = extractTotal(receipt(['ありがとうございました']));
    expect(r.best, isNull);
    expect(r.candidates, isEmpty);
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/total_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/domain/services/receipt/total.dart`:
```dart
import 'amounts.dart';
import 'rows.dart';

enum ExtractionConfidence { high, medium, low }

class AmountCandidate {
  final int yen;
  final ExtractionConfidence confidence;
  final String sourceText;
  final String reason;
  const AmountCandidate({
    required this.yen,
    required this.confidence,
    required this.sourceText,
    required this.reason,
  });
}

class TotalExtraction {
  final AmountCandidate? best;
  final List<AmountCandidate> candidates;
  const TotalExtraction({required this.best, required this.candidates});
}

// --- キーワード語彙 ---
final _reP1 = RegExp(r'合計|お会計|御会計|ご請求|お支払|領収');
final _reP2 = RegExp(r'税込|内税込|総額|総合計|総計');
final _reP3 = RegExp(r'お買上げ|お買い上げ|お買上|買上|お買物');
final _reP4 = RegExp(r'(?<![小中抜外合会総課])計');
final _reTaxExcluded = RegExp(r'税抜|本体|外税対象');
final _reExclusion = RegExp(
    r'預り|預か|お預|現金|キャッシュ|釣|つり|返金|お返し|'
    r'ポイント|残高|クレジット|カード|電子マネー|チャージ|差引|利用額|'
    r'値引|割引|クーポン|非課税|課税対象額');
final _reSubtotal = RegExp(r'小計');
final _reTax = RegExp(r'消費税|外税|内税(?!込)');
final _reTendered = RegExp(r'預');
final _reChange = RegExp(r'釣|つり');

class _RowInfo {
  final ReceiptRow row;
  final int index;
  final int total;
  final List<AmountToken> tokens;
  _RowInfo(this.row, this.index, this.total, this.tokens);
}

/// 行の右端（最右トークン）の非負金額。無ければnull。
int? _rowAmount(List<AmountToken> tokens) {
  final positives = tokens.where((t) => !t.negative).toList();
  if (positives.isEmpty) return null;
  return positives.last.yen; // 行内で最後（最右/最終出現）
}

TotalExtraction extractTotal(List<ReceiptRow> rows) {
  final infos = <_RowInfo>[];
  for (final (i, row) in rows.indexed) {
    final tokens = extractAmounts(row);
    infos.add(_RowInfo(row, i, rows.length, tokens));
  }

  // --- 現金恒等式の素材 ---
  int? tendered;
  int? change;
  for (final info in infos) {
    final text = info.row.text;
    final amount = _rowAmount(info.tokens);
    if (amount == null) continue;
    if (_reTendered.hasMatch(text)) tendered ??= amount;
    if (_reChange.hasMatch(text) && !_reTendered.hasMatch(text)) change ??= amount;
  }
  final cashIdentity =
      (tendered != null && change != null) ? tendered - change : null;

  // --- キーワード候補のスコアリング ---
  final scored = <(int score, int rowIndex, AmountCandidate cand)>[];
  for (final info in infos) {
    final text = info.row.text;
    if (_reExclusion.hasMatch(text)) continue;

    int tier = 0;
    if (_reP2.hasMatch(text)) {
      tier = 110;
    } else if (_reP1.hasMatch(text)) {
      tier = 100;
    } else if (_reP3.hasMatch(text)) {
      tier = 80;
    } else if (_reP4.hasMatch(text) && !_reSubtotal.hasMatch(text)) {
      tier = 30;
    }
    if (tier == 0) continue;

    final amount = _rowAmount(info.tokens);
    if (amount == null || amount <= 0) continue;

    var score = tier;
    if (_reTaxExcluded.hasMatch(text)) score -= 1000;
    if (RegExp(r'税込|内税').hasMatch(text)) score += 25;
    if (info.row.centerY > 0.5) score += 10;
    final token =
        info.tokens.lastWhere((t) => !t.negative && t.yen == amount);
    if (token.tier != AmountTier.bare) score += 10;
    if (cashIdentity != null && amount == cashIdentity) score += 40;

    if (score <= 0) continue; // 税抜降格は候補から外す（合成パスで扱う）
    scored.add((
      score,
      info.index,
      AmountCandidate(
        yen: amount,
        // キーワード行でも金額が裸数字（通貨手がかりなし）なら low
        confidence: token.tier == AmountTier.bare
            ? ExtractionConfidence.low
            : ExtractionConfidence.high,
        sourceText: text,
        reason: 'keyword(score=$score)',
      )
    ));
  }

  // 同点はより下の行（index大）を優先 → score desc, index desc
  scored.sort((a, b) {
    final s = b.$1.compareTo(a.$1);
    return s != 0 ? s : b.$2.compareTo(a.$2);
  });

  final candidates = <AmountCandidate>[];
  void addCandidate(AmountCandidate c) {
    if (candidates.any((e) => e.yen == c.yen)) return;
    if (candidates.length >= 5) return;
    candidates.add(c);
  }

  for (final s in scored) {
    addCandidate(s.$3);
  }

  AmountCandidate? best = candidates.isNotEmpty ? candidates.first : null;

  // --- 税抜合計 + 消費税 の合成（税込系候補ゼロのとき） ---
  if (best == null) {
    int? taxExcludedTotal;
    var taxSum = 0;
    for (final info in infos) {
      final text = info.row.text;
      final amount = _rowAmount(info.tokens);
      if (amount == null) continue;
      if (_reTaxExcluded.hasMatch(text) && RegExp(r'合計|計').hasMatch(text)) {
        taxExcludedTotal ??= amount;
      } else if (_reTax.hasMatch(text) && !_reExclusion.hasMatch(text)) {
        taxSum += amount;
      }
    }
    if (taxExcludedTotal != null && taxSum > 0) {
      best = AmountCandidate(
        yen: taxExcludedTotal + taxSum,
        confidence: ExtractionConfidence.medium,
        sourceText: '税抜合計+消費税',
        reason: 'synthesized(taxExcluded+tax)',
      );
      addCandidate(best);
    }
  }

  // --- フォールバック: 除外行以外の Tier A/B 最大値 ---
  if (best == null) {
    final pool = <AmountToken>[];
    int? subtotal;
    var taxSum = 0;
    for (final info in infos) {
      final text = info.row.text;
      final amount = _rowAmount(info.tokens);
      if (_reSubtotal.hasMatch(text) && amount != null) subtotal ??= amount;
      if (_reTax.hasMatch(text) && amount != null) taxSum += amount;
      if (_reExclusion.hasMatch(text)) continue;
      pool.addAll(info.tokens
          .where((t) => !t.negative && t.tier != AmountTier.bare));
    }
    if (pool.isNotEmpty) {
      AmountToken pick;
      if (subtotal != null && taxSum > 0) {
        final target = subtotal + taxSum;
        pick = pool.reduce((a, c) =>
            (c.yen - target).abs() < (a.yen - target).abs() ? c : a);
      } else {
        pick = pool.reduce((a, c) => c.yen > a.yen ? c : a);
      }
      best = AmountCandidate(
        yen: pick.yen,
        confidence: ExtractionConfidence.medium,
        sourceText: pick.raw,
        reason: 'fallback(max-plausible)',
      );
      addCandidate(best);
    }
  }

  // --- 現金恒等式によるrecovery ---
  if (best == null && cashIdentity != null && cashIdentity > 0) {
    best = AmountCandidate(
      yen: cashIdentity,
      confidence: ExtractionConfidence.medium,
      sourceText: 'お預り-お釣り',
      reason: 'cash-identity',
    );
    addCandidate(best);
  }

  return TotalExtraction(best: best, candidates: candidates);
}
```

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/total_test.dart` → PASS（16ケース）

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/receipt/total.dart test/receipt/total_test.dart
git commit -m "feat: tax-inclusive total selection (keyword scoring, fallback, cash-identity)"
```

---

## Task 6: 日付抽出（和暦・時代推定・検証・選択）

**Files:**
- Create: `lib/domain/services/receipt/date.dart`
- Test: `test/receipt/date_test.dart`

**Interfaces:**
- Consumes: `ReceiptRow`、`CivilDate`（Phase 1）、`ExtractionConfidence`（Task 5）
- Produces:
  - `class DateCandidate { final CivilDate date; final ExtractionConfidence confidence; final String sourceText; final String reason; }`
  - `class DateExtraction { final DateCandidate? best; final List<DateCandidate> candidates; }`
  - `DateExtraction extractDate(List<ReceiptRow> rows, CivilDate today)`
  - ロジック（研究ブリーフ§4準拠＋批評反映）:
    - regex: 西暦4桁 / 和暦（`令和/平成/昭和/R/H/S`＋`元`対応、変換 2018/1988/1925+N）/ 短年 `Y{1,2}.M.D`（**時代推定**: 2桁→西暦20YY候補と和暦2018+YY候補の両方を生成し、**未来でなく今日に近い方**を採用。1桁は和暦のみ）/ **MM/DDのみは同一行に時刻がある場合だけ**（年=今日を超えない直近年）
    - 検証: 暦妥当（`CivilDate.isValid`）・**未来棄却**（today+1日超）・**古すぎ棄却**（year<2000）
    - 除外: 行に `期限/有効/まで/~` があれば棄却（ポイント有効期限・キャンペーン）
    - 選択スコア: 同一行に時刻 +50 ／ 上部ほど加点 `(1−centerY)*20` ／ 行に `発行/取引/ご利用/日時/レジ` +15
    - 確信度: 時刻同居のフル日付 high（**時刻非同居のフル日付は medium に降格**）／ 時代推定・短年 medium ／ MM/DDのみ・**今日既定** low
    - 候補ゼロ → `best = DateCandidate(today, low, '', 'default-today')`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/receipt/date_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/date.dart';
import 'package:kakeibo_app/domain/services/receipt/normalize.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/services/receipt/total.dart'
    show ExtractionConfidence;
import 'package:kakeibo_app/domain/money/civil_date.dart';

const today = CivilDate(2026, 7, 3);

DateExtraction run(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (final (i, line) in lines.indexed) {
    blocks.add(OcrBlock(
      text: normalizeOcrText(line),
      rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
      confidence: 0.9,
    ));
  }
  return extractDate(groupRows(blocks), today);
}

void main() {
  test('gregorian with 年月日 and time -> high confidence', () {
    final r = run(['2026年1月15日 14:30']);
    expect(r.best!.date, const CivilDate(2026, 1, 15));
    expect(r.best!.confidence, ExtractionConfidence.high);
  });

  test('gregorian slash/dash variants', () {
    expect(run(['2026/01/15']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['2026-1-5']).best!.date, const CivilDate(2026, 1, 5));
  });

  test('two-digit year resolves to 20YY when plausible', () {
    expect(run(['26.01.15']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['26/1/5']).best!.date, const CivilDate(2026, 1, 5));
  });

  test('wareki full and abbreviated', () {
    expect(run(['令和8年1月15日']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['R8.1.15']).best!.date, const CivilDate(2026, 1, 15));
    expect(run(['令和元年5月1日']).best!.date, const CivilDate(2019, 5, 1));
    expect(run(['H31.4.20']).best!.date, const CivilDate(2019, 4, 20));
  });

  test('bare single-digit year is inferred as 令和 (8.07.03 -> 2026)', () {
    final r = run(['8.07.03']);
    expect(r.best!.date, const CivilDate(2026, 7, 3));
    expect(r.best!.confidence, ExtractionConfidence.medium);
  });

  test('two-digit ambiguity prefers the interpretation closest to today', () {
    // 06.07.03: 西暦2006(20年前) vs 令和6=2024(2年前) -> 2024
    final r = run(['06.07.03']);
    expect(r.best!.date, const CivilDate(2024, 7, 3));
  });

  test('future dates (point expiry) are rejected in favor of the issue date', () {
    final r = run(['2026/01/15 10:00', 'ポイント有効期限 2027/03/31']);
    expect(r.best!.date, const CivilDate(2026, 1, 15));
  });

  test('期限/有効/まで rows are excluded even without a better date', () {
    final r = run(['お支払い期限 2026/06/30']);
    expect(r.best!.reason, 'default-today'); // 期限行しか無ければ今日既定
  });

  test('topmost date preferred over campaign date below', () {
    final r = run(['2026/07/01', 'セール開催 2026/06/20']);
    expect(r.best!.date, const CivilDate(2026, 7, 1));
  });

  test('invalid calendar dates rejected', () {
    final r = run(['2026/02/30']);
    expect(r.best!.reason, 'default-today');
  });

  test('too-old years rejected', () {
    final r = run(['1999/01/15']);
    expect(r.best!.reason, 'default-today');
  });

  test('MM/DD only requires an adjacent time; year rolls back across new year',
      () {
    // today=2026-07-03: 「12/28 18:05」→ 2025-12-28（未来にしない）
    final r = run(['12/28 18:05']);
    expect(r.best!.date, const CivilDate(2025, 12, 28));
    expect(r.best!.confidence, ExtractionConfidence.low);
  });

  test('no date at all -> today as low-confidence default', () {
    final r = run(['ありがとうございました']);
    expect(r.best!.date, today);
    expect(r.best!.confidence, ExtractionConfidence.low);
    expect(r.best!.reason, 'default-today');
  });

  test('phone numbers are not misread as dates', () {
    final r = run(['TEL 03-1234-5678']);
    expect(r.best!.reason, 'default-today');
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/date_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/domain/services/receipt/date.dart`:
```dart
import '../../money/civil_date.dart';
import 'rows.dart';
import 'total.dart' show ExtractionConfidence;

class DateCandidate {
  final CivilDate date;
  final ExtractionConfidence confidence;
  final String sourceText;
  final String reason;
  const DateCandidate({
    required this.date,
    required this.confidence,
    required this.sourceText,
    required this.reason,
  });
}

class DateExtraction {
  final DateCandidate? best;
  final List<DateCandidate> candidates;
  const DateExtraction({required this.best, required this.candidates});
}

final _reGregorian = RegExp(
    r'(?<y>\d{4})\s*[/\-.年]\s*(?<m>\d{1,2})\s*[/\-.月]\s*(?<d>\d{1,2})\s*日?');
final _reWareki = RegExp(
    r'(?<era>令和|平成|昭和|[RHS])\s*(?<ey>元|\d{1,2})\s*[年.\-/]\s*'
    r'(?<m>\d{1,2})\s*[月.\-/]\s*(?<d>\d{1,2})\s*日?');
final _reShortYear = RegExp(
    r'(?<![\d/\-.年])(?<y>\d{1,2})[/\-.](?<m>\d{1,2})[/\-.](?<d>\d{1,2})(?![\d/\-.])');
final _reMonthDay = RegExp(
    r'(?<![\d/\-.年月])(?<m>\d{1,2})[/月](?<d>\d{1,2})日?(?![\d/\-.日])');
final _reTime = RegExp(r'\d{1,2}\s*[:時]\s*\d{2}');
final _reExpiry = RegExp(r'期限|有効|まで|~');
final _reIssueCue = RegExp(r'発行|取引|ご利用|日時|レジ');
final _rePhoneGuard = RegExp(r'TEL|電話|FAX|〒', caseSensitive: false);

int _warekiYear(String era, String ey) {
  final n = (ey == '元') ? 1 : int.parse(ey);
  return switch (era) {
    '令和' || 'R' => 2018 + n,
    '平成' || 'H' => 1988 + n,
    '昭和' || 'S' => 1925 + n,
    _ => -1,
  };
}

CivilDate? _valid(int y, int m, int d) {
  final c = CivilDate(y, m, d);
  return c.isValid ? c : null;
}

/// today+1日 を返す（tzスラック）
CivilDate _tomorrow(CivilDate today) {
  final dt = DateTime.utc(today.year, today.month, today.day)
      .add(const Duration(days: 1));
  return CivilDate(dt.year, dt.month, dt.day);
}

int _daysFromToday(CivilDate d, CivilDate today) {
  final a = DateTime.utc(d.year, d.month, d.day);
  final b = DateTime.utc(today.year, today.month, today.day);
  return a.difference(b).inDays;
}

class _Raw {
  final CivilDate date;
  final ExtractionConfidence confidence;
  final String reason;
  _Raw(this.date, this.confidence, this.reason);
}

DateExtraction extractDate(List<ReceiptRow> rows, CivilDate today) {
  final tomorrow = _tomorrow(today);
  final found = <(double score, int order, DateCandidate cand)>[];
  var order = 0;

  bool acceptable(CivilDate d) =>
      d.year >= 2000 && d.compareTo(tomorrow) <= 0;

  for (final row in rows) {
    final text = row.text;
    if (_rePhoneGuard.hasMatch(text)) continue; // TEL/〒行の数値は日付にしない
    if (_reExpiry.hasMatch(text)) continue; // 有効期限・キャンペーン行
    final hasTime = _reTime.hasMatch(text);

    final raws = <_Raw>[];

    for (final m in _reWareki.allMatches(text)) {
      final y = _warekiYear(m.namedGroup('era')!, m.namedGroup('ey')!);
      final d = _valid(y, int.parse(m.namedGroup('m')!), int.parse(m.namedGroup('d')!));
      if (d != null) raws.add(_Raw(d, ExtractionConfidence.high, 'wareki'));
    }

    for (final m in _reGregorian.allMatches(text)) {
      final d = _valid(int.parse(m.namedGroup('y')!), int.parse(m.namedGroup('m')!),
          int.parse(m.namedGroup('d')!));
      if (d != null) raws.add(_Raw(d, ExtractionConfidence.high, 'gregorian'));
    }

    // 短年: 2桁→西暦20YYと和暦2018+YYの両解釈、1桁→和暦のみ。
    // 双方validなら「未来でなく今日に近い方」。
    if (raws.isEmpty) {
      for (final m in _reShortYear.allMatches(text)) {
        final yTok = m.namedGroup('y')!;
        final mo = int.parse(m.namedGroup('m')!);
        final da = int.parse(m.namedGroup('d')!);
        final interp = <CivilDate>[];
        if (yTok.length == 2) {
          final g = _valid(2000 + int.parse(yTok), mo, da);
          if (g != null) interp.add(g);
        }
        final w = _valid(2018 + int.parse(yTok), mo, da);
        if (w != null) interp.add(w);
        final ok = interp.where(acceptable).toList();
        if (ok.isEmpty) continue;
        ok.sort((a, b) =>
            _daysFromToday(b, today).compareTo(_daysFromToday(a, today)));
        // 今日に最も近い（過去方向で最大の daysFromToday）
        raws.add(_Raw(ok.first, ExtractionConfidence.medium, 'short-year'));
      }
    }

    // MM/DDのみ: 同一行に時刻がある場合だけ。年は今日を超えない直近年。
    if (raws.isEmpty && hasTime) {
      for (final m in _reMonthDay.allMatches(text)) {
        final mo = int.parse(m.namedGroup('m')!);
        final da = int.parse(m.namedGroup('d')!);
        var d = _valid(today.year, mo, da);
        if (d != null && d.compareTo(tomorrow) > 0) {
          d = _valid(today.year - 1, mo, da);
        }
        if (d != null && acceptable(d)) {
          raws.add(_Raw(d, ExtractionConfidence.low, 'month-day'));
        }
      }
    }

    for (final raw in raws) {
      if (!acceptable(raw.date)) continue;
      var score = 0.0;
      if (hasTime) score += 50;
      score += (1 - row.centerY) * 20;
      if (_reIssueCue.hasMatch(text)) score += 15;
      // フル日付でも時刻非同居なら medium に降格（時刻同居が最強の取引手がかり）
      final conf =
          (raw.confidence == ExtractionConfidence.high && !hasTime)
              ? ExtractionConfidence.medium
              : raw.confidence;
      found.add((
        score,
        order++,
        DateCandidate(
            date: raw.date, confidence: conf, sourceText: text, reason: raw.reason)
      ));
    }
  }

  found.sort((a, b) {
    final s = b.$1.compareTo(a.$1);
    return s != 0 ? s : a.$2.compareTo(b.$2);
  });

  final candidates = <DateCandidate>[];
  for (final f in found) {
    if (candidates.any((c) => c.date == f.$3.date)) continue;
    if (candidates.length >= 5) break;
    candidates.add(f.$3);
  }

  final best = candidates.isNotEmpty
      ? candidates.first
      : DateCandidate(
          date: today,
          confidence: ExtractionConfidence.low,
          sourceText: '',
          reason: 'default-today');

  return DateExtraction(best: best, candidates: candidates);
}
```

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/date_test.dart` → PASS（15ケース）

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/receipt/date.dart test/receipt/date_test.dart
git commit -m "feat: receipt date extraction (wareki, era inference, validation, selection)"
```

---

## Task 7: ReceiptParser 統括＋合成フルレシートのエンドツーエンド

**Files:**
- Create: `lib/domain/services/receipt/receipt_parser.dart`
- Test: `test/receipt/receipt_parser_test.dart`

**Interfaces:**
- Consumes: 全前段
- Produces:
  - `class ParsedReceipt { final AmountCandidate? total; final List<AmountCandidate> totalCandidates; final DateCandidate date; final List<DateCandidate> dateCandidates; }`（dateは常に非null＝今日既定があるため）
  - `class ReceiptParser { ReceiptParser({CivilDate Function()? today}); ParsedReceipt parse(List<OcrBlock> blocks); }` — パイプライン: 各ブロックtextを`normalizeOcrText` → `groupRows` → `extractTotal` / `extractDate`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/receipt/receipt_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/domain/services/receipt/total.dart'
    show ExtractionConfidence;
import 'package:kakeibo_app/domain/money/civil_date.dart';

const fixedToday = CivilDate(2026, 7, 3);

ReceiptParser parser() => ReceiptParser(today: () => fixedToday);

/// 1行=1ブロックの合成レシート（正規化はparserがやる＝生テキストで渡す）
List<OcrBlock> lines(List<String> texts) => [
      for (final (i, t) in texts.indexed)
        OcrBlock(
          text: t,
          rect: OcrRect(0.05, 0.05 + i * 0.045, 0.9, 0.03),
          confidence: 0.9,
        ),
    ];

void main() {
  test('supermarket receipt end-to-end (raw full-width input)', () {
    final r = parser().parse(lines([
      'スーパーマルエツ 渋谷店',
      '〒150-0002 東京都渋谷区',
      'TEL 03-1234-5678',
      '２０２６年６月３０日(火) １８：４５',
      'レジ001 No.0123 責任者012',
      'ネギ ＠98 ×2 196',
      '牛乳 258',
      '小計 ３，５００',
      '消費税(10%) ３５０',
      '合計 ￥３，８５０',
      'お預り ￥５，０００',
      'お釣り ￥１，１５０',
      'ポイント残高 12,340P',
      '登録番号 T1234567890123',
    ]));
    expect(r.total!.yen, 3850);
    expect(r.total!.confidence, ExtractionConfidence.high);
    expect(r.date.date, const CivilDate(2026, 6, 30));
    expect(r.date.confidence, ExtractionConfidence.high);
  });

  test('convenience store with wareki thermal date', () {
    final r = parser().parse(lines([
      'セブン-イレブン',
      'R8.6.30 09:12 レジ2',
      'おにぎり 150円',
      'お茶 130円',
      '合計 ¥280',
      '現金 ¥300',
      'おつり ¥20',
    ]));
    expect(r.total!.yen, 280);
    expect(r.date.date, const CivilDate(2026, 6, 30));
  });

  test('drugstore with points and campaign dates', () {
    final r = parser().parse(lines([
      'マツモトキヨシ',
      '2026/06/28 20:01',
      'シャンプー 880',
      '合計 ¥880',
      'ポイント有効期限 2027/03/31',
      'ポイント残高 5,000',
    ]));
    expect(r.total!.yen, 880);
    expect(r.date.date, const CivilDate(2026, 6, 28));
  });

  test('OCR dropped the 合計 keyword -> fallback still lands on the total', () {
    final r = parser().parse(lines([
      '2026/07/01 12:00',
      'コーヒー 480',
      'ケーキ 520',
      '1,100', // 合計ラベルがOCR落ち（税込1100）
      'お預り 2,000',
      'おつり 900',
    ]));
    expect(r.total!.yen, 1100);
    expect(r.total!.confidence, ExtractionConfidence.medium);
    expect(r.date.date, const CivilDate(2026, 7, 1));
  });

  test('label and amount as separate blocks on the same physical row', () {
    final blocks = [
      const OcrBlock(text: '合計', rect: OcrRect(0.05, 0.60, 0.2, 0.03), confidence: 0.95),
      const OcrBlock(text: '¥3,850', rect: OcrRect(0.65, 0.601, 0.3, 0.03), confidence: 0.95),
      const OcrBlock(text: '2026/07/01', rect: OcrRect(0.05, 0.10, 0.4, 0.03), confidence: 0.95),
    ];
    final r = parser().parse(blocks);
    expect(r.total!.yen, 3850);
  });

  test('empty input -> null total, today default date, empty candidates', () {
    final r = parser().parse(const []);
    expect(r.total, isNull);
    expect(r.totalCandidates, isEmpty);
    expect(r.date.date, fixedToday);
    expect(r.date.reason, 'default-today');
  });

  test('candidates are exposed for the confirm-screen switch UI', () {
    final r = parser().parse(lines(['小計 3,500', '合計 3,850']));
    expect(r.totalCandidates.first.yen, 3850);
    expect(r.totalCandidates.length, greaterThanOrEqualTo(1));
  });
}
```

- [ ] **Step 2: 赤を確認** — Run: `flutter test test/receipt/receipt_parser_test.dart` → FAIL

- [ ] **Step 3: 実装**

Create `lib/domain/services/receipt/receipt_parser.dart`:
```dart
import '../../money/civil_date.dart';
import '../ocr/ocr_types.dart';
import 'date.dart';
import 'normalize.dart';
import 'rows.dart';
import 'total.dart';

export 'date.dart' show DateCandidate, DateExtraction;
export 'total.dart' show AmountCandidate, ExtractionConfidence, TotalExtraction;

/// レシートOCRの最終出力。確認画面はこの候補リストで切替UIを出す。
class ParsedReceipt {
  final AmountCandidate? total;
  final List<AmountCandidate> totalCandidates;
  final DateCandidate date; // 常に非null（見つからなければ今日・low）
  final List<DateCandidate> dateCandidates;
  const ParsedReceipt({
    required this.total,
    required this.totalCandidates,
    required this.date,
    required this.dateCandidates,
  });
}

/// 純Dartのレシートパーサ（spec §7）。
/// パイプライン: 正規化 → 行復元 → 合計抽出 / 日付抽出。
/// 時計は注入して全テストを決定的にする。
class ReceiptParser {
  final CivilDate Function() _today;

  ReceiptParser({CivilDate Function()? today})
      : _today = today ?? (() => CivilDate.fromDateTime(DateTime.now()));

  ParsedReceipt parse(List<OcrBlock> blocks) {
    final normalized = [
      for (final b in blocks)
        OcrBlock(
          text: normalizeOcrText(b.text),
          rect: b.rect,
          confidence: b.confidence,
        ),
    ];
    final rows = groupRows(normalized);
    final total = extractTotal(rows);
    final date = extractDate(rows, _today());
    return ParsedReceipt(
      total: total.best,
      totalCandidates: total.candidates,
      date: date.best!,
      dateCandidates: date.candidates,
    );
  }
}
```

- [ ] **Step 4: 緑を確認** — Run: `flutter test test/receipt/receipt_parser_test.dart` → PASS（7ケース）

- [ ] **Step 5: コミット**
```bash
git add lib/domain/services/receipt/receipt_parser.dart test/receipt/receipt_parser_test.dart
git commit -m "feat: ReceiptParser orchestration with candidate lists and injected clock"
```

---

## Task 8: JSONフィクスチャ形式（Mac橋渡し互換）＋決定的摂動ロバストネス

**Files:**
- Create: `test/support/receipt_fixtures.dart`
- Create: `test/fixtures/receipts/sample_supermarket.json`
- Test: `test/receipt/perturbation_test.dart`

**Interfaces:**
- Produces:
  - **JSONフィクスチャ形式**（将来Mac実機のApple Vision出力を録るブリッジツールが吐く形式と同一）:
    ```json
    {
      "name": "sample-supermarket",
      "blocks": [
        {"text": "合計 ¥3,850", "x": 0.05, "y": 0.60, "w": 0.9, "h": 0.03, "confidence": 0.97}
      ],
      "expected": {"totalYen": 3850, "date": "2026-06-30"}
    }
    ```
  - `class ReceiptFixture { final String name; final List<OcrBlock> blocks; final int? expectedTotalYen; final CivilDate? expectedDate; }`
  - `ReceiptFixture loadFixture(String path)`（`dart:io`＋`jsonDecode`）
  - **決定的摂動**（乱数なしの明示変換。`List<OcrBlock> -> List<OcrBlock>`）:
    - `dropCurrencyMarks` — 全ブロックから `¥` を除去（カンマアンカーで生き残るか）
    - `dropTotalKeyword` — `合計` を含むブロックからその語を除去（フォールバック経路の検証）
    - `confuseZeros` — 金額らしきトークンの `0` を `O` に置換（修復経路の検証）
    - `mergeRowBlocks` — 各物理行の複数ブロックを1ブロックに結合（結合レイアウト耐性）

- [ ] **Step 1: フィクスチャJSONを作成**

Create `test/fixtures/receipts/sample_supermarket.json`:
```json
{
  "name": "sample-supermarket",
  "blocks": [
    {"text": "スーパーマルエツ 渋谷店", "x": 0.05, "y": 0.05, "w": 0.9, "h": 0.03, "confidence": 0.98},
    {"text": "TEL 03-1234-5678", "x": 0.05, "y": 0.10, "w": 0.9, "h": 0.03, "confidence": 0.95},
    {"text": "2026年6月30日(火) 18:45", "x": 0.05, "y": 0.15, "w": 0.9, "h": 0.03, "confidence": 0.96},
    {"text": "ネギ", "x": 0.05, "y": 0.25, "w": 0.3, "h": 0.03, "confidence": 0.9},
    {"text": "196", "x": 0.70, "y": 0.25, "w": 0.25, "h": 0.03, "confidence": 0.9},
    {"text": "牛乳", "x": 0.05, "y": 0.30, "w": 0.3, "h": 0.03, "confidence": 0.9},
    {"text": "258", "x": 0.70, "y": 0.30, "w": 0.25, "h": 0.03, "confidence": 0.9},
    {"text": "小計", "x": 0.05, "y": 0.45, "w": 0.3, "h": 0.03, "confidence": 0.95},
    {"text": "3,500", "x": 0.65, "y": 0.45, "w": 0.3, "h": 0.03, "confidence": 0.95},
    {"text": "消費税(10%)", "x": 0.05, "y": 0.50, "w": 0.35, "h": 0.03, "confidence": 0.95},
    {"text": "350", "x": 0.70, "y": 0.50, "w": 0.25, "h": 0.03, "confidence": 0.95},
    {"text": "合計", "x": 0.05, "y": 0.55, "w": 0.3, "h": 0.03, "confidence": 0.97},
    {"text": "¥3,850", "x": 0.65, "y": 0.55, "w": 0.3, "h": 0.03, "confidence": 0.97},
    {"text": "お預り", "x": 0.05, "y": 0.60, "w": 0.3, "h": 0.03, "confidence": 0.95},
    {"text": "¥5,000", "x": 0.65, "y": 0.60, "w": 0.3, "h": 0.03, "confidence": 0.95},
    {"text": "お釣り", "x": 0.05, "y": 0.65, "w": 0.3, "h": 0.03, "confidence": 0.95},
    {"text": "¥1,150", "x": 0.65, "y": 0.65, "w": 0.3, "h": 0.03, "confidence": 0.95},
    {"text": "ポイント残高 12,340P", "x": 0.05, "y": 0.72, "w": 0.9, "h": 0.03, "confidence": 0.9},
    {"text": "登録番号 T1234567890123", "x": 0.05, "y": 0.78, "w": 0.9, "h": 0.03, "confidence": 0.9}
  ],
  "expected": {"totalYen": 3850, "date": "2026-06-30"}
}
```

- [ ] **Step 2: 失敗するテストを書く**

Create `test/receipt/perturbation_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import '../support/receipt_fixtures.dart';

const fixedToday = CivilDate(2026, 7, 3);
ReceiptParser parser() => ReceiptParser(today: () => fixedToday);

void main() {
  late ReceiptFixture fx;

  setUpAll(() {
    fx = loadFixture('test/fixtures/receipts/sample_supermarket.json');
  });

  test('pristine fixture parses to expected total and date', () {
    final r = parser().parse(fx.blocks);
    expect(r.total!.yen, fx.expectedTotalYen);
    expect(r.date.date, fx.expectedDate);
  });

  test('survives dropped currency marks (comma anchor takes over)', () {
    final r = parser().parse(dropCurrencyMarks(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
  });

  test('survives dropped 合計 keyword via fallback / cash identity', () {
    final r = parser().parse(dropTotalKeyword(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
  });

  test('survives 0->O digit confusion via repair', () {
    final r = parser().parse(confuseZeros(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
  });

  test('survives merged row blocks (label+amount in one block)', () {
    final r = parser().parse(mergeRowBlocks(fx.blocks));
    expect(r.total!.yen, fx.expectedTotalYen);
    expect(r.date.date, fx.expectedDate);
  });
}
```

- [ ] **Step 3: 赤を確認** — Run: `flutter test test/receipt/perturbation_test.dart` → FAIL（loader/摂動未定義）

- [ ] **Step 4: loaderと摂動を実装**

Create `test/support/receipt_fixtures.dart`:
```dart
import 'dart:convert';
import 'dart:io';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

/// Mac実機ブリッジ（後続Phase）が吐くのと同一のJSON形式のフィクスチャ。
class ReceiptFixture {
  final String name;
  final List<OcrBlock> blocks;
  final int? expectedTotalYen;
  final CivilDate? expectedDate;
  const ReceiptFixture({
    required this.name,
    required this.blocks,
    required this.expectedTotalYen,
    required this.expectedDate,
  });
}

ReceiptFixture loadFixture(String path) {
  final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final blocksRaw = root['blocks'] as List<dynamic>;
  final expected = root['expected'] as Map<String, dynamic>?;
  return ReceiptFixture(
    name: root['name'] as String,
    blocks: [
      for (final b in blocksRaw.cast<Map<String, dynamic>>())
        OcrBlock(
          text: b['text'] as String,
          rect: OcrRect(
            (b['x'] as num).toDouble(),
            (b['y'] as num).toDouble(),
            (b['w'] as num).toDouble(),
            (b['h'] as num).toDouble(),
          ),
          confidence: (b['confidence'] as num).toDouble(),
        ),
    ],
    expectedTotalYen: expected?['totalYen'] as int?,
    expectedDate: expected?['date'] == null
        ? null
        : CivilDate.parse(expected!['date'] as String),
  );
}

// --- 決定的摂動（乱数なし） ---

List<OcrBlock> _mapText(List<OcrBlock> blocks, String Function(String) f) => [
      for (final b in blocks)
        OcrBlock(text: f(b.text), rect: b.rect, confidence: b.confidence),
    ];

/// ¥/￥ を全て落とす（OCRが通貨記号を拾えなかったケース）
List<OcrBlock> dropCurrencyMarks(List<OcrBlock> blocks) =>
    _mapText(blocks, (t) => t.replaceAll(RegExp('[¥￥]'), ''));

/// 「合計」キーワードを落とす（太字大フォントのOCR落ち）
List<OcrBlock> dropTotalKeyword(List<OcrBlock> blocks) =>
    _mapText(blocks, (t) => t.replaceAll('合計', ''));

/// 金額中の 0 を O に誤読させる
List<OcrBlock> confuseZeros(List<OcrBlock> blocks) =>
    _mapText(blocks, (t) => t.replaceAllMapped(
        RegExp(r'(?<=\d)0|0(?=\d)'), (m) => 'O'));

/// 各物理行の複数ブロックを1ブロックに結合（結合レイアウト）
List<OcrBlock> mergeRowBlocks(List<OcrBlock> blocks) {
  final rows = groupRows(blocks);
  return [
    for (final row in rows)
      OcrBlock(
        text: row.blocks.map((b) => b.text).join(' '),
        rect: OcrRect(
          row.blocks.first.rect.x,
          row.top,
          row.blocks.last.rect.right - row.blocks.first.rect.x,
          row.bottom - row.top,
        ),
        confidence: row.blocks
                .map((b) => b.confidence)
                .reduce((a, c) => a + c) /
            row.blocks.length,
      ),
  ];
}
```

- [ ] **Step 5: 緑を確認** — Run: `flutter test test/receipt/perturbation_test.dart` → PASS（5ケース）

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
git commit -m "feat: JSON fixture format (Mac-bridge compatible) and deterministic perturbation robustness"
```

---

## Self-Review

**1. Spec coverage（spec §7）:**
- §7.1 正準TextBlock空間（左上原点・正規化・行粒度・confidence）＋OcrService抽象＋Fake → Task 1 ✅（規約はテストで固定）
- §7.2 金額抽出（通貨手がかり必須のtier、ブラックリスト行、数字正規化、ラベル厳密ランク、同一行近傍、フォールバック除外拡張、クロス検証、割引）→ Task 2/4/5 ✅
- §7.3 日付抽出（各形式regex、和暦変換、時代推定、検証、取引手がかり選択、年欠落、今日既定）→ Task 6 ✅
- §7.4 1レシート=1取引の限界 → パーサ出力はtotal/dateのみ（明細分割なし）。UI（後続Phase）が「保存して続けて入力」を提供 ✅
- §7.5 確信度tier（離散・説明可能）＋候補切替 → Task 5/6/7（`reason`つき候補リスト）✅
- §8.2 フィクスチャ橋渡し（正準TextBlock境界で記録・摂動レイヤ）→ Task 8 ✅（JSON形式を今回確定、Macブリッジは後続Phaseで同形式を吐く）
- §7.6 画像ライフサイクル → **範囲外**（カメラ/破棄はUIフェーズ・iOSフェーズ）

**2. Placeholder scan:** 全ステップに実コード。TBDなし。

**3. Type consistency:**
- `OcrBlock/OcrRect`（T1）→ rows/amounts/parser/fixturesで一貫 ✅
- `ExtractionConfidence`はtotal.dartで定義しdate/parserがimport（重複定義なし）✅
- `AmountCandidate`/`DateCandidate`/`ParsedReceipt`のフィールドはT5/T6/T7で一致 ✅
- `CivilDate.isValid`/`parse`/`compareTo`/`fromDateTime`はPhase 1実装済みAPI ✅

**注意（実行者向け）:** ヒューリスティクスは合成フィクスチャで調整したもの。**実レシートフィクスチャ（Mac収集）で必ず再調整する**前提であり、本Phaseの完了＝「実データで完成」ではない（spec §13の宿題は残る）。regexのlookbehind（`(?<!...)`）と named groups はDart 3で対応済みだが、実行時に想定と違えばテストが赤で教えてくれる構造にしてある。
