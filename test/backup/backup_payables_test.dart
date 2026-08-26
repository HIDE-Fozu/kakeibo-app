import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/data/repositories/drift_payment_repository.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/payable_builder.dart';

import '../support/test_db.dart';

/// 支払い区分（カード）と未払金のバックアップ収録・復元（形式v10）。
/// 「分割払いカードが同梱漏れしていた」を繰り返さないための回帰。
void main() {
  const codec = BackupCodec();
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newMemoryDb();
    service = BackupService(db);
  });
  tearDown(() => db.close());

  /// カード＋購入取引＋未払金（3回分割）を1件ずつ作る。
  Future<void> seed() async {
    final cards = DriftPaymentCardRepository(db);
    final payables = DriftPayableRepository(db);
    final cardId = await cards.add(const PaymentCardEntity(
        name: '楽天カード', payDay: 27, annualRatePercent: 15.0));
    final all = await db.categoryDao.allCategories();
    final txId = await db.transactionDao
        .insertTransaction(TransactionsCompanion.insert(
      type: TxnType.expense,
      amount: 9000,
      date: const CivilDate(2026, 8, 10),
      categoryId: all.firstWhere((c) => c.name == '食費').id,
      source: TxnSource.manual,
    ));
    await payables.add(buildInstallmentPayable(
      transactionId: txId,
      cardId: cardId,
      principalMinor: 9000,
      count: 3,
      annualRatePercent: 0,
      startYm: 202609,
    ));
  }

  test('exportにカードと未払金（スケジュール込み）が載る', () async {
    await seed();
    final p = await service.exportPayload();
    expect(p.formatVersion, 10);
    expect(p.paymentCards.single.name, '楽天カード');
    expect(p.paymentCards.single.payDay, 27);
    expect(p.paymentCards.single.businessDayRule, BusinessDayRule.next);
    final pa = p.payables.single;
    expect(pa.installmentCount, 3);
    expect(pa.totalMinor, 9000);
    expect(pa.schedule.map((s) => s.ym).toList(), [202609, 202610, 202611]);
    expect(pa.schedule.map((s) => s.amountMinor).toList(), [3000, 3000, 3000]);
  });

  test('export → restore → export が同内容（往復で壊れない）', () async {
    await seed();
    final before = await service.exportJson();
    await service.applyRestore(codec.decode(before));
    final after = await service.exportJson();
    String strip(String s) =>
        s.replaceFirst(RegExp('"exportedAt": "[^"]*"'), '"exportedAt": "X"');
    expect(strip(after), strip(before));
  });

  test('復元でカード・未払金・予定がIDごと戻る', () async {
    await seed();
    final json = await service.exportJson();
    // 全部消してから復元
    await db.customStatement('DELETE FROM payable_schedules');
    await db.customStatement('DELETE FROM payables');
    await db.customStatement('DELETE FROM payment_cards');
    await service.applyRestore(codec.decode(json));

    final card = await db.select(db.paymentCards).getSingle();
    expect(card.name, '楽天カード');
    final payable = await db.select(db.payables).getSingle();
    expect(payable.cardId, card.id);
    expect(payable.totalMinor, 9000);
    final sched = await db.select(db.payableSchedules).get();
    expect(sched, hasLength(3));
    expect(sched.fold<int>(0, (a, s) => a + s.amountMinor), 9000);
  });

  test('v9バックアップ（支払い区分なし）は空で復元される', () async {
    await seed();
    final root = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
    root['formatVersion'] = 9;
    root.remove('paymentCards');
    root.remove('payables');
    final decoded = codec.decode(jsonEncode(root));
    expect(decoded.paymentCards, isEmpty);
    expect(decoded.payables, isEmpty);
  });

  group('壊れたバックアップは復元させない', () {
    Future<String> mutated(
        void Function(Map<String, dynamic> root) f) async {
      await seed();
      final root =
          jsonDecode(await service.exportJson()) as Map<String, dynamic>;
      f(root);
      return jsonEncode(root);
    }

    test('スケジュールの合計が総額と違う', () async {
      final json = await mutated((r) {
        final sched = (r['payables'] as List).single as Map<String, dynamic>;
        (sched['schedule'] as List).removeLast(); // 3000円ぶん足りなくなる
        sched['installmentCount'] = 2;
      });
      expect(() => codec.decode(json),
          throwsA(isA<BackupValidationError>()));
    });

    test('未払金のカードが同梱カードに解決できない', () async {
      final json = await mutated(
          (r) => ((r['payables'] as List).single as Map)['cardId'] = 999);
      expect(() => codec.decode(json),
          throwsA(isA<BackupValidationError>()));
    });

    test('未払金の購入取引が同梱取引に解決できない', () async {
      final json = await mutated(
          (r) => ((r['payables'] as List).single as Map)['transactionId'] = 999);
      expect(() => codec.decode(json),
          throwsA(isA<BackupValidationError>()));
    });

    test('支払日が範囲外', () async {
      final json = await mutated(
          (r) => ((r['paymentCards'] as List).single as Map)['payDay'] = 32);
      expect(() => codec.decode(json),
          throwsA(isA<BackupValidationError>()));
    });
  });
}
