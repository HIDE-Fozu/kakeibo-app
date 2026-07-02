import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/db/enums.dart';

/// 検証を通る最小の正当JSON
String validJson() {
  const codec = BackupCodec();
  return codec.encode(BackupPayload(
    formatVersion: BackupCodec.formatVersion,
    exportedAt: DateTime.utc(2026, 7, 3),
    categories: const [
      BackupCategory(
          id: 1, name: '未分類', type: CategoryType.expense,
          icon: null, sortOrder: 0, isArchived: false, isSystem: true),
      BackupCategory(
          id: 2, name: '未分類', type: CategoryType.income,
          icon: null, sortOrder: 1, isArchived: false, isSystem: true),
    ],
    transactions: const [],
  ));
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kakeibo_backup_test_');
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// 呼ぶたびに1秒進む注入クロック
  DateTime Function() ticker() {
    var t = DateTime.utc(2026, 7, 3, 12, 0, 0);
    return () {
      t = t.add(const Duration(seconds: 1));
      return t;
    };
  }

  test('writeVerified persists, and latest()/listGenerations() order newest-first',
      () async {
    final store = AutoBackupStore(tmp, now: ticker());
    final f1 = await store.writeVerified(validJson());
    final f2 = await store.writeVerified(validJson());

    expect(f1.existsSync(), isTrue);
    expect(f2.existsSync(), isTrue);
    final gens = store.listGenerations();
    expect(gens.length, 2);
    expect(gens.first.path, f2.path); // 新しい順
    expect(store.latest()!.path, f2.path);
    expect(store.latestTimestamp(), DateTime.utc(2026, 7, 3, 12, 0, 2));
  });

  test('invalid json is rejected, file removed, AutoBackupWriteError thrown',
      () async {
    final store = AutoBackupStore(tmp, now: ticker());
    await expectLater(
      store.writeVerified('{"broken": true}'),
      throwsA(isA<AutoBackupWriteError>()),
    );
    expect(store.listGenerations(), isEmpty); // 失敗ファイルは残らない
  });

  test('prunes beyond maxGenerations, deleting the oldest', () async {
    final store = AutoBackupStore(tmp, now: ticker(), maxGenerations: 3);
    final files = <File>[];
    for (var i = 0; i < 5; i++) {
      files.add(await store.writeVerified(validJson()));
    }
    final gens = store.listGenerations();
    expect(gens.length, 3);
    // 最新3つ＝最後に書いた3つ
    expect(gens.map((f) => f.path).toSet(),
        files.sublist(2).map((f) => f.path).toSet());
    expect(files[0].existsSync(), isFalse); // 最古は削除済み
    expect(files[1].existsSync(), isFalse);
  });

  test('empty dir -> latest() and latestTimestamp() are null', () {
    final store = AutoBackupStore(tmp);
    expect(store.latest(), isNull);
    expect(store.latestTimestamp(), isNull);
  });
}
