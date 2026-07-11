import 'dart:convert';
import 'dart:io';

import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/ocr/ocr_types.dart';

class TruthItem {
  final String name;
  final int unitPriceYen;
  final int qty;
  final int amountYen;
  final int taxRate;
  const TruthItem({
    required this.name,
    required this.unitPriceYen,
    required this.qty,
    required this.amountYen,
    required this.taxRate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'unitPriceYen': unitPriceYen,
        'qty': qty,
        'amountYen': amountYen,
        'taxRate': taxRate,
      };

  factory TruthItem.fromJson(Map<String, dynamic> j) => TruthItem(
        name: j['name'] as String,
        unitPriceYen: j['unitPriceYen'] as int,
        qty: j['qty'] as int,
        amountYen: j['amountYen'] as int,
        taxRate: j['taxRate'] as int,
      );
}

class TruthDiscount {
  final String label;
  final int amountYen;
  const TruthDiscount({required this.label, required this.amountYen});

  Map<String, dynamic> toJson() => {'label': label, 'amountYen': amountYen};

  factory TruthDiscount.fromJson(Map<String, dynamic> j) =>
      TruthDiscount(label: j['label'] as String, amountYen: j['amountYen'] as int);
}

class TruthTaxLine {
  final int rate;
  final int taxYen;
  const TruthTaxLine({required this.rate, required this.taxYen});

  Map<String, dynamic> toJson() => {'rate': rate, 'taxYen': taxYen};

  factory TruthTaxLine.fromJson(Map<String, dynamic> j) =>
      TruthTaxLine(rate: j['rate'] as int, taxYen: j['taxYen'] as int);
}

class ReceiptStyle {
  final String dateFormat; // kanji | slash | dotShort | warekiShort | warekiKanji
  final String totalKeyword; // 合計 | お買上げ計 | 合　計 | 総合計 | お会計
  final String currencyMark; // yen | fullwidthYen | none | enSuffix
  const ReceiptStyle({
    required this.dateFormat,
    required this.totalKeyword,
    required this.currencyMark,
  });

  Map<String, dynamic> toJson() => {
        'dateFormat': dateFormat,
        'totalKeyword': totalKeyword,
        'currencyMark': currencyMark,
      };

  factory ReceiptStyle.fromJson(Map<String, dynamic> j) => ReceiptStyle(
        dateFormat: j['dateFormat'] as String,
        totalKeyword: j['totalKeyword'] as String,
        currencyMark: j['currencyMark'] as String,
      );
}

class TruthReceipt {
  final String storeName;
  final String storeType;
  final CivilDate? date;
  final List<TruthItem> items;
  final List<TruthDiscount> discounts;
  final String taxMode; // inclusive | exclusive
  final List<TruthTaxLine> taxLines;
  final int totalYen;
  final int? tenderedYen;
  final int? changeYen;
  final ReceiptStyle style;
  final int noiseLevel;
  const TruthReceipt({
    required this.storeName,
    required this.storeType,
    required this.date,
    required this.items,
    required this.discounts,
    required this.taxMode,
    required this.taxLines,
    required this.totalYen,
    required this.tenderedYen,
    required this.changeYen,
    required this.style,
    required this.noiseLevel,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'storeType': storeType,
        'date': date?.toIso(),
        'items': [for (final i in items) i.toJson()],
        'discounts': [for (final d in discounts) d.toJson()],
        'taxMode': taxMode,
        'taxLines': [for (final t in taxLines) t.toJson()],
        'totalYen': totalYen,
        'tenderedYen': tenderedYen,
        'changeYen': changeYen,
        'style': style.toJson(),
        'noiseLevel': noiseLevel,
      };

  factory TruthReceipt.fromJson(Map<String, dynamic> j) => TruthReceipt(
        storeName: j['storeName'] as String,
        storeType: j['storeType'] as String,
        date: j['date'] == null ? null : CivilDate.parse(j['date'] as String),
        items: [
          for (final i in j['items'] as List) TruthItem.fromJson(i as Map<String, dynamic>)
        ],
        discounts: [
          for (final d in j['discounts'] as List)
            TruthDiscount.fromJson(d as Map<String, dynamic>)
        ],
        taxMode: j['taxMode'] as String,
        taxLines: [
          for (final t in j['taxLines'] as List)
            TruthTaxLine.fromJson(t as Map<String, dynamic>)
        ],
        totalYen: j['totalYen'] as int,
        tenderedYen: j['tenderedYen'] as int?,
        changeYen: j['changeYen'] as int?,
        style: ReceiptStyle.fromJson(j['style'] as Map<String, dynamic>),
        noiseLevel: j['noiseLevel'] as int,
      );
}

/// 合成フィクスチャ。`expected` は truth から導出する（単一情報源、spec §4-1）。
class SynthFixture {
  final String name;
  final List<OcrBlock> blocks;
  final TruthReceipt truth;
  const SynthFixture({required this.name, required this.blocks, required this.truth});

  Map<String, dynamic> toJson() => {
        'name': name,
        'blocks': [
          for (final b in blocks)
            {
              'text': b.text,
              'x': b.rect.x,
              'y': b.rect.y,
              'w': b.rect.w,
              'h': b.rect.h,
              'confidence': b.confidence,
            }
        ],
        'expected': {'totalYen': truth.totalYen, 'date': truth.date?.toIso()},
        'truth': truth.toJson(),
      };
}

String encodeFixture(SynthFixture f) =>
    '${const JsonEncoder.withIndent(' ').convert(f.toJson())}\n';

SynthFixture loadSynthFixture(String path) {
  final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return SynthFixture(
    name: root['name'] as String,
    blocks: [
      for (final b in (root['blocks'] as List).cast<Map<String, dynamic>>())
        OcrBlock(
          text: b['text'] as String,
          rect: OcrRect(
            (b['x'] as num).toDouble(),
            (b['y'] as num).toDouble(),
            (b['w'] as num).toDouble(),
            (b['h'] as num).toDouble(),
          ),
          confidence: (b['confidence'] as num).toDouble(),
        ),
    ],
    truth: TruthReceipt.fromJson(root['truth'] as Map<String, dynamic>),
  );
}
