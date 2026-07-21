import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/category_emoji.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';

void main() {
  test('ja シード: slug が安定キーで付与される（外食=dining は食費=food の内訳）',
      () async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
    addTearDown(db.close);

    final all = await db.categoryDao.allCategories();
    final food = all.firstWhere((c) => c.slug == 'food');
    final dining = all.firstWhere((c) => c.slug == 'dining');
    expect(food.name, '食費');
    expect(dining.name, '外食');
    expect(dining.parentId, food.id);
    // その他は expense/income で slug が分かれる
    expect(all.where((c) => c.slug == 'otherExpense').single.type,
        CategoryType.expense);
    expect(all.where((c) => c.slug == 'otherIncome').single.type,
        CategoryType.income);
    // システム未分類は2件とも slug='uncategorized'
    expect(all.where((c) => c.slug == 'uncategorized').length, 2);
    // ユーザー作成でない全シード行に slug が付く
    expect(all.every((c) => c.slug != null), isTrue);
  });

  test('en シード: 端末言語=英語なら英語名で、slug は同一', () async {
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(),
          closeStreamsSynchronously: true),
      seedLocaleTag: 'en',
    );
    addTearDown(db.close);

    final all = await db.categoryDao.allCategories();
    expect(all.firstWhere((c) => c.slug == 'food').name, 'Food');
    expect(all.firstWhere((c) => c.slug == 'dining').name, 'Dining out');
    expect(all.firstWhere((c) => c.slug == 'salary').name, 'Salary');
    // 件数・構造は言語に依らず同じ
    expect(all.length, 20);
  });

  test('ko/es シード: 各言語の名称でシードされる', () async {
    for (final (lang, foodName) in [('ko', '식비'), ('es', 'Alimentación')]) {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(),
            closeStreamsSynchronously: true),
        seedLocaleTag: lang,
      );
      addTearDown(db.close);
      final all = await db.categoryDao.allCategories();
      expect(all.firstWhere((c) => c.slug == 'food').name, foodName);
      expect(all.length, 20);
    }
  });

  test('未対応言語は英語にフォールバック', () async {
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(),
          closeStreamsSynchronously: true),
      seedLocaleTag: 'xx', // 未対応
    );
    addTearDown(db.close);
    final all = await db.categoryDao.allCategories();
    expect(all.firstWhere((c) => c.slug == 'food').name, 'Food');
  });

  test('categoryEmoji: slug から絵文字、icon 優先、未知は既定', () {
    expect(categoryEmoji(null, 'food'), '🍚');
    expect(categoryEmoji('🎯', 'food'), '🎯'); // ユーザーicon優先
    expect(categoryEmoji(null, null), '📁'); // slugなし（ユーザー作成）
    expect(categoryEmoji(null, 'unknownSlug'), '📁');
  });
}
