import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('サマリタブ: 合計と内訳（降順・アーカイブラベル）・空状態', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);

    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final hobbyId = cats.firstWhere((x) => x.name == '趣味・娯楽').id;
    final salaryId = cats.firstWhere((x) => x.name == '給与').id;
    final repo = c.read(transactionRepositoryProvider);
    Future<void> add(int yen, int catId, TxnType type) =>
        repo.add(TransactionEntity(
            type: type,
            amountYen: yen,
            date: const CivilDate(2026, 7, 10),
            categoryId: catId,
            source: TxnSource.manual));
    await add(3000, foodId, TxnType.expense);
    await add(1000, hobbyId, TxnType.expense);
    await add(50000, salaryId, TxnType.income);
    await c.read(categoryRepositoryProvider).setArchived(hobbyId, true);

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();

    expect(find.text('2026年7月'), findsOneWidget);
    expect(find.text('+¥50,000'), findsOneWidget); // 収入
    expect(find.text('-¥4,000'), findsOneWidget); // 支出
    expect(find.text('+¥46,000'), findsOneWidget); // 差引
    expect(find.text('食費'), findsOneWidget);
    expect(find.text('趣味・娯楽（アーカイブ）'), findsOneWidget); // §4.3: 集計には残す
    expect(find.text('75%'), findsOneWidget); // 3000/4000

    // 内訳は金額降順: 食費が趣味より上
    final foodY = tester.getTopLeft(find.text('食費')).dy;
    final hobbyY = tester.getTopLeft(find.text('趣味・娯楽（アーカイブ）')).dy;
    expect(foodY, lessThan(hobbyY));

    // 空月へ移動すると空状態
    await tester.tap(find.byKey(const Key('summary-next')));
    await tester.pumpAndSettle();
    expect(find.text('この月のデータはまだありません'), findsOneWidget);
    expect(find.text('カレンダーの＋から入力できます'), findsOneWidget); // 入力導線（spec §5.5）
  });

  testWidgets('内訳ありカテゴリ: 合計はロールアップ・▼内訳で展開して内訳と（内訳なし）が出る',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final eatOutId = cats.firstWhere((x) => x.name == '外食').id;
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 1200,
        date: const CivilDate(2026, 7, 3),
        categoryId: foodId,
        source: TxnSource.manual));
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 800,
        date: const CivilDate(2026, 7, 20),
        categoryId: eatOutId,
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();

    expect(find.text('¥2,000'), findsOneWidget); // 食費グループ計（1200+800）
    expect(find.text('外食'), findsNothing); // 展開前は出ない

    await tester.tap(find.byKey(Key('expand-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('外食'), findsOneWidget);
    expect(find.text('¥800'), findsOneWidget);
    expect(find.text('（内訳なし）'), findsOneWidget);
    expect(find.text('¥1,200'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget); // 外食の親内%
    expect(find.text('60%'), findsOneWidget); // 内訳なしの親内%
    // （内訳なし）1200 > 外食800 → 降順で（内訳なし）が上（モック準拠）
    final directY = tester.getTopLeft(find.text('（内訳なし）')).dy;
    final eatOutY = tester.getTopLeft(find.text('外食')).dy;
    expect(directY, lessThan(eatOutY));

    // 再タップで畳む
    await tester.tap(find.byKey(Key('expand-$foodId')));
    await tester.pumpAndSettle();
    expect(find.text('外食'), findsNothing);
  });

  testWidgets('内訳のないカテゴリは従来の単色バー・expandトグルなし', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final dailyId = cats.firstWhere((x) => x.name == '日用品').id;
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 500,
        date: const CivilDate(2026, 7, 3),
        categoryId: dailyId,
        source: TxnSource.manual));
    await tester.pumpAndSettle();

    await tester.tap(find.text('サマリ'));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('expand-$dailyId')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('▼ 内訳'), findsNothing);
  });
}
