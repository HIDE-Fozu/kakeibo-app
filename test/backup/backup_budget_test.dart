import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/settings/budget_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_db.dart';

/// 毎月の予算（prefs住まい）のバックアップ収録・復元（形式v9）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = BackupCodec();
  late AppDatabase db;

  setUp(() => db = newMemoryDb());
  tearDown(() => db.close());

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('prefs付きexportは予算を収録する（未設定=オフ/0）', () async {
    final p = await prefsWith({
      kBudgetEnabledPrefsKey: true,
      kMonthlyBudgetMinorPrefsKey: 50000,
    });
    final payload = await BackupService(db, prefs: p).exportPayload();
    expect(payload.budget, isNotNull);
    expect(payload.budget!.enabled, isTrue);
    expect(payload.budget!.amountMinor, 50000);

    final empty = await BackupService(db, prefs: await prefsWith({}))
        .exportPayload();
    expect(empty.budget, isNotNull); // 収録済み（既定値）≠ 未収録
    expect(empty.budget!.enabled, isFalse);
    expect(empty.budget!.amountMinor, 0);
  });

  test('prefs無しexportは未収録（null）＝JSONにキー自体が載らない', () async {
    final payload = await BackupService(db).exportPayload();
    expect(payload.budget, isNull);
    final root = jsonDecode(codec.encode(payload)) as Map<String, dynamic>;
    expect(root.containsKey('budget'), isFalse);
  });

  test('applyRestore: 収録済み予算で端末の設定を置換する', () async {
    final p = await prefsWith({
      kBudgetEnabledPrefsKey: true,
      kMonthlyBudgetMinorPrefsKey: 50000,
    });
    final service = BackupService(db, prefs: p);
    final json = await service.exportJson(); // オン5万の時点を採取

    await p.setBool(kBudgetEnabledPrefsKey, false);
    await p.setInt(kMonthlyBudgetMinorPrefsKey, 0);
    await service.applyRestore(codec.decode(json));
    expect(p.getBool(kBudgetEnabledPrefsKey), isTrue);
    expect(p.getInt(kMonthlyBudgetMinorPrefsKey), 50000);
  });

  test('applyRestore: v8バックアップ（未収録）は端末の予算を変更しない', () async {
    final p = await prefsWith({
      kBudgetEnabledPrefsKey: true,
      kMonthlyBudgetMinorPrefsKey: 50000,
    });
    final service = BackupService(db, prefs: p);
    final root = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
    root['formatVersion'] = 8;
    root.remove('budget');
    root.remove('shoppingMemo');
    root.remove('installmentCards');

    await service.applyRestore(codec.decode(jsonEncode(root)));
    expect(p.getBool(kBudgetEnabledPrefsKey), isTrue);
    expect(p.getInt(kMonthlyBudgetMinorPrefsKey), 50000);
  });

  test('負の予算額 -> BackupValidationError', () async {
    final p = await prefsWith({kMonthlyBudgetMinorPrefsKey: 100});
    final root = jsonDecode(await BackupService(db, prefs: p).exportJson())
        as Map<String, dynamic>;
    (root['budget'] as Map<String, dynamic>)['amountMinor'] = -1;
    expect(() => codec.decode(jsonEncode(root)),
        throwsA(isA<BackupValidationError>()));
  });
}
