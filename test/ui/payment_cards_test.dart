import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';

import '../support/test_app.dart';
import 'calendar_chore_ghost_test.dart' show containerOf;

/// 支払い区分モードの設定とカード管理。
void main() {
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
  }

  testWidgets('既定オフ: カード管理は出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openSettings(tester);
    await tester.scrollUntilVisible(
        find.byKey(const Key('payment-mode-switch')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('payment-mode-switch')), findsOneWidget);
    expect(find.byKey(const Key('payment-cards-tile')), findsNothing);
  });

  testWidgets('オンにするとカード管理が現れ、カードを登録できる', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    final c = containerOf(tester);
    await openSettings(tester);

    await tester.scrollUntilVisible(
        find.byKey(const Key('payment-mode-switch')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('payment-mode-switch')));
    await tester.pumpAndSettle();
    expect(h.prefs.getBool('paymentModeEnabled'), isTrue);

    await tester.tap(find.byKey(const Key('payment-cards-tile')));
    await tester.pumpAndSettle();
    expect(find.text('カードがまだありません。右上の＋から、名称と引き落とし日を登録してください。'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('payment-card-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('payment-card-name')), '楽天カード');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment-card-save')));
    await tester.pumpAndSettle();

    // 一覧に出る。既定は毎月27日・翌営業日。
    expect(find.text('楽天カード'), findsOneWidget);
    expect(find.text('毎月27日 / 翌営業日'), findsOneWidget);
    final saved = await c.read(paymentCardRepositoryProvider).all();
    expect(saved.single.payDay, 27);
    expect(saved.single.businessDayRule, BusinessDayRule.next);
    expect(saved.single.annualRatePercent, 0); // 空欄=無金利
  });

  testWidgets('名称が空だと保存できない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(
        prefs: {'onboardingDone': true, 'locale': 'ja', 'paymentModeEnabled': true});
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openSettings(tester);
    await tester.scrollUntilVisible(
        find.byKey(const Key('payment-cards-tile')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('payment-cards-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment-card-add')));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
        find.byKey(const Key('payment-card-save')));
    expect(save.onPressed, isNull);
  });
}
