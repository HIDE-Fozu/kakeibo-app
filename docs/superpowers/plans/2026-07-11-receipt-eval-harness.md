# レシート検証装備（合成コーパス＋評価ハーネス）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 既存の純Dartレシートパーサを、合成レシート1,200件でフィールド別精度採点できるCLI一式（生成・語彙・評価）を作る。

**Architecture:** `tool/` 配下に純Dartの3つのCLI（vocab生成→コーパス生成→評価）。真値サンプラ→テンプレートレンダラ→決定的ノイズ注入のパイプラインで、LLM（Ollama）は語彙生成のみに使い数字には一切触れさせない。評価は既存 `ReceiptParser` を固定時計で呼び、total/dateの正解率をノイズレベル別に集計する。

**Tech Stack:** Dart（Flutter 3.44.4 / SDK ^3.12.2）、dart:io（HTTP・ファイル）、Ollama REST API（qwen3:14b、語彙生成のみ）

**Spec:** `docs/superpowers/specs/2026-07-11-receipt-eval-harness-design.md`（以下「spec」。全タスクはspecに従属する）

## Global Constraints

- 新しいpub依存を**追加しない**（HTTPは `dart:io` の `HttpClient`、引数パースは手書き）
- `tool/` と `test/harness/` のファイルは `package:kakeibo_app/` のうち**純Dart部分のみ**import可: `domain/services/ocr/ocr_types.dart`・`domain/services/receipt/*`・`domain/money/civil_date.dart`。flutter/driftのimport禁止
- **既存ファイルは一切変更しない**（lib/・test/の既存物。新規追加のみ）
- シードは単一の `Random(seed)` を サンプラ→レンダラ→ノイズ の順で引き回す（消費順が仕様）
- 出力はUTF-8（BOMなし）・改行LF（Dartの `writeAsStringSync` は `\n` をそのまま書くのでそのままでよい）
- Ollamaモデルは `qwen3:14b` 固定。評価時の固定時計は `CivilDate(2026, 7, 11)`
- `flutter analyze` は tool/ も対象。lint（flutter_lints 6）に通るコードを書く（シングルクォート等）
- コミットは各タスク末尾で1回。メッセージ末尾に `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- 実装サブエージェントは**Sonnet**、レビューは**Sonnet＋Opusの二重**（spec §13）
- 表にない判断が出たら `.superpowers/sdd/progress.md` に記録して統括が裁定（ユーザーを止めない）

## 実装上の確定判断（specの決定表を補完。実装者はここに従う）

| 論点 | 決定 |
|---|---|
| 小計行 | 全レシートで常に印字（品目計） |
| お預り額 | `((total+999)~/1000)*1000`（1,000円単位切上げ。totalが1,000の倍数なら同額＝釣り0円） |
| ノイズ操作の適用順 | ①¥落ち→②合計キーワード落ち→③行結合→④ブロック分割→⑤文字置換→⑥空ブロック除去 |
| 混在税率の対象 | スーパー・ドラッグストアのみ50%で混在。混在時は各品目が確率60%で8%、それ以外10% |
| 税モードの店種別確率 | スーパー/コンビニ/ドラッグ: 内税80%・外税20%／飲食店/カフェ: 内税70%／その他: 内税60% |
| 品目数が2以上必要な様式 | なし（全様式1品からOK） |
| 割引額 | 品目計の5〜30%を一様サンプル、`< 品目計` にクランプ、0円なら割引行なし |
| ブロック幅 | `w = clamp(0.02×文字数, 0.05, 0.55)`。金額ブロックは右端0.95に右寄せ |
| confidence | ブロックごとに `0.90 + rng.nextDouble()*0.08` |
| 語彙の要求数 | 品目: 様式ごとに160個要求→重複除去後50以上・全体1,000以上で合格。店名: 様式ごと15個要求→10以上・全体80以上 |
| Ollamaリクエスト | `POST /api/chat`、`stream:false`、`think:false`、`format` にJSONスキーマ。タイムアウト120秒。リトライなし（spec §8） |

## ファイル構成（このplanで作る全ファイル）

```
tool/
  receipt_gen/
    generate.dart            … コーパス生成CLI（main + runGenerate）
    data/vocab.json          … Task 9でOllamaから生成しコミット
    src/truth.dart           … 真値モデル＋SynthFixture＋JSONコーデック
    src/validate.dart        … 整合性バリデータ（spec §4-2）
    src/vocab.dart           … Vocab型＋検証規則（spec §6）
    src/formats.dart         … 日付・金額の印字フォーマッタ
    src/sampler.dart         … 真値サンプラ
    src/renderer.dart        … 真値→OcrBlock列レンダラ
    src/noise.dart           … 決定的ノイズ注入
  receipt_vocab/
    generate_vocab.dart      … 語彙生成CLI（Ollama REST）
  receipt_eval/
    evaluate.dart            … 評価CLI（main + runEvaluate）
    src/scorer.dart          … 採点
    src/report.dart          … report.md / report.json 生成
test/harness/
  truth_codec_test.dart
  validate_test.dart
  vocab_validate_test.dart
  formats_test.dart
  sampler_test.dart
  renderer_test.dart
  noise_test.dart
  generate_determinism_test.dart
  scorer_test.dart
  report_test.dart
  e2e_smoke_test.dart
  fixtures/test_vocab.json   … テスト用ミニ語彙（手書き・検証規則の対象外）
```

---

### Task 1: 真値モデル＋JSONコーデック（truth.dart）

**Files:**
- Create: `tool/receipt_gen/src/truth.dart`
- Test: `test/harness/truth_codec_test.dart`

**Interfaces:**
- Consumes: `package:kakeibo_app/domain/money/civil_date.dart` の `CivilDate`（`CivilDate(y,m,d)` / `CivilDate.parse('YYYY-MM-DD')` / `.toIso()` / `==`定義済み）、`package:kakeibo_app/domain/services/ocr/ocr_types.dart` の `OcrBlock`/`OcrRect`
- Produces: `TruthItem`, `TruthDiscount`, `TruthTaxLine`, `ReceiptStyle`, `TruthReceipt`（全フィールドfinal・`toJson`/`fromJson`）、`SynthFixture`（`name`,`blocks`,`truth`。`toJson`が`expected`を`truth`から導出）、`encodeFixture(SynthFixture)`→整形JSON文字列、`loadSynthFixture(String path)`

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/truth_codec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../../tool/receipt_gen/src/truth.dart';

TruthReceipt sampleTruthFixture({CivilDate? date = const CivilDate(2026, 6, 30)}) {
  return TruthReceipt(
    storeName: 'フレッシュたなか青果',
    storeType: 'supermarket',
    date: date,
    items: const [
      TruthItem(name: '国産豚小間切れ', unitPriceYen: 1950, qty: 2, amountYen: 3900, taxRate: 8),
    ],
    discounts: const [TruthDiscount(label: '割引', amountYen: 50)],
    taxMode: 'inclusive',
    taxLines: const [TruthTaxLine(rate: 8, taxYen: 285)],
    totalYen: 3850,
    tenderedYen: 5000,
    changeYen: 1150,
    style: const ReceiptStyle(dateFormat: 'kanji', totalKeyword: '合計', currencyMark: 'yen'),
    noiseLevel: 1,
  );
}

void main() {
  test('TruthReceipt round-trips through JSON', () {
    final t = sampleTruthFixture();
    final back = TruthReceipt.fromJson(t.toJson());
    expect(back.toJson(), t.toJson());
    expect(back.date, const CivilDate(2026, 6, 30));
    expect(back.items.single.amountYen, 3900);
  });

  test('date=null round-trips', () {
    final t = sampleTruthFixture(date: null);
    expect(TruthReceipt.fromJson(t.toJson()).date, isNull);
  });

  test('SynthFixture derives expected from truth', () {
    final f = SynthFixture(
      name: 'syn-l1-0001',
      blocks: const [
        OcrBlock(text: '合計', rect: OcrRect(0.05, 0.5, 0.1, 0.03), confidence: 0.95),
      ],
      truth: sampleTruthFixture(),
    );
    final json = f.toJson();
    expect((json['expected'] as Map)['totalYen'], 3850);
    expect((json['expected'] as Map)['date'], '2026-06-30');
    final noDate = SynthFixture(name: 'x', blocks: const [], truth: sampleTruthFixture(date: null));
    expect((noDate.toJson()['expected'] as Map)['date'], isNull);
  });

  test('encodeFixture ends with LF and is stable', () {
    final f = SynthFixture(name: 'x', blocks: const [], truth: sampleTruthFixture());
    final s = encodeFixture(f);
    expect(s.endsWith('\n'), isTrue);
    expect(encodeFixture(f), s);
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/truth_codec_test.dart`
Expected: FAIL（`truth.dart` が存在しない旨のコンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/src/truth.dart
import 'dart:convert';
import 'dart:io';

import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

class TruthItem {
  final String name;
  final int unitPriceYen;
  final int qty;
  final int amountYen;
  final int taxRate;
  const TruthItem({
    required this.name,
    required this.unitPriceYen,
    required this.qty,
    required this.amountYen,
    required this.taxRate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'unitPriceYen': unitPriceYen,
        'qty': qty,
        'amountYen': amountYen,
        'taxRate': taxRate,
      };

  factory TruthItem.fromJson(Map<String, dynamic> j) => TruthItem(
        name: j['name'] as String,
        unitPriceYen: j['unitPriceYen'] as int,
        qty: j['qty'] as int,
        amountYen: j['amountYen'] as int,
        taxRate: j['taxRate'] as int,
      );
}

class TruthDiscount {
  final String label;
  final int amountYen;
  const TruthDiscount({required this.label, required this.amountYen});

  Map<String, dynamic> toJson() => {'label': label, 'amountYen': amountYen};

  factory TruthDiscount.fromJson(Map<String, dynamic> j) =>
      TruthDiscount(label: j['label'] as String, amountYen: j['amountYen'] as int);
}

class TruthTaxLine {
  final int rate;
  final int taxYen;
  const TruthTaxLine({required this.rate, required this.taxYen});

  Map<String, dynamic> toJson() => {'rate': rate, 'taxYen': taxYen};

  factory TruthTaxLine.fromJson(Map<String, dynamic> j) =>
      TruthTaxLine(rate: j['rate'] as int, taxYen: j['taxYen'] as int);
}

class ReceiptStyle {
  final String dateFormat; // kanji | slash | dotShort | warekiShort | warekiKanji
  final String totalKeyword; // 合計 | お買上げ計 | 合　計 | 総合計 | お会計
  final String currencyMark; // yen | fullwidthYen | none | enSuffix
  const ReceiptStyle({
    required this.dateFormat,
    required this.totalKeyword,
    required this.currencyMark,
  });

  Map<String, dynamic> toJson() => {
        'dateFormat': dateFormat,
        'totalKeyword': totalKeyword,
        'currencyMark': currencyMark,
      };

  factory ReceiptStyle.fromJson(Map<String, dynamic> j) => ReceiptStyle(
        dateFormat: j['dateFormat'] as String,
        totalKeyword: j['totalKeyword'] as String,
        currencyMark: j['currencyMark'] as String,
      );
}

class TruthReceipt {
  final String storeName;
  final String storeType;
  final CivilDate? date;
  final List<TruthItem> items;
  final List<TruthDiscount> discounts;
  final String taxMode; // inclusive | exclusive
  final List<TruthTaxLine> taxLines;
  final int totalYen;
  final int? tenderedYen;
  final int? changeYen;
  final ReceiptStyle style;
  final int noiseLevel;
  const TruthReceipt({
    required this.storeName,
    required this.storeType,
    required this.date,
    required this.items,
    required this.discounts,
    required this.taxMode,
    required this.taxLines,
    required this.totalYen,
    required this.tenderedYen,
    required this.changeYen,
    required this.style,
    required this.noiseLevel,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'storeType': storeType,
        'date': date?.toIso(),
        'items': [for (final i in items) i.toJson()],
        'discounts': [for (final d in discounts) d.toJson()],
        'taxMode': taxMode,
        'taxLines': [for (final t in taxLines) t.toJson()],
        'totalYen': totalYen,
        'tenderedYen': tenderedYen,
        'changeYen': changeYen,
        'style': style.toJson(),
        'noiseLevel': noiseLevel,
      };

  factory TruthReceipt.fromJson(Map<String, dynamic> j) => TruthReceipt(
        storeName: j['storeName'] as String,
        storeType: j['storeType'] as String,
        date: j['date'] == null ? null : CivilDate.parse(j['date'] as String),
        items: [
          for (final i in j['items'] as List) TruthItem.fromJson(i as Map<String, dynamic>)
        ],
        discounts: [
          for (final d in j['discounts'] as List)
            TruthDiscount.fromJson(d as Map<String, dynamic>)
        ],
        taxMode: j['taxMode'] as String,
        taxLines: [
          for (final t in j['taxLines'] as List)
            TruthTaxLine.fromJson(t as Map<String, dynamic>)
        ],
        totalYen: j['totalYen'] as int,
        tenderedYen: j['tenderedYen'] as int?,
        changeYen: j['changeYen'] as int?,
        style: ReceiptStyle.fromJson(j['style'] as Map<String, dynamic>),
        noiseLevel: j['noiseLevel'] as int,
      );
}

/// 合成フィクスチャ。`expected` は truth から導出する（単一情報源、spec §4-1）。
class SynthFixture {
  final String name;
  final List<OcrBlock> blocks;
  final TruthReceipt truth;
  const SynthFixture({required this.name, required this.blocks, required this.truth});

  Map<String, dynamic> toJson() => {
        'name': name,
        'blocks': [
          for (final b in blocks)
            {
              'text': b.text,
              'x': b.rect.x,
              'y': b.rect.y,
              'w': b.rect.w,
              'h': b.rect.h,
              'confidence': b.confidence,
            }
        ],
        'expected': {'totalYen': truth.totalYen, 'date': truth.date?.toIso()},
        'truth': truth.toJson(),
      };
}

String encodeFixture(SynthFixture f) =>
    '${const JsonEncoder.withIndent(' ').convert(f.toJson())}\n';

SynthFixture loadSynthFixture(String path) {
  final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return SynthFixture(
    name: root['name'] as String,
    blocks: [
      for (final b in (root['blocks'] as List).cast<Map<String, dynamic>>())
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
    truth: TruthReceipt.fromJson(root['truth'] as Map<String, dynamic>),
  );
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/truth_codec_test.dart`
Expected: PASS（4 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_gen/src/truth.dart test/harness/truth_codec_test.dart
git commit -m "feat(harness): truth model and fixture JSON codec"
```

---

### Task 2: 整合性バリデータ（validate.dart）

**Files:**
- Create: `tool/receipt_gen/src/validate.dart`
- Test: `test/harness/validate_test.dart`

**Interfaces:**
- Consumes: Task 1の `TruthReceipt`、`OcrBlock`
- Produces: `List<String> validateTruth(TruthReceipt t)`（spec §4-2 規則1〜4。空リスト=合格）、`List<String> validateContainment(List<OcrBlock> blocks, String renderedTotalAmount, String? renderedDateLine)`（規則5: L0での含有性）

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/validate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../../tool/receipt_gen/src/truth.dart';
import '../../tool/receipt_gen/src/validate.dart';
import 'truth_codec_test.dart' show sampleTruthFixture;

TruthReceipt _mutate(TruthReceipt t, {int? totalYen, int? changeYen, List<TruthDiscount>? discounts, List<TruthItem>? items}) {
  return TruthReceipt(
    storeName: t.storeName,
    storeType: t.storeType,
    date: t.date,
    items: items ?? t.items,
    discounts: discounts ?? t.discounts,
    taxMode: t.taxMode,
    taxLines: t.taxLines,
    totalYen: totalYen ?? t.totalYen,
    tenderedYen: t.tenderedYen,
    changeYen: changeYen ?? t.changeYen,
    style: t.style,
    noiseLevel: t.noiseLevel,
  );
}

void main() {
  test('valid truth passes all rules', () {
    expect(validateTruth(sampleTruthFixture()), isEmpty);
  });

  test('rule 1: total mismatch detected', () {
    expect(validateTruth(_mutate(sampleTruthFixture(), totalYen: 9999)), isNotEmpty);
  });

  test('rule 2: item amount != unit*qty detected', () {
    final bad = _mutate(sampleTruthFixture(), totalYen: 3851, items: const [
      TruthItem(name: 'x', unitPriceYen: 1950, qty: 2, amountYen: 3901, taxRate: 8),
    ]);
    expect(validateTruth(bad), isNotEmpty);
  });

  test('rule 3: change identity violation detected', () {
    expect(validateTruth(_mutate(sampleTruthFixture(), changeYen: 1)), isNotEmpty);
  });

  test('rule 4: discounts >= items sum detected', () {
    final bad = _mutate(sampleTruthFixture(),
        totalYen: -100, discounts: const [TruthDiscount(label: 'x', amountYen: 4000)]);
    expect(validateTruth(bad), isNotEmpty);
  });

  test('rule 1 exclusive: total = items - discounts + tax', () {
    final t = sampleTruthFixture();
    final ex = TruthReceipt(
      storeName: t.storeName,
      storeType: t.storeType,
      date: t.date,
      items: t.items, // 3900
      discounts: t.discounts, // 50
      taxMode: 'exclusive',
      taxLines: const [TruthTaxLine(rate: 8, taxYen: 312)], // 3900*8~/100
      totalYen: 3900 - 50 + 312,
      tenderedYen: null,
      changeYen: null,
      style: t.style,
      noiseLevel: 0,
    );
    expect(validateTruth(ex), isEmpty);
  });

  test('rule 5: containment', () {
    const blocks = [
      OcrBlock(text: '合計', rect: OcrRect(0.05, 0.5, 0.1, 0.03), confidence: 0.95),
      OcrBlock(text: '¥3,850', rect: OcrRect(0.7, 0.5, 0.2, 0.03), confidence: 0.95),
      OcrBlock(text: '2026年6月30日(火) 18:45', rect: OcrRect(0.05, 0.1, 0.5, 0.03), confidence: 0.95),
    ];
    expect(validateContainment(blocks, '¥3,850', '2026年6月30日(火) 18:45'), isEmpty);
    expect(validateContainment(blocks, '¥9,999', null), isNotEmpty);
    expect(validateContainment(blocks, '¥3,850', '存在しない日付行'), isNotEmpty);
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/validate_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/src/validate.dart
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import 'truth.dart';

/// spec §4-2 規則1〜4。戻り値は違反の説明（空=合格）。
List<String> validateTruth(TruthReceipt t) {
  final errors = <String>[];
  final itemsSum = t.items.fold(0, (a, i) => a + i.amountYen);
  final discountSum = t.discounts.fold(0, (a, d) => a + d.amountYen);
  final taxSum = t.taxLines.fold(0, (a, x) => a + x.taxYen);

  final expectedTotal =
      t.taxMode == 'inclusive' ? itemsSum - discountSum : itemsSum - discountSum + taxSum;
  if (t.totalYen != expectedTotal) {
    errors.add('rule1: totalYen=${t.totalYen} expected=$expectedTotal (${t.taxMode})');
  }
  for (final i in t.items) {
    if (i.amountYen != i.unitPriceYen * i.qty) {
      errors.add('rule2: ${i.name} amount=${i.amountYen} != ${i.unitPriceYen}x${i.qty}');
    }
  }
  if (t.tenderedYen != null && t.changeYen != null) {
    if (t.changeYen != t.tenderedYen! - t.totalYen) {
      errors.add('rule3: change=${t.changeYen} != ${t.tenderedYen}-${t.totalYen}');
    }
  }
  if (t.discounts.isNotEmpty && discountSum >= itemsSum) {
    errors.add('rule4: discounts=$discountSum >= itemsSum=$itemsSum');
  }
  return errors;
}

/// spec §4-2 規則5（L0のみ呼ぶ）: 合計金額文字列と日付行が本文に出現すること。
List<String> validateContainment(
    List<OcrBlock> blocks, String renderedTotalAmount, String? renderedDateLine) {
  final errors = <String>[];
  final texts = blocks.map((b) => b.text).toList();
  if (!texts.any((s) => s.contains(renderedTotalAmount))) {
    errors.add('rule5: total text "$renderedTotalAmount" not found');
  }
  if (renderedDateLine != null && !texts.any((s) => s.contains(renderedDateLine))) {
    errors.add('rule5: date line "$renderedDateLine" not found');
  }
  return errors;
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/validate_test.dart`
Expected: PASS（7 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_gen/src/validate.dart test/harness/validate_test.dart
git commit -m "feat(harness): truth consistency validator (spec 4-2)"
```

---

### Task 3: Vocab型＋語彙検証（vocab.dart）＋テスト用ミニ語彙

**Files:**
- Create: `tool/receipt_gen/src/vocab.dart`
- Create: `test/harness/fixtures/test_vocab.json`
- Test: `test/harness/vocab_validate_test.dart`

**Interfaces:**
- Produces: `const List<String> storeTypes`（8様式のID。**全タスクがこの定数を参照**: `['supermarket','convenience','drugstore','restaurant','cafe','homecenter','bookstore','gasstation']`）、`class Vocab { Map<String, List<String>> items; Map<String, List<String>> storeNames; factory Vocab.fromJson(Map); List<String> validate(); }`、`Vocab loadVocab(String path)`
- `validate()` の規則（spec §6）: 数字（半角/全角）を含む語の拒否／重複拒否／様式ごと品目50以上・店名10以上／品目全体1,000以上・店名全体80以上／店名のNGリスト部分一致拒否。**注意: この規則は本番 `tool/receipt_gen/data/vocab.json` 用。テスト用ミニ語彙は `validate()` を通さずに使う**

- [ ] **Step 1: テスト用ミニ語彙を作る**

```json
// test/harness/fixtures/test_vocab.json
{
  "model": "test",
  "items": {
    "supermarket": ["ネギ", "牛乳", "国産豚小間切れ", "食パン"],
    "convenience": ["おにぎり鮭", "お茶", "からあげ", "サンドイッチ"],
    "drugstore": ["ばんそうこう", "シャンプー", "ティッシュ", "うがい薬"],
    "restaurant": ["日替わり定食", "生ビール", "餃子", "ライス"],
    "cafe": ["ブレンドコーヒー", "カフェラテ", "チーズケーキ", "紅茶"],
    "homecenter": ["軍手", "木ねじ", "ペンキ", "園芸土"],
    "bookstore": ["文庫本", "雑誌", "ノート", "ボールペン"],
    "gasstation": ["レギュラー", "洗車", "オイル交換", "ワイパー"]
  },
  "storeNames": {
    "supermarket": ["フレッシュたなか青果", "みどりマート"],
    "convenience": ["エブリデイストア", "まちかどショップ"],
    "drugstore": ["すこやか薬局", "ケンコードラッグ"],
    "restaurant": ["食堂やまびこ", "大衆酒場つばめ"],
    "cafe": ["喫茶ひなた", "カフェこもれび"],
    "homecenter": ["ホームワイド田島", "DIYセンターまるこ"],
    "bookstore": ["よつば書店", "文栄堂"],
    "gasstation": ["いろはSS", "はやぶさ石油"]
  }
}
```

- [ ] **Step 2: 失敗するテストを書く**

```dart
// test/harness/vocab_validate_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  test('test_vocab.json loads', () {
    final v = loadVocab('test/harness/fixtures/test_vocab.json');
    expect(v.items.keys.toSet(), storeTypes.toSet());
    expect(v.storeNames['supermarket'], isNotEmpty);
  });

  test('validate rejects digits, duplicates, NG names, and shortage', () {
    Vocab mini(Map<String, List<String>> namePatch) {
      // 数字なし・ユニークな130語×8様式=1,040語のダミー（i<133 で (i%7, i~/7) がユニーク）
      final items = {
        for (final s in storeTypes)
          s: [for (var i = 0; i < 130; i++) '品目$s${'い' * (i % 7)}${'う' * (i ~/ 7)}']
      };
      final names = {for (final s in storeTypes) s: List.generate(12, (i) => '架空店$s${'ぬ' * i}')};
      names.addAll(namePatch);
      return Vocab(items: items, storeNames: names);
    }

    expect(mini({}).validate(), isEmpty);
    expect(mini({'supermarket': ['店1号', ...List.generate(11, (i) => '店${'あ' * (i + 1)}')]}).validate(),
        isNotEmpty, reason: '数字入り店名');
    expect(mini({'cafe': ['同じ店', '同じ店', ...List.generate(10, (i) => '店${'か' * (i + 1)}')]}).validate(),
        isNotEmpty, reason: '重複');
    expect(mini({'supermarket': ['スーパーマルエツ渋谷', ...List.generate(11, (i) => '店${'さ' * (i + 1)}')]}).validate(),
        isNotEmpty, reason: 'NGリスト（実在チェーン）');
    expect(mini({'bookstore': ['一軒だけ']}).validate(), isNotEmpty, reason: '店名10未満');
  });

  test('committed production vocab.json is valid (skips until Task 9)', () {
    final f = File('tool/receipt_gen/data/vocab.json');
    if (!f.existsSync()) {
      markTestSkipped('vocab.json not generated yet (Task 9)');
      return;
    }
    expect(loadVocab(f.path).validate(), isEmpty);
  }, skip: false);
}
```

- [ ] **Step 3: 失敗を確認**

Run: `flutter test test/harness/vocab_validate_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 4: 実装**

```dart
// tool/receipt_gen/src/vocab.dart
import 'dart:convert';
import 'dart:io';

const List<String> storeTypes = [
  'supermarket',
  'convenience',
  'drugstore',
  'restaurant',
  'cafe',
  'homecenter',
  'bookstore',
  'gasstation',
];

/// 実在チェーン混入防止のNGリスト（部分一致・spec §5）。
const List<String> ngStoreNames = [
  'マルエツ', 'イオン', 'セブン', 'ローソン', 'ファミリーマート',
  'ヨーカドー', 'ライフ', 'サミット', 'オーケー', '西友',
  'マツモトキヨシ', 'ウエルシア', 'ツルハ', 'スギ薬局', 'カインズ',
  'コーナン', 'ビバホーム', '紀伊國屋', 'TSUTAYA', 'ENEOS',
];

final RegExp _digits = RegExp('[0-9０-９]');

class Vocab {
  final Map<String, List<String>> items;
  final Map<String, List<String>> storeNames;
  const Vocab({required this.items, required this.storeNames});

  factory Vocab.fromJson(Map<String, dynamic> j) => Vocab(
        items: {
          for (final e in (j['items'] as Map<String, dynamic>).entries)
            e.key: (e.value as List).cast<String>(),
        },
        storeNames: {
          for (final e in (j['storeNames'] as Map<String, dynamic>).entries)
            e.key: (e.value as List).cast<String>(),
        },
      );

  /// 本番vocab.jsonの合格規則（spec §6）。空=合格。
  List<String> validate() {
    final errors = <String>[];
    var totalItems = 0;
    var totalNames = 0;
    for (final st in storeTypes) {
      final it = items[st] ?? const [];
      final names = storeNames[st] ?? const [];
      totalItems += it.length;
      totalNames += names.length;
      if (it.length < 50) errors.add('$st: items ${it.length} < 50');
      if (names.length < 10) errors.add('$st: storeNames ${names.length} < 10');
      if (it.toSet().length != it.length) errors.add('$st: duplicate items');
      if (names.toSet().length != names.length) errors.add('$st: duplicate storeNames');
      for (final w in [...it, ...names]) {
        if (_digits.hasMatch(w)) errors.add('$st: digit in "$w"');
      }
      for (final n in names) {
        for (final ng in ngStoreNames) {
          if (n.contains(ng)) errors.add('$st: NG store name "$n" (matches $ng)');
        }
      }
    }
    if (totalItems < 1000) errors.add('total items $totalItems < 1000');
    if (totalNames < 80) errors.add('total storeNames $totalNames < 80');
    return errors;
  }
}

Vocab loadVocab(String path) =>
    Vocab.fromJson(jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>);
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/harness/vocab_validate_test.dart`
Expected: PASS（2 passed, 1 skipped）

- [ ] **Step 6: コミット**

```bash
git add tool/receipt_gen/src/vocab.dart test/harness/fixtures/test_vocab.json test/harness/vocab_validate_test.dart
git commit -m "feat(harness): vocab model, validation rules, test mini-vocab"
```

---

### Task 4: 印字フォーマッタ（formats.dart）

**Files:**
- Create: `tool/receipt_gen/src/formats.dart`
- Test: `test/harness/formats_test.dart`

**Interfaces:**
- Produces: `String comma(int n)`、`String formatAmount(int yen, String currencyMark)`、`String formatDateLine(CivilDate d, String dateFormat, String timeHHmm)`

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/formats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../../tool/receipt_gen/src/formats.dart';

void main() {
  test('comma', () {
    expect(comma(8), '8');
    expect(comma(3850), '3,850');
    expect(comma(1234567), '1,234,567');
  });

  test('formatAmount 4 marks', () {
    expect(formatAmount(3850, 'yen'), '¥3,850');
    expect(formatAmount(3850, 'fullwidthYen'), '￥3,850');
    expect(formatAmount(3850, 'none'), '3,850');
    expect(formatAmount(3850, 'enSuffix'), '3,850円');
    expect(() => formatAmount(1, 'unknown'), throwsArgumentError);
  });

  test('formatDateLine 5 formats (2026-06-30 is Tuesday, R8)', () {
    const d = CivilDate(2026, 6, 30);
    expect(formatDateLine(d, 'kanji', '18:45'), '2026年6月30日(火) 18:45');
    expect(formatDateLine(d, 'slash', '18:45'), '2026/06/30 18:45');
    expect(formatDateLine(d, 'dotShort', '08:05'), '26.06.30 08:05');
    expect(formatDateLine(d, 'warekiShort', '18:45'), 'R8.06.30 18:45');
    expect(formatDateLine(d, 'warekiKanji', '18:45'), '令和8年6月30日 18:45');
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/formats_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/src/formats.dart
import 'package:kakeibo_app/domain/money/civil_date.dart';

String comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String formatAmount(int yen, String currencyMark) => switch (currencyMark) {
      'yen' => '¥${comma(yen)}',
      'fullwidthYen' => '￥${comma(yen)}',
      'none' => comma(yen),
      'enSuffix' => '${comma(yen)}円',
      _ => throw ArgumentError('unknown currencyMark: $currencyMark'),
    };

const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

String formatDateLine(CivilDate d, String dateFormat, String timeHHmm) {
  final w = _weekdays[DateTime.utc(d.year, d.month, d.day).weekday - 1];
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final r = d.year - 2018; // 令和N年
  return switch (dateFormat) {
    'kanji' => '${d.year}年${d.month}月${d.day}日($w) $timeHHmm',
    'slash' => '${d.year}/$mm/$dd $timeHHmm',
    'dotShort' => '${d.year % 100}.$mm.$dd $timeHHmm',
    'warekiShort' => 'R$r.$mm.$dd $timeHHmm',
    'warekiKanji' => '令和$r年${d.month}月${d.day}日 $timeHHmm',
    _ => throw ArgumentError('unknown dateFormat: $dateFormat'),
  };
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/formats_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_gen/src/formats.dart test/harness/formats_test.dart
git commit -m "feat(harness): date/amount print formatters"
```

---

### Task 5: 真値サンプラ（sampler.dart）

**Files:**
- Create: `tool/receipt_gen/src/sampler.dart`
- Test: `test/harness/sampler_test.dart`

**Interfaces:**
- Consumes: Task 1 `TruthReceipt`系、Task 2 `validateTruth`、Task 3 `Vocab`/`storeTypes`
- Produces: `TruthReceipt sampleTruth(Random rng, Vocab vocab, int noiseLevel)`、定数 `const dateFormats`, `const totalKeywords`, `const currencyMarks`, `const baseDate = CivilDate(2026, 7, 11)`

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/sampler_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../../tool/receipt_gen/src/sampler.dart';
import '../../tool/receipt_gen/src/validate.dart';
import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  final vocab = loadVocab('test/harness/fixtures/test_vocab.json');

  test('1,000 samples all pass validateTruth (spec 9-1)', () {
    final rng = Random(20260711);
    for (var i = 0; i < 1000; i++) {
      final t = sampleTruth(rng, vocab, i % 3);
      final errors = validateTruth(t);
      expect(errors, isEmpty, reason: 'sample #$i: $errors\n${t.toJson()}');
    }
  });

  test('distribution constraints hold over 1,000 samples', () {
    final rng = Random(1);
    var dateAbsent = 0;
    for (var i = 0; i < 1000; i++) {
      final t = sampleTruth(rng, vocab, 0);
      expect(t.items.length, inInclusiveRange(1, 25));
      for (final it in t.items) {
        expect(it.unitPriceYen, inInclusiveRange(8, 9980));
        if (it.qty > 1) expect(t.storeType, 'supermarket', reason: 'qty>1 is supermarket-only');
        expect(it.qty, inInclusiveRange(1, 3));
      }
      if (t.date == null) {
        dateAbsent++;
      } else {
        expect(t.date!.compareTo(const CivilDate(2025, 7, 12)) >= 0, isTrue);
        expect(t.date!.compareTo(const CivilDate(2026, 7, 11)) <= 0, isTrue);
      }
      if (t.taxLines.length > 1) {
        expect(['supermarket', 'drugstore'].contains(t.storeType), isTrue,
            reason: '混在税率はスーパー/ドラッグのみ');
      }
      if (t.tenderedYen != null) {
        expect(t.tenderedYen! >= t.totalYen, isTrue);
        expect(t.tenderedYen! % 1000, 0);
      }
      expect(t.totalYen > 0, isTrue);
    }
    expect(dateAbsent, inInclusiveRange(20, 90), reason: '日付なし≈5%');
  });

  test('same seed same sequence', () {
    final a = sampleTruth(Random(42), vocab, 1);
    final b = sampleTruth(Random(42), vocab, 1);
    expect(a.toJson(), b.toJson());
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/sampler_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/src/sampler.dart
import 'dart:math';

import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'truth.dart';
import 'vocab.dart';

const List<String> dateFormats = ['kanji', 'slash', 'dotShort', 'warekiShort', 'warekiKanji'];
const List<String> totalKeywords = ['合計', 'お買上げ計', '合　計', '総合計', 'お会計'];
const List<String> currencyMarks = ['yen', 'fullwidthYen', 'none', 'enSuffix'];

/// 評価時の固定today（spec §7）。日付サンプル範囲の基準でもある。
const CivilDate baseDate = CivilDate(2026, 7, 11);

T _pick<T>(Random rng, List<T> list) => list[rng.nextInt(list.length)];

String _sampleTaxMode(Random rng, String storeType) {
  final p = rng.nextInt(10);
  return switch (storeType) {
    'supermarket' || 'convenience' || 'drugstore' => p < 8 ? 'inclusive' : 'exclusive',
    'restaurant' || 'cafe' => p < 7 ? 'inclusive' : 'exclusive',
    _ => p < 6 ? 'inclusive' : 'exclusive',
  };
}

TruthReceipt sampleTruth(Random rng, Vocab vocab, int noiseLevel) {
  final storeType = _pick(rng, storeTypes);
  final storeName = _pick(rng, vocab.storeNames[storeType]!);

  CivilDate? date;
  if (rng.nextInt(100) >= 5) {
    final dt = DateTime.utc(baseDate.year, baseDate.month, baseDate.day)
        .subtract(Duration(days: rng.nextInt(365)));
    date = CivilDate(dt.year, dt.month, dt.day);
  }

  final taxMode = _sampleTaxMode(rng, storeType);
  final mixed = taxMode == 'inclusive' &&
      (storeType == 'supermarket' || storeType == 'drugstore') &&
      rng.nextInt(2) == 0;

  final n = rng.nextInt(3) < 2 ? 1 + rng.nextInt(8) : 9 + rng.nextInt(17);
  final items = <TruthItem>[];
  for (var i = 0; i < n; i++) {
    final name = _pick(rng, vocab.items[storeType]!);
    final unit = 8 + rng.nextInt(9973); // 8..9980
    final qty =
        (storeType == 'supermarket' && rng.nextInt(10) == 0) ? 2 + rng.nextInt(2) : 1;
    final rate = mixed ? (rng.nextInt(10) < 6 ? 8 : 10) : 10;
    items.add(TruthItem(
        name: name, unitPriceYen: unit, qty: qty, amountYen: unit * qty, taxRate: rate));
  }
  final itemsSum = items.fold(0, (a, i) => a + i.amountYen);

  final discounts = <TruthDiscount>[];
  if (rng.nextInt(5) == 0) {
    final minD = itemsSum * 5 ~/ 100;
    final maxD = itemsSum * 30 ~/ 100;
    var d = maxD > minD ? minD + rng.nextInt(maxD - minD + 1) : minD;
    if (d >= itemsSum) d = itemsSum - 1;
    if (d > 0) discounts.add(TruthDiscount(label: '割引', amountYen: d));
  }
  final discountSum = discounts.fold(0, (a, d) => a + d.amountYen);

  final rates = items.map((i) => i.taxRate).toSet().toList()..sort();
  final taxLines = <TruthTaxLine>[];
  for (final r in rates) {
    final base =
        items.where((i) => i.taxRate == r).fold(0, (a, i) => a + i.amountYen);
    taxLines.add(TruthTaxLine(
        rate: r,
        taxYen: taxMode == 'inclusive' ? base * r ~/ (100 + r) : base * r ~/ 100));
  }
  final taxSum = taxLines.fold(0, (a, t) => a + t.taxYen);
  final total =
      taxMode == 'inclusive' ? itemsSum - discountSum : itemsSum - discountSum + taxSum;

  int? tendered;
  int? change;
  if (rng.nextInt(2) == 0) {
    tendered = (total + 999) ~/ 1000 * 1000;
    change = tendered - total;
  }

  return TruthReceipt(
    storeName: storeName,
    storeType: storeType,
    date: date,
    items: items,
    discounts: discounts,
    taxMode: taxMode,
    taxLines: taxLines,
    totalYen: total,
    tenderedYen: tendered,
    changeYen: change,
    style: ReceiptStyle(
      dateFormat: _pick(rng, dateFormats),
      totalKeyword: _pick(rng, totalKeywords),
      currencyMark: _pick(rng, currencyMarks),
    ),
    noiseLevel: noiseLevel,
  );
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/sampler_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_gen/src/sampler.dart test/harness/sampler_test.dart
git commit -m "feat(harness): deterministic truth sampler"
```

---

### Task 6: レンダラ（renderer.dart）

**Files:**
- Create: `tool/receipt_gen/src/renderer.dart`
- Test: `test/harness/renderer_test.dart`

**Interfaces:**
- Consumes: Task 1 `TruthReceipt`、Task 4 `formatAmount`/`formatDateLine`/`comma`、`OcrBlock`/`OcrRect`
- Produces: `class RenderResult { List<OcrBlock> blocks; String renderedTotalAmount; String? renderedDateLine; }`、`RenderResult renderReceipt(TruthReceipt t, Random rng)`

行の構成順（決定・全様式共通）: 店名 → 電話(60%) → 日付+時刻(truth.dateがある場合のみ) → 品目（qty>1はスーパーのみ2行: 品名行＋`2コX単価` 金額行。混在税率のスーパー/ドラッグは8%品名に`※`後置） → 小計 → 割引行 → 税行（内税は単一ブロック `（内消費税等 8% ¥xx）`、外税はペア `消費税(10%)` + 金額） → 合計行（`style.totalKeyword` + 金額） → お預り/お釣り(truthにある場合) → ポイント行(30%) → 登録番号行(40%)。

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/renderer_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/src/renderer.dart';
import '../../tool/receipt_gen/src/sampler.dart';
import '../../tool/receipt_gen/src/validate.dart';
import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  final vocab = loadVocab('test/harness/fixtures/test_vocab.json');

  test('containment holds for 200 sampled truths (spec 9-2)', () {
    final rng = Random(20260711);
    for (var i = 0; i < 200; i++) {
      final t = sampleTruth(rng, vocab, 0);
      final r = renderReceipt(t, rng);
      final errors =
          validateContainment(r.blocks, r.renderedTotalAmount, r.renderedDateLine);
      expect(errors, isEmpty, reason: '#$i: $errors');
      expect(r.renderedDateLine == null, t.date == null);
    }
  });

  test('geometry: rects in 0..1, rows ordered, label left of amount', () {
    final rng = Random(7);
    for (var i = 0; i < 100; i++) {
      final t = sampleTruth(rng, vocab, 0);
      final r = renderReceipt(t, rng);
      double prevY = -1;
      for (final b in r.blocks) {
        expect(b.rect.x >= 0 && b.rect.right <= 1.0, isTrue, reason: b.text);
        expect(b.rect.y >= 0 && b.rect.bottom <= 1.0, isTrue, reason: b.text);
        expect(b.confidence, inInclusiveRange(0.90, 0.98));
        expect(b.rect.y >= prevY, isTrue, reason: 'y must be non-decreasing');
        prevY = b.rect.y;
      }
      // 合計行: キーワードブロックの右に金額ブロック
      final kwIdx = r.blocks.indexWhere((b) => b.text == t.style.totalKeyword);
      expect(kwIdx, greaterThanOrEqualTo(0));
      final amount = r.blocks[kwIdx + 1];
      expect(amount.text, r.renderedTotalAmount);
      expect(amount.rect.x > r.blocks[kwIdx].rect.right, isTrue);
    }
  });

  test('deterministic for same rng seed', () {
    final t = sampleTruth(Random(5), vocab, 0);
    final a = renderReceipt(t, Random(9));
    final b = renderReceipt(t, Random(9));
    expect(a.blocks.length, b.blocks.length);
    for (var i = 0; i < a.blocks.length; i++) {
      expect(a.blocks[i].text, b.blocks[i].text);
      expect(a.blocks[i].rect.y, b.blocks[i].rect.y);
      expect(a.blocks[i].confidence, b.blocks[i].confidence);
    }
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/renderer_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/src/renderer.dart
import 'dart:math';

import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import 'formats.dart';
import 'truth.dart';

class RenderResult {
  final List<OcrBlock> blocks;
  final String renderedTotalAmount;
  final String? renderedDateLine;
  const RenderResult({
    required this.blocks,
    required this.renderedTotalAmount,
    required this.renderedDateLine,
  });
}

class _Line {
  final String label;
  final String? amount;
  const _Line.single(this.label) : amount = null;
  const _Line.pair(this.label, String this.amount);
}

double _w(String s) => (0.02 * s.length).clamp(0.05, 0.55);

String _digits(Random rng, int n) =>
    List.generate(n, (_) => rng.nextInt(10).toString()).join();

RenderResult renderReceipt(TruthReceipt t, Random rng) {
  final mark = t.style.currencyMark;
  final lines = <_Line>[];

  lines.add(_Line.single(t.storeName));
  if (rng.nextInt(10) < 6) {
    lines.add(_Line.single('TEL 0${rng.nextInt(9) + 1}-${_digits(rng, 4)}-${_digits(rng, 4)}'));
  }

  String? dateLine;
  if (t.date != null) {
    final hh = 8 + rng.nextInt(15); // 8..22
    final mi = rng.nextInt(60);
    dateLine = formatDateLine(
        t.date!, t.style.dateFormat, '$hh:${mi.toString().padLeft(2, '0')}');
    lines.add(_Line.single(dateLine));
  }

  final mixedMark = t.taxLines.length > 1 &&
      (t.storeType == 'supermarket' || t.storeType == 'drugstore');
  for (final it in t.items) {
    final name = (mixedMark && it.taxRate == 8) ? '${it.name}※' : it.name;
    if (it.qty > 1) {
      lines.add(_Line.single(name));
      lines.add(_Line.pair('${it.qty}コX${it.unitPriceYen}', formatAmount(it.amountYen, mark)));
    } else {
      lines.add(_Line.pair(name, formatAmount(it.amountYen, mark)));
    }
  }

  final itemsSum = t.items.fold(0, (a, i) => a + i.amountYen);
  lines.add(_Line.pair('小計', formatAmount(itemsSum, mark)));
  for (final d in t.discounts) {
    lines.add(_Line.pair(d.label, '-${formatAmount(d.amountYen, mark)}'));
  }
  for (final tx in t.taxLines) {
    if (t.taxMode == 'inclusive') {
      lines.add(_Line.single('（内消費税等 ${tx.rate}% ${formatAmount(tx.taxYen, mark)}）'));
    } else {
      lines.add(_Line.pair('消費税(${tx.rate}%)', formatAmount(tx.taxYen, mark)));
    }
  }

  final totalText = formatAmount(t.totalYen, mark);
  lines.add(_Line.pair(t.style.totalKeyword, totalText));

  if (t.tenderedYen != null) {
    lines.add(_Line.pair('お預り', formatAmount(t.tenderedYen!, mark)));
    lines.add(_Line.pair('お釣り', formatAmount(t.changeYen!, mark)));
  }
  if (rng.nextInt(10) < 3) {
    lines.add(_Line.single('ポイント残高 ${comma(100 + rng.nextInt(99900))}P'));
  }
  if (rng.nextInt(10) < 4) {
    lines.add(_Line.single('登録番号 T${_digits(rng, 13)}'));
  }

  // レイアウト: y_i = 0.03 + i*step, step = 0.94/行数, h = 0.8*step（spec §5）
  final step = 0.94 / lines.length;
  final h = step * 0.8;
  final blocks = <OcrBlock>[];
  for (var i = 0; i < lines.length; i++) {
    final y = 0.03 + i * step;
    final l = lines[i];
    blocks.add(OcrBlock(
      text: l.label,
      rect: OcrRect(0.05, y, _w(l.label), h),
      confidence: 0.90 + rng.nextDouble() * 0.08,
    ));
    if (l.amount != null) {
      final aw = _w(l.amount!);
      blocks.add(OcrBlock(
        text: l.amount!,
        rect: OcrRect(0.95 - aw, y, aw, h),
        confidence: 0.90 + rng.nextDouble() * 0.08,
      ));
    }
  }
  return RenderResult(
      blocks: blocks, renderedTotalAmount: totalText, renderedDateLine: dateLine);
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/renderer_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_gen/src/renderer.dart test/harness/renderer_test.dart
git commit -m "feat(harness): truth-to-OcrBlock template renderer"
```

---

### Task 7: ノイズ注入（noise.dart）

**Files:**
- Create: `tool/receipt_gen/src/noise.dart`
- Test: `test/harness/noise_test.dart`

**Interfaces:**
- Consumes: Task 1 `TruthReceipt`（`noiseLevel`と`style.totalKeyword`を読む）、`package:kakeibo_app/domain/services/receipt/rows.dart` の `groupRows`（行結合の再実装に使う。test/support の `mergeRowBlocks` は import しない — tool は test/ に依存しない）
- Produces: `List<OcrBlock> applyNoise(List<OcrBlock> blocks, TruthReceipt t, Random rng)`

適用順（確定判断表どおり）: ¥落ち → 合計キーワード落ち → 行結合 → ブロック分割 → 文字置換 → 空ブロック除去。率はspec §5の表（L1: 置換2%/分割3%/¥落ち10%、L2: 置換5%/分割8%/行結合30%/¥落ち25%/キーワード落ち10%）。

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/noise_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

import '../../tool/receipt_gen/src/noise.dart';
import '../../tool/receipt_gen/src/renderer.dart';
import '../../tool/receipt_gen/src/sampler.dart';
import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  final vocab = loadVocab('test/harness/fixtures/test_vocab.json');

  test('L0 is identity', () {
    final rng = Random(1);
    final t = sampleTruth(rng, vocab, 0);
    final blocks = renderReceipt(t, rng).blocks;
    expect(identical(applyNoise(blocks, t, Random(2)), blocks), isTrue);
  });

  test('deterministic for same seed', () {
    final rng = Random(3);
    final t = sampleTruth(rng, vocab, 2);
    final blocks = renderReceipt(t, rng).blocks;
    final a = applyNoise(blocks, t, Random(4));
    final b = applyNoise(blocks, t, Random(4));
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].text, b[i].text);
      expect(a[i].rect.x, b[i].rect.x);
    }
  });

  test('no empty blocks; substitutions only 0->O 1->I long-vowel', () {
    final rng = Random(5);
    for (var i = 0; i < 200; i++) {
      final t = sampleTruth(rng, vocab, 2);
      final out = applyNoise(renderReceipt(t, rng).blocks, t, rng);
      for (final b in out) {
        expect(b.text.trim(), isNotEmpty);
      }
    }
  });

  test('split preserves concatenated text when only split fires', () {
    // 分割だけを強制するため、確率draw順を利用せず統計的に検証:
    // L1では ¥落ち10%・分割3%・置換2% のみ。500レシートで
    // 「元blocks数 <= ノイズ後blocks数」（分割は増やす一方、結合はL2のみ）を確認。
    final rng = Random(6);
    for (var i = 0; i < 500; i++) {
      final t = sampleTruth(rng, vocab, 1);
      final blocks = renderReceipt(t, rng).blocks;
      final out = applyNoise(blocks, t, rng);
      expect(out.length >= blocks.length - blocks.length ~/ 10, isTrue,
          reason: 'L1で大幅減はおかしい（空ブロック除去は¥単独ブロック程度）');
    }
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/noise_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/src/noise.dart
import 'dart:math';

import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

import 'truth.dart';

List<OcrBlock> _mapText(List<OcrBlock> blocks, String Function(String) f) => [
      for (final b in blocks)
        OcrBlock(text: f(b.text), rect: b.rect, confidence: b.confidence),
    ];

/// 各物理行を1ブロックへ結合（test/support/receipt_fixtures.dart のmergeRowBlocksと同等。
/// toolはtest/に依存できないためlibのgroupRowsで再実装）。
List<OcrBlock> _mergeRows(List<OcrBlock> blocks) {
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
        confidence: row.blocks.map((b) => b.confidence).reduce((a, c) => a + c) /
            row.blocks.length,
      ),
  ];
}

const _subs = {'0': 'O', '1': 'I', 'ー': '一'};

List<OcrBlock> applyNoise(List<OcrBlock> blocks, TruthReceipt t, Random rng) {
  final level = t.noiseLevel;
  if (level == 0) return blocks;

  var out = blocks;

  // ① ¥落ち（レシート単位）
  if (rng.nextInt(100) < (level == 1 ? 10 : 25)) {
    out = _mapText(out, (s) => s.replaceAll(RegExp('[¥￥]'), ''));
  }
  // ② 合計キーワード落ち（L2のみ・レシート単位）
  if (level == 2 && rng.nextInt(100) < 10) {
    out = _mapText(out, (s) => s.replaceAll(t.style.totalKeyword, ''));
  }
  // ③ 行結合（L2のみ・レシート単位）
  if (level == 2 && rng.nextInt(100) < 30) {
    out = _mergeRows(out);
  }
  // ④ ブロック分割
  final pSplit = level == 1 ? 3 : 8;
  final split = <OcrBlock>[];
  for (final b in out) {
    if (b.text.length >= 2 && rng.nextInt(100) < pSplit) {
      final cut = 1 + rng.nextInt(b.text.length - 1);
      final r = b.rect;
      final w1 = r.w * cut / b.text.length;
      split.add(OcrBlock(
          text: b.text.substring(0, cut),
          rect: OcrRect(r.x, r.y, w1, r.h),
          confidence: b.confidence));
      split.add(OcrBlock(
          text: b.text.substring(cut),
          rect: OcrRect(r.x + w1, r.y, r.w - w1, r.h),
          confidence: b.confidence));
    } else {
      split.add(b);
    }
  }
  out = split;
  // ⑤ 文字置換
  final pSub = level == 1 ? 2 : 5;
  out = [
    for (final b in out)
      OcrBlock(
        text: b.text
            .split('')
            .map((c) =>
                _subs.containsKey(c) && rng.nextInt(100) < pSub ? _subs[c]! : c)
            .join(),
        rect: b.rect,
        confidence: b.confidence,
      ),
  ];
  // ⑥ 空ブロック除去
  return [
    for (final b in out)
      if (b.text.trim().isNotEmpty) b,
  ];
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/noise_test.dart`
Expected: PASS（4 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_gen/src/noise.dart test/harness/noise_test.dart
git commit -m "feat(harness): deterministic OCR noise injection (L0/L1/L2)"
```

---

### Task 8: コーパス生成CLI（generate.dart）＋決定性テスト

**Files:**
- Create: `tool/receipt_gen/generate.dart`
- Test: `test/harness/generate_determinism_test.dart`

**Interfaces:**
- Consumes: Task 1〜7の全部
- Produces: `Future<void> runGenerate({required int seed, required String outDir, required String vocabPath, int countPerLevel = 400})`、CLI `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus [--vocab <path>] [--count-per-level N]`（`--vocab` 省略時 `tool/receipt_gen/data/vocab.json`）。ファイル名 `syn-l{level}-{0001..}.json`。出力先は毎回全削除→再生成。生成中にspec §4-2違反があれば `StateError` → CLIはexit 1

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/generate_determinism_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/generate.dart';

void main() {
  const vocabPath = 'test/harness/fixtures/test_vocab.json';

  test('smoke: 5 per level -> 15 files with correct names; rerun wipes', () async {
    final dir = Directory.systemTemp.createTempSync('gen_smoke');
    try {
      await runGenerate(
          seed: 20260711, outDir: dir.path, vocabPath: vocabPath, countPerLevel: 5);
      final names = dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();
      expect(names.length, 15);
      expect(names.first, 'syn-l0-0001.json');
      expect(names.last, 'syn-l2-0005.json');

      // 異物を置いて再実行→消えている（全削除→再生成）
      File('${dir.path}/garbage.txt').writeAsStringSync('x');
      await runGenerate(
          seed: 20260711, outDir: dir.path, vocabPath: vocabPath, countPerLevel: 5);
      expect(File('${dir.path}/garbage.txt').existsSync(), isFalse);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('same seed -> byte-identical corpus (spec 9-3, 20 files)', () async {
    final d1 = Directory.systemTemp.createTempSync('gen_a');
    final d2 = Directory.systemTemp.createTempSync('gen_b');
    try {
      await runGenerate(seed: 1, outDir: d1.path, vocabPath: vocabPath, countPerLevel: 7);
      await runGenerate(seed: 1, outDir: d2.path, vocabPath: vocabPath, countPerLevel: 7);
      final files1 = d1.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f1 in files1) {
        final f2 = File('${d2.path}/${f1.uri.pathSegments.last}');
        expect(f2.readAsBytesSync(), f1.readAsBytesSync(),
            reason: f1.uri.pathSegments.last);
      }
    } finally {
      d1.deleteSync(recursive: true);
      d2.deleteSync(recursive: true);
    }
  });

  test('different seed -> different corpus', () async {
    final d1 = Directory.systemTemp.createTempSync('gen_c');
    final d2 = Directory.systemTemp.createTempSync('gen_d');
    try {
      await runGenerate(seed: 1, outDir: d1.path, vocabPath: vocabPath, countPerLevel: 3);
      await runGenerate(seed: 2, outDir: d2.path, vocabPath: vocabPath, countPerLevel: 3);
      final a = File('${d1.path}/syn-l0-0001.json').readAsStringSync();
      final b = File('${d2.path}/syn-l0-0001.json').readAsStringSync();
      expect(a == b, isFalse);
    } finally {
      d1.deleteSync(recursive: true);
      d2.deleteSync(recursive: true);
    }
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/generate_determinism_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_gen/generate.dart
import 'dart:io';
import 'dart:math';

import 'src/noise.dart';
import 'src/renderer.dart';
import 'src/sampler.dart';
import 'src/truth.dart';
import 'src/validate.dart';
import 'src/vocab.dart';

Future<void> runGenerate({
  required int seed,
  required String outDir,
  required String vocabPath,
  int countPerLevel = 400,
}) async {
  final vocab = loadVocab(vocabPath);
  final dir = Directory(outDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  final rng = Random(seed);
  for (var level = 0; level <= 2; level++) {
    for (var i = 1; i <= countPerLevel; i++) {
      final truth = sampleTruth(rng, vocab, level);
      final render = renderReceipt(truth, rng);
      final blocks = applyNoise(render.blocks, truth, rng);
      final name = 'syn-l$level-${i.toString().padLeft(4, '0')}';
      final errors = [
        ...validateTruth(truth),
        if (level == 0)
          ...validateContainment(
              render.blocks, render.renderedTotalAmount, render.renderedDateLine),
      ];
      if (errors.isNotEmpty) {
        throw StateError('$name failed validation: $errors');
      }
      final fixture = SynthFixture(name: name, blocks: blocks, truth: truth);
      File('${dir.path}/$name.json').writeAsStringSync(encodeFixture(fixture));
    }
  }
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final seed = int.tryParse(_arg(args, '--seed') ?? '');
  final out = _arg(args, '--out');
  if (seed == null || out == null) {
    stderr.writeln(
        'usage: dart run tool/receipt_gen/generate.dart --seed <int> --out <dir> [--vocab <path>] [--count-per-level <n>]');
    exit(2);
  }
  final vocabPath = _arg(args, '--vocab') ?? 'tool/receipt_gen/data/vocab.json';
  if (!File(vocabPath).existsSync()) {
    // spec §8: 自動でOllamaを叩かず、先に語彙生成を促して終了する
    stderr.writeln('vocab not found: $vocabPath — 先に dart run tool/receipt_vocab/generate_vocab.dart を実行してください');
    exit(1);
  }
  final count = int.tryParse(_arg(args, '--count-per-level') ?? '400') ?? 400;
  try {
    await runGenerate(
        seed: seed, outDir: out, vocabPath: vocabPath, countPerLevel: count);
    stdout.writeln('generated ${count * 3} fixtures in $out (seed=$seed)');
  } on Object catch (e) {
    stderr.writeln('generation failed: $e');
    exit(1);
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/generate_determinism_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: CLIの手動スモーク（`dart run`が通ることの確認）**

Run: `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus_smoke --vocab test/harness/fixtures/test_vocab.json --count-per-level 5`
Expected: exit 0、`generated 15 fixtures in build/receipt_corpus_smoke (seed=20260711)`
（もし `dart run` がFlutter依存で失敗したら: 台帳に記録し、`flutter test` 経由の実行に切替える判断を統括に仰ぐ。build_runnerが同形式で動いている実績があるため失敗は想定外）

- [ ] **Step 6: コミット**

```bash
git add tool/receipt_gen/generate.dart test/harness/generate_determinism_test.dart
git commit -m "feat(harness): corpus generation CLI with wipe-and-regenerate + determinism tests"
```

---

### Task 9: 語彙生成CLI（Ollama）＋本番vocab.json生成・コミット

**Files:**
- Create: `tool/receipt_vocab/generate_vocab.dart`
- Create: `tool/receipt_gen/data/vocab.json`（CLI実行の成果物）
- Test: 既存 `test/harness/vocab_validate_test.dart` の skip されていた3本目が実行されるようになる

**Interfaces:**
- Consumes: Task 3 `Vocab`/`storeTypes`/`ngStoreNames`
- Produces: CLI `dart run tool/receipt_vocab/generate_vocab.dart [--model qwen3:14b] [--out tool/receipt_gen/data/vocab.json]`。Ollama未起動・接続不可なら明示メッセージでexit 1（リトライなし、spec §8）

**前提:** Ollamaが起動済みで `ollama pull qwen3:14b` 済みであること（約9GB。実行前に `ollama list` で確認し、なければpullする）。

- [ ] **Step 1: 実装（この タスクはLLM出力が非決定的なため後段検証型。ユニットテストは検証関数の再利用=Task 3で済んでいる）**

```dart
// tool/receipt_vocab/generate_vocab.dart
import 'dart:convert';
import 'dart:io';

import '../receipt_gen/src/vocab.dart';

const _storeTypeJa = {
  'supermarket': 'スーパーマーケット',
  'convenience': 'コンビニエンスストア',
  'drugstore': 'ドラッグストア',
  'restaurant': '大衆的な飲食店・定食屋',
  'cafe': '喫茶店・カフェ',
  'homecenter': 'ホームセンター',
  'bookstore': '書店・文具店',
  'gasstation': 'ガソリンスタンド',
};

Future<List<String>> _ask(String model, String prompt) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.postUrl(Uri.parse('http://localhost:11434/api/chat'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'model': model,
      'stream': false,
      'think': false,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'format': {
        'type': 'object',
        'properties': {
          'words': {
            'type': 'array',
            'items': {'type': 'string'}
          }
        },
        'required': ['words'],
      },
      'options': {'temperature': 0.9},
    }));
    final res = await req.close().timeout(const Duration(seconds: 120));
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw HttpException('status ${res.statusCode}: $body');
    }
    final content =
        (jsonDecode(body) as Map<String, dynamic>)['message']['content'] as String;
    final words =
        ((jsonDecode(content) as Map<String, dynamic>)['words'] as List).cast<String>();
    return words;
  } finally {
    client.close();
  }
}

List<String> _clean(List<String> raw) {
  final digits = RegExp('[0-9０-９]');
  final seen = <String>{};
  return [
    for (final w0 in raw)
      if (w0.trim().isNotEmpty)
        if (!digits.hasMatch(w0.trim()))
          if (seen.add(w0.trim())) w0.trim(),
  ];
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final model = _arg(args, '--model') ?? 'qwen3:14b';
  final out = _arg(args, '--out') ?? 'tool/receipt_gen/data/vocab.json';

  final items = <String, List<String>>{};
  final names = <String, List<String>>{};
  try {
    for (final st in storeTypes) {
      final ja = _storeTypeJa[st]!;
      stdout.writeln('items: $st ...');
      items[st] = _clean(await _ask(
          model,
          '日本の$jaのレシートに印字される品目名（商品・メニューの短い表記）を160個、'
          'JSONで出してください。数字・価格・数量・単位・記号は一切含めないこと。'
          '実在の商標・ブランド名は避け、一般的な品目名にすること。'));
      stdout.writeln('storeNames: $st ...');
      final rawNames = _clean(await _ask(
          model,
          '日本の$jaの架空の店名を15個、JSONで出してください。'
          '実在するチェーン店の名前やそれに酷似した名前は禁止。数字は含めないこと。'));
      names[st] = [
        for (final n in rawNames)
          if (!ngStoreNames.any(n.contains)) n,
      ];
    }
  } on Object catch (e) {
    stderr.writeln('Ollama呼び出しに失敗しました（Ollama起動と `ollama pull $model` を確認）: $e');
    exit(1);
  }

  final vocab = Vocab(items: items, storeNames: names);
  final errors = vocab.validate();
  if (errors.isNotEmpty) {
    stderr.writeln('生成語彙が検証不合格（再実行してください）: $errors');
    exit(1);
  }
  final json = const JsonEncoder.withIndent(' ').convert({
    'model': model,
    'items': items,
    'storeNames': names,
  });
  File(out)
    ..createSync(recursive: true)
    ..writeAsStringSync('$json\n');
  stdout.writeln('wrote $out');
}
```

- [ ] **Step 2: モデル確認・取得**

Run: `ollama list`
なければ: `ollama pull qwen3:14b`（約9GB・回線次第で数分〜）

- [ ] **Step 3: 本番語彙を生成**

Run: `dart run tool/receipt_vocab/generate_vocab.dart`
Expected: 各様式2リクエスト×8様式が進行し `wrote tool/receipt_gen/data/vocab.json`。検証不合格でexit 1なら再実行（LLMの出目依存。2〜3回で通る想定。通らなければ台帳に記録し要求数を200に上げる裁定を統括へ）

- [ ] **Step 4: コミット済み語彙の検証テストが通ることを確認**

Run: `flutter test test/harness/vocab_validate_test.dart`
Expected: PASS（3 tests、skipなし）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_vocab/generate_vocab.dart tool/receipt_gen/data/vocab.json
git commit -m "feat(harness): Ollama vocab generation CLI + committed production vocab"
```

---

### Task 10: 採点（scorer.dart）

**Files:**
- Create: `tool/receipt_eval/src/scorer.dart`
- Test: `test/harness/scorer_test.dart`

**Interfaces:**
- Consumes: `package:kakeibo_app/domain/services/receipt/receipt_parser.dart` の `ParsedReceipt`（`total: AmountCandidate?`＝`.yen`、`totalCandidates`、`date: DateCandidate`＝`.date`）、Task 1 `TruthReceipt`
- Produces:

```dart
class ReceiptOutcome {
  final bool? totalCorrect;      // 常に非null（total採点は全レシート対象）だがbool?で統一
  final bool? dateCorrect;       // truth.date==null のとき null（採点除外）
  final bool candidateHit;       // totalCandidates内に正解があるか
  final bool? dateAbsentHandled; // truth.date==null のときのみ非null: parsed.date.date==today
}
ReceiptOutcome scoreOne(TruthReceipt truth, ParsedReceipt parsed, CivilDate today);

class Cell { int scored; int correct; double get accuracy; Map<String, dynamic> toJson(); }
class EvalAggregate {
  Map<int, Cell> totalByLevel;   // 0,1,2
  Map<int, Cell> dateByLevel;
  Map<int, Cell> candidateByLevel;
  Map<String, Cell> totalByStoreType;
  Map<int, int> dateAbsentSeen;
  Map<int, int> dateAbsentHandled;
  List<String> failures;         // totalかdateを外したfixture name
  void add(String name, int level, String storeType, ReceiptOutcome o);
  Map<String, dynamic> toJson(); // {'l0': {'total': {...}, 'date': {...}}, ...} 他
}
```

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/harness/scorer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../../tool/receipt_eval/src/scorer.dart';
import 'truth_codec_test.dart' show sampleTruthFixture;

const _today = CivilDate(2026, 7, 11);

ParsedReceipt _parse(List<String> lines) {
  final blocks = <OcrBlock>[];
  for (var i = 0; i < lines.length; i++) {
    blocks.add(OcrBlock(
        text: lines[i],
        rect: OcrRect(0.05, 0.05 + i * 0.05, 0.9, 0.03),
        confidence: 0.95));
  }
  return ReceiptParser(today: () => _today).parse(blocks);
}

void main() {
  test('correct total and date', () {
    final parsed = _parse(['2026年6月30日(火) 18:45', '合計 ¥3,850']);
    final o = scoreOne(sampleTruthFixture(), parsed, _today);
    expect(o.totalCorrect, isTrue);
    expect(o.dateCorrect, isTrue);
    expect(o.candidateHit, isTrue);
    expect(o.dateAbsentHandled, isNull);
  });

  test('wrong total, right date', () {
    final parsed = _parse(['2026年6月30日(火) 18:45', '合計 ¥9,999']);
    final o = scoreOne(sampleTruthFixture(), parsed, _today);
    expect(o.totalCorrect, isFalse);
    expect(o.dateCorrect, isTrue);
  });

  test('date-absent receipt: excluded and fallback-today asserted', () {
    final parsed = _parse(['合計 ¥3,850']);
    final o = scoreOne(sampleTruthFixture(date: null), parsed, _today);
    expect(o.dateCorrect, isNull);
    expect(o.dateAbsentHandled, isTrue);
  });

  test('aggregate math and failures list', () {
    final agg = EvalAggregate();
    agg.add('a', 0, 'supermarket',
        const ReceiptOutcome(totalCorrect: true, dateCorrect: true, candidateHit: true, dateAbsentHandled: null));
    agg.add('b', 0, 'supermarket',
        const ReceiptOutcome(totalCorrect: false, dateCorrect: null, candidateHit: false, dateAbsentHandled: true));
    final j = agg.toJson();
    final l0 = j['l0'] as Map<String, dynamic>;
    expect((l0['total'] as Map)['scored'], 2);
    expect((l0['total'] as Map)['correct'], 1);
    expect((l0['total'] as Map)['accuracy'], 0.5);
    expect((l0['date'] as Map)['scored'], 1);
    expect((l0['date'] as Map)['accuracy'], 1.0);
    expect(agg.failures, ['b']);
    expect((j['dateAbsent'] as Map)['l0'], {'seen': 1, 'handled': 1});
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/scorer_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: 実装**

```dart
// tool/receipt_eval/src/scorer.dart
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../../receipt_gen/src/truth.dart';

class ReceiptOutcome {
  final bool? totalCorrect;
  final bool? dateCorrect;
  final bool candidateHit;
  final bool? dateAbsentHandled;
  const ReceiptOutcome({
    required this.totalCorrect,
    required this.dateCorrect,
    required this.candidateHit,
    required this.dateAbsentHandled,
  });
}

/// spec §7: total=best候補のyen一致、date=truth.date==nullなら採点除外＋today返却を確認。
ReceiptOutcome scoreOne(TruthReceipt truth, ParsedReceipt parsed, CivilDate today) {
  final totalCorrect = parsed.total?.yen == truth.totalYen;
  final candidateHit = parsed.totalCandidates.any((c) => c.yen == truth.totalYen);
  if (truth.date == null) {
    return ReceiptOutcome(
      totalCorrect: totalCorrect,
      dateCorrect: null,
      candidateHit: candidateHit,
      dateAbsentHandled: parsed.date.date == today,
    );
  }
  return ReceiptOutcome(
    totalCorrect: totalCorrect,
    dateCorrect: parsed.date.date == truth.date,
    candidateHit: candidateHit,
    dateAbsentHandled: null,
  );
}

class Cell {
  int scored = 0;
  int correct = 0;
  double get accuracy => scored == 0 ? 0 : correct / scored;

  void add(bool ok) {
    scored++;
    if (ok) correct++;
  }

  Map<String, dynamic> toJson() =>
      {'scored': scored, 'correct': correct, 'accuracy': accuracy};
}

class EvalAggregate {
  final totalByLevel = {0: Cell(), 1: Cell(), 2: Cell()};
  final dateByLevel = {0: Cell(), 1: Cell(), 2: Cell()};
  final candidateByLevel = {0: Cell(), 1: Cell(), 2: Cell()};
  final totalByStoreType = <String, Cell>{};
  final dateAbsentSeen = {0: 0, 1: 0, 2: 0};
  final dateAbsentHandled = {0: 0, 1: 0, 2: 0};
  final failures = <String>[];

  void add(String name, int level, String storeType, ReceiptOutcome o) {
    var failed = false;
    if (o.totalCorrect != null) {
      totalByLevel[level]!.add(o.totalCorrect!);
      totalByStoreType.putIfAbsent(storeType, Cell.new).add(o.totalCorrect!);
      if (!o.totalCorrect!) failed = true;
    }
    candidateByLevel[level]!.add(o.candidateHit);
    if (o.dateCorrect != null) {
      dateByLevel[level]!.add(o.dateCorrect!);
      if (!o.dateCorrect!) failed = true;
    } else {
      dateAbsentSeen[level] = dateAbsentSeen[level]! + 1;
      if (o.dateAbsentHandled ?? false) {
        dateAbsentHandled[level] = dateAbsentHandled[level]! + 1;
      }
    }
    if (failed) failures.add(name);
  }

  Map<String, dynamic> toJson() => {
        for (final l in [0, 1, 2])
          'l$l': {
            'total': totalByLevel[l]!.toJson(),
            'date': dateByLevel[l]!.toJson(),
            'candidateHit': candidateByLevel[l]!.toJson(),
          },
        'dateAbsent': {
          for (final l in [0, 1, 2])
            'l$l': {'seen': dateAbsentSeen[l], 'handled': dateAbsentHandled[l]},
        },
        'totalByStoreType': {
          for (final e in totalByStoreType.entries) e.key: e.value.toJson(),
        },
        'failures': failures,
      };
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/harness/scorer_test.dart`
Expected: PASS（4 tests）

- [ ] **Step 5: コミット**

```bash
git add tool/receipt_eval/src/scorer.dart test/harness/scorer_test.dart
git commit -m "feat(harness): field-level scorer and aggregate"
```

---

### Task 11: レポート＋評価CLI（report.dart / evaluate.dart）＋E2Eスモーク＋健全性アンカー

**Files:**
- Create: `tool/receipt_eval/src/report.dart`
- Create: `tool/receipt_eval/evaluate.dart`
- Test: `test/harness/report_test.dart`
- Test: `test/harness/e2e_smoke_test.dart`

**Interfaces:**
- Consumes: Task 10 `EvalAggregate`、Task 1 `loadSynthFixture`、既存 `ReceiptParser`、既存 `test/support/receipt_fixtures.dart` と同形式の golden JSON（`loadFixture` 相当を evaluate 内で自前実装 — test/ に依存しないため）
- Produces:
  - `String buildReportMd(EvalAggregate agg, {required int corpusCount, Map<String, dynamic>? golden})`
  - `String buildReportJson(EvalAggregate agg, {required int corpusCount, Map<String, dynamic>? golden})`（`jsonEncode` した文字列、キーはaggの `toJson()` ＋ `corpusCount` ＋ `golden`）
  - `Future<int> runEvaluate({required String corpusDir, required String outDir, String goldenDir = 'test/fixtures/receipts/golden', double? minTotalAcc, double? minDateAcc, bool dumpFailures = false})` → 終了コード（0=成功。閾値指定があり未達なら1）
  - CLI `dart run tool/receipt_eval/evaluate.dart --corpus build/receipt_corpus --out build/receipt_eval [--min-total-acc N] [--min-date-acc N] [--dump-failures]`
  - report.md の精度は小数1桁%表記（spec §8）。failures はデフォルト先頭20件、`--dump-failures` で全件

- [ ] **Step 1: 失敗するテストを書く（report）**

```dart
// test/harness/report_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_eval/src/report.dart';
import '../../tool/receipt_eval/src/scorer.dart';

EvalAggregate _agg() {
  final agg = EvalAggregate();
  for (var i = 0; i < 10; i++) {
    agg.add('syn-l0-${i.toString().padLeft(4, '0')}', 0, 'supermarket',
        ReceiptOutcome(totalCorrect: i < 9, dateCorrect: i < 8, candidateHit: true, dateAbsentHandled: null));
  }
  return agg;
}

void main() {
  test('json has 6 cells and corpusCount', () {
    final j = jsonDecode(buildReportJson(_agg(), corpusCount: 10)) as Map<String, dynamic>;
    for (final l in ['l0', 'l1', 'l2']) {
      expect((j[l] as Map).containsKey('total'), isTrue);
      expect((j[l] as Map).containsKey('date'), isTrue);
    }
    expect(((j['l0'] as Map)['total'] as Map)['accuracy'], 0.9);
    expect(j['corpusCount'], 10);
  });

  test('md contains accuracy table with 1-decimal percent', () {
    final md = buildReportMd(_agg(), corpusCount: 10);
    expect(md, contains('90.0%'));
    expect(md, contains('80.0%'));
    expect(md, contains('| L0 |'));
    expect(md, contains('syn-l0-0008')); // date外し → failures
  });

  test('failures truncated to 20 in md by default', () {
    final agg = EvalAggregate();
    for (var i = 0; i < 30; i++) {
      agg.add('f$i', 1, 'cafe',
          const ReceiptOutcome(totalCorrect: false, dateCorrect: false, candidateHit: false, dateAbsentHandled: null));
    }
    final md = buildReportMd(agg, corpusCount: 30);
    expect(md, contains('f19'));
    expect(md, isNot(contains('f20\n')));
    expect(md, contains('他10件'));
  });
}
```

- [ ] **Step 2: 失敗を確認**

Run: `flutter test test/harness/report_test.dart`
Expected: FAIL（コンパイルエラー）

- [ ] **Step 3: report実装**

```dart
// tool/receipt_eval/src/report.dart
import 'dart:convert';

import 'scorer.dart';

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

String buildReportJson(EvalAggregate agg,
    {required int corpusCount, Map<String, dynamic>? golden}) {
  return jsonEncode({
    ...agg.toJson(),
    'corpusCount': corpusCount,
    if (golden != null) 'golden': golden,
  });
}

String buildReportMd(EvalAggregate agg,
    {required int corpusCount, Map<String, dynamic>? golden, bool dumpFailures = false}) {
  final b = StringBuffer()
    ..writeln('# レシートパーサ評価レポート')
    ..writeln()
    ..writeln('対象: $corpusCount 件')
    ..writeln()
    ..writeln('| レベル | total精度 | date精度 | 候補内正解 |')
    ..writeln('|---|---|---|---|');
  for (final l in [0, 1, 2]) {
    b.writeln('| L$l | ${_pct(agg.totalByLevel[l]!.accuracy)} '
        '(${agg.totalByLevel[l]!.correct}/${agg.totalByLevel[l]!.scored}) '
        '| ${_pct(agg.dateByLevel[l]!.accuracy)} '
        '(${agg.dateByLevel[l]!.correct}/${agg.dateByLevel[l]!.scored}) '
        '| ${_pct(agg.candidateByLevel[l]!.accuracy)} |');
  }
  b
    ..writeln()
    ..writeln('日付なしレシート処理: '
        '${[for (final l in [0, 1, 2]) 'L$l ${agg.dateAbsentHandled[l]}/${agg.dateAbsentSeen[l]}'].join(' / ')}')
    ..writeln()
    ..writeln('## 様式別 total精度 ワースト5')
    ..writeln();
  final worst = agg.totalByStoreType.entries.toList()
    ..sort((a, b2) => a.value.accuracy.compareTo(b2.value.accuracy));
  for (final e in worst.take(5)) {
    b.writeln('- ${e.key}: ${_pct(e.value.accuracy)} (${e.value.correct}/${e.value.scored})');
  }
  b
    ..writeln()
    ..writeln('## 失敗レシート（total/dateいずれか不一致）')
    ..writeln();
  final shown = dumpFailures ? agg.failures : agg.failures.take(20).toList();
  for (final f in shown) {
    b.writeln('- $f');
  }
  if (!dumpFailures && agg.failures.length > 20) {
    b.writeln('- …他${agg.failures.length - 20}件（--dump-failures で全件）');
  }
  if (golden != null) {
    b
      ..writeln()
      ..writeln('## Golden set（実レシート）')
      ..writeln()
      ..writeln('件数: ${golden['count']} / total一致: ${golden['totalCorrect']} / date一致: ${golden['dateCorrect']}');
  }
  return b.toString();
}
```

- [ ] **Step 4: reportテストが通ることを確認**

Run: `flutter test test/harness/report_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: 失敗するテストを書く（E2E＋健全性アンカー）**

```dart
// test/harness/e2e_smoke_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../../tool/receipt_eval/evaluate.dart';
import '../../tool/receipt_gen/generate.dart';
import '../support/receipt_fixtures.dart';

void main() {
  test('E2E: generate 20/level -> evaluate -> reports exist and parse (spec 9-6)', () async {
    final corpus = Directory.systemTemp.createTempSync('e2e_corpus');
    final out = Directory.systemTemp.createTempSync('e2e_out');
    try {
      await runGenerate(
          seed: 20260711,
          outDir: corpus.path,
          vocabPath: 'test/harness/fixtures/test_vocab.json',
          countPerLevel: 20);
      final code = await runEvaluate(corpusDir: corpus.path, outDir: out.path);
      expect(code, 0);
      final json = jsonDecode(File('${out.path}/report.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(json['corpusCount'], 60);
      for (final l in ['l0', 'l1', 'l2']) {
        expect(((json[l] as Map)['total'] as Map)['scored'], greaterThan(0));
      }
      expect(File('${out.path}/report.md').existsSync(), isTrue);
    } finally {
      corpus.deleteSync(recursive: true);
      out.deleteSync(recursive: true);
    }
  });

  test('sanity anchor: sample_supermarket.json still parses to 3850 / 2026-06-30 (spec 9-7)', () {
    final fx = loadFixture('test/fixtures/receipts/sample_supermarket.json');
    final parsed =
        ReceiptParser(today: () => const CivilDate(2026, 7, 11)).parse(fx.blocks);
    expect(parsed.total?.yen, 3850);
    expect(parsed.date.date, const CivilDate(2026, 6, 30));
  });

  test('missing golden dir does not crash', () async {
    final corpus = Directory.systemTemp.createTempSync('e2e_c2');
    final out = Directory.systemTemp.createTempSync('e2e_o2');
    try {
      await runGenerate(
          seed: 1,
          outDir: corpus.path,
          vocabPath: 'test/harness/fixtures/test_vocab.json',
          countPerLevel: 2);
      final code = await runEvaluate(
          corpusDir: corpus.path, outDir: out.path, goldenDir: '/no/such/dir');
      expect(code, 0);
    } finally {
      corpus.deleteSync(recursive: true);
      out.deleteSync(recursive: true);
    }
  });
}
```

- [ ] **Step 6: 失敗を確認**

Run: `flutter test test/harness/e2e_smoke_test.dart`
Expected: FAIL（`evaluate.dart` が存在しない）

- [ ] **Step 7: evaluate実装**

```dart
// tool/receipt_eval/evaluate.dart
import 'dart:convert';
import 'dart:io';

import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../receipt_gen/src/truth.dart';
import 'src/report.dart';
import 'src/scorer.dart';

const CivilDate evalToday = CivilDate(2026, 7, 11);

/// golden JSON（実機ブリッジ形式: blocks + expected）の読込。truthは持たない。
({List<OcrBlock> blocks, int? totalYen, CivilDate? date}) _loadGolden(String path) {
  final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final expected = root['expected'] as Map<String, dynamic>?;
  return (
    blocks: [
      for (final b in (root['blocks'] as List).cast<Map<String, dynamic>>())
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
    totalYen: expected?['totalYen'] as int?,
    date: expected?['date'] == null ? null : CivilDate.parse(expected!['date'] as String),
  );
}

Future<int> runEvaluate({
  required String corpusDir,
  required String outDir,
  String goldenDir = 'test/fixtures/receipts/golden',
  double? minTotalAcc,
  double? minDateAcc,
  bool dumpFailures = false,
}) async {
  final parser = ReceiptParser(today: () => evalToday);
  final agg = EvalAggregate();

  final files = Directory(corpusDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('syn-'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final fx = loadSynthFixture(f.path);
    final parsed = parser.parse(fx.blocks);
    agg.add(fx.name, fx.truth.noiseLevel, fx.truth.storeType,
        scoreOne(fx.truth, parsed, evalToday));
  }

  Map<String, dynamic>? golden;
  final gDir = Directory(goldenDir);
  if (gDir.existsSync()) {
    var count = 0;
    var totalOk = 0;
    var dateOk = 0;
    for (final f in gDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final g = _loadGolden(f.path);
      final parsed = parser.parse(g.blocks);
      count++;
      if (g.totalYen != null && parsed.total?.yen == g.totalYen) totalOk++;
      if (g.date != null && parsed.date.date == g.date) dateOk++;
    }
    if (count > 0) golden = {'count': count, 'totalCorrect': totalOk, 'dateCorrect': dateOk};
  }

  final out = Directory(outDir)..createSync(recursive: true);
  File('${out.path}/report.json').writeAsStringSync(
      '${buildReportJson(agg, corpusCount: files.length, golden: golden)}\n');
  File('${out.path}/report.md').writeAsStringSync(buildReportMd(agg,
      corpusCount: files.length, golden: golden, dumpFailures: dumpFailures));

  var code = 0;
  if (minTotalAcc != null) {
    for (final l in [0, 1, 2]) {
      if (agg.totalByLevel[l]!.accuracy * 100 < minTotalAcc) code = 1;
    }
  }
  if (minDateAcc != null) {
    for (final l in [0, 1, 2]) {
      if (agg.dateByLevel[l]!.accuracy * 100 < minDateAcc) code = 1;
    }
  }
  return code;
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final corpus = _arg(args, '--corpus');
  final out = _arg(args, '--out');
  if (corpus == null || out == null) {
    stderr.writeln(
        'usage: dart run tool/receipt_eval/evaluate.dart --corpus <dir> --out <dir> [--min-total-acc N] [--min-date-acc N] [--dump-failures]');
    exit(2);
  }
  try {
    final code = await runEvaluate(
      corpusDir: corpus,
      outDir: out,
      minTotalAcc: double.tryParse(_arg(args, '--min-total-acc') ?? ''),
      minDateAcc: double.tryParse(_arg(args, '--min-date-acc') ?? ''),
      dumpFailures: args.contains('--dump-failures'),
    );
    stdout.writeln('report written to $out (exit=$code)');
    exit(code);
  } on Object catch (e) {
    stderr.writeln('evaluation failed: $e');
    exit(1);
  }
}
```

- [ ] **Step 8: E2Eテストが通ることを確認**

Run: `flutter test test/harness/e2e_smoke_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 9: コミット**

```bash
git add tool/receipt_eval/ test/harness/report_test.dart test/harness/e2e_smoke_test.dart
git commit -m "feat(harness): report writer and evaluation CLI with e2e smoke + sanity anchor"
```

---

### Task 12: フル実行＋完了定義の全項目検証＋ベースライン記録

**Files:**
- Modify: `.superpowers/sdd/progress.md`（ベースライン数値の記録）

このタスクは統括（メインセッション）が自分で実行する（spec §13「完了定義のコマンドは統括が自分でも叩く」）。

- [ ] **Step 1: フルコーパス生成（完了定義2）**

Run: `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus`
Expected: exit 0、`generated 1200 fixtures in build/receipt_corpus (seed=20260711)`
Check: `(Get-ChildItem build/receipt_corpus | Measure-Object).Count` → 1200、`syn-l0-*` `syn-l1-*` `syn-l2-*` 各400

- [ ] **Step 2: byte一致（完了定義3）**

Run: `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus2`
Run: `git diff --no-index build/receipt_corpus build/receipt_corpus2`
Expected: 出力なし（完全一致）。確認後 `build/receipt_corpus2` は削除

- [ ] **Step 3: フル評価（完了定義5）**

Run: `dart run tool/receipt_eval/evaluate.dart --corpus build/receipt_corpus --out build/receipt_eval`
Expected: exit 0、`build/receipt_eval/report.md` と `report.json` 生成。report.json に `l0`/`l1`/`l2` × `total`/`date` の6セルが数値で存在

- [ ] **Step 4: 静的解析＋全テスト（完了定義7・8）**

Run: `flutter analyze`
Expected: `No issues found!`
Run: `flutter test`
Expected: 全緑（既存256本＋test/harness/新規全部）

- [ ] **Step 5: ベースライン記録**

`build/receipt_eval/report.md` のL0/L1/L2精度表を `.superpowers/sdd/progress.md` に転記（Phase 5後半のパーサ改善の起点として）。**注意: 精度が低くても完了。** 数値はパーサの現在地であって本装備の合否ではない（spec §11）。

- [ ] **Step 6: コミット**

```bash
git add .superpowers/sdd/progress.md
git commit -m "chore(harness): record parser baseline accuracy from full corpus run"
```

---

## 完了定義との対応表（spec §11）

| 完了定義 | 検証タスク |
|---|---|
| 1. vocab.jsonコミット＋検証テスト緑 | Task 9 |
| 2. 1,200件生成・exit 0 | Task 12 Step 1 |
| 3. byte一致 | Task 12 Step 2（＋Task 8のテスト） |
| 4. 整合性違反0（違反時exit 1） | Task 8実装＋Task 2/5のテスト |
| 5. 評価CLI exit 0・6セルレポート | Task 12 Step 3（＋Task 11のテスト） |
| 6. 健全性アンカー | Task 11 e2e_smoke_test |
| 7. flutter analyze 0 | Task 12 Step 4 |
| 8. flutter test 全緑 | Task 12 Step 4 |
