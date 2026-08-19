import 'package:drift/drift.dart';
import 'tables.dart';
import 'daos.dart';
import 'enums.dart';
import 'converters.dart';
import 'category_seeds.dart';
import '../../domain/money/civil_date.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Transactions,
    RecurringRules,
    ChoreTasks,
    ChoreRecords,
    InstallmentPlans,
    DeletedTransactions,
  ],
  daos: [CategoryDao, TransactionDao, RecurringRuleDao, ChoreDao],
)
class AppDatabase extends _$AppDatabase {
  /// 新規インストール時にシードするカテゴリ名の言語（BCP-47のlanguageCode）。
  /// 既定 'ja'。bootstrap が端末言語を解決して渡す。テストは既定のまま日本語。
  final String seedLocaleTag;
  AppDatabase(super.e, {this.seedLocaleTag = 'ja'});

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: 内訳機能。既存カテゴリは全て親（parentId=null）のまま。
            await m.addColumn(categories, categories.parentId);
          }
          if (from < 3) {
            // v3: 詳細入力（分割）のレシート紐づけ。既存行は null=単独取引。
            await m.addColumn(transactions, transactions.splitGroupId);
          }
          if (from < 4) {
            // v4: 店舗名をmemoから分離。旧memo欄は「メモ・店名」でOCRも店名を
            // 入れていたため、既存memoは店名として storeName へ移し、memoは空に。
            await m.addColumn(transactions, transactions.storeName);
            await customStatement(
                'UPDATE transactions SET store_name = memo, memo = NULL');
          }
          if (from < 5) {
            // v5: カテゴリに slug（安定キー）を追加。既存シード行は日本語名で
            // バックフィルし、絵文字・自動税率がローカライズ後も壊れないようにする。
            await m.addColumn(categories, categories.slug);
            await _backfillSlugs();
          }
          if (from < 6) {
            // v6: 毎月の固定費・収入（定期取引ルール）。既存データは無関係。
            await m.createTable(recurringRules);
          }
          if (from < 7) {
            // v7: つきいちタスク（家事リマインダー）合体。既存データは無関係。
            // 現行（v9）定義で作られるので後続の変換は不要。
            await m.createTable(choreTasks);
            await m.createTable(choreRecords);
          } else if (from < 8) {
            // v7 → v9: 「N日ごと」しか無かった頃のデータ。繰り返し方は
            // everyDays のまま維持し（間隔を失わない）、毎月の予定日は
            // 次回期日（anchor_date + interval_days）の「日」を初期値にする。
            await m.alterTable(TableMigration(
              choreTasks,
              columnTransformer: {
                choreTasks.dayOfMonth: const CustomExpression<int>(
                    "CAST(strftime('%d', date(anchor_date, "
                    "'+' || interval_days || ' days')) AS INTEGER)"),
                choreTasks.repeatUnit: const Constant('everyDays'),
              },
            ));
          } else if (from < 9) {
            // v8 → v9: 「毎月N日」だけだった頃のデータ。繰り返し方は
            // monthlyDay、間隔は既定値（列のdefault）で埋める。
            await m.alterTable(TableMigration(
              choreTasks,
              newColumns: [choreTasks.repeatUnit, choreTasks.intervalDays],
            ));
          }
          if (from < 10) {
            // v10: 分割払いの計画＋取引への紐付け。既存行は null=分割払い以外。
            await m.createTable(installmentPlans);
            await m.addColumn(transactions, transactions.installmentPlanId);
          }
          if (from < 11) {
            // v11: ごみ箱（最近削除した取引）。既存データは無関係。
            await m.createTable(deletedTransactions);
          }
        },
        beforeOpen: (details) async {
          // FK は接続ごとに有効化しないと SQLite が無視する。
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated) {
            await _seedInitialCategories();
          }
        },
      );

  /// 新規DBのカテゴリシード。slug（安定キー）＋端末言語の表示名で挿入する。
  /// 構成・並び順は kSeedCategories（旧シードと同一）。外食は食費の内訳。
  Future<void> _seedInitialCategories() async {
    final lang = seedLocaleTag;
    final idBySlug = <String, int>{};
    // parentSlug 解決のため順次挿入（親は子より前に定義されている）。
    for (final s in kSeedCategories) {
      final parentId = s.parentSlug == null ? null : idBySlug[s.parentSlug];
      final id = await into(categories).insert(CategoriesCompanion.insert(
        name: seedCategoryName(s.slug, lang),
        type: s.type,
        sortOrder: Value(s.sortOrder),
        isSystem: Value(s.isSystem),
        parentId: Value(parentId),
        slug: Value(s.slug),
      ));
      idBySlug[s.slug] = id; // uncategorized は2回入るが親参照には使わないので可
    }
  }

  /// v4→v5: 既存シード行（日本語名）に slug を付与。ユーザー作成行はnullのまま。
  Future<void> _backfillSlugs() async {
    for (final e in seedSlugByJapaneseName.entries) {
      await (update(categories)
            ..where((c) => c.name.equals(e.key) & c.slug.isNull()))
          .write(CategoriesCompanion(slug: Value(e.value)));
    }
    // 'その他' は expense/income で slug が分かれる。
    await (update(categories)
          ..where((c) =>
              c.name.equals('その他') &
              c.type.equalsValue(CategoryType.expense) &
              c.slug.isNull()))
        .write(const CategoriesCompanion(slug: Value('otherExpense')));
    await (update(categories)
          ..where((c) =>
              c.name.equals('その他') &
              c.type.equalsValue(CategoryType.income) &
              c.slug.isNull()))
        .write(const CategoriesCompanion(slug: Value('otherIncome')));
  }
}
