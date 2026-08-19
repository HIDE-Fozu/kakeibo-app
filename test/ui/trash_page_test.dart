import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/presentation/trash_page.dart';

import '../support/test_app.dart';

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

Future<int> seedTrashed(WidgetTester tester, ProviderContainer c,
    {int amount = 800, String? store}) async {
  return (await tester.runAsync(() async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final id = await c.read(transactionRepositoryProvider).add(TransactionEntity(
          type: TxnType.expense,
          amountYen: amount,
          date: const CivilDate(2026, 7, 10),
          categoryId: foodId,
          storeName: store,
          source: TxnSource.manual,
        ));
    await c.read(trashRepositoryProvider).moveToTrash(id);
    return id;
  }))!;
}

void main() {
  testWidgets('ごみ箱: 空状態→行の表示→復元でSnackBarと共に戻る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const TrashPage());
    expect(find.text('ごみ箱は空です'), findsOneWidget);

    final c = containerOf(tester);
    await seedTrashed(tester, c, store: 'コンビニ');
    await tester.pumpAndSettle();
    expect(find.text('食費'), findsOneWidget);
    expect(find.text('-¥800'), findsOneWidget);
    expect(find.textContaining('コンビニ'), findsOneWidget);
    expect(find.textContaining('に削除'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restore));
    await tester.pumpAndSettle();
    expect(find.text('復元しました'), findsOneWidget);
    expect(find.text('ごみ箱は空です'), findsOneWidget);
    final back = await tester.runAsync(
        () => c.read(transactionRepositoryProvider).forMonth(2026, 7));
    expect(back!.single.amountYen, 800);
    // SnackBarのタイマー回収
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('ごみ箱を空にする: 確認ダイアログ→全消し', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const TrashPage());
    final c = containerOf(tester);
    await seedTrashed(tester, c, amount: 100);
    await seedTrashed(tester, c, amount: 200);
    await tester.pumpAndSettle();
    expect(find.text('-¥100'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trash-empty')));
    await tester.pumpAndSettle();
    expect(find.text('ごみ箱を空にしますか？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('trash-empty-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('ごみ箱は空です'), findsOneWidget);
    final rest = await tester.runAsync(
        () => c.read(trashRepositoryProvider).watchAll().first);
    expect(rest, isEmpty);
  });
}
