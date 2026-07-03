import 'package:drift/drift.dart';
import 'tables.dart';
import 'daos.dart';
import 'enums.dart';
import 'converters.dart';
import '../../domain/money/civil_date.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

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
        },
        beforeOpen: (details) async {
          // FK は接続ごとに有効化しないと SQLite が無視する。
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated) {
            await _seedInitialCategories();
          }
        },
      );

  Future<void> _seedInitialCategories() async {
    // 並び順は sortOrder に一致させる。システム「未分類」は末尾。
    const expensePresets = <String>[
      '食費', '外食', '日用品', '水道光熱費', '通信費', '交通費', '交際費',
      '趣味・娯楽', '衣服・美容', '医療・健康', '住居', '教育', '特別費', 'その他',
    ];
    const incomePresets = <String>['給与', '賞与', '副収入', 'その他'];

    await batch((b) {
      var order = 0;
      for (final name in expensePresets) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.expense,
            sortOrder: Value(order++),
          ),
        );
      }
      for (final name in incomePresets) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.income,
            sortOrder: Value(order++),
          ),
        );
      }
      // システム「未分類」（削除不可・集計には含めるがピッカーで扱いを分ける）
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '未分類',
          type: CategoryType.expense,
          sortOrder: Value(order++),
          isSystem: const Value(true),
        ),
      );
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '未分類',
          type: CategoryType.income,
          sortOrder: Value(order++),
          isSystem: const Value(true),
        ),
      );
    });
  }
}
