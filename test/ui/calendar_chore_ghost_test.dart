import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

import '../support/test_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first),
        listen: false);

Future<int> foodCategoryId(ProviderContainer c) async {
  final cats = await waitForData(c, allCategoriesProvider);
  return cats.firstWhere((cat) => cat.name == '食費').id;
}

/// 統合カレンダー（家事ドット・固定費ゴースト・見込み収支）のUIテスト。
/// 固定時計 = 2026-07-15（createHarness既定）。
void main() {
  testWidgets('ゴースト: セルにグレー額・日パネルに予定行・見込み行が出る', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);
    final catId = await foodCategoryId(c);

    // 家賃 85,000・毎月27日（今日7/15 → 7/27は未来 = ゴースト）
    await c.read(recurringRuleRepositoryProvider).add(RecurringRuleEntity(
          type: TxnType.expense,
          amountMinor: 85000,
          categoryId: catId,
          dayOfMonth: 27,
          storeName: '家賃',
          startYm: 202607,
        ));
    await tester.pumpAndSettle();

    // セル27にグレーの予定額
    expect(find.byKey(const Key('ghost-amount-2026-07-27')), findsOneWidget);
    // 凡例
    expect(find.text('固定費の予定'), findsOneWidget);
    // ヘッダーの見込み収支（月末）: 実績0 - 85,000
    expect(find.byKey(const Key('forecast-line')), findsOneWidget);
    expect(find.textContaining('見込み収支（月末）'), findsOneWidget);
    expect(find.textContaining('-¥85,000'), findsWidgets);

    // 7/27を選択→日パネルに「予定」行
    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ghost-1')), findsOneWidget);
    expect(find.text('予定'), findsOneWidget);

    // 予定行タップ→ルール編集ページへ
    await tester.tap(find.byKey(const ValueKey('ghost-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recurring-save')), findsOneWidget);
  });

  testWidgets('基準日シート: 毎月25日にすると見込みが25日時点になる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);
    final catId = await foodCategoryId(c);
    await c.read(recurringRuleRepositoryProvider).add(RecurringRuleEntity(
          type: TxnType.expense,
          amountMinor: 85000,
          categoryId: catId,
          dayOfMonth: 27,
          startYm: 202607,
        ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('forecast-line')));
    await tester.pumpAndSettle();
    expect(find.text('見込み収支の基準日'), findsOneWidget);

    // 「毎月25日」（日指定タイルの既定値）を選択
    await tester.tap(find.byKey(const Key('forecast-anchor-day')));
    await tester.pumpAndSettle();

    // 25日時点: 家賃(27日)は含まれない → +¥0。ラベルは（7/25時点）
    // （「差引 +¥0」と紛れないよう見込み行の文字列全体で確認）
    expect(find.textContaining('見込み収支（7/25時点）　+¥0'), findsOneWidget);

    // 月末に戻す
    await tester.tap(find.byKey(const Key('forecast-line')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forecast-anchor-monthend')));
    await tester.pumpAndSettle();
    expect(find.textContaining('見込み収支（月末）'), findsOneWidget);
  });

  testWidgets('家事: 期日ドット・今日の日パネルの「やった」で記録→期日が進む', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);

    // ハブラシ交換 14日ごと・anchor 7/1 → 期日 7/15（今日）
    await c.read(choreRepositoryProvider).addTask(
        name: 'ハブラシ交換',
        emoji: '🪥',
        intervalDays: 14,
        anchorDate: const CivilDate(2026, 7, 1));
    await tester.pumpAndSettle();

    // 今日(7/15)に期日ドット（橙）・日パネルに期日行+やったボタン
    expect(find.byKey(const Key('chore-dot-due-2026-07-15')), findsOneWidget);
    expect(find.text('今日'), findsWidgets);
    final doneBtn = find.byKey(const Key('chore-done-btn-1'));
    expect(doneBtn, findsOneWidget);

    await tester.tap(doneBtn);
    await tester.pumpAndSettle();

    // スナックバー（次回 7/29 = 7/15 + 14）と実施記録行・緑ドット
    expect(find.textContaining('次回は7/29'), findsOneWidget);
    expect(find.byKey(const Key('chore-dot-done-2026-07-15')), findsOneWidget);
    expect(find.byKey(const Key('chore-dot-due-2026-07-29')), findsOneWidget);
    expect(find.byKey(const Key('chore-done-1')), findsOneWidget); // 記録行
    expect(find.byKey(const Key('chore-done-btn-1')), findsNothing); // 期日行は消えた
  });

  testWidgets('家事: 超過は赤ドット+今日のパネルに超過行（過去日のパネルには出ない）', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);

    // anchor 6/1・30日ごと → 期日 7/1（今日7/15 → 14日超過）
    await c.read(choreRepositoryProvider).addTask(
        name: 'フィルター掃除',
        emoji: '🧹',
        intervalDays: 30,
        anchorDate: const CivilDate(2026, 6, 1));
    await tester.pumpAndSettle();

    // 期日7/1に赤ドット・今日のパネルに超過行（やった付き）
    expect(
        find.byKey(const Key('chore-dot-overdue-2026-07-01')), findsOneWidget);
    expect(find.text('14日超過'), findsOneWidget);
    expect(find.byKey(const Key('chore-done-btn-1')), findsOneWidget);

    // 過去日(7/10)を選ぶと超過行は出ない（救済導線は今日だけ）
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chore-due-1')), findsNothing);
  });
}
