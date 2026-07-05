import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';
import 'package:kakeibo_app/domain/services/receipt/rows.dart';

import '../support/receipt_fixtures.dart';

/// 実機収集フィクスチャの観測プローブ（実装調整用の可視化。落ちない）。
/// expected を書き込んだフィクスチャは receipt_parser_test 側で検証する。
void main() {
  test('probe: 実レシートのパース結果一覧', () {
    final dir = Directory('test/fixtures/receipts');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('receipt-2026'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final parser = ReceiptParser(today: () => const CivilDate(2026, 7, 6));
    for (final f in files) {
      final fx = loadFixture(f.path);
      final parsed = parser.parse(fx.blocks);
      final rows = groupRows(fx.blocks);
      // 上部行（店名候補圏）を生テキストで観察
      final top = rows.where((r) => r.centerY < 0.35).take(8).toList();
      // ignore: avoid_print
      print('=== ${fx.name}');
      for (final r in top) {
        // ignore: avoid_print
        print('  [y=${r.centerY.toStringAsFixed(2)}] ${r.text}');
      }
      // ignore: avoid_print
      print('  -> store=${parsed.storeName} / '
          'total=${parsed.total?.yen}(${parsed.total?.confidence.name}:${parsed.total?.reason}) / '
          'date=${parsed.date.date}(${parsed.date.confidence.name}) / '
          'cands=${parsed.totalCandidates.map((c) => c.yen).toList()}');
    }
  });
}
