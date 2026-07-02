import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';

BackupPayload samplePayload() => BackupPayload(
      formatVersion: BackupCodec.formatVersion,
      exportedAt: DateTime.utc(2026, 7, 3, 12, 0),
      categories: const [
        BackupCategory(
            id: 1, name: '食費', type: CategoryType.expense,
            icon: null, sortOrder: 0, isArchived: false, isSystem: false),
        BackupCategory(
            id: 19, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 18, isArchived: false, isSystem: true),
        BackupCategory(
            id: 20, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 19, isArchived: false, isSystem: true),
      ],
      transactions: [
        BackupTxn(
          id: 10, type: TxnType.expense, amount: 1200,
          date: const CivilDate(2026, 7, 3), categoryId: 1,
          paymentMethod: PaymentMethod.cash, memo: 'スーパー, "特売"',
          source: TxnSource.manual, imagePath: null,
          createdAt: DateTime.utc(2026, 7, 3, 1, 2, 3),
          updatedAt: DateTime.utc(2026, 7, 3, 1, 2, 3),
        ),
      ],
    );

void main() {
  const codec = BackupCodec();

  test('encode produces the documented JSON structure', () {
    final json = codec.encode(samplePayload());
    final root = jsonDecode(json) as Map<String, dynamic>;

    expect(root['formatVersion'], 1);
    expect(root['exportedAt'], '2026-07-03T12:00:00.000Z');

    final cats = root['categories'] as List;
    expect(cats.length, 3);
    expect((cats[0] as Map)['name'], '食費');
    expect((cats[0] as Map)['type'], 'expense');
    expect((cats[1] as Map)['isSystem'], true);

    final txs = root['transactions'] as List;
    final tx = txs.single as Map;
    expect(tx['amount'], 1200);
    expect(tx['date'], '2026-07-03'); // civil date文字列
    expect(tx['paymentMethod'], 'cash');
    expect(tx['createdAt'], '2026-07-03T01:02:03.000Z'); // UTC ISO
    expect(tx['memo'], 'スーパー, "特売"'); // JSONは任意文字を安全に運ぶ
  });

  test('null optionals serialize as JSON null', () {
    final json = codec.encode(samplePayload());
    final root = jsonDecode(json) as Map<String, dynamic>;
    final tx = (root['transactions'] as List).single as Map;
    expect(tx.containsKey('imagePath'), isTrue);
    expect(tx['imagePath'], isNull);
  });
}
