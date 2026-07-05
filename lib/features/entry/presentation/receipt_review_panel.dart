import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../domain/services/receipt/receipt_parser.dart';
import '../application/entry_form_controller.dart';

/// 確信度tier→ハイライト色（spec §7.5・モック確定soft色）。nullは無色（手修正済み等）。
Color? confidenceTint(ExtractionConfidence? c) => switch (c) {
      null => null,
      ExtractionConfidence.high => kConfidenceHighSoft,
      ExtractionConfidence.medium => kConfidenceMediumSoft,
      ExtractionConfidence.low => kExpenseSoft,
    };

class ReceiptReviewPanel extends ConsumerWidget {
  final EntryFormState state;
  const ReceiptReviewPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = state.receipt;
    if (receipt == null) return const SizedBox.shrink();
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final path = state.imagePath;
    final hasImage = path != null && File(path).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                    height: 48, child: Center(child: Text('画像なし')))),
          )
        else
          Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('画像なし'),
          ),
        // 店名: 候補チップから選ぶ（選択→メモへ）。1位の自動特定は不安定なため
        // 金額/日付と同じ「候補提示＋ワンタップ切替」に統一。
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(Icons.storefront_outlined,
                    size: 16, color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: receipt.storeCandidates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '店名不明',
                          key: const Key('store-name'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        children: [
                          for (final cand in receipt.storeCandidates)
                            ChoiceChip(
                              label: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 180),
                                child: Text(cand,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              selected: state.memo == cand,
                              onSelected: (_) => ctrl.setMemo(cand),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        if (receipt.total == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '金額を読み取れませんでした。手入力してください',
              key: const Key('ocr-fallback-note'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (receipt.totalCandidates.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final cand in receipt.totalCandidates)
                ChoiceChip(
                  label: Text(formatYen(cand.yen)),
                  selected: identical(state.matchedTotalCandidate, cand),
                  onSelected: (_) => ctrl.selectTotalCandidate(cand),
                ),
            ],
          ),
        ],
        if (receipt.dateCandidates.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final cand in receipt.dateCandidates)
                ChoiceChip(
                  label: Text(cand.date.toIso()),
                  selected: identical(state.matchedDateCandidate, cand),
                  onSelected: (_) => ctrl.selectDateCandidate(cand),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
