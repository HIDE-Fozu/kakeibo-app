import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/receipt_gen/src/vocab.dart';

void main() {
  test('test_vocab.json loads', () {
    final v = loadVocab('test/harness/fixtures/test_vocab.json');
    expect(v.items.keys.toSet(), storeTypes.toSet());
    expect(v.storeNames['supermarket'], isNotEmpty);
  });

  test('validate rejects digits, duplicates, NG names, and shortage', () {
    Vocab mini(Map<String, List<String>> namePatch) {
      // 数字なし・ユニークな130語×8様式=1,040語のダミー（i<133 で (i%7, i~/7) がユニーク）
      final items = {
        for (final s in storeTypes)
          s: [for (var i = 0; i < 130; i++) '品目$s${'い' * (i % 7)}${'う' * (i ~/ 7)}']
      };
      final names = {for (final s in storeTypes) s: List.generate(12, (i) => '架空店$s${'ぬ' * i}')};
      names.addAll(namePatch);
      return Vocab(items: items, storeNames: names);
    }

    expect(mini({}).validate(), isEmpty);
    expect(mini({'supermarket': ['店1号', ...List.generate(11, (i) => '店${'あ' * (i + 1)}')]}).validate(),
        isNotEmpty, reason: '数字入り店名');
    expect(mini({'cafe': ['同じ店', '同じ店', ...List.generate(10, (i) => '店${'か' * (i + 1)}')]}).validate(),
        isNotEmpty, reason: '重複');
    expect(mini({'supermarket': ['スーパーマルエツ渋谷', ...List.generate(11, (i) => '店${'さ' * (i + 1)}')]}).validate(),
        isNotEmpty, reason: 'NGリスト（実在チェーン）');
    expect(mini({'bookstore': ['一軒だけ']}).validate(), isNotEmpty, reason: '店名10未満');
  });

  test('committed production vocab.json is valid (skips until Task 9)', () {
    final f = File('tool/receipt_gen/data/vocab.json');
    if (!f.existsSync()) {
      markTestSkipped('vocab.json not generated yet (Task 9)');
      return;
    }
    expect(loadVocab(f.path).validate(), isEmpty);
  }, skip: false);
}
