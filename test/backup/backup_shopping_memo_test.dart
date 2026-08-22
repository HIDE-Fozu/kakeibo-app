import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/settings/shopping_memo_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_db.dart';

/// 買い物メモ（prefs住まい）のバックアップ収録・復元（形式v9）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = BackupCodec();
  late AppDatabase db;

  setUp(() => db = newMemoryDb());
  tearDown(() => db.close());

  Future<SharedPreferences> prefsWith(String? memo) async {
    SharedPreferences.setMockInitialValues(
        memo == null ? {} : {kShoppingMemoPrefsKey: memo});
    return SharedPreferences.getInstance();
  }

  test('prefs付きexportはメモを収録する（未入力=空文字）', () async {
    final p = await prefsWith('牛乳');
    final payload = await BackupService(db, prefs: p).exportPayload();
    expect(payload.shoppingMemo, '牛乳');

    await p.remove(kShoppingMemoPrefsKey);
    final empty = await BackupService(db, prefs: p).exportPayload();
    expect(empty.shoppingMemo, ''); // 収録済み（空）≠ 未収録
  });

  test('prefs無しexportは未収録（null）＝JSONにキー自体が載らない', () async {
    final payload = await BackupService(db).exportPayload();
    expect(payload.shoppingMemo, isNull);
    final root = jsonDecode(codec.encode(payload)) as Map<String, dynamic>;
    expect(root.containsKey('shoppingMemo'), isFalse);
  });

  test('applyRestore: 収録済みメモで端末のメモを置換する', () async {
    final p = await prefsWith('牛乳');
    final service = BackupService(db, prefs: p);
    final json = await service.exportJson(); // 「牛乳」の時点を採取

    await p.setString(kShoppingMemoPrefsKey, '卵');
    await service.applyRestore(codec.decode(json));
    expect(p.getString(kShoppingMemoPrefsKey), '牛乳');
  });

  test('applyRestore: v8バックアップ（未収録）は端末のメモを変更しない', () async {
    final p = await prefsWith('牛乳');
    final service = BackupService(db, prefs: p);
    final root = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
    root['formatVersion'] = 8;
    root.remove('shoppingMemo');
    root.remove('installmentCards');

    await p.setString(kShoppingMemoPrefsKey, '卵');
    await service.applyRestore(codec.decode(jsonEncode(root)));
    expect(p.getString(kShoppingMemoPrefsKey), '卵');
  });
}
