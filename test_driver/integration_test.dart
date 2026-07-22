import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// integration_test のスクリーンショットを build/qa_screens/ に保存するドライバ。
/// 実行: flutter drive --driver=test_driver/integration_test.dart
///        --target=integration_test/i18n_qa_test.dart -d `<device>`
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('build/qa_screens/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
