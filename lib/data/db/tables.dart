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

  /// 安定キー（シードカテゴリのみ非null）。表示名(name)から独立し、絵文字・
  /// 自動税率・多言語シードの結び付け先になる。ユーザー作成カテゴリはnull。
  /// v5で追加。既存シード行は名前一致でバックフィルする（database.dartのmigration）。
  TextColumn get slug => text().nullable()();

  /// 非null=内訳（親カテゴリのid）。階層は2段まで（アプリ側で保証）。
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
}

/// 毎月の固定費・収入のルール。期日が来ると transactions へ通常の取引として
/// 起票される（source=recurring）。起票後の取引は普通の取引と同じに編集・削除でき、
/// 削除しても再起票されない（lastGeneratedYm が前進済みのため）。v6で追加。
@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TxnType>()();
  IntColumn get amount => integer()(); // 整数minor unit・非負（アプリ側で保証）
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();

  /// 毎月の起票日 1..31。短い月は末日に丸める（31日→2月は28/29日）。
  IntColumn get dayOfMonth => integer()();
  TextColumn get storeName => text().nullable()();
  TextColumn get memo => text().nullable()();

  /// false=一時停止（起票しない）。停止中も lastGeneratedYm は進めず、
  /// 再開時に停止期間分をさかのぼって起票しない（applyDue 参照）。
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 起票を開始する月（YYYY*100+MM。例: 2026年8月=202608）。
  IntColumn get startYm => integer()();

  /// 起票する最後の月（両端含む）。null=無期限。
  IntColumn get endYm => integer().nullable()();

  /// 最後に起票した月。null=まだ一度も起票していない。
  IntColumn get lastGeneratedYm => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// つきいちタスク（低頻度の家事リマインダー）。routine-reminder から v2.2.0 で合体。
/// 次回期日は保存せず、repeatUnit に応じて「毎月dayOfMonth日」または
/// 「最後の記録＋intervalDays」から導出する。v7で追加・v8で毎月N日化・v9で両対応。
@DataClassName('ChoreTaskRow')
class ChoreTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  TextColumn get emoji => text().withDefault(const Constant('📌'))();
  /// 繰り返し方（v9で追加）。monthlyDay=毎月N日 / everyDays=N日ごと。
  TextColumn get repeatUnit => textEnum<ChoreRepeatUnit>()
      .withDefault(const Constant('monthlyDay'))();

  // 毎月の予定日 1..31（v8で間隔日数から変更。フォームで保証、DBはCHECKなし）
  IntColumn get dayOfMonth => integer()();

  /// N日ごとの間隔 1..999（v7の interval_days を v9で復活）。
  IntColumn get intervalDays => integer().withDefault(const Constant(30))();
  TextColumn get anchorDate => text().map(const CivilDateConverter())();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// つきいちタスクの実施記録。v7で追加。
@DataClassName('ChoreRecordRow')
class ChoreRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(ChoreTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get doneDate => text().map(const CivilDateConverter())();
  TextColumn get memo => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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

  /// 店舗名。v4でmemoから分離（memoは自由記述の詳細専用に）。null=未設定。
  TextColumn get storeName => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get source => textEnum<TxnSource>()();
  TextColumn get imagePath => text().nullable()();

  /// 同じレシート（詳細入力の1回）から生まれた取引を束ねるID。null=単独取引。
  /// v3で追加。日別一覧のグループカード表示と「詳細入力で開き直す」に使う。
  TextColumn get splitGroupId => text().nullable()();

  /// 分割払いの計画（installment_plans.id）。null=分割払い由来ではない。
  /// v10で追加。計画の編集/削除でこの取引群は作り直し/削除される（cascade）。
  IntColumn get installmentPlanId => integer()
      .nullable()
      .references(InstallmentPlans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 分割払いの計画（FB 2026-08-16）。保存時に count ヶ月分の支出取引を一括起票し、
/// 取引側は installmentPlanId で紐づく。編集=取引を作り直し・削除=取引ごと削除
/// （FK cascade）。金額の計算は installment_calc.dart（実質年率の元利均等）。
/// v10で追加。
@DataClassName('InstallmentPlanRow')
class InstallmentPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get principal => integer()(); // 購入金額（minor unit・非負）
  IntColumn get count => integer()(); // 支払い回数（>=1）
  RealColumn get annualRatePercent => real()(); // 実質年率（%）
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  IntColumn get dayOfMonth => integer()(); // 支払日 1..31（短い月は末日に丸め）
  IntColumn get startYm => integer()(); // 初回の月（YYYY*100+MM）
  TextColumn get cardName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// ごみ箱（最近削除した取引）のスナップショット（FB 2026-08-16: SnackBarの
/// 「元に戻す」を撤去し、設定画面から復元できる形に）。削除時に取引の内容を
/// ここへ移し、復元は同内容の再add（id/createdAtは新規: Undoと同じ制約）。
/// 30日で自動パージ。カテゴリ等へFKは張らない（参照先が消えても行を残す）。
/// deletedAt はSQL既定を使わず必ずDart側（UTC）で入れる（テキスト保存の
/// datetime は CURRENT_TIMESTAMP と書式が混ざると比較が壊れるため）。v11で追加。
@DataClassName('DeletedTransactionRow')
class DeletedTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TxnType>()();
  IntColumn get amount => integer()(); // 整数円・非負
  TextColumn get date => text().map(const CivilDateConverter())();
  IntColumn get categoryId => integer()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();
  TextColumn get storeName => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get source => textEnum<TxnSource>()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get splitGroupId => text().nullable()();
  IntColumn get installmentPlanId => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime()();
}

/// 支払い区分＝繰延払いの手段（カード等）。v12で追加。
///
/// 現金・即時払いは「カード未選択」で表す（この表に行を作らない）。
/// [payDay] はそのカードの引き落とし日（1..31・短い月は末日に丸め）で、
/// 休業日は [businessDayRule] に従って営業日へ寄せる。
/// [closingDay] は締め日（31=月末締め）。カード会社ごとに違う（楽天カードは
/// 月末締め・翌27日払いだが、楽天市場の利用だけ27日締め）ので設定できるようにし、
/// それでも合わないケースは未払金ごとに支払い月を上書きして直す。
/// [annualRatePercent] は「あとから分割」にしたときの既定の実質年率。
@DataClassName('PaymentCardRow')
class PaymentCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get payDay => integer()();

  /// 締め日 1..31（31=月末締め・既定）。締め日までの利用は翌月払い、
  /// 締め日を過ぎた利用は翌々月払いになる。
  IntColumn get closingDay =>
      integer().withDefault(const Constant(31))();
  TextColumn get businessDayRule =>
      textEnum<BusinessDayRule>().withDefault(const Constant('next'))();
  RealColumn get annualRatePercent => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 未払金（カードで買った1件＝1オブジェクト）。購入取引と1:1。v12で追加。
///
/// 買った時点では現金が動かない負債で、カードの支払日にまとめて引き落とされる。
/// 引き落とし自体は**取引として起票しない**（起票すると購入と二重計上になる）。
/// 支払日の表示は payable_schedules から導出する（固定費のゴーストと同じ考え方）。
///
/// [installmentCount] 1=一括・N=あとから分割。[totalMinor] は元本＋手数料で、
/// payable_schedules の合計と常に一致していなければならない（機械判定あり）。
/// 削除・回数変更は「この未払金」というオブジェクト単位で行う。
@DataClassName('PayableRow')
class Payables extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get cardId =>
      integer().references(PaymentCards, #id, onDelete: KeyAction.restrict)();
  IntColumn get installmentCount => integer().withDefault(const Constant(1))();
  RealColumn get annualRatePercent => real().withDefault(const Constant(0))();
  IntColumn get totalMinor => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // 購入取引ひとつに未払金はひとつ。
  @override
  List<Set<Column>> get uniqueKeys => [
        {transactionId}
      ];
}

/// 未払金の支払い予定（何月にいくら）。v12で追加。
/// 一括なら1行、あとから分割ならN行。合計は必ず payables.total_minor と一致する
/// （「この月は1万円・この月は2万円」と個別に触れるようにしたときの安全網）。
@DataClassName('PayableScheduleRow')
class PayableSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get payableId =>
      integer().references(Payables, #id, onDelete: KeyAction.cascade)();
  IntColumn get ym => integer()(); // 支払い月 YYYYMM
  IntColumn get amountMinor => integer()();

  // 同じ未払金が同じ月に2行持つことはない。
  @override
  List<Set<Column>> get uniqueKeys => [
        {payableId, ym}
      ];
}
