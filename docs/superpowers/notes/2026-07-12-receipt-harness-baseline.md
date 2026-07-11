# レシート検証装備 完成＋パーサ精度ベースライン（2026-07-12）

spec: `docs/superpowers/specs/2026-07-11-receipt-eval-harness-design.md` / plan: `docs/superpowers/plans/2026-07-11-receipt-eval-harness.md`
完了定義8項目すべて機械検証済み。全296テスト緑（既存256＋ハーネス40）・analyze 0。

## ベースライン（seed=20260711、合成1,200件、評価today=2026-07-11固定）

| レベル | total精度 | date精度 | 候補内正解 |
|---|---|---|---|
| L0（ノイズなし） | **100.0%** (400/400) | **100.0%** (381/381) | 100.0% |
| L1（軽ノイズ） | 97.0% (388/400) | 95.7% (376/393) | 97.0% |
| L2（重ノイズ） | 91.5% (366/400) | 87.5% (335/383) | 92.0% |

- 日付なしレシートのフォールバック処理: 43/43 正常
- 様式別totalワースト: homecenter 95.0% / convenience 95.6% / cafe 95.7%
- 再現コマンド: `dart run tool/receipt_gen/generate.dart --seed 20260711 --out build/receipt_corpus` → `dart run tool/receipt_eval/evaluate.dart --corpus build/receipt_corpus --out build/receipt_eval`

## 読み方（Phase 5後半の改善指針）

- **L0=100%はクリーン入力に対して既存パーサが完成済みという証左。** 改善対象はノイズ耐性のみ（¥落ち・行結合・文字置換0→O/1→I）
- ノイズ率は実測なしの仮置き（spec §5）。TestFlight後に実レシート15枚をgolden set（`test/fixtures/receipts/golden/*.json`、置くだけで評価に自動合流）としてVision実誤りと突き合わせ、率を再校正してから精度目標を立てること
- 語彙（vocab.json）に縮退エントリあり（drugstore/bookstore中心）。合計/日付の測定には無害だが、**Phase 6のカテゴリ推定に使う前に品質フィルタ必須**

## 実行中の裁定記録（planからの逸脱、いずれも統括承認済み）

1. 混在税率は内税時のみ（spec §5の税3種に一致、plan決定表を明確化）
2. 時刻はゼロ埋めなしH:MM（spec表記を修正）
3. 語彙生成CLIをチャンク方式に変更（100語/リクエスト×様式ごと130語到達まで最大4回・タイムアウト300s）— qwen3:14bの歩留まり不足と120sタイムアウト死への対処。**教訓: ローカルLLMは要求個数を返さない前提で追い炊き設計にする**
4. `'golden': ?golden`（lint起因の等価書換）
