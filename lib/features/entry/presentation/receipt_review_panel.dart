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
        // 店舗名: OCR候補チップから選ぶ or「直接入力」で手入力（→storeNameへ）。
        // 1位の自動特定は不安定なため、金額/日付と同じ候補提示＋ワンタップ切替に統一。
        // 詳細メモとは別欄（店名と詳細を混ぜない）。
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 16, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '店舗名',
                    key: const Key('store-name'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _storeChips(context, ctrl, receipt.storeCandidates,
                  state.storeName.trim()),
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

  /// 店舗名の候補チップ列。手入力した値が候補にない場合は先頭に選択済みチップで
  /// 表示し、末尾に常に「直接入力」ボタンを置く（候補ゼロでも手入力できる）。
  Widget _storeChips(BuildContext context, EntryFormController ctrl,
      List<String> candidates, String store) {
    final hasCustom = store.isNotEmpty && !candidates.contains(store);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasCustom)
          ChoiceChip(
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(store, overflow: TextOverflow.ellipsis),
            ),
            selected: true,
            onSelected: (_) => _editStoreName(context, ctrl, store),
          ),
        for (final cand in candidates)
          ChoiceChip(
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(cand, overflow: TextOverflow.ellipsis),
            ),
            selected: store == cand,
            onSelected: (_) => ctrl.setStoreName(cand),
          ),
        ActionChip(
          key: const Key('store-edit'),
          avatar: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('直接入力'),
          onPressed: () => _editStoreName(context, ctrl, store),
        ),
      ],
    );
  }

  Future<void> _editStoreName(
      BuildContext context, EntryFormController ctrl, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('店舗名を入力'),
        content: TextField(
          key: const Key('store-edit-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '店舗名',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('store-edit-ok'),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('決定'),
          ),
        ],
      ),
    );
    if (result != null) ctrl.setStoreName(result.trim());
  }
}
