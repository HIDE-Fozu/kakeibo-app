import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_codec.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';
import 'package:kakeibo_app/data/backup/backup_service.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/backup_controller.dart';

import '../support/test_app.dart';
import '../support/test_db.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;

  BackupController ctrl() => c.read(backupControllerProvider.notifier);

  /// storeNow: 自動バックアップ世代のタイムスタンプを固定する
  Future<void> setUpWith({DateTime? storeNow}) async {
    h = await createHarness();
    // 同一providerの二重overrideを避け、ハーネスのstoreNowパラメータで注入する
    c = ProviderContainer(
        overrides:
            h.overrides(storeNow: storeNow == null ? null : () => storeNow));
    addTearDown(c.dispose);
    addTearDown(h.dispose);
  }

  Future<void> seedTx() async {
    final cats = await waitForData(c, allCategoriesProvider);
    final foodId = cats.firstWhere((x) => x.name == '食費').id;
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
        type: TxnType.expense,
        amountYen: 500,
        date: const CivilDate(2026, 7, 10),
        categoryId: foodId,
        source: TxnSource.manual));
  }

  test('backupNow: 世代が増え lastBackup が更新される', () async {
    await setUpWith();
    final sub = c.listen(lastBackupProvider, (_, _) {});
    addTearDown(sub.close);
    expect(sub.read(), isNull);
    await seedTx();
    await ctrl().backupNow();
    expect(c.read(autoBackupStoreProvider).listGenerations(), hasLength(1));
    expect(c.read(lastBackupProvider), isNotNull);
  });

  test('起動時ポリシー: 空DBは何もしない', () async {
    await setUpWith();
    expect(await ctrl().runStartupBackupIfStale(), isFalse);
    expect(c.read(autoBackupStoreProvider).listGenerations(), isEmpty);
  });

  test('起動時ポリシー: 未作成なら実行、24h以内ならスキップ、超えたら実行', () async {
    // utcNow(固定)=2026-07-15T03:00。世代タイムスタンプは storeNow で制御。
    await setUpWith(storeNow: DateTime.utc(2026, 7, 15, 2)); // 1時間前
    await seedTx();
    expect(await ctrl().runStartupBackupIfStale(), isTrue); // 未作成→実行
    expect(await ctrl().runStartupBackupIfStale(), isFalse); // 1h前→スキップ
    // 世代を27時間前に置き直す
    for (final f in c.read(autoBackupStoreProvider).listGenerations()) {
      f.deleteSync();
    }
    final stale = AutoBackupStore(h.backupDir,
        now: () => DateTime.utc(2026, 7, 14, 0)); // 27時間前
    await stale.writeVerified(await c.read(backupServiceProvider).exportJson());
    expect(await ctrl().runStartupBackupIfStale(), isTrue);
  });

  test('exportJson 平文: デコード可能なJSONがexportsに書かれる', () async {
    await setUpWith();
    await seedTx();
    final file = await ctrl().exportJson();
    expect(file.path, endsWith('.json'));
    expect(file.path, contains('20260715-0300')); // utcNow固定
    final payload = const BackupCodec().decode(file.readAsStringSync());
    expect(payload.transactions, hasLength(1));
  });

  test('exportJson 暗号化: .kkbk がdecryptで復号できる', () async {
    await setUpWith();
    await seedTx();
    final file = await ctrl().exportJson(passphrase: 'himitsu');
    expect(file.path, endsWith('.kkbk'));
    final json = await c
        .read(backupCryptoProvider)
        .decrypt(file.readAsBytesSync(), 'himitsu');
    expect(json, contains('formatVersion'));
  });

  test('exportCsv: BOM付きCSVが書かれる', () async {
    await setUpWith();
    await seedTx();
    final file = await ctrl().exportCsv();
    expect(file.path, endsWith('.csv'));
    // readAsStringはBOMを剥がすため、バイト列でBOM(EF BB BF)を検証する
    expect(file.readAsBytesSync().sublist(0, 3), [0xEF, 0xBB, 0xBF]);
  });

  test('同秒内の同種エクスポートでもファイルが上書きされない', () async {
    await setUpWith();
    await seedTx();
    final a = await ctrl().exportJson();
    final b = await ctrl().exportJson();
    expect(a.path, isNot(b.path));
    expect(a.existsSync(), isTrue);
    expect(b.existsSync(), isTrue);
  });

  test('listRestoreSources: 自動世代とexportsがマージされ暗号化フラグが立つ', () async {
    await setUpWith();
    await seedTx();
    await ctrl().backupNow();
    await ctrl().exportJson();
    await ctrl().exportJson(passphrase: 'x');
    final sources = ctrl().listRestoreSources();
    expect(sources.where((s) => s.isAutoBackup), hasLength(1));
    expect(sources.where((s) => s.encrypted), hasLength(1));
    expect(sources.first.label, contains('自動バックアップ'));
  });

  test('restoreFrom: 置換復元＋復元前スナップショットが残る', () async {
    await setUpWith();
    await seedTx();
    await ctrl().backupNow(); // 1件時点の世代
    await seedTx(); // 2件に
    final src = ctrl().listRestoreSources().first;
    await ctrl().restoreFrom(src);
    final after = await c.read(transactionRepositoryProvider).forMonth(2026, 7);
    expect(after, hasLength(1)); // 1件時点に戻った
    // 復元前スナップショット（2件時点）が自動退避されている
    expect(c.read(autoBackupStoreProvider).listGenerations().length,
        greaterThanOrEqualTo(2));
  });

  test('restoreFrom: 暗号化はパスフレーズ必須・誤りは復号エラー', () async {
    await setUpWith();
    await seedTx();
    await ctrl().exportJson(passphrase: 'correct');
    final src = ctrl().listRestoreSources().firstWhere((s) => s.encrypted);
    expect(() => ctrl().restoreFrom(src),
        throwsA(isA<PassphraseRequiredError>()));
    await expectLater(
        ctrl().restoreFrom(src, passphrase: 'wrong'), throwsA(anything));
    await ctrl().restoreFrom(src, passphrase: 'correct'); // 成功
  });

  test('restoreFrom: 空バックアップは EmptyBackupError、allowEmptyで通る', () async {
    await setUpWith();
    await seedTx();
    // 別の空DBから正当な空エクスポートを作る
    final other = newMemoryDb();
    addTearDown(other.close);
    final emptyJson = await BackupService(other).exportJson();
    h.exportsDir.createSync(recursive: true);
    final f = File(
        '${h.exportsDir.path}${Platform.pathSeparator}kakeibo-export-empty.json')
      ..writeAsStringSync(emptyJson);
    final src =
        ctrl().listRestoreSources().firstWhere((s) => s.file.path == f.path);
    await expectLater(
        ctrl().restoreFrom(src), throwsA(isA<EmptyBackupError>()));
    await ctrl().restoreFrom(src, allowEmpty: true);
    expect(
        await c.read(transactionRepositoryProvider).forMonth(2026, 7), isEmpty);
  });
}
