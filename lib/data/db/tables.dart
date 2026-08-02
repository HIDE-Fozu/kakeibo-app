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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
