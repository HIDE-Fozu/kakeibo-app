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
        BackupTxn(
          id: 11, type: TxnType.expense, amount: 3567,
          date: const CivilDate(2026, 9, 15), categoryId: 1,
          paymentMethod: null, memo: '分割払い 1/10回',
          source: TxnSource.manual, imagePath: null,
          installmentPlanId: 1,
          createdAt: DateTime.utc(2026, 8, 16, 0, 0, 0),
          updatedAt: DateTime.utc(2026, 8, 16, 0, 0, 0),
        ),
      ],
      installmentPlans: [
        BackupInstallmentPlan(
          id: 1, principal: 33000, count: 10, annualRatePercent: 17.0,
          categoryId: 1, dayOfMonth: 15, startYm: 202609, cardName: '楽天カード',
          createdAt: DateTime.utc(2026, 8, 16, 0, 0, 0),
          updatedAt: DateTime.utc(2026, 8, 16, 0, 0, 0),
        ),
      ],
      recurringRules: [
        BackupRecurringRule(
          id: 1, type: TxnType.expense, amount: 80000, categoryId: 1,
          dayOfMonth: 27, storeName: '大家さん', memo: '家賃',
          isActive: true, startYm: 202608, endYm: null, lastGeneratedYm: 202608,
          createdAt: DateTime.utc(2026, 8, 1, 0, 0, 0),
          updatedAt: DateTime.utc(2026, 8, 1, 0, 0, 0),
        ),
      ],
      choreTasks: [
        BackupChoreTask(
          id: 1, name: 'ハブラシ交換', emoji: '🪥',
          repeatUnit: ChoreRepeatUnit.monthlyDay, dayOfMonth: 30,
          intervalDays: 30,
          anchorDate: const CivilDate(2026, 7, 1), archived: false,
          createdAt: DateTime.utc(2026, 7, 1, 0, 0, 0),
        ),
      ],
      choreRecords: [
        BackupChoreRecord(
          id: 1, taskId: 1, doneDate: const CivilDate(2026, 7, 10), memo: '新品',
          createdAt: DateTime.utc(2026, 7, 10, 0, 0, 0),
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

    expect(root['formatVersion'], 8);
    expect(root['exportedAt'], '2026-07-03T12:00:00.000Z');

    final cats = root['categories'] as List;
    expect(cats.length, 3);
    expect((cats[0] as Map)['name'], '食費');
    expect((cats[0] as Map)['type'], 'expense');
    expect((cats[1] as Map)['isSystem'], true);

    final txs = root['transactions'] as List;
    expect(txs.length, 2);
    final tx = txs.first as Map;
    expect((txs[1] as Map)['installmentPlanId'], 1);
    final plans = root['installmentPlans'] as List;
    expect((plans.single as Map)['annualRatePercent'], 17.0);
    expect((plans.single as Map)['cardName'], '楽天カード');
    expect(tx['amount'], 1200);
    expect(tx['date'], '2026-07-03'); // civil date文字列
    expect(tx['paymentMethod'], 'cash');
    expect(tx['createdAt'], '2026-07-03T01:02:03.000Z'); // UTC ISO
    expect(tx['memo'], 'スーパー, "特売"'); // JSONは任意文字を安全に運ぶ
  });

  test('null optionals serialize as JSON null', () {
    final json = codec.encode(samplePayload());
    final root = jsonDecode(json) as Map<String, dynamic>;
    final tx = (root['transactions'] as List).first as Map;
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

    test('v7バックアップ（installmentPlans無し）は空で復元される', () {
      final json = mutate((r) {
        r['formatVersion'] = 7;
        r.remove('installmentPlans');
        for (final t in r['transactions'] as List) {
          (t as Map).remove('installmentPlanId');
        }
      });
      final decoded = codec.decode(json);
      expect(decoded.installmentPlans, isEmpty);
      expect(decoded.transactions.every((t) => t.installmentPlanId == null),
          isTrue);
    });

    test('取引の installmentPlanId が同梱計画に無い -> BackupValidationError', () {
      final json = mutate((r) => r['installmentPlans'] = <dynamic>[]);
      expect(() => codec.decode(json), throwsA(isA<BackupValidationError>()));
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
      expect(payload.formatVersion, 8); // decodeはマイグレーション後に現行版を返す
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

  group('formatVersion 4（定期ルール）', () {
    test('v3 JSON（recurringRulesなし）はmigrateされ空ルールで復元', () {
      final json = mutate((r) {
        r['formatVersion'] = 3;
        r.remove('recurringRules');
      });
      final payload = codec.decode(json);
      expect(payload.formatVersion, 8);
      expect(payload.recurringRules, isEmpty);
    });

    test('roundtripで定期ルールの全フィールドが保存される', () {
      final decoded = codec.decode(codec.encode(samplePayload()));
      final r = decoded.recurringRules.single;
      expect(r.amount, 80000);
      expect(r.dayOfMonth, 27);
      expect(r.storeName, '大家さん');
      expect(r.startYm, 202608);
      expect(r.endYm, isNull);
      expect(r.lastGeneratedYm, 202608);
      expect(r.isActive, isTrue);
    });

    test('ルールのcategoryIdが同梱カテゴリに解決できないと拒否', () {
      expect(
        () => codec.decode(mutate((r) =>
            ((r['recurringRules'] as List).first as Map)['categoryId'] = 99)),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('dayOfMonth範囲外・不正なYYYYMM・負の金額は拒否', () {
      expect(
        () => codec.decode(mutate((r) =>
            ((r['recurringRules'] as List).first as Map)['dayOfMonth'] = 0)),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) =>
            ((r['recurringRules'] as List).first as Map)['dayOfMonth'] = 32)),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) =>
            ((r['recurringRules'] as List).first as Map)['startYm'] = 202613)),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) =>
            ((r['recurringRules'] as List).first as Map)['amount'] = -1)),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('ルールID重複は拒否', () {
      expect(
        () => codec.decode(mutate((r) {
          final rules = r['recurringRules'] as List;
          rules.add(Map<String, dynamic>.from(rules.first as Map));
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });
  });

  group('formatVersion 6/7（つきいちの繰り返し設定）', () {
    test('v5 JSON（N日ごとの世代）は everyDays＋間隔そのままで復元', () {
      final json = mutate((r) {
        r['formatVersion'] = 5;
        final t = (r['choreTasks'] as List).first as Map<String, dynamic>;
        t..remove('dayOfMonth')
         ..remove('repeatUnit');
        t['intervalDays'] = 14; // anchor 7/1 + 14日 = 7/15 → 毎月の予定日は15
      });
      final payload = codec.decode(json);
      expect(payload.formatVersion, 8);
      final t = payload.choreTasks.single;
      expect(t.repeatUnit, ChoreRepeatUnit.everyDays); // 間隔の意味を失わない
      expect(t.intervalDays, 14);
      expect(t.dayOfMonth, 15); // 単位を切り替えた時の初期値
    });

    test('v5 JSON: 予定日の引き継ぎは月をまたぐ（7/1+45日=8/15→15）', () {
      final json = mutate((r) {
        r['formatVersion'] = 5;
        final t = (r['choreTasks'] as List).first as Map<String, dynamic>;
        t..remove('dayOfMonth')
         ..remove('repeatUnit');
        t['intervalDays'] = 45;
      });
      expect(codec.decode(json).choreTasks.single.dayOfMonth, 15);
    });

    test('v6 JSON（毎月N日のみの世代）は monthlyDay＋既定間隔で復元', () {
      final json = mutate((r) {
        r['formatVersion'] = 6;
        final t = (r['choreTasks'] as List).first as Map<String, dynamic>;
        t..remove('repeatUnit')
         ..remove('intervalDays');
        t['dayOfMonth'] = 27;
      });
      final t = codec.decode(json).choreTasks.single;
      expect(t.repeatUnit, ChoreRepeatUnit.monthlyDay);
      expect(t.dayOfMonth, 27);
      expect(t.intervalDays, 30);
    });
  });

  group('formatVersion 5（つきいちタスク）', () {
    test('v4 JSON（choreTasks/choreRecordsなし）はmigrateされ空で復元', () {
      final json = mutate((r) {
        r['formatVersion'] = 4;
        r.remove('choreTasks');
        r.remove('choreRecords');
      });
      final payload = codec.decode(json);
      expect(payload.formatVersion, 8);
      expect(payload.choreTasks, isEmpty);
      expect(payload.choreRecords, isEmpty);
    });

    test('roundtripでタスク・記録の全フィールドが保存される', () {
      final payload = codec.decode(codec.encode(samplePayload()));
      final t = payload.choreTasks.single;
      expect(t.id, 1);
      expect(t.name, 'ハブラシ交換');
      expect(t.emoji, '🪥');
      expect(t.repeatUnit, ChoreRepeatUnit.monthlyDay);
      expect(t.dayOfMonth, 30);
      expect(t.intervalDays, 30);
      expect(t.anchorDate, const CivilDate(2026, 7, 1));
      expect(t.archived, isFalse);
      expect(t.createdAt, DateTime.utc(2026, 7, 1));
      final rec = payload.choreRecords.single;
      expect(rec.taskId, 1);
      expect(rec.doneDate, const CivilDate(2026, 7, 10));
      expect(rec.memo, '新品');
    });

    test('記録のtaskIdが同梱タスクに解決できないと拒否', () {
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreRecords'] as List).first as Map)['taskId'] = 999;
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('不正なrepeatUnit・intervalDaysは拒否', () {
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreTasks'] as List).first as Map)['repeatUnit'] = 'weekly';
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreTasks'] as List).first as Map)['intervalDays'] = 0;
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreTasks'] as List).first as Map)['intervalDays'] = 1000;
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });

    test('不正なdayOfMonth・空name・不正日付・ID重複は拒否', () {
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreTasks'] as List).first as Map)['dayOfMonth'] = 0;
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreTasks'] as List).first as Map)['dayOfMonth'] = 32;
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreTasks'] as List).first as Map)['name'] = '';
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          ((r['choreRecords'] as List).first as Map)['doneDate'] = '2026-13-99';
        })),
        throwsA(isA<BackupValidationError>()),
      );
      expect(
        () => codec.decode(mutate((r) {
          final tasks = r['choreTasks'] as List;
          tasks.add(Map<String, dynamic>.from(tasks.first as Map));
        })),
        throwsA(isA<BackupValidationError>()),
      );
    });
  });
}
