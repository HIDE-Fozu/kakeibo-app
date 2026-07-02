Note: This task is squarely in my domain knowledge (Japanese receipts, OCR post-processing, regex, Dart) and connects to your Kakeibo receipt-OCR project. I'm returning a complete, implementation-ready spec directly rather than doing redundant web searches — the value here is concrete rules grounded in how Japanese thermal receipts actually print, not citations.

---

# Japanese Receipt Parser — TOTAL & DATE Extraction Spec (pure-Dart)

Input model assumed: `List<Block>` where `Block = { String text; Rect rect; }` and `Rect = { double x, y, w, h; }` (x,y = top-left, origin top-left, y grows downward — Apple Vision reports bottom-left normalized, so **normalize to top-left pixel space first**).

Pipeline order: **Normalize text → reconstruct rows from bboxes → detect DATE → detect TOTAL (keyword+row) → fallback TOTAL → cross-validate.**

---

## 0. Text normalization (do this FIRST, pure-Dart, no NFKC dependency)

`dart:core` has no NFKC. Do an explicit char map so `\d` (ASCII-only in Dart) works and currency/era markers are canonical. Apply per-block before any regex.

| From | To | Notes |
|---|---|---|
| `０-９` (U+FF10–FF19) | `0-9` | full-width digits |
| `，` (FF0C) `、`(rare) | `,` | grouping comma |
| `．`(FF0E) `。`(rare) | `.` | decimal/date dot |
| `：`(FF1A) | `:` | time |
| `／`(FF0F) | `/` | date sep |
| `￥`(FFE5) | `¥` | full-width yen |
| `　`(U+3000) | ` ` | full-width space |
| `－`(FF0D) `‐`(2010) `‑`(2011) `–`(2013) `—`(2014) `ー`(30FC, katakana chōon) `−`(2212) | `-` | **all dashes→hyphen** (thermal printers mix these) |
| `Ａ-Ｚ ａ-ｚ` (FF21–FF5A) | `A-Z a-z` | for `R/H/S`, `No`, `TEL` |
| `％`(FF05) | `%` | tax rate |
| `〜`(301C) `～`(FF5E) | `~` | ranges |

Keep negative markers `▲ △` as-is (they are distinct glyphs, not in the map) — handle them in the amount parser. Also collapse internal spaces inside a number token: OCR often splits `¥ 1, 234`.

```dart
String normalize(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xFF10 && r <= 0xFF19) { sb.writeCharCode(r - 0xFEE0); continue; } // digits
    if (r >= 0xFF21 && r <= 0xFF5A) { sb.writeCharCode(r - 0xFEE0); continue; } // A-z
    switch (r) {
      case 0xFF0C: sb.write(','); break;
      case 0xFF0E: sb.write('.'); break;
      case 0xFF1A: sb.write(':'); break;
      case 0xFF0F: sb.write('/'); break;
      case 0xFFE5: sb.write('¥'); break;
      case 0x3000: sb.write(' '); break;
      case 0xFF05: sb.write('%'); break;
      case 0xFF0D: case 0x2010: case 0x2011: case 0x2013:
      case 0x2014: case 0x30FC: case 0x2212: sb.write('-'); break;
      default: sb.writeCharCode(r);
    }
  }
  return sb.toString();
}
```

---

## 1. Row reconstruction from bounding boxes

Receipts are two-column (label left, amount right-aligned). Vision usually returns one block per visual line, but sometimes label and amount are **separate blocks on the same physical row**. Rebuild rows:

**Rules**
1. `lineH = median(block.h)`. Tolerance `τ = 0.6 * lineH`.
2. Two blocks are **same row** if `|centerY_a − centerY_b| ≤ τ` **and** they vertically overlap (`overlap = min(bottom) − max(top) > 0`).
3. Cluster blocks into rows (union-find or sort-by-centerY + greedy). Within a row, sort by `x` ascending. The **rightmost** block is the amount candidate.
4. Build `rowText = blocks.map(text).join(' ')` for keyword matching, but keep per-block rects so you can pick the right-aligned number precisely.

**Same-row right-aligned amount selection** (given a keyword at block K):
- Candidates = amount-bearing blocks B in K's row with `B.x + B.w ≥ K.x + K.w` (to the right of / overlapping-right of the keyword). Pick `argmax(B.x + B.w)` (furthest right).
- If keyword and number are in the **same block** (`"合計 ¥3,850"`), split within-block via the amount regex — take the last amount match in that block.
- If no number in K's row (label wrapped), check the **next row down** (`centerY` just below, x on the right side).

---

## 2. Amount tokenization (regex, tiered by confidence)

Run on normalized text. Use tiers — higher tier = safer, less context needed.

```dart
// value core: 1-3 digits, optional thousands groups; OR a bare run of 1-7 digits
const _grp = r'\d{1,3}(?:,\d{3})+';        // must have at least one comma group
const _bare = r'\d{1,7}';                   // no comma
const _neg  = r'[-▲△]?';                    // discount / change-minus markers
```

**Tier A — currency-anchored (high confidence, accept almost anywhere):**
```dart
// ¥ / ￥(→¥) prefix, or 円 suffix. Space-tolerant.
final reYenPrefix = RegExp(r'[¥\\]\s*(' + _neg + r'(?:' + _grp + r'|' + _bare + r'))');
final reYenSuffix = RegExp(r'(' + _neg + r'(?:' + _grp + r'|' + _bare + r'))\s*円');
// thermal receipts sometimes wrap the grand total in asterisks: *¥3,850* / ＊3,850＊
final reStarred   = RegExp(r'\*\s*[¥]?\s*(' + _grp + r')\s*\*');
```
(Note `\\` catches the common OCR misread of `¥` as backslash.)

**Tier B — comma-grouped bare number (medium):** `_grp` alone. Commas almost never appear in phone/postal/qty, so `3,850` is very likely money.

**Tier C — bare integer (low; only trust when picked by same-row keyword logic or fallback):** `_bare`.

**Value parser:**
```dart
int? parseYen(String tok) {
  final neg = RegExp(r'^\s*[-▲△]').hasMatch(tok);
  final digits = tok.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty || digits.length > 8) return null;
  final v = int.parse(digits);
  return neg ? -v : v;
}
```

**Reject a numeric token as an amount if ANY holds (pitfall guards):**

| Reject when… | Regex / test on the token or its row |
|---|---|
| Phone number | row contains `TEL`/`電話`/`FAX` **or** token matches `r'0\d{1,4}-\d{1,4}-\d{3,4}'` **or** a digit run of length 10–11 starting with `0` |
| Postal code | `r'〒\s*\d{3}-?\d{4}'` or `\d{3}-\d{4}` immediately after `〒` |
| Invoice reg. no. (インボイス) | `r'T\d{13}'` or row has `登録番号` |
| Date | token consumed by a DATE match (see §4) or row has `年`/`月`/`日` in date shape |
| Time | `r'\d{1,2}:\d{2}'` |
| Quantity / unit price | row has `数量`/`単価`/`点`, or token preceded by `×`/`x`/`X`/`＠`/`@` (`r'[×xX＠@]\s*\d'`) |
| Tax **rate** (not amount) | token immediately followed by `%` (`r'\d+\s*%'`) |
| Register/transaction id | row has `No`/`レジ`/`責`/`取引`/`伝票`/`会員` and token is a long unbroken digit run (≥6, no comma) |
| Implausible magnitude | `v < 1` or `v > 9,999,999` (configurable ceiling) |
| Part of a longer digit run | enforce boundaries: `(?<![\d,])…(?![\d])` |

---

## 3. TOTAL (税込合計) detection

### 3a. Keyword lexicon (priority tiers)

**POSITIVE — total keywords (search rows; higher tier wins ties):**

| Tier | Keywords (regex alternation) | Notes |
|---|---|---|
| P1 | `合計` `お会計` `御会計` `ご請求(額)?` `お支払(い)?(金額)?` `領収(金額)?` | grand total. `合計` substring does **not** match `小計` (小計 = 小+計, no 合), so it's self-safe against subtotal. |
| P2 | `税込(合計)?` `内税込` `総額` `総合計` `総計` | explicitly tax-inclusive; boost score. |
| P3 | `お買上げ(計)?` `お買い上げ` `お買上` `買上(額)?` `お買物` | store-specific total label. |
| P4 (weak) | bare `計` | **only** if not preceded by `小`/`中`/`税抜`/`外税`. Use `r'(?<![小中税抜外])計'`. Low weight. |

**NEGATIVE — demote/never-pick (tax-excluded total variants):**
`税抜(き)?(合計)?` · `本体(価格)?` · `外税対象` → if a row's total-keyword is qualified by these, **do not** treat as the tax-inclusive total (keep as backup only if nothing else).

**EXCLUSION — these rows are NEVER the total** (tendered/change/points/payment):
```
お預り  お預かり  御預(り)?  預り  お預  預  現金  キャッシュ
おつり  お釣(り)?  釣(り)?  釣銭  つり  找  返金  お返し
ポイント  ポイント残高  ポイント利用  保有ポイント  獲得ポイント  残高  ﾎﾟｲﾝﾄ
クレジット  ｸﾚｼﾞｯﾄ  カード  電子マネー  チャージ  差引  利用額
値引(き)?  割引  クーポン  クーポン値引  非課税  課税対象額
```
Nuance on `現金`: it usually equals **tendered** (when a separate `お釣り` row exists) but can equal the paid total (exact cash, no change). Treat it as tendered for max-fallback exclusion, but keep its value for the cross-check in §3e.

### 3b. Selecting the total (keyword path)

1. For every row, classify: `positiveTier` (P1–P4 or none), `isTaxExcludedVariant`, `isExclusionRow`.
2. Skip exclusion rows. For each positive row, extract the **right-aligned same-row amount** (§1) and `parseYen`.
3. **Score** each candidate:
   ```
   score = tierWeight(P1=100,P2=110,P3=80,P4=30)
         + (rowHasTaxIncludeMarker(税込/内税) ? +25 : 0)
         + (isTaxExcludedVariant ? -1000 : 0)
         + (isBottomHalfOfReceipt ? +10 : 0)   // totals sit low
         + (amountHasCommaOrYen ? +10 : 0)      // formatting confidence
         + (amount == tendered - change ? +40 : 0) // cross-check, see 3e
   ```
4. Pick the **max-score positive candidate**. On a tie, prefer the one **lower on the receipt** (larger y) and with a `税込` marker.

### 3c. Tax-inclusive disambiguation

Japanese retail must show tax-included price (総額表示義務), so a plain `合計` is tax-inclusive by default. Handle explicit splits:
```
小計        3,500
消費税(10%)   350
合計        3,850     ← pick this (税込)
```
vs internal tax:
```
合計        3,850
(内消費税   350)     ← 内 means already included; still pick 合計 3,850
```
If a receipt prints **both** `税抜合計` and `税込合計`, always take `税込合計`. If only `税抜合計` + `消費税` are present with no `税込`/`合計`, compute `total = 税抜合計 + Σ消費税`.

### 3d. Fallback (no usable keyword)

When OCR drops `合計` (common — bold/large font misreads):
1. Collect all Tier-A/B amounts (currency- or comma-anchored) that pass §2 guards.
2. Drop any on **exclusion rows** (§3a) — critically removing `お預り` (which is often *larger* than the total) and `おつり`/`ポイント`.
3. If `小計` (subtotal) found: `total ≈ 小計 + Σ税`; pick the candidate closest to that.
4. Else: **`total = max(remaining plausible amounts)`** — the grand total is the largest legitimate purchase figure once tendered/change/points are excluded.

### 3e. Cross-validation (cheap, high value)

- **Cash identity:** if both `お預り`(=T) and `おつり/お釣り`(=C) exist, then `total == T − C`. Use to confirm or to *recover* the total when the 合計 row itself was misread. Big score boost / tiebreaker.
- **Sum check (optional):** `total ≈ Σ(line-item prices)`; only if item parsing is reliable — treat as soft signal, not a gate (discounts/rounding break exact equality).
- **Sanity:** reject final total `< 1` or `> ceiling`; warn if `total > お預り` (impossible for cash).

---

## 4. DATE detection

### 4a. Regexes (run on normalized text; era letters already upper-half-width)

```dart
// Gregorian, 4-digit year — separators / - . 年月日, no-leading-zero tolerant
final reGregorian = RegExp(
  r'(?<y>\d{4})\s*[/\-.年]\s*(?<m>\d{1,2})\s*[/\-.月]\s*(?<d>\d{1,2})\s*日?');

// 2-digit year (thermal): 24.01.15 / 24/1/5  — MUST validate + require boundaries
final reShortYear = RegExp(
  r'(?<![\d/\-.])(?<y>\d{2})[/\-.](?<m>\d{1,2})[/\-.](?<d>\d{1,2})(?![\d/\-.])');

// Wareki: 令和6年1月15日 / R6.1.15 / R6/01/15 / 令和元年… / H31…
final reWareki = RegExp(
  r'(?<era>令和|平成|昭和|明治|[RHSM])\s*(?<ey>元|\d{1,2})\s*[年.\-/]\s*'
  r'(?<m>\d{1,2})\s*[月.\-/]\s*(?<d>\d{1,2})\s*日?');

// Time (to strip & to confirm the transaction datetime)
final reTime = RegExp(r'(?<h>\d{1,2})\s*[:時]\s*(?<min>\d{2})');
```

**Ordering:** try `reWareki` and `reGregorian` first; use `reShortYear` **only** if the row also has `年`/a time, or as a lower-priority candidate, because 2-digit patterns collide with phone/price fragments.

### 4b. Wareki → 西暦 conversion

| Era | Marker(s) | Formula | Range |
|---|---|---|---|
| 令和 Reiwa | `令和` `令` `R` | `year = 2018 + N` | R1=2019 (from 2019-05-01), R6=2024, R7=2025 |
| 平成 Heisei | `平成` `平` `H` | `year = 1988 + N` | H1=1989 … H31=2019 (–04-30) |
| 昭和 Shōwa | `昭和` `昭` `S` | `year = 1925 + N` | S64=1989 |
| 明治/大正 | rare on receipts | — | ignore/skip |

`元` (元年) → N = 1. So `令和元年` → 2019.

```dart
int wareki(String era, String ey) {
  final n = (ey == '元') ? 1 : int.parse(ey);
  switch (era) {
    case '令和': case '令': case 'R': return 2018 + n;
    case '平成': case '平': case 'H': return 1988 + n;
    case '昭和': case '昭': case 'S': return 1925 + n;
    default: return -1;
  }
}
```

### 4c. Selection + validation rules

1. **Build & validate calendar date:** `1 ≤ m ≤ 12`, `1 ≤ d ≤ daysInMonth(y,m)` (reject Feb 30, 4/31, etc. — construct `DateTime` and verify round-trip). Big-endian only (Y-M-D or M-D); **no DD/MM ambiguity in Japanese receipts**.
2. **Reject future:** `date > today + 1 day` (1-day slack for timezone) → discard. This kills point-expiry (`ポイント有効期限`), campaign-end, best-before dates, which are typically future.
3. **Reject too-old:** `date.year < 2000` (configurable) → discard OCR garbage / 2-digit misreads.
4. **Prefer issue date at top:** among survivors, rank by (a) has adjacent **time** on same/near row → strongest (transaction datetime), (b) **smallest y** (highest on receipt — issue date sits in the store-header area), (c) row/nearby text contains `発行`/`取引`/`ご利用`/`日時`. Avoid dates sitting next to `期限`/`有効`/`まで`/`〜`.
5. **2-digit year:** map `YY < 70 → 2000+YY`, else `1900+YY` (receipts are recent, so effectively always `2000+`). Only accept if it passes future/old checks.
6. Strip any trailing `(月)…(日)` weekday and time before final date; keep time separately if you want a `DateTime`.

---

## 5. Suggested Dart module shape

```dart
class ParsedReceipt {
  final int? totalYen;       // 税込合計
  final DateTime? date;      // issue date (with time if found)
  final double totalConfidence, dateConfidence;
  final Map<String, dynamic> debug; // chosen row, score, candidates
}

ParsedReceipt parseReceipt(List<Block> blocks) { … }
```
- Keep normalization, row-grouping, amount-tokenizer, total-scorer, date-extractor as **separately unit-testable** pure functions.
- Emit `debug` (candidates + scores + rejected reasons) — essential for tuning against real fixtures.
- All regexes as `static final RegExp` compiled once.

---

## 6. Test fixtures to build (cover each hazard explicitly)

Create synthetic `List<Block>` fixtures + expected `{total, date}`; include real photos later.

**TOTAL cases**
1. Plain `合計 ¥3,850` with `小計 3,500` + `消費税 350` → 3850 (not 3500).
2. Tendered larger than total: `合計 3,850 / お預り 10,000 / お釣り 6,150` → 3850; verify `T−C` cross-check.
3. Points trap: `ポイント 385 / ポイント残高 12,340 / 合計 3,850` → 3850 (never 12,340).
4. Credit: `合計 3,850 / クレジット 3,850 / カード ****1234` → 3850.
5. `税抜合計 3,500 / 税込合計 3,850` → 3850 (pick 税込).
6. No keyword (OCR dropped 合計) → fallback max, excluding お預り/おつり.
7. `¥`-misread-as-`\` : `合計 \3,850`.
8. Full-width: `合計　￥３，８５０`.
9. Discount line `値引 -100` present → not chosen as total; total still correct.
10. Starred total `*¥3,850*`.
11. Label/amount as **separate blocks same row** (bbox path) vs same block.
12. `軽減税率` receipt with `※`/`軽` marks + two tax rates (8%/10%) → total unaffected.

**Amount pitfalls (should NOT be picked)**
13. `TEL 03-1234-5678`, `〒123-4567`, `登録番号 T1234567890123`, `数量 3`, `＠150 ×2`, `10%`.

**DATE cases**
14. `2024年1月15日 14:30` → 2024-01-15.
15. `2024/01/15`, `2024-1-5`, `24.01.15`, `24/1/5`.
16. Wareki: `令和6年1月15日`, `R6.1.15`, `R6/01/15`, `令和元年5月1日`→2019-05-01, `H31.4.20`→2019-04-20.
17. Future point-expiry present (`ポイント有効期限 2027/03/31`) + issue `2024/01/15` → pick 2024-01-15 (reject future).
18. Two dates, issue-at-top vs campaign-below → pick top/with-time.
19. Invalid calendar `2024/02/30` → rejected.
20. Phone/postal must not be misread as a 2-digit-year date.

---

### One-line summary of the decision core
**TOTAL** = highest-scored right-aligned amount on a `合計/税込/お会計/総額`-class row, excluding every `お預り/おつり/現金/ポイント/クレジット/値引` row and every `税抜/本体` variant; validated by `合計 == お預り − おつり`; fallback = max plausible amount after removing tendered/change/points/phone/qty/date tokens. **DATE** = the calendar-valid, non-future, top-most (preferably time-adjacent) date, with 令和/平成/昭和 (R/H/S) converted via `2018/1988/1925 + N`.