import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/settings/installment_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_db.dart';

/// 分割払いカード（prefs住まい）のバックアップ収録・復元（形式v9）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = BackupCodec();
  late AppDatabase db;

  setUp(() => db = newMemoryDb());
  tearDown(() => db.close());

  Future<SharedPreferences> prefsWith(List<String> cards) async {
    SharedPreferences.setMockInitialValues(
        cards.isEmpty ? {} : {kInstallmentCardsPrefsKey: cards});
    return SharedPreferences.getInstance();
  }

  test('prefs付きexportはカードを収録する（未登録=空リスト）', () async {
    final p = await prefsWith(['楽天カード\t15.0', 'VISA\t18.0']);
    final payload = await BackupService(db, prefs: p).exportPayload();
    final cards = payload.installmentCards;
    expect(cards, isNotNull);
    expect(cards!.map((c) => c.name), ['楽天カード', 'VISA']);
    expect(cards.map((c) => c.annualRatePercent), [15.0, 18.0]);

    await p.remove(kInstallmentCardsPrefsKey);
    final empty = await BackupService(db, prefs: p).exportPayload();
    expect(empty.installmentCards, isNotNull); // 収録済み（空）≠ 未収録
    expect(empty.installmentCards, isEmpty);
  });

  test('prefs無しexportは未収録（null）＝JSONにキー自体が載らない', () async {
    final payload = await BackupService(db).exportPayload();
    expect(payload.installmentCards, isNull);
    final root =
        jsonDecode(codec.encode(payload)) as Map<String, dynamic>;
    expect(root.containsKey('installmentCards'), isFalse);
  });

  test('applyRestore: 収録済みカードで端末のカードを置換する', () async {
    final p = await prefsWith(['楽天カード\t15.0']);
    final service = BackupService(db, prefs: p);
    final json = await service.exportJson(); // 楽天1枚の時点を採取

    // その後カードが入れ替わった状態から復元
    await p.setStringList(kInstallmentCardsPrefsKey, ['VISA\t18.0']);
    await service.applyRestore(codec.decode(json));
    expect(p.getStringList(kInstallmentCardsPrefsKey), ['楽天カード\t15.0']);
  });

  test('applyRestore: v8バックアップ（未収録）は端末のカードを変更しない', () async {
    final p = await prefsWith(['楽天カード\t15.0']);
    final service = BackupService(db, prefs: p);
    final root = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
    root['formatVersion'] = 8;
    root.remove('installmentCards');

    await p.setStringList(kInstallmentCardsPrefsKey, ['VISA\t18.0']);
    await service.applyRestore(codec.decode(jsonEncode(root)));
    expect(p.getStringList(kInstallmentCardsPrefsKey), ['VISA\t18.0']);
  });
}
