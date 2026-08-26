import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_payment_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payable_builder.dart';
import 'package:kakeibo_app/domain/services/payment_schedule.dart';

import 'support/test_db.dart';

/// 支払い区分（カード）と未払金の読み書き。
void main() {
  late AppDatabase db;
  late DriftPaymentCardRepository cards;
  late DriftPayableRepository payables;

  setUp(() {
    db = newMemoryDb();
    cards = DriftPaymentCardRepository(db);
    payables = DriftPayableRepository(db);
  });
  tearDown(() => db.close());

  Future<int> foodId() async {
    final all = await db.categoryDao.allCategories();
    return all.firstWhere((c) => c.name == '食費').id;
  }

  /// 購入取引を1件作って id を返す。
  Future<int> buyTx(int amount, CivilDate date) async =>
      db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        type: TxnType.expense,
        amount: amount,
        date: date,
        categoryId: await foodId(),
        source: TxnSource.manual,
      ));

  Future<int> rakuten() => cards.add(const PaymentCardEntity(
        name: '楽天カード',
        payDay: 27,
        annualRatePercent: 15.0,
      ));

  group('カード', () {
    test('登録・一覧・既定値', () async {
      await rakuten();
      final list = await cards.all();
      expect(list.single.name, '楽天カード');
      expect(list.single.payDay, 27);
      expect(list.single.businessDayRule, BusinessDayRule.next); // 既定=翌営業日
      expect(list.single.isArchived, isFalse);
    });

    test('アーカイブは一覧から消える（includeArchivedで見える）', () async {
      final id = await rakuten();
      await cards.archive(id);
      expect(await cards.all(), isEmpty);
      expect(await cards.all(includeArchived: true), hasLength(1));
    });

    test('未払金から使われているカードは削除できない（読める例外）', () async {
      final cardId = await rakuten();
      final txId = await buyTx(3000, const CivilDate(2026, 8, 10));
      await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 10),
      ));
      expect(() => cards.delete(cardId), throwsA(isA<StateError>()));
      // 未使用なら消せる
      final other = await cards.add(
          const PaymentCardEntity(name: 'エポス', payDay: 27));
      await cards.delete(other);
      expect(await cards.all(), hasLength(1));
    });
  });

  group('未払金（一括）', () {
    test('購入日から翌月の支払いに載る', () async {
      final cardId = await rakuten();
      final txId = await buyTx(3000, const CivilDate(2026, 8, 10));
      await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 10),
      ));

      final p = await payables.forTransaction(txId);
      expect(p, isNotNull);
      expect(p!.installmentCount, 1);
      expect(p.totalMinor, 3000); // 1回払いは手数料なし
      expect(p.schedule.single.ym, 202609);
      expect(p.schedule.single.amountMinor, 3000);
    });

    test('支払い月を上書きできる（「9月分じゃなく10月分」）', () async {
      final cardId = await rakuten();
      final txId = await buyTx(3000, const CivilDate(2026, 8, 28));
      await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 28),
        paymentYm: 202610, // 楽天市場は27日締め → この買い物は10月払い
      ));
      final p = await payables.forTransaction(txId);
      expect(p!.schedule.single.ym, 202610);
    });

    test('購入取引を消すと未払金も消える（cascade）', () async {
      final cardId = await rakuten();
      final txId = await buyTx(3000, const CivilDate(2026, 8, 10));
      await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 10),
      ));
      await (db.delete(db.transactions)..where((t) => t.id.equals(txId))).go();
      expect(await payables.forTransaction(txId), isNull);
      expect(await db.select(db.payableSchedules).get(), isEmpty);
    });

    test('未払金だけ消すと購入取引は残る（＝即時払いに戻る）', () async {
      final cardId = await rakuten();
      final txId = await buyTx(3000, const CivilDate(2026, 8, 10));
      final id = await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 10),
      ));
      await payables.delete(id);
      expect(await payables.forTransaction(txId), isNull);
      final txs = await db.transactionDao.transactionsInMonth(2026, 8);
      expect(txs.single.amount, 3000);
    });
  });

  group('バッジ（いつ払うか）', () {
    test('翌月・翌々月・具体月・回数を出し分ける', () async {
      final cardId = await rakuten();
      final txId = await buyTx(3000, const CivilDate(2026, 8, 10));

      // 既定（月末締め）＝翌月
      await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 10),
      ));
      var p = (await payables.forTransaction(txId))!;
      expect(payableBadgeOf(p, const CivilDate(2026, 8, 10)),
          isA<PayableBadgeNextMonth>());

      // 27日締めで28日に買う＝翌々月
      await payables.replace(buildSinglePayable(
        id: p.id,
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 28),
        closingDay: 27,
      ));
      p = (await payables.forTransaction(txId))!;
      expect(payableBadgeOf(p, const CivilDate(2026, 8, 28)),
          isA<PayableBadgeMonthAfterNext>());

      // もっと先へずらしたら月そのもの
      await payables.replace(buildSinglePayable(
        id: p.id,
        transactionId: txId,
        cardId: cardId,
        amountMinor: 3000,
        purchaseDate: const CivilDate(2026, 8, 10),
        paymentYm: 202612,
      ));
      p = (await payables.forTransaction(txId))!;
      final badge = payableBadgeOf(p, const CivilDate(2026, 8, 10));
      expect(badge, isA<PayableBadgeMonth>());
      expect((badge as PayableBadgeMonth).month, 12);

      // 分割は回数
      await payables.replace(buildInstallmentPayable(
        id: p.id,
        transactionId: txId,
        cardId: cardId,
        principalMinor: 3000,
        count: 3,
        annualRatePercent: 0,
        startYm: 202609,
      ));
      p = (await payables.forTransaction(txId))!;
      final times = payableBadgeOf(p, const CivilDate(2026, 8, 10));
      expect(times, isA<PayableBadgeTimes>());
      expect((times as PayableBadgeTimes).count, 3);
    });
  });

  group('あとから分割', () {
    test('1万円を10回に割ると各月に載り、合計＝総額', () async {
      final cardId = await rakuten();
      final txId = await buyTx(10000, const CivilDate(2026, 8, 10));
      final id = await payables.add(buildSinglePayable(
        transactionId: txId,
        cardId: cardId,
        amountMinor: 10000,
        purchaseDate: const CivilDate(2026, 8, 10),
      ));

      await payables.replace(buildInstallmentPayable(
        id: id,
        transactionId: txId,
        cardId: cardId,
        principalMinor: 10000,
        count: 10,
        annualRatePercent: 15.0,
        startYm: 202609,
      ));

      final p = (await payables.forTransaction(txId))!;
      expect(p.installmentCount, 10);
      expect(p.schedule, hasLength(10));
      expect(p.schedule.first.ym, 202609);
      expect(p.schedule.last.ym, 202706);
      expect(p.totalMinor, greaterThan(10000)); // 手数料が乗る
      expect(scheduleTotalMinor(p.schedule), p.totalMinor);
    });

    test('10回払いを3回払いに変更できる（同じオブジェクトのまま）', () async {
      final cardId = await rakuten();
      final txId = await buyTx(10000, const CivilDate(2026, 8, 10));
      final id = await payables.add(buildInstallmentPayable(
        transactionId: txId,
        cardId: cardId,
        principalMinor: 10000,
        count: 10,
        annualRatePercent: 15.0,
        startYm: 202609,
      ));

      await payables.replace(buildInstallmentPayable(
        id: id,
        transactionId: txId,
        cardId: cardId,
        principalMinor: 10000,
        count: 3,
        annualRatePercent: 15.0,
        startYm: 202609,
      ));

      final p = (await payables.forTransaction(txId))!;
      expect(p.id, id); // 同一オブジェクト
      expect(p.installmentCount, 3);
      expect(p.schedule, hasLength(3)); // 古い10行は残らない
      expect(scheduleTotalMinor(p.schedule), p.totalMinor);
    });

    test('無金利なら総額＝元本で、端数は初回に寄る', () async {
      final cardId = await rakuten();
      final txId = await buyTx(10000, const CivilDate(2026, 8, 10));
      await payables.add(buildInstallmentPayable(
        transactionId: txId,
        cardId: cardId,
        principalMinor: 10000,
        count: 3,
        annualRatePercent: 0,
        startYm: 202609,
      ));
      final p = (await payables.forTransaction(txId))!;
      expect(p.totalMinor, 10000);
      expect(p.schedule.map((s) => s.amountMinor).toList(),
          [3334, 3333, 3333]);
    });

    test('開始月をずらすと以降が連動する', () async {
      final cardId = await rakuten();
      final txId = await buyTx(9000, const CivilDate(2026, 8, 10));
      await payables.add(buildInstallmentPayable(
        transactionId: txId,
        cardId: cardId,
        principalMinor: 9000,
        count: 3,
        annualRatePercent: 0,
        startYm: 202609,
      ));
      final before = (await payables.forTransaction(txId))!;
      await payables.replace(shiftPaymentYm(before, 202611));
      final after = (await payables.forTransaction(txId))!;
      expect(after.schedule.map((s) => s.ym).toList(),
          [202611, 202612, 202701]);
      expect(scheduleTotalMinor(after.schedule), after.totalMinor);
    });
  });

  group('整合の門番', () {
    test('合計が総額と一致しないスケジュールは書けない', () async {
      final cardId = await rakuten();
      final txId = await buyTx(10000, const CivilDate(2026, 8, 10));
      final broken = PayableEntity(
        transactionId: txId,
        cardId: cardId,
        installmentCount: 2,
        totalMinor: 10000,
        schedule: const [
          PayableInstallment(ym: 202609, amountMinor: 5000),
          PayableInstallment(ym: 202610, amountMinor: 4000), // 合計9000
        ],
      );
      expect(() => payables.add(broken), throwsA(isA<ArgumentError>()));
      expect(await db.select(db.payables).get(), isEmpty); // 1行も入らない
    });

    test('回数とスケジュール件数の食い違いも弾く', () async {
      final cardId = await rakuten();
      final txId = await buyTx(1000, const CivilDate(2026, 8, 10));
      expect(
        () => payables.add(PayableEntity(
          transactionId: txId,
          cardId: cardId,
          installmentCount: 3,
          totalMinor: 1000,
          schedule: const [
            PayableInstallment(ym: 202609, amountMinor: 1000),
          ],
        )),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('その月の引き落とし', () {
    test('カード別に合算される', () async {
      final rk = await rakuten();
      final epos =
          await cards.add(const PaymentCardEntity(name: 'エポス', payDay: 27));

      final a = await buyTx(3000, const CivilDate(2026, 8, 10));
      final b = await buyTx(2000, const CivilDate(2026, 8, 20));
      final c = await buyTx(5000, const CivilDate(2026, 8, 15));
      for (final (tx, card, amt) in [(a, rk, 3000), (b, rk, 2000), (c, epos, 5000)]) {
        await payables.add(buildSinglePayable(
          transactionId: tx,
          cardId: card,
          amountMinor: amt,
          purchaseDate: const CivilDate(2026, 8, 10),
        ));
      }

      final sep = await payables.watchForPaymentYm(202609).first;
      expect(sep, hasLength(3));
      expect(cardTotalDueIn(sep, rk, 202609), 5000);
      expect(cardTotalDueIn(sep, epos, 202609), 5000);
      expect(cardTotalDueIn(sep, rk, 202610), 0);
    });

    test('分割は該当月だけが引かれる', () async {
      final cardId = await rakuten();
      final txId = await buyTx(9000, const CivilDate(2026, 8, 10));
      await payables.add(buildInstallmentPayable(
        transactionId: txId,
        cardId: cardId,
        principalMinor: 9000,
        count: 3,
        annualRatePercent: 0,
        startYm: 202609,
      ));
      for (final (ym, expected) in [
        (202609, 3000),
        (202610, 3000),
        (202611, 3000),
        (202612, 0),
      ]) {
        final due = await payables.watchForPaymentYm(ym).first;
        expect(cardTotalDueIn(due, cardId, ym), expected, reason: 'ym=$ym');
      }
    });
  });
}
