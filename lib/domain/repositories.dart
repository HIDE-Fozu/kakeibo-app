import '../data/db/daos.dart' show CategorySpendRow;
import '../data/db/enums.dart';
import 'entities.dart';
import 'money/civil_date.dart';

abstract interface class TransactionRepository {
  Future<int> add(TransactionEntity tx);

  /// 全取引件数（通貨ロック判定用）。
  Future<int> count();
  Future<List<TransactionEntity>> forMonth(int year, int month);
  Future<MonthlySummary> summary(int year, int month);
  Future<List<CategorySpendRow>> spendingByCategory(int year, int month);

  /// 既存取引を更新する（tx.id 必須）。updatedAt は実装が更新し、source は不変。
  Future<void> update(TransactionEntity tx);

  Stream<List<TransactionEntity>> watchMonth(int year, int month);
  Stream<MonthlySummary> watchSummary(int year, int month);
  Stream<List<CategorySpendRow>> watchSpendingByCategory(int year, int month);

  /// categoryId -> 最終利用日（取引date基準）。高速入力の「最近使った順」に使う。
  Stream<Map<int, CivilDate>> watchLastUsedByCategory();

  /// 冪等（存在しないIDでも例外を投げない）。
  Future<void> delete(int id);
}

abstract interface class RecurringRuleRepository {
  Stream<List<RecurringRuleEntity>> watchAll();
  Future<int> add(RecurringRuleEntity rule);

  /// 既存ルールを更新する（rule.id 必須）。
  /// 停止→再開の切り替え時は、停止期間分のさかのぼり起票を防ぐため
  /// lastGeneratedYm を today の前月まで進める（当月分からの起票になる）。
  Future<void> update(RecurringRuleEntity rule, {required CivilDate today});

  /// 冪等（存在しないIDでも例外を投げない）。起票済みの取引は消さない。
  Future<void> delete(int id);

  /// 期日到来分を取引として起票し lastGeneratedYm を進める。生成件数を返す。
  /// 冪等（同じ today で何度呼んでも二重起票しない）。起動時・復帰時に呼ぶ。
  Future<int> applyDue(CivilDate today);
}

abstract interface class ChoreRepository {
  Stream<List<ChoreTask>> watchTasks();
  Stream<List<ChoreRecord>> watchRecords();

  /// resync 用の一括読み（Future版。stream.first はテストでハングするため使わない）。
  Future<List<ChoreTask>> allTasks();
  Future<List<ChoreRecord>> allRecords();

  Future<int> addTask({
    required String name,
    required String emoji,
    ChoreRepeatUnit repeatUnit,
    required int dayOfMonth,
    int intervalDays,
    required CivilDate anchorDate,
  });

  /// 既存タスクを更新する（name/emoji/繰り返し設定/anchorDate/archived）。
  Future<void> updateTask(ChoreTask task);
  Future<void> setArchived(int taskId, bool archived);

  /// 記録もカスケード削除される。冪等。
  Future<void> deleteTask(int taskId);

  Future<int> addRecord({
    required int taskId,
    required CivilDate doneDate,
    String memo = '',
  });

  /// 記録の doneDate/memo を更新する（record.id 必須）。
  Future<void> updateRecord(ChoreRecord record);
  Future<void> deleteRecord(int recordId);

  /// 同じタスク・同じ日にすでに記録があるか（重複確認用）。
  Future<bool> hasRecordOn(int taskId, CivilDate date);
}

abstract interface class CategoryRepository {
  Future<List<CategoryEntity>> active();

  /// 階層整列で返す: 親をsortOrder順、各親の直後にその内訳をsortOrder順。
  Stream<List<CategoryEntity>> watchAll();

  /// setArchived(id, true) と同じ（アーカイブガードも共通）。
  Future<void> archive(int categoryId);

  /// 取引が紐づく型変更は集計desyncを招くため [CategoryInUseError] を投げる。
  /// 内訳自身／内訳を持つ親は「typeは親と一致」の不変条件を破るため
  /// CategoryHierarchyError（実装参照）を投げる。
  Future<void> changeType(int categoryId, CategoryType type);

  /// 同一スコープ（同じ親）末尾のsortOrderで追加。name.trim()が空なら [ArgumentError]。
  /// parentId指定時は内訳として追加。親が存在しない／親自身が内訳（2段超）／
  /// 親がシステム／typeが親と不一致なら CategoryHierarchyError（実装参照）。
  Future<int> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
    int? parentId,
  });

  /// isSystem行への操作は [SystemCategoryError]（rename/setArchived/reorder共通）。
  Future<void> rename(int categoryId, String name);

  /// アクティブな内訳が残る親のアーカイブは CategoryHierarchyError
  /// （幽霊カテゴリ防止。内訳→親の順ならアーカイブ可）。
  Future<void> setArchived(int categoryId, bool archived);

  /// 渡した順に sortOrder = 0,1,2,... を振り直す。
  /// 同一スコープ（同じ親）のidのみ受理し、混在は [ArgumentError]。
  Future<void> reorder(List<int> orderedIds);
}
