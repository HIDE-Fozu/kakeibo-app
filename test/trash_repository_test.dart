import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import 'support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late int foodId;
  // 可変時計（purgeのテストで進める）。既定はハーネス既定と同じ。
  late DateTime nowUtc;

  setUp(() async {
    h = await createHarness();
    nowUtc = DateTime.utc(2026, 7, 15, 3, 0);
    c = ProviderContainer(overrides: h.overrides(utcNow: () => nowUtc));
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
  });

  TransactionEntity txOf({int amount = 800, String? store, String? group}) =>
      TransactionEntity(
        type: TxnType.expense,
        amountYen: amount,
        date: const CivilDate(2026, 7, 10),
        categoryId: foodId,
        storeName: store,
        memo: 'メモ',
        source: TxnSource.manual,
        splitGroupId: group,
      );

  test('moveToTrash: 取引が消え、内容ごとごみ箱へ移る', () async {
    final txRepo = c.read(transactionRepositoryProvider);
    final trash = c.read(trashRepositoryProvider);
    final id = await txRepo.add(txOf(store: 'コンビニ', group: 'g1'));
    await trash.moveToTrash(id);
    expect(await txRepo.forMonth(2026, 7), isEmpty);
    final e = (await trash.watchAll().first).single;
    expect(e.deletedAt, nowUtc);
    expect(e.tx.amountYen, 800);
    expect(e.tx.storeName, 'コンビニ');
    expect(e.tx.memo, 'メモ');
    expect(e.tx.splitGroupId, 'g1');
    expect(e.tx.categoryId, foodId);
    expect(e.tx.date, const CivilDate(2026, 7, 10));
  });

  test('moveToTrash: 存在しないidは何もしない（冪等）', () async {
    final trash = c.read(trashRepositoryProvider);
    await trash.moveToTrash(999);
    expect(await trash.watchAll().first, isEmpty);
  });

  test('restore: 同内容で取引に戻り、ごみ箱から消える', () async {
    final txRepo = c.read(transactionRepositoryProvider);
    final trash = c.read(trashRepositoryProvider);
    final id = await txRepo.add(txOf(store: 'コンビニ'));
    await trash.moveToTrash(id);
    final e = (await trash.watchAll().first).single;
    await trash.restore(e.id);
    final back = (await txRepo.forMonth(2026, 7)).single;
    expect(back.amountYen, 800);
    expect(back.storeName, 'コンビニ');
    expect(back.memo, 'メモ');
    expect(await trash.watchAll().first, isEmpty);
    // 冪等: もう一度restoreしても二重にならない
    await trash.restore(e.id);
    expect((await txRepo.forMonth(2026, 7)).length, 1);
  });

  InstallmentPlanEntity planOf({int count = 2}) => InstallmentPlanEntity(
        principalMinor: 20000,
        count: count,
        annualRatePercent: 0,
        categoryId: foodId,
        dayOfMonth: 15,
        startYm: 202609,
        cardName: '楽天カード',
      );

  List<TransactionEntity> paymentsOf(int count) => [
        for (var i = 0; i < count; i++)
          TransactionEntity(
            type: TxnType.expense,
            amountYen: 10000,
            date: CivilDate(2026, 9 + i, 15),
            categoryId: foodId,
            source: TxnSource.manual,
          ),
      ];

  test('restore: 分割払いの計画が残っていれば紐付けを保つ', () async {
    final txRepo = c.read(transactionRepositoryProvider);
    final trash = c.read(trashRepositoryProvider);
    final planId = await c
        .read(installmentPlanRepositoryProvider)
        .add(planOf(), paymentsOf(2));
    final pay = (await txRepo.forMonth(2026, 9)).single;
    await trash.moveToTrash(pay.id!);
    final e = (await trash.watchAll().first).single;
    expect(e.tx.installmentPlanId, planId);
    await trash.restore(e.id);
    expect((await txRepo.forMonth(2026, 9)).single.installmentPlanId, planId);
  });

  test('restore: 計画が消えていたら紐付けを外して復元する', () async {
    final txRepo = c.read(transactionRepositoryProvider);
    final trash = c.read(trashRepositoryProvider);
    final planRepo = c.read(installmentPlanRepositoryProvider);
    final planId = await planRepo.add(planOf(), paymentsOf(2));
    final pay = (await txRepo.forMonth(2026, 9)).single;
    await trash.moveToTrash(pay.id!);
    await planRepo.delete(planId); // 10月分の取引も消える（ごみ箱の行は残る）
    final e = (await trash.watchAll().first).single;
    await trash.restore(e.id);
    final back = (await txRepo.forMonth(2026, 9)).single;
    expect(back.installmentPlanId, isNull);
    expect(back.amountYen, 10000);
  });

  test('purgeExpired: 30日を超えた行だけ消える', () async {
    final txRepo = c.read(transactionRepositoryProvider);
    final trash = c.read(trashRepositoryProvider);
    final id1 = await txRepo.add(txOf(amount: 100));
    final id2 = await txRepo.add(txOf(amount: 200));
    await trash.moveToTrash(id1); // deletedAt = 7/15
    nowUtc = DateTime.utc(2026, 8, 4, 3, 0);
    await trash.moveToTrash(id2); // deletedAt = 8/4
    nowUtc = DateTime.utc(2026, 8, 15, 3, 1); // 7/15分だけ30日超
    final removed = await trash.purgeExpired();
    expect(removed, 1);
    final rest = await trash.watchAll().first;
    expect(rest.single.tx.amountYen, 200);
  });

  test('emptyTrash: 全行が消える', () async {
    final txRepo = c.read(transactionRepositoryProvider);
    final trash = c.read(trashRepositoryProvider);
    await trash.moveToTrash(await txRepo.add(txOf(amount: 100)));
    await trash.moveToTrash(await txRepo.add(txOf(amount: 200)));
    await trash.emptyTrash();
    expect(await trash.watchAll().first, isEmpty);
  });
}
