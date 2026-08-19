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
  late TestHarness h;

  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    setPhoneSurface(tester);
    h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    return ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
  }

  Future<int> seed(ProviderContainer c, int yen,
      {int day = 15, TxnType type = TxnType.expense, String? memo}) async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    return c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: type,
        amountYen: yen,
        date: CivilDate(2026, 7, day),
        categoryId: foodId,
        source: TxnSource.manual,
        memo: memo));
  }

  testWidgets('月ヘッダ: 年月と支出/収入/差引、chevronで月移動', (tester) async {
    final c = await pumpShell(tester);
    await seed(c, 500);
    await seed(c, 2000, type: TxnType.income);
    await tester.pumpAndSettle();

    expect(find.text('2026年7月'), findsOneWidget);
    expect(find.textContaining('支出 ¥500'), findsOneWidget);
    expect(find.textContaining('収入 ¥2,000'), findsOneWidget);
    expect(find.textContaining('差引 +¥1,500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026年8月'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prev-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026年7月'), findsOneWidget);
  });

  testWidgets('日セルに支出のみの略記マーカーが出る', (tester) async {
    final c = await pumpShell(tester);
    await seed(c, 12345, day: 20);
    await tester.pumpAndSettle();
    expect(find.text('1.2万'), findsOneWidget);
  });

  testWidgets('日タップでその日のリスト、tap=編集・swipe=ごみ箱へ', (tester) async {
    final c = await pumpShell(tester);
    await seed(c, 800, day: 16, memo: 'コンビニ');
    await tester.pumpAndSettle();

    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    expect(find.text('コンビニ'), findsOneWidget);
    expect(find.text('-¥800'), findsOneWidget);

    // tap -> 編集画面
    await tester.tap(find.text('コンビニ'));
    await tester.pumpAndSettle();
    expect(find.text('編集'), findsOneWidget);
    await tester.tap(find.byType(CloseButton)); // fullscreenDialogは閉じるボタン
    await tester.pumpAndSettle();

    // swipe -> ごみ箱へ（FB 2026-08-16: Undoは撤去・×ボタン付き・10秒で消える）
    await tester.drag(find.text('コンビニ'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('ごみ箱に移動しました（設定から復元できます）'), findsOneWidget);
    expect(find.text('元に戻す'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget); // showCloseIcon
    expect(await c.read(transactionRepositoryProvider).forMonth(2026, 7), isEmpty);
    final trashed = await tester.runAsync(
        () => c.read(trashRepositoryProvider).watchAll().first);
    expect(trashed!.single.tx.amountYen, 800);
    // 10秒で自動的に消える（accessibleNavigation罠の回帰ガード:
    // アクション無しなので必ずタイマーで閉じる）
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('ごみ箱に移動しました（設定から復元できます）'), findsNothing);
  });

  testWidgets('空の日: 追加ボタンは無く、FABから選択日既定で入力が開く', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    expect(find.textContaining('記録はありません'), findsOneWidget);
    expect(find.byKey(const Key('add-on-day')), findsNothing); // 旧「この日に追加」は削除
    expect(find.textContaining('金額を入力する'), findsWidgets); // FAB＋空状態の案内
    // FABから選択日既定で入力が開く（テンキーが出る）
    await tester.tap(find.byKey(const Key('fab-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('np-00')), findsOneWidget);
    expect(find.text('2026年7月20日'), findsOneWidget);
  });

  testWidgets('FAB: 選択日を既定に入力画面へ', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fab-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('np-00')), findsOneWidget);
    expect(find.text('2026年7月18日'), findsOneWidget);
  });
}
