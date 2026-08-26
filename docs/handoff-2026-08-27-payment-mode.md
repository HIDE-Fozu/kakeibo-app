# 引き継ぎ 2026-08-27 — 支払い区分モード（未払金・あとから分割）

前の正典: docs/handoff-2026-08-23-budget-memo.md。本書が新しい正典。

## 🎯 現在地

- ブランチ **`feature/paper-design`**・HEAD = fc7837b ＋本書。**未push**。
- **672テスト緑 / analyze 0**。sim（iPhone 17）スクショ目視済み。**実機未配備**。
- **2.3.0(47) は審査提出済み（8/23）**。本セッション分は 47 に入っていない。
- ★**実機には 8/23 04:21 の IPA（コミット 2e0f406 時点）しか入っていない**。
  買い物メモ・予算・支払い区分は実機で確認できない。配備が必要。

## 支払い区分モードとは（ユーザー要望 2026-08-26）

カードで買った分を **未払金**（負債）として持ち、カードの引き落とし日に
まとめて現金が出ていく、という会計の形をアプリに入れたもの。設定でON/OFF。

### 決めたこと（ユーザー裁定）

1. **既定は現金主義**。上部サマリの見出しは「支出」ではなく**「支払い」**で、
   引き落とし日で数える。未払金はサマリに入らない。
   発生主義（買った日で数える・見出しは「支出」）にも**歯車で切り替えられる**。
2. **未払金は1オブジェクト**。1万円の買い物を10回払いにしても、3回払いに
   戻しても、削除しても、操作の単位は「その1万円」。
3. **支払い月は上書きできる**。締め日はカード/加盟店で違う（楽天カードでも
   楽天市場は27日締め・Amazonは月末締め）ため、締め日の設定ではなく
   「これは9月分じゃなく10月分」という**個別の変更**で吸収する。
4. 個別月の金額編集（「この月は1万・この月は2万」）は**後回し**。ただし
   **合計＝総額の機械判定は先に入れてある**（それが安全網になる）。

## 実装（5コミット）

| コミット | 内容 |
|---|---|
| a32b32b | 土台: 日本の祝日判定（算術）＋支払日の営業日調整 |
| 31f4586 | データ層: schema v12（カード・未払金・支払い予定）＋backup v10 |
| a5e42bc | 設定のモードON/OFF・カード管理・入力での支払い区分選択 |
| c8530ae | 表示: 未払バッジ・引き落とし行・数え方の歯車 |
| b895423 | セルと見込み収支も現金主義に揃える（食い違いの解消） |
| fc7837b | あとから分割（回数・開始月の変更・解除） |

### 設計で外せない点

- **引き落としは取引として起票しない**。起票すると購入と二重計上になる。
  支払日の表示は payable_schedules からの**導出**（固定費ゴーストと同じ考え方）。
- **上部サマリ・カレンダーのセル・見込み収支は必ず同じ定義**にする。
  ここが食い違うと「計算が間違っている」に見える（FB 2026-08-21 と同型で、
  実際に一度やらかして b895423 で直した）。
- **合計＝総額の検証はリポジトリの add/replace が門番**。UIからもバックアップの
  復元からも壊れた予定は入らない。
- 祝日で日付をずらすのは**通貨がJPYのときだけ**（日本の銀行の慣行なので）。
- 祝日判定は**2023年以降の現行法**のみ。五輪特例（2020-2022）と2018年以前の
  12/23天皇誕生日は再現しない。引き落とし日は未来日なので実害なし。

### 主要ファイル

- `lib/domain/services/jp_holidays.dart` — 祝日（データファイル無し）
- `lib/domain/services/payment_schedule.dart` — 支払日・支払い月・整合検証
- `lib/domain/services/payable_builder.dart` — 一括/分割の組み立て
- `lib/data/db/tables.dart` — PaymentCards / Payables / PayableSchedules
- `lib/data/repositories/drift_payment_repository.dart` — 整合の門番
- `lib/features/payment/` — providers・カード管理・未払金の詳細
- テスト: `test/jp_holidays_test.dart` `test/payment_schedule_test.dart`
  `test/payable_repository_test.dart` `test/providers/payment_summary_test.dart`
  `test/ui/payment_*.dart` `test/ui/payable_detail_test.dart`
  `test/backup/backup_payables_test.dart`

## 次にやること

1. **実機配備**（最優先）。8/23以降の3セッション分（メモ・予算・支払い区分）が
   実機で1つも確認できていない。ユーザーが「どこにあるか分からない」状態。
2. 審査結果（2.3.0(47)）→ 通過ならmainマージ/push承認。
3. 支払い区分の実機受入 → FB反映。
4. 積み残し: 個別月の金額編集（合計一致の機械判定は実装済み）・
   prefsのカード（分割払い画面）とDBのカード（支払い区分）の統合・
   入力画面の抜本リデザイン・母レシート回収→expected回帰テスト化。

## 動かし方

- テスト: `flutter test`（672件）
- スクショ: `flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/payment_shots_test.dart -d <sim-id>`
- 実機: `flutter run --release -d 00008140-00180D0911C2801C`（TI10B1・ワイヤレス）

## ⚠️ 2026-08-27 の実機配備でデータを消した（要記録）

`flutter install -d <ios-device> --release` は、同じ bundle id のアプリが
既に入っていると **「Uninstalling old version...」で先に消してから入れる**。
iOSではアンインストール＝データコンテナごと削除なので、**端末のアプリ内
データは全部消えた**（アプリ内の自動バックアップも同じコンテナなので道連れ）。

- 配備自体は成功: TI10B1 に 2.3.0(47)・schema v12 の新ビルドが入って起動済み。
- 生き残るのは、共有シートで **アプリの外**（Files / Drive 等）へ書き出した
  バックアップだけ。端末の Finder/iCloud バックアップからの復元も理屈上は可能。
- **次から**: iOS実機へ配備する前に必ずユーザーにバックアップを書き出させ、
  データが消え得ることを明示して同意を取る。保持したいなら Xcode から Run するか
  TestFlight 配信にする。
- 2回目の配備（メモのせり上げを入れた版）でも同じく「Uninstalling old version」
  が出た＝**この経路では毎回消える**。偶発ではない。

### ★ `flutter install` は再ビルドしない（2026-08-27 に踏んだ）

`flutter install` は `build/ios/iphoneos/Runner.app` の**既存の成果物を入れるだけ**。
コードを直して install を繰り返しても、最初にビルドした古いバイナリが入り続ける。
ユーザーに「実機に入ってないんじゃない？前と変わらない」と言われるまで、
2回、入っていない物を「入れた」と報告してしまった。

**配備の手順（必ずこの順で・検証まで含めて1セット）:**
1. `flutter build ios --release`（`flutter run --release` でも可）
2. `flutter install -d 00008140-00180D0911C2801C --release`
3. **端末側で検証**: `xcrun devicectl device info apps --device <id> | grep kakeibo`
   → 版数が上がっていること。判別できるよう**配備のたびに build number を上げる**。
4. `xcrun devicectl device process launch --device <id> com.hidefozu.kakeibo`

現在の実機 = **2.4.0(48)**（メモの直接入力・せり上げ・支払い区分まで全部入り）。
pubspec も 2.4.0+48 に上げてある（2.3.0(47) は審査中なので次は2.4.0が妥当）。

## メモのせり上げ（FB 2026-08-27・ff02bf5）

メモタブを押すと日別カードがカレンダーの上に乗る。背景タップで戻る。
**せり上げ中に日付・つきいちへ切り替えても高さは変わらない**。

実装で外せない点: タブの選択状態（`dayTabProvider`）とカードの高さ
（`daySheetExpandedProvider`）を**別々の provider に持ち上げてある**。
`_DaySection` のローカル state のままだと、通常表示とオーバーレイの切り替えで
State が作り直され、タブが日付に戻ってしまう。
