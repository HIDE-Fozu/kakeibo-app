import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payable_builder.dart';
import 'package:kakeibo_app/features/calendar/application/calendar_providers.dart';
import 'package:kakeibo_app/features/payment/application/payment_providers.dart';

import '../support/test_app.dart';

/// 上部サマリが二重計上しないこと。固定時計 = 2026-07-15。
/// 要点: カード購入は「買った日」か「引き落とし日」のどちらか一方でしか数えない。
void main() {
  late TestHarness h;
  late ProviderContainer c;
  late int foodId;

  Future<void> setUpWith({required Map<String, Object> prefs}) async {
    h = await createHarness(prefs: prefs);
    c = ProviderContainer(overrides: h.overrides());
    addTearDown(c.dispose);
    addTearDown(h.dispose);
    final cats = await waitForData(c, allCategoriesProvider);
    foodId = cats.firstWhere((x) => x.name == '食費').id;
  }

  Map<String, Object> prefsWith({required bool mode, bool cash = true}) => {
        'onboardingDone': true,
        'locale': 'ja',
        if (mode) 'paymentModeEnabled': true,
        'summaryBasisCash': cash,
      };

  /// 7/10 にカードで買う。引き落としは 8/27（木・営業日）。
  Future<int> buyOnCard(int amount, {int day = 10}) async {
    final cardId = await c
        .read(paymentCardRepositoryProvider)
        .add(const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: amount,
            date: CivilDate(2026, 7, day),
            categoryId: foodId,
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: amount,
          purchaseDate: CivilDate(2026, 7, day),
        ));
    return cardId;
  }

  Future<void> addCash(int amount, {int day = 12}) =>
      c.read(transactionRepositoryProvider).add(TransactionEntity(
            type: TxnType.expense,
            amountYen: amount,
            date: CivilDate(2026, 7, day),
            categoryId: foodId,
            source: TxnSource.manual));

  /// 購読を張ってイベントを流し、その月の支出（支払い）を読む。
  Future<int> expenseOf(int year, int month) async {
    final sub = c.listen(monthToDateSummaryProvider((year, month)), (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return sub.read().requireValue.expense;
  }

  test('現金主義: カード購入は購入月に入らず、引き落とし月に入る', () async {
    await setUpWith(prefs: prefsWith(mode: true));
    await buyOnCard(3000);
    await addCash(800); // 現金の支出はそのまま7月に入る

    expect(await expenseOf(2026, 7), 800);
    expect(await expenseOf(2026, 8), 3000);
  });

  test('発生主義: カード購入は購入月に入り、引き落とし月には入らない', () async {
    await setUpWith(prefs: prefsWith(mode: true, cash: false));
    await buyOnCard(3000);
    await addCash(800);

    expect(await expenseOf(2026, 7), 3800);
    expect(await expenseOf(2026, 8), 0);
  });

  test('モードOFF: 未払金があっても従来どおり購入日に計上', () async {
    await setUpWith(prefs: prefsWith(mode: false));
    await buyOnCard(3000);

    expect(await expenseOf(2026, 7), 3000);
    expect(await expenseOf(2026, 8), 0);
  });

  test('現金主義: 引き落とし日が未来なら当月の実績に入らない', () async {
    await setUpWith(prefs: prefsWith(mode: true));
    // 6月に買う → 7/27（月）引き落とし。今日は7/15なのでまだ実績ではない。
    final cardId = await c
        .read(paymentCardRepositoryProvider)
        .add(const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: 4000,
            date: const CivilDate(2026, 6, 20),
            categoryId: foodId,
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: 4000,
          purchaseDate: const CivilDate(2026, 6, 20),
        ));

    expect(await expenseOf(2026, 7), 0); // 7/27はまだ来ていない
    expect(await expenseOf(2026, 6), 0); // 買った月にも入らない（現金主義）
  });

  test('カード引き落とし行は営業日調整済みの日付で出る', () async {
    await setUpWith(prefs: prefsWith(mode: true));
    // 8月に買う → 9/27（日）→ 9/28（月）
    final cardId = await c
        .read(paymentCardRepositoryProvider)
        .add(const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: 5000,
            date: const CivilDate(2026, 8, 10),
            categoryId: foodId,
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildSinglePayable(
          transactionId: txId,
          cardId: cardId,
          amountMinor: 5000,
          purchaseDate: const CivilDate(2026, 8, 10),
        ));

    final sub = c.listen(cardPaymentsProvider((2026, 9)), (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final lines = sub.read();
    expect(lines, hasLength(1));
    expect(lines.single.card.name, '楽天カード');
    expect(lines.single.date, const CivilDate(2026, 9, 28));
    expect(lines.single.amountMinor, 5000);
  });

  test('あとから分割: 各月の引き落としに割れて乗る', () async {
    await setUpWith(prefs: prefsWith(mode: true));
    final cardId = await c
        .read(paymentCardRepositoryProvider)
        .add(const PaymentCardEntity(name: '楽天カード', payDay: 27));
    final txId = await c.read(transactionRepositoryProvider).add(
        TransactionEntity(
            type: TxnType.expense,
            amountYen: 9000,
            date: const CivilDate(2026, 7, 10),
            categoryId: foodId,
            source: TxnSource.manual));
    await c.read(payableRepositoryProvider).add(buildInstallmentPayable(
          transactionId: txId,
          cardId: cardId,
          principalMinor: 9000,
          count: 3,
          annualRatePercent: 0,
          startYm: 202608,
        ));

    expect(await expenseOf(2026, 7), 0); // 買った月には入らない
    expect(await expenseOf(2026, 8), 3000);
    expect(await expenseOf(2026, 9), 3000);
    expect(await expenseOf(2026, 10), 3000);
    expect(await expenseOf(2026, 11), 0);
  });

  test('モードOFFなら引き落とし行そのものが出ない', () async {
    await setUpWith(prefs: prefsWith(mode: false));
    await buyOnCard(3000);
    final sub = c.listen(cardPaymentsProvider((2026, 8)), (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(sub.read(), isEmpty);
  });
}
