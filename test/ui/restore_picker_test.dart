import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/backup_controller.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('復元ピッカー: 確認ダイアログ→復元→SnackBar、UIも自動更新', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 500,
        date: const CivilDate(2026, 7, 15),
        categoryId: foodId,
        source: TxnSource.manual));
    await c.read(backupControllerProvider.notifier).backupNow(); // 1件時点
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 999,
        date: const CivilDate(2026, 7, 15),
        categoryId: foodId,
        source: TxnSource.manual)); // 2件に

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restore-tile')));
    await tester.pumpAndSettle();
    expect(find.textContaining('自動バックアップ'), findsOneWidget);

    await tester.tap(find.textContaining('自動バックアップ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-restore')));
    await tester.pumpAndSettle();

    expect(find.text('復元しました'), findsOneWidget);
    expect(await repo.forMonth(2026, 7), hasLength(1)); // 1件時点に戻った

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
