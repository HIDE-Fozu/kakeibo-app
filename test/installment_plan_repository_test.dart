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

  setUp(() async {
    h = await createHarness();
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
  });

  InstallmentPlanEntity planOf({int? id, int count = 3}) =>
      InstallmentPlanEntity(
        id: id,
        principalMinor: 30000,
        count: count,
        annualRatePercent: 0,
        categoryId: foodId,
        dayOfMonth: 15,
        startYm: 202609,
        cardName: '楽天カード',
      );

  List<TransactionEntity> paymentsOf(int count, int amount) => [
        for (var i = 0; i < count; i++)
          TransactionEntity(
            type: TxnType.expense,
            amountYen: amount,
            date: CivilDate(2026, 9 + i, 15),
            categoryId: foodId,
            storeName: '楽天カード',
            memo: '分割払い ${i + 1}/$count回',
            source: TxnSource.manual,
          ),
      ];

  test('add: 計画と取引が紐づいて保存される', () async {
    final repo = c.read(installmentPlanRepositoryProvider);
    final id = await repo.add(planOf(), paymentsOf(3, 10000));
    final plans = c.read(installmentPlanRepositoryProvider);
    expect(id, greaterThan(0));
    final txRepo = c.read(transactionRepositoryProvider);
    final sep = await txRepo.forMonth(2026, 9);
    expect(sep.single.installmentPlanId, id);
    expect(sep.single.amountYen, 10000);
    expect((await txRepo.forMonth(2026, 11)).single.installmentPlanId, id);
    expect(plans, isNotNull);
  });

  test('replace: 紐づく取引が作り直される（他の取引は無傷）', () async {
    final repo = c.read(installmentPlanRepositoryProvider);
    final txRepo = c.read(transactionRepositoryProvider);
    // 無関係の取引
    await txRepo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 500,
        date: const CivilDate(2026, 9, 1),
        categoryId: foodId,
        source: TxnSource.manual));
    final id = await repo.add(planOf(), paymentsOf(3, 10000));

    // 2回に編集（金額も変更）
    await repo.replace(planOf(id: id, count: 2), paymentsOf(2, 15000));
    final sep = await txRepo.forMonth(2026, 9);
    expect(sep, hasLength(2)); // 無関係の500円 + 新しい1回目
    expect(sep.where((t) => t.installmentPlanId == id).single.amountYen, 15000);
    expect((await txRepo.forMonth(2026, 11)), isEmpty); // 旧3回目は消えた
  });

  test('delete: 計画と紐づく取引が消える（他の取引は無傷）', () async {
    final repo = c.read(installmentPlanRepositoryProvider);
    final txRepo = c.read(transactionRepositoryProvider);
    await txRepo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 500,
        date: const CivilDate(2026, 9, 1),
        categoryId: foodId,
        source: TxnSource.manual));
    final id = await repo.add(planOf(), paymentsOf(3, 10000));
    await repo.delete(id);
    final sep = await txRepo.forMonth(2026, 9);
    expect(sep.single.amountYen, 500);
    expect(await txRepo.forMonth(2026, 10), isEmpty);
  });

  test('add: 住宅ローン級（420回）も一括insertで全件入る', () async {
    final repo = c.read(installmentPlanRepositoryProvider);
    final payments = [
      for (var i = 0; i < 420; i++)
        TransactionEntity(
          type: TxnType.expense,
          amountYen: 100,
          date: CivilDate(2026 + (8 + i) ~/ 12, (8 + i) % 12 + 1, 15),
          categoryId: foodId,
          source: TxnSource.manual,
        ),
    ];
    final planId = await repo.add(planOf(count: 420), payments);
    expect(await c.read(transactionRepositoryProvider).count(), 420);
    // 先頭と最後（2026-09-15 と 2061-08-15）が計画に紐づいている
    final first = await c.read(transactionRepositoryProvider).forMonth(2026, 9);
    final last = await c.read(transactionRepositoryProvider).forMonth(2061, 8);
    expect(first.single.installmentPlanId, planId);
    expect(last.single.installmentPlanId, planId);
  });
}
