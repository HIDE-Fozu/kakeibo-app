import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/app/theme.dart';
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

  testWidgets('ページの色: フルカラーピッカーで背景色を変更できる', (tester) async {
    final c = await openSettings(tester);
    // 設定リストの色タイルまでスクロール
    await tester.scrollUntilVisible(
        find.byKey(const Key('page-color-tile')), 200);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accent-color-tile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('page-color-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('color-preview')), findsOneWidget);

    // Bスライダを左端へ動かす → 背景色が既定(kPaper)から変わる
    await tester.drag(find.byType(Slider).last, const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('color-apply')));
    await tester.pumpAndSettle();

    expect(c.read(appSettingsProvider).pageColor.toARGB32(),
        isNot(kPaper.toARGB32()));
  });

  testWidgets('言語タイル: Englishを選ぶと設定に永続化される', (tester) async {
    final c = await openSettings(tester);
    await tester.scrollUntilVisible(
        find.byKey(const Key('language-tile')), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).locale?.languageCode, 'en');
  });

  testWidgets('通貨タイル: 取引が無ければUSDに変更できる', (tester) async {
    final c = await openSettings(tester);
    await tester.scrollUntilVisible(
        find.byKey(const Key('currency-tile')), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('USD'));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).currencyCode, 'USD');
  });

  testWidgets('通貨タイル: 取引があるとロックされ変更不可', (tester) async {
    final c = await openSettings(tester);
    await seed(c); // 取引を1件作る
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('currency-tile')), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-tile')));
    await tester.pumpAndSettle();
    // ロック説明ダイアログが出て、ピッカーは開かない。
    expect(find.text('通貨は変更できません'), findsOneWidget);
    expect(c.read(appSettingsProvider).currencyCode, 'JPY');
  });
}
