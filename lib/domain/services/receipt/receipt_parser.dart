import '../../money/civil_date.dart';
import '../ocr/ocr_types.dart';
import 'date.dart';
import 'normalize.dart';
import 'rows.dart';
import 'total.dart';

export 'date.dart' show DateCandidate, DateExtraction;
export 'total.dart' show AmountCandidate, ExtractionConfidence, TotalExtraction;

/// レシートOCRの最終出力。確認画面はこの候補リストで切替UIを出す。
class ParsedReceipt {
  final AmountCandidate? total;
  final List<AmountCandidate> totalCandidates;
  final DateCandidate date; // 常に非null（見つからなければ今日・low）
  final List<DateCandidate> dateCandidates;
  const ParsedReceipt({
    required this.total,
    required this.totalCandidates,
    required this.date,
    required this.dateCandidates,
  });
}

/// 純Dartのレシートパーサ（spec §7）。
/// パイプライン: 正規化 → 行復元 → 合計抽出 / 日付抽出。
/// 時計は注入して全テストを決定的にする。
class ReceiptParser {
  final CivilDate Function() _today;

  ReceiptParser({CivilDate Function()? today})
      : _today = today ?? (() => CivilDate.fromDateTime(DateTime.now()));

  ParsedReceipt parse(List<OcrBlock> blocks) {
    final normalized = [
      for (final b in blocks)
        OcrBlock(
          text: normalizeOcrText(b.text),
          rect: b.rect,
          confidence: b.confidence,
        ),
    ];
    final rows = groupRows(normalized);
    final total = extractTotal(rows);
    final date = extractDate(rows, _today());
    return ParsedReceipt(
      total: total.best,
      totalCandidates: total.candidates,
      date: date.best!,
      dateCandidates: date.candidates,
    );
  }
}
