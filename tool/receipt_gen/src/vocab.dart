import 'dart:convert';
import 'dart:io';

const List<String> storeTypes = [
  'supermarket',
  'convenience',
  'drugstore',
  'restaurant',
  'cafe',
  'homecenter',
  'bookstore',
  'gasstation',
];

/// 実在チェーン混入防止のNGリスト（部分一致・spec §5）。
const List<String> ngStoreNames = [
  'マルエツ', 'イオン', 'セブン', 'ローソン', 'ファミリーマート',
  'ヨーカドー', 'ライフ', 'サミット', 'オーケー', '西友',
  'マツモトキヨシ', 'ウエルシア', 'ツルハ', 'スギ薬局', 'カインズ',
  'コーナン', 'ビバホーム', '紀伊國屋', 'TSUTAYA', 'ENEOS',
];

final RegExp _digits = RegExp('[0-9０-９]');

class Vocab {
  final Map<String, List<String>> items;
  final Map<String, List<String>> storeNames;
  const Vocab({required this.items, required this.storeNames});

  factory Vocab.fromJson(Map<String, dynamic> j) => Vocab(
        items: {
          for (final e in (j['items'] as Map<String, dynamic>).entries)
            e.key: (e.value as List).cast<String>(),
        },
        storeNames: {
          for (final e in (j['storeNames'] as Map<String, dynamic>).entries)
            e.key: (e.value as List).cast<String>(),
        },
      );

  /// 本番vocab.jsonの合格規則（spec §6）。空=合格。
  List<String> validate() {
    final errors = <String>[];
    var totalItems = 0;
    var totalNames = 0;
    for (final st in storeTypes) {
      final it = items[st] ?? const [];
      final names = storeNames[st] ?? const [];
      totalItems += it.length;
      totalNames += names.length;
      if (it.length < 50) errors.add('$st: items ${it.length} < 50');
      if (names.length < 10) errors.add('$st: storeNames ${names.length} < 10');
      if (it.toSet().length != it.length) errors.add('$st: duplicate items');
      if (names.toSet().length != names.length) errors.add('$st: duplicate storeNames');
      for (final w in [...it, ...names]) {
        if (_digits.hasMatch(w)) errors.add('$st: digit in "$w"');
      }
      for (final n in names) {
        for (final ng in ngStoreNames) {
          if (n.contains(ng)) errors.add('$st: NG store name "$n" (matches $ng)');
        }
      }
    }
    if (totalItems < 1000) errors.add('total items $totalItems < 1000');
    if (totalNames < 80) errors.add('total storeNames $totalNames < 80');
    return errors;
  }
}

Vocab loadVocab(String path) =>
    Vocab.fromJson(jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>);
