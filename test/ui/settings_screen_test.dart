import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;

  Future<ProviderContainer> openSettings(WidgetTester tester) async {
    setPhoneSurface(tester);
    h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> seed(ProviderContainer c) async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 500,
        date: const CivilDate(2026, 7, 10),
        categoryId: foodId,
        source: TxnSource.manual));
  }

  testWidgets('ステータス→今すぐバックアップで「今日」に変わる', (tester) async {
    final c = await openSettings(tester);
    await seed(c);
    await tester.pumpAndSettle();
    expect(find.text('バックアップ未作成'), findsWidgets); // 設定＋カレンダーバナー
    await tester.tap(find.byKey(const Key('backup-now')));
    await tester.pumpAndSettle();
    expect(find.textContaining('前回バックアップ'), findsWidgets);

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('JSONエクスポート: 暗号化選択で.kkbkが作られる', (tester) async {
    final c = await openSettings(tester);
    await seed(c);
    await tester.tap(find.byKey(const Key('export-json')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('passphrase-field')), 'pw');
    await tester.tap(find.text('暗号化して保存'));
    await tester.pumpAndSettle();
    expect(find.textContaining('保存しました'), findsOneWidget);
    expect(h.exportsDir.listSync().where((f) => f.path.endsWith('.kkbk')),
        hasLength(1));

    // SnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('CSVエクスポートとレシート画像トグルの永続化', (tester) async {
    final c = await openSettings(tester);
    await seed(c);
    await tester.tap(find.byKey(const Key('export-csv')));
    await tester.pumpAndSettle();
    expect(h.exportsDir.listSync().where((f) => f.path.endsWith('.csv')),
        hasLength(1));

    await tester.tap(find.byKey(const Key('retain-images-switch')));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).retainReceiptImages, isTrue);

    // CSVエクスポートのSnackBar Timer(4s)を消化
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
