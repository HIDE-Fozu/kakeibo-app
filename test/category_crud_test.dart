import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_category_repository.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository repo;

  setUp(() {
    db = newMemoryDb();
    repo = DriftCategoryRepository(db);
  });

  tearDown(() => db.close());

  test('addCategory: 末尾sortOrderで追加され watchAll に現れる', () async {
    final id = await repo.addCategory(name: 'ペット', type: CategoryType.expense, icon: '🐈');
    final all = await repo.watchAll().first;
    final added = all.firstWhere((c) => c.id == id);
    expect(added.name, 'ペット');
    final maxOther = all
        .where((c) => c.id != id)
        .map((c) => c.sortOrder)
        .reduce((a, b) => a > b ? a : b);
    expect(added.sortOrder, greaterThan(maxOther - 1));
  });

  test('addCategory: 空白名はArgumentError', () async {
    expect(() => repo.addCategory(name: '  ', type: CategoryType.expense),
        throwsArgumentError);
  });

  test('rename が反映され、システムカテゴリはSystemCategoryError', () async {
    final all = await repo.watchAll().first;
    final food = all.firstWhere((c) => c.name == '食費');
    final system = all.firstWhere((c) => c.isSystem);
    await repo.rename(food.id, '食料品');
    expect((await repo.watchAll().first).any((c) => c.name == '食料品'), isTrue);
    expect(() => repo.rename(system.id, 'x'), throwsA(isA<SystemCategoryError>()));
  });

  test('setArchived の往復とシステム保護', () async {
    final all = await repo.watchAll().first;
    final food = all.firstWhere((c) => c.name == '食費');
    final system = all.firstWhere((c) => c.isSystem);
    await repo.setArchived(food.id, true);
    expect((await repo.watchAll().first).firstWhere((c) => c.id == food.id).isArchived,
        isTrue);
    await repo.setArchived(food.id, false);
    expect((await repo.watchAll().first).firstWhere((c) => c.id == food.id).isArchived,
        isFalse);
    expect(() => repo.setArchived(system.id, true),
        throwsA(isA<SystemCategoryError>()));
  });

  test('reorder: 渡した順で sortOrder=0.. が振られる', () async {
    final all = await repo.watchAll().first;
    final exp = all
        .where((c) => c.type == CategoryType.expense && !c.isSystem)
        .toList();
    final reversed = exp.reversed.map((c) => c.id).toList();
    await repo.reorder(reversed);
    final after = await repo.watchAll().first;
    final byId = {for (final c in after) c.id: c};
    for (var i = 0; i < reversed.length; i++) {
      expect(byId[reversed[i]]!.sortOrder, i);
    }
  });
}
