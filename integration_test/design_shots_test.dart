import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 紙デザイン刷新（2026-08-20 モック）の目視確認（使い捨て）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('paper design shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // モック相当のデータを実時計の当月に仕込む
    final c = ProviderScope.containerOf(
        t.element(find.byType(MaterialApp).first),
        listen: false);
    final cats = await c.read(categoryRepositoryProvider).active();
    final food = cats.firstWhere((x) => x.name == '食費');
    final income = cats.firstWhere((x) => x.type == CategoryType.income);
    final today = c.read(clockProvider)();
    final repo = c.read(transactionRepositoryProvider);
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 800,
        date: today,
        categoryId: food.id,
        storeName: 'コンビニ',
        source: TxnSource.manual));
    await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 72000,
        date: CivilDate(today.year, today.month, 27),
        categoryId: food.id,
        source: TxnSource.manual));
    await repo.add(TransactionEntity(
        type: TxnType.income,
        amountYen: 270000,
        date: CivilDate(today.year, today.month, 25),
        categoryId: income.id,
        source: TxnSource.manual));
    await settle(t);

    // 1) カレンダー全景（サマリカード・白カードセル・日別カードに行）
    await shot(t, 'design_1_calendar');

    // 1b) つきいちタブ（空状態）→ 日別へ戻す
    await t.tap(find.byKey(const Key('day-tab-chores')));
    await settle(t);
    await shot(t, 'design_1b_chores_tab');
    await t.tap(find.byKey(const Key('day-tab-label')));
    await settle(t);

    // 2) 空の日 → 空状態（支出/収入ボタン）
    await t.tap(find.text('5'));
    await settle(t);
    await shot(t, 'design_2_empty_day');

    // 3) 「収入を追加」→ 入力画面が収入で開く
    await t.tap(find.byKey(const Key('day-add-income')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'design_3_income_entry');
  });
}
