import 'package:drift/drift.dart';
import '../db/database.dart';
import 'auto_backup_store.dart';
import 'backup_codec.dart';
import 'backup_data.dart';
import 'csv_exporter.dart';

/// バックアップ／復元のオーケストレーション。
/// 検証は BackupCodec に集約されており、本クラスはDBとの読み書きに徹する。
class BackupService {
  final AppDatabase _db;
  final BackupCodec _codec;
  final AutoBackupStore? _store;

  BackupService(this._db,
      {this._codec = const BackupCodec(), this._store});

  Future<BackupPayload> exportPayload() async {
    final cats = await (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.id)]))
        .get();
    final txs = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final rules = await (_db.select(_db.recurringRules)
          ..orderBy([(r) => OrderingTerm.asc(r.id)]))
        .get();
    final choreTasks = await (_db.select(_db.choreTasks)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final choreRecords = await (_db.select(_db.choreRecords)
          ..orderBy([(r) => OrderingTerm.asc(r.id)]))
        .get();
    final plans = await (_db.select(_db.installmentPlans)
          ..orderBy([(r) => OrderingTerm.asc(r.id)]))
        .get();
    return BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.now().toUtc(),
      categories: [
        for (final c in cats)
          BackupCategory(
            id: c.id,
            name: c.name,
            type: c.type,
            icon: c.icon,
            sortOrder: c.sortOrder,
            isArchived: c.isArchived,
            isSystem: c.isSystem,
            parentId: c.parentId,
            slug: c.slug,
          ),
      ],
      transactions: [
        for (final t in txs)
          BackupTxn(
            id: t.id,
            type: t.type,
            amount: t.amount,
            date: t.date,
            categoryId: t.categoryId,
            paymentMethod: t.paymentMethod,
            storeName: t.storeName,
            memo: t.memo,
            source: t.source,
            imagePath: t.imagePath,
            splitGroupId: t.splitGroupId,
            installmentPlanId: t.installmentPlanId,
            createdAt: t.createdAt.toUtc(),
            updatedAt: t.updatedAt.toUtc(),
          ),
      ],
      installmentPlans: [
        for (final pl in plans)
          BackupInstallmentPlan(
            id: pl.id,
            principal: pl.principal,
            count: pl.count,
            annualRatePercent: pl.annualRatePercent,
            categoryId: pl.categoryId,
            dayOfMonth: pl.dayOfMonth,
            startYm: pl.startYm,
            cardName: pl.cardName,
            createdAt: pl.createdAt.toUtc(),
            updatedAt: pl.updatedAt.toUtc(),
          ),
      ],
      recurringRules: [
        for (final r in rules)
          BackupRecurringRule(
            id: r.id,
            type: r.type,
            amount: r.amount,
            categoryId: r.categoryId,
            dayOfMonth: r.dayOfMonth,
            storeName: r.storeName,
            memo: r.memo,
            isActive: r.isActive,
            startYm: r.startYm,
            endYm: r.endYm,
            lastGeneratedYm: r.lastGeneratedYm,
            createdAt: r.createdAt.toUtc(),
            updatedAt: r.updatedAt.toUtc(),
          ),
      ],
      choreTasks: [
        for (final t in choreTasks)
          BackupChoreTask(
            id: t.id,
            name: t.name,
            emoji: t.emoji,
            repeatUnit: t.repeatUnit,
            dayOfMonth: t.dayOfMonth,
            intervalDays: t.intervalDays,
            anchorDate: t.anchorDate,
            archived: t.archived,
            createdAt: t.createdAt.toUtc(),
          ),
      ],
      choreRecords: [
        for (final r in choreRecords)
          BackupChoreRecord(
            id: r.id,
            taskId: r.taskId,
            doneDate: r.doneDate,
            memo: r.memo,
            createdAt: r.createdAt.toUtc(),
          ),
      ],
    );
  }

  Future<String> exportJson() async => _codec.encode(await exportPayload());

  /// 閲覧用CSV（エクスポート専用・復元不可）。
  Future<String> exportCsv() async => buildTransactionsCsv(await exportPayload());

  /// バックアップJSONからの復元（置換）。順序が生命線:
  /// 1) 完全検証 → 2) 空チェック → 3) 現在DBのスナップショット(検証付き) → 4) アトミックswap
  /// 1〜3のどこで失敗してもDBは無傷。4は単一トランザクションで途中失敗は全ロールバック。
  Future<void> restoreFromJson(String json, {bool allowEmpty = false}) async {
    final payload = _codec.decode(json); // 不正ならここで型付き例外

    if (payload.transactions.isEmpty && !allowEmpty) {
      throw EmptyBackupError(
          '取引が0件のバックアップです。本当に復元する場合は明示的な確認が必要です');
    }

    final store = _store;
    if (store == null) {
      throw StateError('復元には AutoBackupStore の設定が必要です');
    }
    await store.writeVerified(await exportJson()); // 失敗=AutoBackupWriteError→中止

    await applyRestore(payload);
  }

  /// 検証済みpayloadでDB全体を置換する。単一トランザクション＝途中失敗は全ロールバック。
  /// 呼び出し前に codec.decode を通すこと（検証はcodecの責務）。
  Future<void> applyRestore(BackupPayload payload) async {
    await _db.transaction(() async {
      // 自己参照FK（parentId）対策: driftのbatchは行ごとに別文でINSERTするため、
      // 内訳が親より先に挿入されると即時FK検査で落ちる。このトランザクション内は
      // FK検査をコミット時まで遅延する（整合性はコミット時に検証される）。
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');

      // FK RESTRICT を回避する順序: 取引・定期ルール → カテゴリ の順に削除。
      // つきいちは記録 → タスク の順（カスケードに頼らず明示削除）。
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.installmentPlans).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.choreRecords).go();
      await _db.delete(_db.choreTasks).go();
      await _db.delete(_db.categories).go();

      // カテゴリ → 取引 の順に、IDを明示して挿入（逐語保存）
      await _db.batch((b) {
        for (final c in payload.categories) {
          b.insert(
            _db.categories,
            CategoriesCompanion(
              id: Value(c.id),
              name: Value(c.name),
              type: Value(c.type),
              icon: Value(c.icon),
              sortOrder: Value(c.sortOrder),
              isArchived: Value(c.isArchived),
              isSystem: Value(c.isSystem),
              parentId: Value(c.parentId),
              slug: Value(c.slug),
            ),
          );
        }
        for (final pl in payload.installmentPlans) {
          b.insert(
            _db.installmentPlans,
            InstallmentPlansCompanion(
              id: Value(pl.id),
              principal: Value(pl.principal),
              count: Value(pl.count),
              annualRatePercent: Value(pl.annualRatePercent),
              categoryId: Value(pl.categoryId),
              dayOfMonth: Value(pl.dayOfMonth),
              startYm: Value(pl.startYm),
              cardName: Value(pl.cardName),
              createdAt: Value(pl.createdAt),
              updatedAt: Value(pl.updatedAt),
            ),
          );
        }
        for (final t in payload.transactions) {
          b.insert(
            _db.transactions,
            TransactionsCompanion(
              id: Value(t.id),
              type: Value(t.type),
              amount: Value(t.amount),
              date: Value(t.date),
              categoryId: Value(t.categoryId),
              paymentMethod: Value(t.paymentMethod),
              storeName: Value(t.storeName),
              memo: Value(t.memo),
              source: Value(t.source),
              imagePath: Value(t.imagePath),
              splitGroupId: Value(t.splitGroupId),
              installmentPlanId: Value(t.installmentPlanId),
              createdAt: Value(t.createdAt),
              updatedAt: Value(t.updatedAt),
            ),
          );
        }
        for (final r in payload.recurringRules) {
          b.insert(
            _db.recurringRules,
            RecurringRulesCompanion(
              id: Value(r.id),
              type: Value(r.type),
              amount: Value(r.amount),
              categoryId: Value(r.categoryId),
              dayOfMonth: Value(r.dayOfMonth),
              storeName: Value(r.storeName),
              memo: Value(r.memo),
              isActive: Value(r.isActive),
              startYm: Value(r.startYm),
              endYm: Value(r.endYm),
              lastGeneratedYm: Value(r.lastGeneratedYm),
              createdAt: Value(r.createdAt),
              updatedAt: Value(r.updatedAt),
            ),
          );
        }
        for (final t in payload.choreTasks) {
          b.insert(
            _db.choreTasks,
            ChoreTasksCompanion(
              id: Value(t.id),
              name: Value(t.name),
              emoji: Value(t.emoji),
              repeatUnit: Value(t.repeatUnit),
              dayOfMonth: Value(t.dayOfMonth),
              intervalDays: Value(t.intervalDays),
              anchorDate: Value(t.anchorDate),
              archived: Value(t.archived),
              createdAt: Value(t.createdAt),
            ),
          );
        }
        for (final r in payload.choreRecords) {
          b.insert(
            _db.choreRecords,
            ChoreRecordsCompanion(
              id: Value(r.id),
              taskId: Value(r.taskId),
              doneDate: Value(r.doneDate),
              memo: Value(r.memo),
              createdAt: Value(r.createdAt),
            ),
          );
        }
      });

      // 事後アサート（防御的・トランザクション内なので失敗すればロールバック）
      final catCount = await _count(_db.categories);
      final txCount = await _count(_db.transactions);
      final ruleCount = await _count(_db.recurringRules);
      final choreTaskCount = await _count(_db.choreTasks);
      final choreRecordCount = await _count(_db.choreRecords);
      final planCount = await _count(_db.installmentPlans);
      if (catCount != payload.categories.length ||
          planCount != payload.installmentPlans.length ||
          txCount != payload.transactions.length ||
          ruleCount != payload.recurringRules.length ||
          choreTaskCount != payload.choreTasks.length ||
          choreRecordCount != payload.choreRecords.length) {
        throw StateError(
            '復元の件数が一致しません: cats=$catCount/${payload.categories.length}, '
            'txs=$txCount/${payload.transactions.length}, '
            'rules=$ruleCount/${payload.recurringRules.length}, '
            'choreTasks=$choreTaskCount/${payload.choreTasks.length}, '
            'choreRecords=$choreRecordCount/${payload.choreRecords.length}, '
            'installmentPlans=$planCount/${payload.installmentPlans.length}');
      }
    });
  }

  Future<int> _count(TableInfo<Table, dynamic> table) async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM ${table.actualTableName}')
        .getSingle();
    return row.read<int>('c');
  }
}
