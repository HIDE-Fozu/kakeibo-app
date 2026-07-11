import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/receipt/receipt_parser.dart';

import '../../receipt_gen/src/truth.dart';

class ReceiptOutcome {
  final bool? totalCorrect;
  final bool? dateCorrect;
  final bool candidateHit;
  final bool? dateAbsentHandled;
  const ReceiptOutcome({
    required this.totalCorrect,
    required this.dateCorrect,
    required this.candidateHit,
    required this.dateAbsentHandled,
  });
}

/// spec §7: total=best候補のyen一致、date=truth.date==nullなら採点除外＋today返却を確認。
ReceiptOutcome scoreOne(TruthReceipt truth, ParsedReceipt parsed, CivilDate today) {
  final totalCorrect = parsed.total?.yen == truth.totalYen;
  final candidateHit = parsed.totalCandidates.any((c) => c.yen == truth.totalYen);
  if (truth.date == null) {
    return ReceiptOutcome(
      totalCorrect: totalCorrect,
      dateCorrect: null,
      candidateHit: candidateHit,
      dateAbsentHandled: parsed.date.date == today,
    );
  }
  return ReceiptOutcome(
    totalCorrect: totalCorrect,
    dateCorrect: parsed.date.date == truth.date,
    candidateHit: candidateHit,
    dateAbsentHandled: null,
  );
}

class Cell {
  int scored = 0;
  int correct = 0;
  double get accuracy => scored == 0 ? 0 : correct / scored;

  void add(bool ok) {
    scored++;
    if (ok) correct++;
  }

  Map<String, dynamic> toJson() =>
      {'scored': scored, 'correct': correct, 'accuracy': accuracy};
}

class EvalAggregate {
  final totalByLevel = {0: Cell(), 1: Cell(), 2: Cell()};
  final dateByLevel = {0: Cell(), 1: Cell(), 2: Cell()};
  final candidateByLevel = {0: Cell(), 1: Cell(), 2: Cell()};
  final totalByStoreType = <String, Cell>{};
  final dateAbsentSeen = {0: 0, 1: 0, 2: 0};
  final dateAbsentHandled = {0: 0, 1: 0, 2: 0};
  final failures = <String>[];

  void add(String name, int level, String storeType, ReceiptOutcome o) {
    var failed = false;
    if (o.totalCorrect != null) {
      totalByLevel[level]!.add(o.totalCorrect!);
      totalByStoreType.putIfAbsent(storeType, Cell.new).add(o.totalCorrect!);
      if (!o.totalCorrect!) failed = true;
    }
    candidateByLevel[level]!.add(o.candidateHit);
    if (o.dateCorrect != null) {
      dateByLevel[level]!.add(o.dateCorrect!);
      if (!o.dateCorrect!) failed = true;
    } else {
      dateAbsentSeen[level] = dateAbsentSeen[level]! + 1;
      if (o.dateAbsentHandled ?? false) {
        dateAbsentHandled[level] = dateAbsentHandled[level]! + 1;
      }
    }
    if (failed) failures.add(name);
  }

  Map<String, dynamic> toJson() => {
        for (final l in [0, 1, 2])
          'l$l': {
            'total': totalByLevel[l]!.toJson(),
            'date': dateByLevel[l]!.toJson(),
            'candidateHit': candidateByLevel[l]!.toJson(),
          },
        'dateAbsent': {
          for (final l in [0, 1, 2])
            'l$l': {'seen': dateAbsentSeen[l], 'handled': dateAbsentHandled[l]},
        },
        'totalByStoreType': {
          for (final e in totalByStoreType.entries) e.key: e.value.toJson(),
        },
        'failures': failures,
      };
}
