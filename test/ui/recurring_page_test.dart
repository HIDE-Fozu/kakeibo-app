import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/recurring/presentation/recurring_rules_page.dart';

import '../support/test_app.dart';

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

void main() {
  testWidgets('追加フロー: 金額+カテゴリ+日付を入れて保存 → 一覧表示＋当月分が起票される',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    // 固定時計は 2026-07-15（ハーネス既定）
    await pumpApp(tester, h, home: const RecurringRulesPage());

    // 空状態 → ＋で編集ページへ
    expect(find.byKey(const Key('recurring-add')), findsOneWidget);
    await tester.tap(find.byKey(const Key('recurring-add')));
    await tester.pumpAndSettle();

    // 保存は金額とカテゴリが揃うまで無効
    final saveBtn = find.byKey(const Key('recurring-save'));
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('recurring-amount')), '80000');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);

    // カテゴリ: 支出タブ既定のドロップダウンから「家賃・住まい」等の先頭を選ぶ
    await tester.tap(find.byKey(const Key('recurring-category-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('食費').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNotNull);

    // 日付は既定の毎月1日のまま・開始は今月から（7/1は経過済み→保存時に起票）
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // 一覧に戻り、ルールが表示される
    expect(find.textContaining('毎月1日'), findsOneWidget);
    expect(find.textContaining('食費'), findsOneWidget);

    // 当月分（2026-07-01）が起票済み
    final c = containerOf(tester);
    final txs =
        await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs, hasLength(1));
    expect(txs.single.amountYen, 80000);
    expect(txs.single.date, const CivilDate(2026, 7, 1));
    expect(txs.single.source, TxnSource.recurring);
  });

  testWidgets('終了月: 「この月で支払いが終わる」を選んで保存 → endYm が入る',
      (tester) async {
    Future<void> settle() => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5));
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    // 固定時計は 2026-07-15 → 終了月の選択肢は 2026年7月から
    await pumpApp(tester, h, home: const RecurringRulesPage());
    await tester.tap(find.byKey(const Key('recurring-add')));
    await settle();
    await tester.enterText(find.byKey(const Key('recurring-amount')), '5000');
    await tester.tap(find.byKey(const Key('recurring-category-expense')));
    await settle();
    await tester.tap(find.textContaining('食費').last);
    await settle();

    // 既定は「終了なし（ずっと）」→ 2026年10月を選ぶ
    await tester.ensureVisible(find.byKey(const Key('recurring-end')));
    await settle();
    await tester.tap(find.byKey(const Key('recurring-end')),
        warnIfMissed: false);
    await settle();
    expect(find.text('終了なし（ずっと）'), findsWidgets); // 欄＋メニュー項目
    await tester.tap(find.text('2026年10月').last, warnIfMissed: false);
    await settle();

    await tester.ensureVisible(find.byKey(const Key('recurring-save')));
    await tester.tap(find.byKey(const Key('recurring-save')));
    await settle();

    // watchAll().first はテストのfake asyncゾーンでデッドロックするので、
    // ページが購読済みの StreamProvider の現在値を同期読みする。
    final c = containerOf(tester);
    final rules =
        c.read(recurringRulesProvider).valueOrNull ?? const <RecurringRuleEntity>[];
    expect(rules.single.endYm, 202610);
  });

  testWidgets('編集フロー: 停止スイッチ・削除ができる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h, home: const RecurringRulesPage());
    final c = containerOf(tester);

    // 事前にルールを1件作成（来月開始=起票なし）
    final cats = await c.read(categoryRepositoryProvider).active();
    final food = cats.firstWhere((cat) => cat.slug == 'food');
    final id = await c.read(recurringRuleRepositoryProvider).add(
          RecurringRuleEntity(
            type: TxnType.expense,
            amountMinor: 12000,
            categoryId: food.id,
            dayOfMonth: 5,
            startYm: 202608,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byKey(Key('recurring-rule-$id')), findsOneWidget);

    // 編集ページへ → 停止に切り替えて保存
    await tester.tap(find.byKey(Key('recurring-rule-$id')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recurring-active')), findsOneWidget);
    await tester.tap(find.byKey(const Key('recurring-active')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('recurring-save')));
    await tester.tap(find.byKey(const Key('recurring-save')));
    await tester.pumpAndSettle();

    // 一覧に「停止中」が出る
    expect(find.textContaining('停止中'), findsOneWidget);

    // 再度開いて削除 → 確認ダイアログ → 一覧から消える
    await tester.tap(find.byKey(Key('recurring-rule-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-delete-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('recurring-rule-$id')), findsNothing);
    // 注意: fake-async 内で drift の stream.first を await するとハングするため
    // DAO の Future で確認する。
    expect(await h.db.recurringRuleDao.allRules(), isEmpty);
  });

  testWidgets('支出/収入セグメント切替でカテゴリ選択がリセットされる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: const RecurringRuleEditPage(rule: null));

    await tester.enterText(find.byKey(const Key('recurring-amount')), '500');
    await tester.tap(find.byKey(const Key('recurring-category-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('食費').last);
    await tester.pumpAndSettle();
    final saveBtn = find.byKey(const Key('recurring-save'));
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNotNull);

    // 収入へ切替 → カテゴリ未選択に戻り保存不可・ドロップダウンは収入用に
    await tester.tap(find.text('収入'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);
    expect(find.byKey(const Key('recurring-category-income')), findsOneWidget);
    expect(find.byKey(const Key('recurring-category-expense')), findsNothing);
  });
}
