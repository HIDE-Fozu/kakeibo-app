import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'support/test_db.dart';

void main() {
  test('a fresh database is seeded with presets and system categories', () async {
    final db = newMemoryDb();
    addTearDown(db.close);

    final all = await db.categoryDao.allCategories();
    // 支出プリセット14 + 収入プリセット4 + 未分類システム2 = 20
    expect(all.length, 20);

    final systems = all.where((c) => c.isSystem).toList();
    expect(systems.length, 2);
    expect(systems.where((c) => c.type == CategoryType.expense).length, 1);
    expect(systems.where((c) => c.type == CategoryType.income).length, 1);

    // プリセットに「食費」と「給与」が含まれる
    expect(all.any((c) => c.name == '食費' && c.type == CategoryType.expense), isTrue);
    expect(all.any((c) => c.name == '給与' && c.type == CategoryType.income), isTrue);

    // 外食は食費の内訳としてシードされる（モック確定のデモ構成）
    final food = all.firstWhere((c) => c.name == '食費');
    final eatOut = all.firstWhere((c) => c.name == '外食');
    expect(eatOut.parentId, food.id);
    expect(eatOut.sortOrder, 0); // 内訳スコープ内の先頭
    // 内訳シードは外食のみ。他は全て親
    expect(all.where((c) => c.parentId != null).length, 1);

    // 全プリセットに絵文字アイコンが付与される（v3）
    expect(food.icon, '🍚');
    expect(all.every((c) => c.icon != null && c.icon!.isNotEmpty), isTrue);
  });

  test('uncategorizedId returns the system category id per type', () async {
    final db = newMemoryDb();
    addTearDown(db.close);

    final expUncat = await db.categoryDao.uncategorizedId(CategoryType.expense);
    final incUncat = await db.categoryDao.uncategorizedId(CategoryType.income);
    expect(expUncat, isNot(incUncat));

    final all = await db.categoryDao.allCategories();
    expect(all.firstWhere((c) => c.id == expUncat).isSystem, isTrue);
    expect(all.firstWhere((c) => c.id == expUncat).type, CategoryType.expense);
  });
}
