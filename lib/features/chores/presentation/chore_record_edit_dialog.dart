import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/chore_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chore_providers.dart';
import 'chore_ui_common.dart';

/// 記録編集ダイアログを開く。日付修正・メモ編集・削除を行う。
/// 保存/削除いずれも ChoreActions 経由でDB更新→resync（通知/バッジ再計算）まで
/// 自動で走る（呼び出し元は結果を待つ必要がない）。
Future<void> showChoreRecordEditDialog(
    BuildContext context, ChoreRecord record) {
  return showDialog<void>(
    context: context,
    builder: (_) => ChoreRecordEditDialog(record: record),
  );
}

class ChoreRecordEditDialog extends ConsumerStatefulWidget {
  const ChoreRecordEditDialog({super.key, required this.record});

  final ChoreRecord record;

  @override
  ConsumerState<ChoreRecordEditDialog> createState() =>
      _ChoreRecordEditDialogState();
}

class _ChoreRecordEditDialogState extends ConsumerState<ChoreRecordEditDialog> {
  late CivilDate _date = widget.record.doneDate;
  late final TextEditingController _memoCtrl =
      TextEditingController(text: widget.record.memo);

  /// 保存・削除の再入ガード（連打防止）。
  bool _busy = false;

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(choreTodayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: dateTimeOfCivil(_date),
      firstDate: DateTime(2000, 1, 1),
      lastDate: dateTimeOfCivil(today), // 未来日は選択不可
    );
    if (picked != null && mounted) {
      setState(() => _date = civilOfDateTime(picked));
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(choreActionsProvider).editRecord(ChoreRecord(
            id: widget.record.id,
            taskId: widget.record.taskId,
            doneDate: _date,
            memo: _memoCtrl.text,
            createdAt: widget.record.createdAt,
          ));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.recurringDeleteConfirmTitle),
        content: Text(l.choreRecordDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            key: const Key('chore-record-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(choreActionsProvider).removeRecord(widget.record.id);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.choreRecordEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('chore-record-edit-date'),
            onTap: _busy ? null : () => unawaited(_pickDate()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(choreShortDate(context, _date)),
            ),
          ),
          TextField(
            key: const Key('chore-record-edit-memo'),
            controller: _memoCtrl,
            maxLength: kChoreMemoMax,
            decoration: InputDecoration(labelText: l.choreMemoLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('chore-record-edit-delete'),
          onPressed: _busy ? null : () => unawaited(_confirmAndDelete()),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l.commonDelete),
        ),
        TextButton(
          key: const Key('chore-record-edit-save'),
          onPressed: _busy ? null : () => unawaited(_save()),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
