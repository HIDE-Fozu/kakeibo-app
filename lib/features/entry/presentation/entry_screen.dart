import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../data/db/enums.dart';
import '../../../domain/money/civil_date.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/entry_form_controller.dart';
import 'category_grid.dart';
import 'numpad.dart';
import 'receipt_review_panel.dart';
import 'subcategory_chips.dart';

class EntryScreen extends ConsumerWidget {
  /// true=ボトムタブに埋め込み（Xで閉じず、保存後はカレンダーへ切替）。
  /// false=編集モーダル（fullscreenDialog・保存でpop）。
  final bool embedded;

  const EntryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryFormControllerProvider);
    if (state == null) return const Scaffold(body: SizedBox());
    final ctrl = ref.read(entryFormControllerProvider.notifier);

    final title = switch (state.mode) {
      EntryMode.create => '入力',
      EntryMode.receiptConfirm => 'レシート確認',
      EntryMode.edit => '編集',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (state.mode == EntryMode.create)
            IconButton(
              key: const Key('scan-receipt'),
              icon: const Icon(Icons.receipt_long),
              onPressed: () => _scanReceipt(context, ref),
            ),
          if (state.mode == EntryMode.edit)
            IconButton(
              key: const Key('delete-entry'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 編集では型不変（DBのupdateFieldsがtypeを書かない。返品はspec §4.4の運用で表現）
              if (state.mode != EntryMode.edit)
                SegmentedButton<TxnType>(
                  segments: const [
                    ButtonSegment(value: TxnType.expense, label: Text('支出')),
                    ButtonSegment(value: TxnType.income, label: Text('収入')),
                  ],
                  selected: {state.type},
                  onSelectionChanged: (s) => ctrl.setType(s.single),
                ),
              ListTile(
                key: const Key('date-tile'),
                dense: true,
                leading: const Icon(Icons.event),
                title: Text(_dateLabel(state.date)),
                tileColor: state.mode == EntryMode.receiptConfirm
                    ? confidenceTint(state.matchedDateCandidate?.confidence)
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateTimeOfCivil(state.date),
                    firstDate: DateTime(2000, 1, 1),
                    lastDate: DateTime(2100, 12, 31),
                  );
                  if (picked != null) ctrl.setDate(civilOfDateTime(picked));
                },
              ),
              if (state.mode == EntryMode.receiptConfirm)
                ReceiptReviewPanel(state: state),
              Container(
                key: const Key('amount-display'),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: state.mode == EntryMode.receiptConfirm
                      ? confidenceTint(state.matchedTotalCandidate?.confidence)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.amountYen == 0 ? '¥0' : formatYen(state.amountYen),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
              Numpad(
                onDigit: ctrl.tapDigit,
                onDoubleZero: ctrl.tapDoubleZero,
                onBackspace: ctrl.backspace,
              ),
              const SizedBox(height: 8),
              CategoryGrid(
                type: state.type,
                selectedId: state.categoryId,
                onTapCategory: ctrl.tapCategory,
              ),
              // 内訳チップは押したカテゴリの真下に出す（母テストで選択に気づきにくかった対策）
              if (state.expandedParentId != null) ...[
                const SizedBox(height: 8),
                SubcategoryChips(
                  key: const Key('subcategory-chips'),
                  parentId: state.expandedParentId!,
                  selectedId: state.categoryId,
                  onToggle: ctrl.toggleSubcategory,
                ),
              ],
              const SizedBox(height: 8),
              // メモは常時入力欄を表示（トグル廃止）。formSeqでリセット時にクリア。
              TextFormField(
                key: ValueKey('memo-field-${state.formSeq}'),
                initialValue: state.memo,
                decoration: const InputDecoration(
                  labelText: 'メモ・店名',
                  border: OutlineInputBorder(),
                ),
                onChanged: ctrl.setMemo,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('save-btn'),
                      onPressed: state.canSave
                          ? () async {
                              final date = state.date;
                              await ctrl.save();
                              if (embedded) {
                                // 保存できたことが分かるようカレンダーへ切替（その日を表示）
                                ref
                                    .read(selectedDayProvider.notifier)
                                    .select(date);
                                ctrl.startCreate(ref.read(clockProvider)());
                                ref
                                    .read(homeTabIndexProvider.notifier)
                                    .set(0);
                              } else if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          : null,
                      child: const Text('保存'),
                    ),
                  ),
                  if (state.mode != EntryMode.edit) ...[
                    // create + receiptConfirm（spec §7.4 分割入力）
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('save-continue-btn'),
                        onPressed: state.canSave
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await ctrl.saveAndContinue();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('保存しました')),
                                );
                              }
                            : null,
                        child: const Text('保存して続ける'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(CivilDate date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Future<void> _scanReceipt(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await ref.read(receiptCaptureProvider).capture();
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('この端末ではレシート撮影を利用できません')),
      );
      return;
    }
    try {
      final blocks = await ref.read(ocrServiceProvider).recognize(path);
      final parsed = ref.read(receiptParserProvider).parse(blocks);
      ref
          .read(entryFormControllerProvider.notifier)
          .startReceipt(parsed, imagePath: path);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('読み取りに失敗しました: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この取引を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(entryFormControllerProvider.notifier).deleteEditing();
    if (context.mounted) Navigator.pop(context);
  }
}
