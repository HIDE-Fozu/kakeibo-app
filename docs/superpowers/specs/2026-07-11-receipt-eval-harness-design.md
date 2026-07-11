# 検証装備設計書: 合成レシートコーパス＋評価ハーネス

日付: 2026-07-11 / 対象: kakeibo-app / 自走単位: 本書1本（縦切り）
関連: `docs/phase5-mac-runbook.md`（Phase 5後半「実レシート15枚でパーサ再調整」の機械化が本書の目的）、`docs/superpowers/specs/2026-07-03-kakeibo-app-design.md` §7、`docs/superpowers/research/apple-vision-ocr.md`

## 0. 目的と位置づけ

既存の純Dartレシートパーサ（`lib/domain/services/receipt/`）の精度を、人間の手動確認なしに測定できる装備を作る。runbookが予定する「実レシート15枚で手動再調整」を、**1,200件の合成コーパスに対するフィールド別精度の回帰レポート**に置き換える。

本書のスコープは**装備の完成**であり、パーサ精度の改善ではない。精度改善はPhase 5後半（Vision実装時）の仕事で、本装備はその採点者になる。よって完了定義に精度閾値は含めない（§11-6の健全性アンカーを除く）。

構造原則: **LLM（Ollama）は数字に一切触れない。** 金額・日付・整合性はすべて決定的コードが生成する。LLMの役割は品目名・店名の語彙生成（一度きり・成果物コミット）のみ。これは「LLM生成データの数字不整合」という欠陥クラスを検出でなく構造で殺すための規約。

## 1. スコープ表

| 入るもの | 入らないもの（対） |
|---|---|
| 合成レシート生成CLI（真値＋OcrBlock列） | 実レシート画像の生成（画像は扱わない。正準空間のみ） |
| 品目レベルの真値スキーマ（v2/B2B布石） | 品目抽出の採点（パーサ未実装のため） |
| 合計・日付の2フィールド採点 | 店名採点（パーサ未実装。真値には保持） |
| ノイズ注入L0/L1/L2（決定的） | Vision実測誤り率での校正（golden set取得後の別作業） |
| Ollamaによる語彙生成＋コミット | カテゴリ推定データセット（Phase 6の別スペック） |
| golden set読込枠（0枚でも動く） | golden set収集そのもの（TestFlight後） |
| レポート出力（md＋json） | CI組込・閾値ゲート有効化（フラグだけ用意） |
| — | アプリ本体のコード・DBスキーマ・UIの変更一切 |
| — | 英語レシート・手書き領収書・Android |

## 2. 操作フロー（オペレータ視点の状態遷移）

```
[語彙なし] --(A: vocab生成・一度だけ)--> [vocab.jsonコミット済み]
[vocab.jsonコミット済み] --(B: コーパス生成)--> [build/receipt_corpus/ 1,200件]
[コーパスあり] --(C: 評価)--> [build/receipt_eval/report.{md,json}]
[コーパスあり] --(B再実行)--> [byte一致（決定性の検証を兼ねる）]
```

- A: `dart run tool/receipt_vocab/generate_vocab.dart --model qwen3:14b`（要 `ollama pull qwen3:14b`・Ollama常駐。**再実行不要**: 決定性はコミット済みvocab.jsonが担保）
- B: `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus`
- C: `dart run tool/receipt_eval/evaluate.dart --corpus build/receipt_corpus --out build/receipt_eval`
- キャンセル経路: いずれも途中終了してよい（出力は毎回全消去→再生成。中間状態を持たない）

## 3. アーキテクチャ

```
tool/
  receipt_vocab/generate_vocab.dart   … Ollama REST(localhost:11434 /api/chat, format=json schema)を叩く薄いCLI
  receipt_gen/
    data/vocab.json                   … コミットされる語彙（LLM成果物。数字を含む語は検証で拒否）
    generate.dart                     … CLIシェル（薄い）
    src/sampler.dart                  … 真値サンプラ（純Dart・シード付きRandom）
    src/renderer.dart                 … 真値→OcrBlock列レンダラ（純Dart・決定的）
    src/noise.dart                    … ノイズ注入（純Dart・決定的）
    src/validate.dart                 … 整合性バリデータ
  receipt_eval/
    evaluate.dart                     … CLIシェル（薄い）
    src/scorer.dart                   … 採点（純Dart）
    src/report.dart                   … md/json出力
test/harness/                         … 上記src/の単体テスト＋E2Eスモーク
```

- 依存規律: `tool/` は `lib/domain/`（純Dart部分: `ocr_types.dart`, `receipt/*`, `civil_date.dart`）のみをimportする。Flutter・driftをimportしない（`dart run`で動くことの構造保証。`dart run build_runner`と同じ動作形態）。
- 既存コードの変更: **なし**。`test/support/receipt_fixtures.dart` の `loadFixture` は変更せず、拡張フィールドを読む `loadFixtureV2` をtool側に持つ。

## 4. データ契約

### 4-1. フィクスチャJSON（既存形式の互換拡張）

既存の `{name, blocks[], expected{totalYen,date}}` をそのまま維持し、`truth` を追加する。既存 `loadFixture` は `truth` を読まないので後方互換。`expected` は `truth` から導出して両方書く（単一情報源はtruth）。

```json
{
  "name": "syn-000123",
  "blocks": [{"text": "...", "x": 0.05, "y": 0.05, "w": 0.9, "h": 0.03, "confidence": 0.96}],
  "expected": {"totalYen": 3850, "date": "2026-06-30"},
  "truth": {
    "storeName": "フレッシュたなか青果",
    "storeType": "supermarket",
    "date": "2026-06-30",
    "items": [{"name": "国産豚小間切れ", "unitPriceYen": 1950, "qty": 2, "amountYen": 3900, "taxRate": 8}],
    "discounts": [{"label": "割引", "amountYen": 50}],
    "taxMode": "inclusive",
    "taxLines": [{"rate": 8, "taxYen": 285}],
    "totalYen": 3850,
    "tenderedYen": 5000,
    "changeYen": 1150,
    "style": {"dateFormat": "kanji", "totalKeyword": "合計", "currencyMark": "yen"},
    "noiseLevel": 1
  }
}
```

### 4-2. 整合性規則（バリデータが全件アサート、違反1件でも生成CLIはexit 1）

1. 内税: `totalYen == Σitems.amountYen − Σdiscounts.amountYen`／外税: `totalYen == Σitems.amountYen − Σdiscounts.amountYen + Σtax`。税は割引前の税率別品目計に対し切り捨て（内税: `base×r÷(100+r)`、外税: `base×r÷100`）。根拠: 割引は会計時値引き扱いで統一し実装・検証を単純化（印字慣例は店により異なるため一方に固定）
2. `items[i].amountYen == unitPriceYen × qty`
3. `changeYen == tenderedYen − totalYen`（両方ある場合）
4. `discounts合計 < 小計`（負の合計を構造的に排除）
5. L0（ノイズなし）では、`totalYen`のカンマ区切り文字列と`expected.date`に対応する日付文字列が blocks 本文に必ず出現する（レンダラ含有性）
6. `expected` は `truth` からの導出値と一致する

## 5. 生成設計（決定表）

すべてシード付き `Random(20260711)` から決定的に導出する。シード値は本日日付由来で意味はない（再現性のためだけに固定）。

| 軸 | 決定 | 根拠 |
|---|---|---|
| 店様式 | 8種: スーパー／コンビニ／ドラッグストア／飲食店／カフェ／ホームセンター／書店／ガソリンスタンド | 家計簿の主要支出先。様式＝テンプレートコード（LLM不使用） |
| 店名 | vocab.jsonの架空店名。実在チェーンNGリスト（コード内に主要20社）と部分一致で照合し除外 | 実在名の混入回避 |
| 日付形式 | 5種: `2026年6月30日(火)`／`2026/06/30`／`26.06.30`／`R8.06.30`／`令和8年6月30日` | 年省略・元号は日付抽出の主戦場 |
| 日付範囲 | 2025-07-12〜2026-07-11 の一様分布 | 評価時の固定today（§7）から過去1年。年省略形式が今日基準で一意に解決できる範囲 |
| 日付なし | 各ノイズレベルの5% | 実在するケース。採点から除外し件数報告のみ（§7） |
| 時刻 | 日付行に常に併記（時はゼロ埋めなし `H:MM`、分は2桁。8:00〜22:59） | 実レシートは時刻併記が通例で、パーサも時刻同居を最強の取引手がかりとして使う（時刻正規表現は`\d{1,2}`で単桁対応） |
| 合計キーワード | 5種: 合計／お買上げ計／合　計／総合計／お会計 | 実レシートの表記揺れ |
| 通貨表記 | 4種: `¥`／`￥`／なし／`円`後置 | 既存摂動`dropCurrencyMarks`の一般化 |
| 税 | 3種: 内税10%のみ／内税8+10混在（8%品に`※`、スーパー・ドラッグストアのみ）／外税 | 軽減税率とその印字 |
| 品目数 | 確率2/3で1〜8、確率1/3で9〜25（各範囲内は一様）。上限25は固定 | 実分布近似。「無制限」にしない |
| ファイル名 | `syn-l{0,1,2}-{0001..0400}.json`（例 `syn-l1-0237.json`） | レベル別件数の機械検査を単純化 |
| 単価 | 8〜9,980円 | 下限=最安売価の現実値、上限=家計簿レシートの現実域 |
| 個数表記 | スーパー様式のみ「2コX128」形式を品目の10%に付与。他様式は常に1行1品 | 様式差の代表1種に限定（v1） |
| 割引行 | レシートの20%に1行（小計の5〜30%、規則4でクランプ) | totalトラップ |
| お預り/お釣り | 50%に付与（お預り≧合計を保証） | 合計より大きい金額トラップ（既存fixtureと同型） |
| ポイント行 | 30%に付与（`ポイント残高 12,340P`型） | 大きな数字のトラップ |
| 電話/登録番号行 | 60%／40%に付与 | 数字トラップ |
| 座標系 | x: ラベル0.05起点・金額右寄せ右端0.95、y: `0.03 + i×(0.94/総行数)`、h: 行ピッチ×0.8、confidence: 0.90〜0.98一様 | 正準空間は画像全体0..1のため長いレシートほど行間が詰まる（実写真と同じ性質）。スケールは既存`sample_supermarket.json`準拠 |
| 件数 | L0/L1/L2 各400、計1,200 | 様式8×日付5×合計5×通貨4=800セルの主要組合せを踏む規模。純Dartで数秒 |

### ノイズ注入（決定的・ブロック単位）

| 操作 | L0 | L1 | L2 | 根拠 |
|---|---|---|---|---|
| 文字置換 `0→O` `1→I` `ー→一`（数字・長音の出現箇所ごと） | 0% | 2% | 5% | 既存`confuseZeros`の一般化 |
| ブロック分割（1ブロック→文字境界で2分割、rectも分割） | 0% | 3% | 8% | Visionの行分断の模擬 |
| 行結合（`mergeRowBlocks`をレシート単位で適用） | 0% | 0% | 30%のレシート | 既存摂動の流用 |
| `¥/￥`落ち（レシート単位） | 0% | 10% | 25% | 既存`dropCurrencyMarks` |
| 合計キーワード落ち（レシート単位） | 0% | 0% | 10% | 既存`dropTotalKeyword`（太字OCR落ち） |

率は実測値のない段階の仮置き。**golden set（実レシート15枚）取得後にVisionの実誤りと突き合わせて再校正する**（その作業はPhase 5後半のスコープ）。ノイズで空文字になったブロックは除去する（実OCRは空ブロックを返さないため）。

## 6. 語彙生成（Ollamaの役割と規律）

- モデル: `qwen3:14b` 固定。根拠: 語彙の多様性生成は推論負荷が低く14Bで足りる。生成は一度きりで再現性はコミット済みJSONが担保するため、モデル更新に追従する必要もない。
- 生成内容: 品目名（店様式別×カテゴリ別、計1,000語以上）、架空店名（様式別、計80以上）。
- プロンプト規律: 数字・価格を含めない指示。出力は `format`=JSONスキーマ強制。
- バリデーション（生成CLIが実施、違反はexit 1）: 数字を含む語の拒否／重複除去／様式ごと品目50語以上・店名10以上／NGリスト照合。
- 成果物 `tool/receipt_gen/data/vocab.json` はgitコミットする。以後の全工程はOllama不要。

## 7. 評価設計

- パーサ呼び出し: `ReceiptParser(today: () => CivilDate(2026, 7, 11))` 固定注入（決定性）。
- 採点（レシートごと）:
  - total: `parsed.total?.yen == truth.totalYen`（`AmountCandidate.yen`。best候補のみ。候補リスト内正解は参考値として別集計）
  - date: `parsed.date.date == truth.date`（`ParsedReceipt.date`は`DateCandidate`型。`truth.date == null` のレシートは採点除外・「日付なし処理数」として計上。クラッシュせずtoday返却をアサート）
- レポート: `build/receipt_eval/report.md`（人間用）＋`report.json`（機械用）。内容: ノイズレベル×フィールドの精度表（6セル）／様式別ワースト5／失敗レシートID一覧（先頭20件、`--dump-failures`で全件）。
- golden set: `test/fixtures/receipts/golden/*.json`（実機ブリッジと同形式）が存在すれば読み込み別表で報告。0枚でも正常動作。
- 終了コード: 実行成功=0。精度では失敗させない（改善はPhase 5後半の仕事）。`--min-total-acc <pct>` `--min-date-acc <pct>` フラグは実装するがデフォルト無効（将来のCIゲート用）。

## 8. 判断保留ゼロ集（追加分）

| 状況 | 決定 |
|---|---|
| `build/receipt_corpus` が既存 | 生成CLIが**無条件で全削除→再生成**（中間状態を持たない） |
| Ollama未起動でvocab生成実行 | 接続エラーを明示してexit 1（リトライしない） |
| vocab.jsonが無い状態でコーパス生成 | exit 1「先にvocab生成」（自動でOllamaを叩かない） |
| 品目数が上限25を超えるサンプル | サンプラが25にクランプ（エラーにしない） |
| ノイズが日付行・合計行に当たる | そのまま採点対象（実機でも起こるため除外しない） |
| 乱数の消費順 | サンプラ→レンダラ→ノイズの順に単一Randomを引き回す（分割しない。順序が仕様） |
| 出力エンコーディング | UTF-8（BOMなし）、改行LF |
| レポートの数値表記 | 精度は小数1桁%（例 97.3%）。四捨五入 |
| 既存256テストへの影響 | ゼロであること（既存ファイル無変更が担保）。新規テストは追加のみ |

> 表にない判断が実装中に出たら、それは設計漏れ＝台帳（`.superpowers/sdd/progress.md`）に記録して統括が裁定する。**ユーザーを止めない。**

## 9. 検証装備（このハーネス自体の。過去バグ逆算）

殺す欠陥クラス: ①LLM生成データの数字不整合（→LLMを数字から構造的に隔離）②フィクスチャ過学習（→1,200件の様式網羅）③非決定テスト（→シード固定・時計注入・LLM成果物のコミット化）。

すべて決定的アサート（ガイドのドメイン表どおり、CLI領域にスクショ判定は不要）:

1. サンプラ整合性: 生成1,000サンプルで§4-2規則1〜4を全件アサート
2. レンダラ含有性: L0でtotal文字列・日付文字列が本文に出現（規則5）
3. 決定性: 同シード2回生成でJSON文字列完全一致（20件スモーク）
4. ノイズ決定性: 同入力・同シードで同出力
5. スコアラ既知例: 手書きの正解/不正解ケースで精度計算が正しい（分母・除外処理含む）
6. E2Eスモーク: N=20生成→評価→report.json存在・スキーマ妥当
7. 健全性アンカー: 既存`sample_supermarket.json`をevalに通し total=3850・date=2026-06-30 一致（既存パーサテストと同値であること）

## 10. テスト一覧

| ファイル | 種別 | 内容 |
|---|---|---|
| `test/harness/sampler_test.dart` | unit | §9-1 |
| `test/harness/renderer_test.dart` | unit | §9-2 |
| `test/harness/determinism_test.dart` | unit | §9-3, 9-4 |
| `test/harness/scorer_test.dart` | unit | §9-5 |
| `test/harness/e2e_smoke_test.dart` | 統合 | §9-6, 9-7 |
| `test/harness/vocab_validate_test.dart` | unit | vocab.jsonの検証規則（§6） |

既存テストの改修許可範囲: **なし**（既存ファイルは一切触らない）。

## 11. 完了定義（すべて機械判定）

1. `tool/receipt_gen/data/vocab.json` がコミット済みで、`flutter test test/harness/vocab_validate_test.dart` 緑
2. `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus` がexit 0、`build/receipt_corpus/` にJSONちょうど1,200件（L0/L1/L2各400、ファイル名で判別可能）
3. 同コマンド再実行後 `git diff --no-index` 相当の比較で全ファイルbyte一致
4. 生成時整合性バリデーション違反0（違反時exit 1の動作は§9-1テストで担保）
5. `dart run tool/receipt_eval/evaluate.dart --corpus build/receipt_corpus --out build/receipt_eval` がexit 0、`report.md`・`report.json` が生成され、json内に `l0.total.accuracy` 等6セルの数値が存在
6. 健全性アンカー（§9-7）pass
7. `flutter analyze` 0 issues
8. `flutter test` 全緑（既存256本＋`test/harness/`新規全部）

精度の目標値は完了定義に**含めない**。report.jsonのL0精度がPhase 5後半の改善ベースラインになる。

## 12. 操作まとめ（受入用）

| やること | コマンド | 期待 |
|---|---|---|
| （初回のみ）モデル取得 | `ollama pull qwen3:14b` | 約9GB取得 |
| （初回のみ）語彙生成 | `dart run tool/receipt_vocab/generate_vocab.dart --model qwen3:14b` | vocab.json更新 |
| コーパス生成 | `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus` | 1,200件・数秒 |
| 評価 | `dart run tool/receipt_eval/evaluate.dart --corpus build/receipt_corpus --out build/receipt_eval` | report.md/json |
| 全テスト | `flutter analyze` → `flutter test` | 0 issues／全緑 |

## 13. サブエージェント分業（モデル配分）

| 区間 | モデル | 備考 |
|---|---|---|
| 実装（sampler/renderer/noise/scorer/CLI） | **Sonnet** | 定型実装。TDD（テスト先行） |
| vocab生成プロンプトの作成・実行 | **Sonnet** | 定型。実行はローカルOllama |
| コードレビュー | **Sonnet＋Opus 二重** | 独立視点 |
| 統括・完了定義の最終確認 | 統括（本セッション） | 完了定義コマンドを統括自身も叩く |

台帳: `.superpowers/sdd/progress.md`。区間ごとに状態を記録し、コンパクト後も再開可能に保つ。50万トークン到達時は状態を.mdへダンプしてからコンパクト。
