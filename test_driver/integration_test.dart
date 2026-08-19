import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// integration_test のスクリーンショットを build/qa_screens/<日付>/ に保存する
/// ドライバ（日付フォルダ分けはFB 2026-08-20）。
/// 実行: flutter drive --driver=test_driver/integration_test.dart
///        --target=integration_test/i18n_qa_test.dart -d `<device>`
Future<void> main() async {
  final day = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('build/qa_screens/$day/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
