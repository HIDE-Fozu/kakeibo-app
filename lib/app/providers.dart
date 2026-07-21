import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup/auto_backup_store.dart';
import '../data/backup/backup_crypto.dart';
import '../data/backup/backup_service.dart';
import '../data/db/database.dart';
import '../data/ocr/cloud_fixture_uploader.dart';
import '../data/ocr/ocr_fixture_recorder.dart';
import '../data/repositories/drift_category_repository.dart';
import '../data/repositories/drift_transaction_repository.dart';
import '../domain/entities.dart';
import '../domain/money/civil_date.dart';
import '../domain/repositories.dart';
import '../domain/services/ocr/ocr_types.dart';
import '../domain/services/ocr/receipt_capture.dart';
import '../domain/services/receipt/receipt_parser.dart';

/// コアprovider群。
///
/// 逸脱メモ（plan参照）: drift_dev 2.34(analyzer ^13)と riverpod codegen/lint が
/// 依存衝突するため、codegenではなく手書きprovider（riverpod 2.6 manual API）。
/// provider名はplanどおり。legacy API（StateProvider等）は使用しない。

// --- 縫い目（bootstrap/テストで必ずoverride） ---

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider は bootstrap/テストで override する'),
);

final backupDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('backupDirProvider は bootstrap/テストで override する'),
);

final exportsDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('exportsDirProvider は bootstrap/テストで override する'),
);

final receiptImagesDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('receiptImagesDirProvider は bootstrap/テストで override する'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider は bootstrap/テストで override する'),
);

final ocrServiceProvider = Provider<OcrService>(
  (ref) => throw UnimplementedError('ocrServiceProvider は bootstrap/テストで override する'),
);

final receiptCaptureProvider = Provider<ReceiptCapture>(
  (ref) => throw UnimplementedError('receiptCaptureProvider は bootstrap/テストで override する'),
);

// --- 時計（決定的テストの要。UI層で DateTime.now() を直接呼ばない） ---

final clockProvider = Provider<CivilDate Function()>(
  (ref) => () => CivilDate.fromDateTime(DateTime.now()),
);

final utcNowProvider = Provider<DateTime Function()>(
  (ref) => () => DateTime.now().toUtc(),
);

// --- 派生配線（override不要） ---

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider)),
);

final autoBackupStoreProvider = Provider<AutoBackupStore>(
  (ref) => AutoBackupStore(ref.watch(backupDirProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(appDatabaseProvider),
    store: ref.watch(autoBackupStoreProvider),
  ),
);

final backupCryptoProvider = Provider<BackupCrypto>((ref) => BackupCrypto());

final receiptParserProvider = Provider<ReceiptParser>(
  (ref) => ReceiptParser(today: ref.watch(clockProvider)),
);

/// スキャンごとのOCRブロックを exports/ocr-fixtures へ保存（debugビルドのみ使用）。
/// 実レシートのフィクスチャ収集（spec §8.2・§13宿題）の回収経路。
final ocrFixtureRecorderProvider = Provider<OcrFixtureRecorder>(
  (ref) => OcrFixtureRecorder(
    Directory(
        '${ref.watch(exportsDirProvider).path}${Platform.pathSeparator}ocr-fixtures'),
    now: ref.watch(utcNowProvider),
  ),
);

/// 【テスト期間限定】収集データのCloudKit送信（オプトイン時のみ呼ばれる）。
final cloudFixtureUploaderProvider = Provider<CloudFixtureUploader>(
  (ref) => CloudFixtureUploader(
    ref.watch(ocrFixtureRecorderProvider).dir,
    ref.watch(sharedPreferencesProvider),
  ),
);

final allCategoriesProvider = StreamProvider<List<CategoryEntity>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// 全取引件数（通貨ロック判定用）。autoDispose で設定画面を開くたび再評価。
final transactionCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(transactionRepositoryProvider).count(),
);
