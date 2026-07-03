import 'package:drift/drift.dart';
import 'tables.dart';
import 'daos.dart';
import 'enums.dart';
import 'converters.dart';
import '../../domain/money/civil_date.dart';

part 'database.g.dart';

/// プリセットカテゴリの絵文字アイコン（シードとv3マイグレーションで共用）。
/// マイグレーションは名前一致かつicon未設定の行のみ埋める（ユーザー設定を尊重）。
const presetCategoryIcons = <String, String>{
  '食費': '🍚',
  '外食': '🍽️',
  '日用品': '🧴',
  '水道光熱費': '💡',
  '通信費': '📱',
  '交通費': '🚃',
  '交際費': '🍻',
  '趣味・娯楽': '🎮',
  '衣服・美容': '👕',
  '医療・健康': '🩺',
  '住居': '🏠',
  '教育': '📚',
  '特別費': '🎁',
  'その他': '📦',
  '給与': '💰',
  '賞与': '🎉',
  '副収入': '💼',
  '未分類': '❓',
};

@DriftDatabase(
  tables: [Categories, Transactions],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

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
            // v3: プリセットカテゴリへ絵文字アイコンを後付け。
            for (final e in presetCategoryIcons.entries) {
              await (update(categories)
                    ..where((c) => c.name.equals(e.key) & c.icon.isNull()))
                  .write(CategoriesCompanion(icon: Value(e.value)));
            }
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
    // 並び順は sortOrder に一致させる（スコープ＝同じ親の中）。システム「未分類」は末尾。
    // 外食は食費の内訳としてシード（モック確定のデモ構成に合わせる）。
    final foodId = await into(categories).insert(CategoriesCompanion.insert(
      name: '食費',
      type: CategoryType.expense,
      icon: Value(presetCategoryIcons['食費']),
      sortOrder: const Value(0),
    ));
    const expensePresets = <String>[
      '日用品', '水道光熱費', '通信費', '交通費', '交際費',
      '趣味・娯楽', '衣服・美容', '医療・健康', '住居', '教育', '特別費', 'その他',
    ];
    const incomePresets = <String>['給与', '賞与', '副収入', 'その他'];

    await batch((b) {
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '外食',
          type: CategoryType.expense,
          icon: Value(presetCategoryIcons['外食']),
          sortOrder: const Value(0), // 内訳スコープ内の先頭
          parentId: Value(foodId),
        ),
      );
      var order = 1; // 食費=0 の続きから
      for (final name in expensePresets) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.expense,
            icon: Value(presetCategoryIcons[name]),
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
            icon: Value(presetCategoryIcons[name]),
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
          icon: Value(presetCategoryIcons['未分類']),
          sortOrder: Value(order++),
          isSystem: const Value(true),
        ),
      );
      b.insert(
        categories,
        CategoriesCompanion.insert(
          name: '未分類',
          type: CategoryType.income,
          icon: Value(presetCategoryIcons['未分類']),
          sortOrder: Value(order++),
          isSystem: const Value(true),
        ),
      );
    });
  }
}
