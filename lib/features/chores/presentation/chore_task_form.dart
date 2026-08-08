import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cell_dropdown.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/chore_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chore_providers.dart';

/// 新規/編集共用のつきいちタスクフォーム（routine-reminder の task_form.dart を移植）。
/// `task: null`=新規（保存で createTask・初回期日=今日以降で最初の毎月N日）、
/// 非null=編集。
///
/// バリデーション: 名前1〜30文字・絵文字1グリフ採用/未入力なら📌。
/// 予定日はプルダウン（1..31）なので不正値は入らない。
/// 編集モードには「アーカイブする」「この項目を削除」（確認あり）が追加される。
class ChoreTaskFormPage extends ConsumerStatefulWidget {
  const ChoreTaskFormPage({super.key, required this.task});

  final ChoreTask? task;

  @override
  ConsumerState<ChoreTaskFormPage> createState() => _ChoreTaskFormPageState();
}

class _ChoreTaskFormPageState extends ConsumerState<ChoreTaskFormPage> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.task?.name ?? '');
  // 新規の既定は今日の「日」（今日作れば今日が初回期日になる自然な既定）。
  late int _day =
      widget.task?.dayOfMonth ?? ref.read(choreTodayProvider).day;
  late final TextEditingController _emojiCtrl =
      TextEditingController(text: widget.task?.emoji ?? '');

  /// 保存の再入ガード。awaitを跨ぐ`_save`は連打で再入可能なため、
  /// 同期的にラッチを立てて二重作成を防ぐ（ボタン無効化＋早期return二重防御）。
  bool _saving = false;
  bool _archiving = false;
  bool _deleting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  /// 名前は空白のみを拒否するためtrim後で判定する。
  String get _trimmedName => _nameCtrl.text.trim();

  bool get _isValid {
    final name = _trimmedName;
    return name.isNotEmpty && name.characters.length <= kChoreNameMax;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final name = _trimmedName;
      // 絵文字もtrim（先頭空白が「1グリフ目」として保存されるのを防ぐ）
      final emojiGraphemes = _emojiCtrl.text.trim().characters;
      final emoji = emojiGraphemes.isEmpty ? '📌' : emojiGraphemes.first;
      final actions = ref.read(choreActionsProvider);
      final currentTask = widget.task;
      if (currentTask == null) {
        await actions.createTask(name: name, emoji: emoji, dayOfMonth: _day);
      } else {
        await actions.updateTaskInfo(ChoreTask(
          id: currentTask.id,
          name: name,
          emoji: emoji,
          dayOfMonth: _day,
          anchorDate: currentTask.anchorDate,
          archived: currentTask.archived,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      // 成功時はpop済み（unmounted）でスキップ。例外等でフォームが残った場合
      // のみ再有効化し、永久に保存不能になるのを防ぐ。
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 「アーカイブする」。確認なし・即実行。一覧・ドット・通知からは消えるが
  /// 履歴は保持される。フォームのみを閉じ、呼び出し元へ戻る。
  Future<void> _archive() async {
    if (_archiving) return;
    setState(() => _archiving = true);
    try {
      await ref.read(choreActionsProvider).setArchived(widget.task!.id, true);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _archiving = false);
    }
  }

  /// 「この項目を削除」。「履歴◯件もすべて削除されます」確認→deleteTask
  /// （記録もカスケード削除）→フォーム・履歴画面の両方を閉じる。
  Future<void> _deleteTask() async {
    if (_deleting) return;
    final l = AppLocalizations.of(context);
    final taskId = widget.task!.id;
    final recordCount = (ref.read(choreRecordsProvider).valueOrNull ?? const [])
        .where((r) => r.taskId == taskId)
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.recurringDeleteConfirmTitle),
        content: Text(l.choreDeleteConfirmBody(recordCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            key: const Key('chore-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(choreActionsProvider).deleteTask(taskId);
      if (mounted) {
        Navigator.of(context)
          ..pop() // フォーム
          ..pop(); // 履歴画面
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.task == null ? l.choreFormNewTitle : l.choreFormEditTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('chore-form-name'),
                controller: _nameCtrl,
                maxLength: kChoreNameMax,
                decoration: InputDecoration(labelText: l.choreFormNameLabel),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              CellDropdownField<int>(
                key: const Key('chore-form-day'),
                value: _day,
                decoration: InputDecoration(
                  labelText: l.choreFormDayLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (var d = 1; d <= 31; d++)
                    CellDropdownItem(d, l.dayOfMonthItem(d)),
                ],
                onChanged: (v) => setState(() => _day = v),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('chore-form-emoji'),
                controller: _emojiCtrl,
                decoration: InputDecoration(labelText: l.choreFormEmojiLabel),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('chore-form-save'),
                onPressed:
                    (_isValid && !_saving) ? () => unawaited(_save()) : null,
                child: Text(l.commonSave),
              ),
              if (widget.task != null) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  key: const Key('chore-archive-btn'),
                  onPressed: _archiving ? null : () => unawaited(_archive()),
                  child: Text(l.choreFormArchiveButton),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('chore-delete-btn'),
                  onPressed: _deleting ? null : () => unawaited(_deleteTask()),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(l.choreFormDeleteButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
