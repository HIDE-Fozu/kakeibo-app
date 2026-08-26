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

/// ごみ箱（最近削除した取引）。取引の削除はhard deleteの代わりにここへ移し、
/// 設定画面から復元できる（FB 2026-08-16: SnackBarの「元に戻す」の受け皿）。
abstract interface class TrashRepository {
  /// deletedAt の新しい順。
  Stream<List<TrashEntry>> watchAll();

  /// 取引を削除してごみ箱へ移す（1トランザクション）。冪等。
  Future<void> moveToTrash(int transactionId);

  /// 同内容を再addしてごみ箱から除く（id/createdAtは新規: 旧Undoと同じ制約）。
  /// 分割払いの計画が既に消えていれば紐付けを外して復元する。冪等。
  Future<void> restore(int trashId);

  /// 保持期間（kTrashRetention）を過ぎた行を消す。消した件数を返す。
  /// ごみ箱ページを開いたときに呼ぶ。
  Future<int> purgeExpired();

  /// 全行を完全削除する（設定の「ごみ箱を空にする」）。
  Future<void> emptyTrash();
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

/// 分割払いの計画。add/replace は計画と支払い取引群を1トランザクションで書く。
abstract interface class InstallmentPlanRepository {
  Stream<List<InstallmentPlanEntity>> watchAll();

  /// 計画と支払い取引を保存（installmentPlanId はリポジトリが振る）。計画idを返す。
  Future<int> add(InstallmentPlanEntity plan, List<TransactionEntity> payments);

  /// 編集: 計画を書き換え、紐づく既存取引を全て削除して payments で作り直す。
  Future<void> replace(
      InstallmentPlanEntity plan, List<TransactionEntity> payments);

  /// 計画と紐づく取引を削除（FK cascade）。
  Future<void> delete(int planId);
}

/// 支払い区分（カード）の登録・並び・アーカイブ。
abstract interface class PaymentCardRepository {
  Stream<List<PaymentCardEntity>> watchAll({bool includeArchived = false});
  Future<List<PaymentCardEntity>> all({bool includeArchived = false});
  Future<int> add(PaymentCardEntity card);
  Future<void> update(PaymentCardEntity card);

  /// アーカイブ（未払金から参照されていても消さずに隠す）。
  Future<void> archive(int cardId, {bool archived = true});

  /// 完全削除。未払金から参照されている場合は StateError（FK restrict）。
  Future<void> delete(int cardId);
}

/// 未払金の読み書き。スケジュールの合計＝総額は書き込み時に必ず検証する。
abstract interface class PayableRepository {
  /// 指定した購入取引の未払金（無ければ null）。
  Future<PayableEntity?> forTransaction(int transactionId);

  /// 支払い月が ym の未払金一覧（その月の引き落とし内訳）。
  Stream<List<PayableEntity>> watchForPaymentYm(int ym);

  /// その月に「買った」カード購入の取引ID集合。
  /// 現金主義のサマリで、購入を支払いから外すために使う。
  Stream<Set<int>> watchCardPurchaseTxIdsIn(int year, int month);

  /// 未払金を作る（購入取引は作成済みであること）。
  Future<int> add(PayableEntity payable);

  /// 回数・率・スケジュールを差し替える（「あとから分割」「再分割」）。
  Future<void> replace(PayableEntity payable);

  /// 未払金だけ消す（購入取引は残る＝即時払いに戻す）。
  Future<void> delete(int payableId);
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
