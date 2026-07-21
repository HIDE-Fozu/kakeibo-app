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
            icon: null, sortOrder: 0, isArchived: false, isSystem: false,
            parentId: null),
        BackupCategory(
            id: 19, name: '未分類', type: CategoryType.expense,
            icon: null, sortOrder: 18, isArchived: false, isSystem: true,
            parentId: null),
        BackupCategory(
            id: 20, name: '未分類', type: CategoryType.income,
            icon: null, sortOrder: 19, isArchived: false, isSystem: true,
            parentId: null),
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

  String mutate(void Function(Map<String, dynamic> root) f) {
    final root = jsonDecode(codec.encode(samplePayload())) as Map<String, dynamic>;
    f(root);
    return jsonEncode(root);
  }

  test('encode produces the documented JSON structure', () {
    final json = codec.encode(samplePayload());
    final root = jsonDecode(json) as Map<String, dynamic>;

    expect(root['formatVersion'], 3);
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

  group('decode', () {
    test('round-trips an encoded payload exactly', () {
      final original = samplePayload();
      final decoded = codec.decode(codec.encode(original));
      // 忠実度はエンコード結果の同値で比較（フィールド網羅かつ簡潔）
      expect(codec.encode(decoded), codec.encode(original));
    });

    test('malformed JSON -> BackupFormatError', () {
      expect(() => codec.decode('{not json'), throwsA(isA<BackupFormatError>()));
      expect(() => codec.decode('[1,2,3]'), throwsA(isA<BackupFormatError>()));
    });

    test('missing / invalid / newer formatVersion -> BackupVersionError', () {
      expect(() => codec.decode(mutate((r) => r.remove('formatVersion'))),
          throwsA(isA<BackupVersionError>()));
      expect(() => codec.decode(mutate((r) => r['formatVersion'] = 0)),
          throwsA(isA<BackupVersionError>()));
      expect(
        () => codec.decode(mutate((r) => r['formatVersion'] = 99)),
        throwsA(isA<BackupVersionError>()
            .having((e) => e.newerThanApp, 'newerThanApp', isTrue)),
      );
    });

    test('negative amount -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate(
            (r) => ((r['transactions'] as List).first as Map)['amount'] = -1)),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('unknown enum value -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate(
            (r) => ((r['transactions'] as List).first as Map)['type'] = 'loan')),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('invalid civil date -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate((r) =>
            ((r['transactions'] as List).first as Map)['date'] = '2026-02-30')),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('unresolvable categoryId -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate((r) =>
            ((r['transactions'] as List).first as Map)['categoryId'] = 777)),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('duplicate transaction / category ids -> BackupValidationError', () {
      expect(
        () => codec.decode(mutate((r) {
          final txs = r['transactions'] as List;
          txs.add(Map<String, dynamic>.from(txs.first as Map)); // 同じid
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          final cats = r['categories'] as List;
          cats.add(Map<String, dynamic>.from(cats.first as Map)); // 同じid
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('missing system (未分類) category for a type -> BackupValidationError',
        () {
      expect(
        () => codec.decode(mutate((r) {
          (r['categories'] as List)
              .removeWhere((c) => (c as Map)['isSystem'] == true);
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('empty transactions decode fine (empty-reject is the restore API job)',
        () {
      final p = codec.decode(mutate((r) => r['transactions'] = <dynamic>[]));
      expect(p.transactions, isEmpty);
    });
  });

  group('formatVersion 2（内訳）', () {
    // v1相当: formatVersionを1に落としparentIdキーを除去
    // （キー除去により _migrateV1toV2 の補完を実際に検証できる）
    String validV1Json() => mutate((r) {
          r['formatVersion'] = 1;
          for (final c in r['categories'] as List) {
            (c as Map).remove('parentId');
          }
        });
    String jsonWithDanglingParent() =>
        mutate((r) => ((r['categories'] as List)[0] as Map)['parentId'] = 99);
    String jsonWithSelfParent() =>
        mutate((r) => ((r['categories'] as List)[0] as Map)['parentId'] = 1);
    String jsonWithGrandchild() => mutate((r) {
          final cats = r['categories'] as List;
          cats.add({'id': 2, 'name': '外食', 'type': 'expense', 'icon': null,
            'sortOrder': 1, 'isArchived': false, 'isSystem': false, 'parentId': 1});
          cats.add({'id': 3, 'name': 'ラーメン', 'type': 'expense', 'icon': null,
            'sortOrder': 0, 'isArchived': false, 'isSystem': false, 'parentId': 2});
        });
    String jsonWithTypeMismatch() => mutate((r) {
          (r['categories'] as List).add({'id': 5, 'name': 'x', 'type': 'income',
            'icon': null, 'sortOrder': 9, 'isArchived': false, 'isSystem': false,
            'parentId': 1}); // 親id=1はexpense
        });
    String jsonWithSystemChild() =>
        mutate((r) => ((r['categories'] as List)[1] as Map)['parentId'] = 1); // cats[1]=未分類(isSystem)

    test('v1 JSON（parentIdなし）はmigrateされ全カテゴリparentId=null', () {
      final payload = codec.decode(validV1Json());
      expect(payload.formatVersion, 3); // decodeはマイグレーション後に現行版を返す
      expect(payload.categories.every((c) => c.parentId == null), isTrue);
    });

    test('v2: parentIdが同梱カテゴリに解決できないと拒否', () {
      expect(() => codec.decode(jsonWithDanglingParent()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: 3段（内訳の下の内訳）は拒否', () {
      expect(() => codec.decode(jsonWithGrandchild()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: 自己参照は拒否', () {
      expect(() => codec.decode(jsonWithSelfParent()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: typeが親と不一致は拒否', () {
      expect(() => codec.decode(jsonWithTypeMismatch()),
          throwsA(isA<BackupValidationError>()));
    });

    test('v2: システムカテゴリのparentIdは拒否', () {
      expect(() => codec.decode(jsonWithSystemChild()),
          throwsA(isA<BackupValidationError>()));
    });

    test('encode→decodeのroundtripでparentIdが保存される', () {
      final json = mutate((r) {
        final cats = r['categories'] as List;
        cats.add({'id': 2, 'name': '外食', 'type': 'expense', 'icon': null,
          'sortOrder': 0, 'isArchived': false, 'isSystem': false, 'parentId': 1});
      });
      final payload = codec.decode(json);
      expect(payload.categories.firstWhere((c) => c.id == 2).parentId, 1);
      final reencoded = codec.decode(codec.encode(payload));
      expect(reencoded.categories.firstWhere((c) => c.id == 2).parentId, 1);
    });
  });
}
