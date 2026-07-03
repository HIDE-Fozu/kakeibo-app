import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/database.dart';
import '../domain/services/ocr/ocr_types.dart';
import '../domain/services/ocr/receipt_capture.dart';
import 'app.dart';
import 'providers.dart';

/// 実行時の実配線。ロジックを持たない（テストはハーネスの override で代替）。
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // table_calendarの曜日ラベル(DateFormat.E)に必須
  final support = await getApplicationSupportDirectory();
  final docs = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();

  final sep = Platform.pathSeparator;
  final db = AppDatabase(
    NativeDatabase.createInBackground(File('${support.path}${sep}kakeibo.sqlite')),
  );

  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      backupDirProvider.overrideWith((ref) => Directory('${support.path}${sep}backups')),
      exportsDirProvider.overrideWith((ref) => Directory('${docs.path}${sep}exports')),
      receiptImagesDirProvider.overrideWith((ref) => Directory('${support.path}${sep}receipt_images')),
      sharedPreferencesProvider.overrideWith((ref) => prefs),
      // Phase 5（Mac）で AppleVisionOcrService / 実カメラ capture に差し替える
      ocrServiceProvider.overrideWith((ref) => const FakeOcrService([])),
      receiptCaptureProvider.overrideWith((ref) => const UnavailableReceiptCapture()),
    ],
    child: const KakeiboApp(),
  ));
}
