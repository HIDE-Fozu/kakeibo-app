import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakeibo_app/app/app.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/app/theme.dart';
import 'package:kakeibo_app/data/backup/auto_backup_store.dart';
import 'package:kakeibo_app/data/backup/backup_crypto.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';
import 'package:kakeibo_app/domain/services/ocr/receipt_capture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_db.dart';

/// UI/providerテスト共通ハーネス。
/// 固定時計 2026-07-15（月中日でmonth境界フレークを回避）。
class TestHarness {
  final AppDatabase db;
  final Directory root;
  final SharedPreferences prefs;
  TestHarness({required this.db, required this.root, required this.prefs});

  Directory get backupDir => Directory('${root.path}${Platform.pathSeparator}backups');
  Directory get exportsDir => Directory('${root.path}${Platform.pathSeparator}exports');
  Directory get imagesDir => Directory('${root.path}${Platform.pathSeparator}images');

  List<Override> overrides({
    CivilDate Function()? clock,
    DateTime Function()? utcNow,
    DateTime Function()? storeNow,
    OcrService? ocr,
    ReceiptCapture? capture,
  }) =>
      [
        appDatabaseProvider.overrideWith((ref) => db),
        backupDirProvider.overrideWith((ref) => backupDir),
        exportsDirProvider.overrideWith((ref) => exportsDir),
        receiptImagesDirProvider.overrideWith((ref) => imagesDir),
        // 自動バックアップ世代のタイムスタンプも決定的に。
        // 完全固定だと世代ファイル名（μs起源）が衝突して上書きされるため、
        // 既定は「基準時刻から1秒ずつ進む」決定的時計にする。
        autoBackupStoreProvider.overrideWith((ref) {
          var tick = 0;
          final base = (utcNow ?? () => DateTime.utc(2026, 7, 15, 3, 0))();
          return AutoBackupStore(
            backupDir,
            now: storeNow ?? () => base.add(Duration(seconds: tick++)),
          );
        }),
        sharedPreferencesProvider.overrideWith((ref) => prefs),
        clockProvider.overrideWith((ref) => clock ?? () => const CivilDate(2026, 7, 15)),
        utcNowProvider.overrideWith((ref) => utcNow ?? () => DateTime.utc(2026, 7, 15, 3, 0)),
        ocrServiceProvider.overrideWith((ref) => ocr ?? const FakeOcrService([])),
        receiptCaptureProvider.overrideWith((ref) => capture ?? const UnavailableReceiptCapture()),
        backupCryptoProvider.overrideWith((ref) => BackupCrypto(pbkdf2Iterations: 1000)),
      ];

  void dispose() {
    db.close();
    try {
      if (root.existsSync()) root.deleteSync(recursive: true);
    } on FileSystemException {
      // Windowsのファイルハンドル解放遅延で稀に失敗する。
      // 一時ディレクトリなのでOSのクリーンアップに任せる。
    }
  }
}

Future<TestHarness> createHarness({
  Map<String, Object> prefs = const {'onboardingDone': true},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // table_calendarの曜日ラベル(DateFormat.E)に必須
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final root = Directory.systemTemp.createTempSync('kakeibo_ui_test');
  return TestHarness(db: newMemoryDb(), root: root, prefs: p);
}

/// アプリ全体（KakeiboApp）または単一画面（home指定）をポンプする。
Future<void> pumpApp(
  WidgetTester tester,
  TestHarness h, {
  Widget? home,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [...h.overrides(), ...extra],
    // home指定でも実テーマを使う（kakeiboColors拡張に依存する画面があるため）
    child: home != null
        ? MaterialApp(theme: buildKakeiboTheme(), home: home)
        : const KakeiboApp(),
  ));
  await tester.pumpAndSettle();
}

/// AsyncValue系providerの最初のデータ到達を待つ。
Future<T> waitForData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final completer = Completer<T>();
  final sub = container.listen<AsyncValue<T>>(provider, (prev, next) {
    if (next is AsyncData<T> && !completer.isCompleted) {
      completer.complete(next.value);
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}

/// テスト用: 固定パスを返す撮影スタブ。
class FakeReceiptCapture implements ReceiptCapture {
  final String? path;
  const FakeReceiptCapture(this.path);
  @override
  Future<String?> capture(ReceiptSource source) async => path;
}

/// iPhone相当の論理サイズ（390x844）。縦長フォームのoverflow検知のため必ず使う。
void setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
