import 'dart:convert';
import 'dart:io';

import '../receipt_gen/src/vocab.dart';

const _storeTypeJa = {
  'supermarket': 'スーパーマーケット',
  'convenience': 'コンビニエンスストア',
  'drugstore': 'ドラッグストア',
  'restaurant': '大衆的な飲食店・定食屋',
  'cafe': '喫茶店・カフェ',
  'homecenter': 'ホームセンター',
  'bookstore': '書店・文具店',
  'gasstation': 'ガソリンスタンド',
};

Future<List<String>> _ask(String model, String prompt) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.postUrl(Uri.parse('http://localhost:11434/api/chat'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'model': model,
      'stream': false,
      'think': false,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'format': {
        'type': 'object',
        'properties': {
          'words': {
            'type': 'array',
            'items': {'type': 'string'}
          }
        },
        'required': ['words'],
      },
      'options': {'temperature': 0.9},
    }));
    final res = await req.close().timeout(const Duration(seconds: 300));
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw HttpException('status ${res.statusCode}: $body');
    }
    final content =
        (jsonDecode(body) as Map<String, dynamic>)['message']['content'] as String;
    final words =
        ((jsonDecode(content) as Map<String, dynamic>)['words'] as List).cast<String>();
    return words;
  } finally {
    client.close();
  }
}

List<String> _clean(List<String> raw) {
  final digits = RegExp('[0-9０-９]');
  final seen = <String>{};
  return [
    for (final w0 in raw)
      if (w0.trim().isNotEmpty)
        if (!digits.hasMatch(w0.trim()))
          if (seen.add(w0.trim())) w0.trim(),
  ];
}

List<String> _ngFilter(List<String> raw) => [
      for (final n in raw)
        if (!ngStoreNames.any(n.contains)) n,
    ];

String _itemsPrompt(String ja, int n) =>
    '日本の$jaのレシートに印字される品目名（商品・メニューの短い表記）を$n個、'
    'JSONで出してください。数字・価格・数量・単位・記号は一切含めないこと。'
    '実在の商標・ブランド名は避け、一般的な品目名にすること。';

String _namesPrompt(String ja, int n) =>
    '日本の$jaの架空の店名を$n個、JSONで出してください。'
    '実在するチェーン店の名前やそれに酷似した名前は禁止。数字は含めないこと。';

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final model = _arg(args, '--model') ?? 'qwen3:14b';
  final out = _arg(args, '--out') ?? 'tool/receipt_gen/data/vocab.json';

  final items = <String, List<String>>{};
  final names = <String, List<String>>{};
  try {
    for (final st in storeTypes) {
      final ja = _storeTypeJa[st]!;
      // 品目: 100個/リクエストで、ユニーク130語に達するまで（最大4リクエスト）。
      // 130 = 検証の総計要件 items>=1000（平均125語/様式）を上回る様式別目標。
      var collectedItems = <String>[];
      for (var req = 1; req <= 4 && collectedItems.length < 130; req++) {
        stdout.writeln('items: $st (req $req, have ${collectedItems.length})...');
        collectedItems = _clean(
            [...collectedItems, ...await _ask(model, _itemsPrompt(ja, 100))]);
      }
      items[st] = collectedItems;
      // 店名: 15個/リクエストで、NGフィルタ後12語に達するまで（最大2リクエスト）。
      var collectedNames = <String>[];
      for (var req = 1; req <= 2 && collectedNames.length < 12; req++) {
        stdout.writeln('storeNames: $st (req $req, have ${collectedNames.length})...');
        collectedNames = _ngFilter(_clean(
            [...collectedNames, ...await _ask(model, _namesPrompt(ja, 15))]));
      }
      names[st] = collectedNames;
    }
  } on Object catch (e) {
    stderr.writeln('Ollama呼び出しに失敗しました（Ollama起動と `ollama pull $model` を確認）: $e');
    exit(1);
  }

  final vocab = Vocab(items: items, storeNames: names);
  final errors = vocab.validate();
  if (errors.isNotEmpty) {
    stderr.writeln('生成語彙が検証不合格（再実行してください）: $errors');
    exit(1);
  }
  final json = const JsonEncoder.withIndent(' ').convert({
    'model': model,
    'items': items,
    'storeNames': names,
  });
  File(out)
    ..createSync(recursive: true)
    ..writeAsStringSync('$json\n');
  stdout.writeln('wrote $out');
}
