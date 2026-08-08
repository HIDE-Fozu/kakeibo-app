import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/entry/application/entry_form_controller.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';

import '../support/test_app.dart';

/// EntryScreen はpushして開く（popの検証のため）。entry_screen_test と同型。
class Host extends ConsumerWidget {
  final void Function(WidgetRef ref) onOpen;
  const Host({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              onOpen(ref);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EntryScreen()));
            },
            child: const Text('open'),
          ),
        ),
      );
}

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
    listen: false);

/// 「毎月の費用/収入」トグル。固定時計 = 2026-07-15。
void main() {
  testWidgets('ON→保存: 記帳+ルール作成・当月の二重起票なし・帯と文言', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) => ref
                .read(entryFormControllerProvider.notifier)
                .startCreate(const CivilDate(2026, 7, 15))));
    final c = containerOf(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 金額 ¥85,000
    await tester.tap(find.text('8'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('0'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();

    // トグルON → 予告帯（毎月[15▾]日に自動で記帳します）+ 保存文言が変わる
    await tester.tap(find.byKey(const Key('entry-recurring-btn')));
    await tester.pump();
    expect(find.byKey(const Key('entry-recurring-note')), findsOneWidget);
    expect(
        tester
            .widget<DropdownButton<int>>(
                find.byKey(const Key('entry-recurring-day')))
            .value,
        15);
    expect(find.text('日に自動で記帳します'), findsOneWidget);
    expect(find.text('保存（＋毎月の費用に登録）'), findsOneWidget);

    await tester.tap(find.textContaining('食費'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('save-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    // 取引は今回の1件だけ（ルールの当月分は watermark 済みで二重起票しない）
    final txs =
        await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.amountYen, 85000);
    expect(txs.single.source, TxnSource.manual);

    // ルールが作られている（毎月15日・startYm=当月・lastGeneratedYm=当月）
    final rules = await c.read(appDatabaseProvider).recurringRuleDao.allRules();
    expect(rules.single.dayOfMonth, 15);
    expect(rules.single.amount, 85000);
    expect(rules.single.type, TxnType.expense);
    expect(rules.single.startYm, 202607);
    expect(rules.single.lastGeneratedYm, 202607);
  });

  testWidgets('収入タブではボタン・保存文言が「毎月の収入」になる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) => ref
                .read(entryFormControllerProvider.notifier)
                .startCreate(const CivilDate(2026, 7, 25))));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('収入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();

    expect(find.text('毎月の収入'), findsOneWidget);
    await tester.tap(find.byKey(const Key('entry-recurring-btn')));
    await tester.pump();
    expect(find.text('保存（＋毎月の収入に登録）'), findsOneWidget);
    expect(
        tester
            .widget<DropdownButton<int>>(
                find.byKey(const Key('entry-recurring-day')))
            .value,
        25);
  });

  testWidgets('過去日付で登録: さかのぼり多重起票せず当月分だけ即起票', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    // 5/10の家賃を今(7/15)入力して「毎月の費用」ON
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) => ref
                .read(entryFormControllerProvider.notifier)
                .startCreate(const CivilDate(2026, 5, 10))));
    final c = containerOf(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.tap(find.byKey(const Key('np-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-recurring-btn')));
    await tester.pump();
    await tester.tap(find.textContaining('食費'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('save-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    final repo = c.read(transactionRepositoryProvider);
    // 5月 = 手入力1件のみ
    final may = await repo.forMonth(2026, 5);
    expect(may.single.source, TxnSource.manual);
    // 6月 = さかのぼり起票なし（lastGeneratedYm=202606の効果）
    expect(await repo.forMonth(2026, 6), isEmpty);
    // 7月 = 期日(7/10)が過ぎているので1件だけ即起票
    final july = await repo.forMonth(2026, 7);
    expect(july.single.source, TxnSource.recurring);
    expect(july.single.date, const CivilDate(2026, 7, 10));
    // ルールの watermark は7月まで進んでいる
    final rules = await c.read(appDatabaseProvider).recurringRuleDao.allRules();
    expect(rules.single.lastGeneratedYm, 202607);
  });

  testWidgets('記帳日を変更: 取引日は8/8のままルールは毎月25日になる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) => ref
                .read(entryFormControllerProvider.notifier)
                .startCreate(const CivilDate(2026, 7, 8))));
    final c = containerOf(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-recurring-btn')));
    await tester.pump();

    // 既定は入力日付の日（毎月8日）→帯のプルダウンで毎月25日へ
    final dayDropdown = find.byKey(const Key('entry-recurring-day'));
    expect(tester.widget<DropdownButton<int>>(dayDropdown).value, 8);
    await tester.tap(dayDropdown);
    await tester.pumpAndSettle();
    // メニュー項目に限定するため InkWell との組で探す
    // （素の find.text はDropdownButton内部のIndexedStack項目にも当たる）。
    // メニューは遅延構築なので25までスクロールしてからタップ。
    final item25 = find.widgetWithText(InkWell, '25');
    await tester.scrollUntilVisible(item25, 96,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(item25, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<int>>(dayDropdown).value, 25);

    await tester.tap(find.textContaining('食費'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('save-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-btn')));
    await tester.pumpAndSettle();

    // 取引は入力日(7/8)のまま・ルールは毎月25日・当月分は手入力扱いで未起票
    final txs = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(txs.single.date, const CivilDate(2026, 7, 8));
    final rules = await c.read(appDatabaseProvider).recurringRuleDao.allRules();
    expect(rules.single.dayOfMonth, 25);
    expect(rules.single.lastGeneratedYm, 202607); // 7/25(未来)は起票されない
  });

  testWidgets('内訳開始でOFF+非表示・編集モードでは出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h,
        home: Host(
            onOpen: (ref) => ref
                .read(entryFormControllerProvider.notifier)
                .startCreate(const CivilDate(2026, 7, 15))));
    final c = containerOf(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.tap(find.byKey(const Key('np-00')));
    await tester.pump();

    // ONにしてから内訳を開始→トグルは消え、stateもOFFへ
    await tester.tap(find.byKey(const Key('entry-recurring-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start-split')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-recurring-btn')), findsNothing);
    expect(find.byKey(const Key('entry-recurring-note')), findsNothing);
    final ctrl = c.read(entryFormControllerProvider.notifier);
    expect(c.read(entryFormControllerProvider)!.recurringOn, isFalse);

    // 内訳をやめて通常に戻ってもOFFのまま（ボタンは再表示）
    ctrl.cancelSplit();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-recurring-btn')), findsOneWidget);
    expect(find.byKey(const Key('entry-recurring-note')), findsNothing);
  });
}
