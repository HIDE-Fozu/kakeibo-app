import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/monthly/presentation/monthly_hub_screen.dart';

import '../support/test_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first),
        listen: false);

/// 食費カテゴリのidを取得（seed済みDB前提）。
Future<int> foodCategoryId(ProviderContainer c) async {
  final cats = await waitForData(c, allCategoriesProvider);
  return cats.firstWhere((cat) => cat.name == '食費').id;
}

void main() {
  // 固定時計 = 2026-07-15（test_app.dart のcreateHarness既定）
  testWidgets('これから: 固定費予定＋家事期日が日付順・見込み収支行が出る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const MonthlyHubScreen());
    final c = containerOf(tester);
    final catId = await foodCategoryId(c);

    final ruleRepo = c.read(recurringRuleRepositoryProvider);
    // 家賃(支出85,000・毎月27日) と 給料(収入280,000・毎月25日)。今日は7/15。
    await ruleRepo.add(RecurringRuleEntity(
      type: TxnType.expense,
      amountMinor: 85000,
      categoryId: catId,
      dayOfMonth: 27,
      storeName: '家賃',
      startYm: 202607,
    ));
    await ruleRepo.add(RecurringRuleEntity(
      type: TxnType.income,
      amountMinor: 280000,
      categoryId: catId,
      dayOfMonth: 25,
      startYm: 202607,
    ));
    // 家事: ハブラシ交換 毎月31日・anchor 7/1 → 期日 7/31（今月内）
    await c.read(choreRepositoryProvider).addTask(
        name: 'ハブラシ交換',
        emoji: '🪥',
        dayOfMonth: 31,
        anchorDate: const CivilDate(2026, 7, 1));
    await tester.pumpAndSettle();

    // タイムライン: 7/25給料 → 7/27家賃 → 7/31ハブラシ の順
    expect(find.text('予定'), findsNWidgets(2));
    expect(find.textContaining('家賃'), findsWidgets);
    expect(find.textContaining('ハブラシ交換'), findsWidgets);

    // 見込み収支（月末）: 実績0 + 280,000 - 85,000 = +195,000
    expect(find.byKey(const Key('hub-forecast-row')), findsOneWidget);
    expect(find.text('見込み収支（月末）'), findsOneWidget);
    expect(find.textContaining('+¥195,000'), findsOneWidget);

    // 家事セクションの行（あと16日 = 7/31 - 7/15）
    expect(find.text('あと16日'), findsOneWidget);
  });

  testWidgets('ルールのスイッチOFF→予定と見込みから外れる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const MonthlyHubScreen());
    final c = containerOf(tester);
    final catId = await foodCategoryId(c);

    final ruleRepo = c.read(recurringRuleRepositoryProvider);
    final id = await ruleRepo.add(RecurringRuleEntity(
      type: TxnType.expense,
      amountMinor: 85000,
      categoryId: catId,
      dayOfMonth: 27,
      startYm: 202607,
    ));
    await tester.pumpAndSettle();
    expect(find.text('予定'), findsOneWidget);
    expect(find.textContaining('-¥85,000'), findsWidgets);

    await tester.tap(find.byKey(Key('hub-rule-switch-$id')));
    await tester.pumpAndSettle();

    // 停止中: 予定バッジが消え、見込みは実績のみ（+¥0）
    expect(find.text('予定'), findsNothing);
    expect(find.textContaining('+¥0'), findsOneWidget);
  });

  testWidgets('＋からつきいちタスクを作成→一覧に出る（次回=今日+間隔）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const MonthlyHubScreen());

    expect(find.text('＋からハブラシ交換などの家事を登録できます'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hub-chore-add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('chore-form-name')), 'まくら干し');
    await tester.enterText(find.byKey(const Key('chore-form-emoji')), '🛏');
    await tester.tap(find.byKey(const Key('chore-form-save')));
    await tester.pumpAndSettle();

    // ハブへ戻り、一覧に出る（予定日は既定=今日の日(15) → 期日7/15=今日）
    expect(find.text('まくら干し'), findsWidgets);
    expect(find.text('毎月15日'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
  });

  testWidgets('タスク行→履歴→編集→アーカイブで一覧から消える', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const MonthlyHubScreen());
    final c = containerOf(tester);
    final taskId = await c.read(choreRepositoryProvider).addTask(
        name: 'フィルター掃除',
        emoji: '🧹',
        dayOfMonth: 15,
        anchorDate: const CivilDate(2026, 7, 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('hub-chore-$taskId')));
    await tester.pumpAndSettle();
    expect(find.text('履歴'), findsOneWidget);
    expect(find.text('記録はまだありません'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chore-edit-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chore-archive-btn')));
    await tester.pumpAndSettle();

    // 履歴に戻る→ハブへ戻るとアーカイブ済みは出ない
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('hub-chore-$taskId')), findsNothing);
  });
}
