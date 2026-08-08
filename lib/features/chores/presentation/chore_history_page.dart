import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities.dart';
import '../../../domain/services/chore_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chore_providers.dart';
import 'chore_record_edit_dialog.dart';
import 'chore_task_form.dart';
import 'chore_ui_common.dart';

/// 1タスク分の履歴画面。ヘッダ（名前・間隔・次回期日）＋実施記録の一覧
/// （実施日降順・同日は作成順）。右上「編集」から項目編集フォームへ、
/// 各行の✎から記録編集ダイアログへ。
class ChoreHistoryPage extends ConsumerWidget {
  const ChoreHistoryPage({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tasks = ref.watch(choreTasksProvider).valueOrNull ?? const [];
    final allRecords = ref.watch(choreRecordsProvider).valueOrNull ?? const [];
    final today = ref.watch(choreTodayProvider);

    // 削除直後の遷移中フレーム等、taskIdがもう存在しない場合のフェイルセーフ。
    ChoreTask? task;
    for (final t in tasks) {
      if (t.id == taskId) {
        task = t;
        break;
      }
    }
    if (task == null) {
      return Scaffold(appBar: AppBar());
    }
    final found = task;

    final records = allRecords.where((r) => r.taskId == taskId).toList()
      ..sort((a, b) {
        final byDate = b.doneDate.compareTo(a.doneDate); // 実施日降順
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt); // 同日は作成順
      });

    final due = nextChoreDue(found, records);
    final left = choreDaysLeft(today, due);
    final isOverdue = left < 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.choreHistoryTitle),
        actions: [
          TextButton(
            key: const Key('chore-edit-btn'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChoreTaskFormPage(task: found),
              ),
            ),
            child: Text(l.commonEdit),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${found.emoji} ${found.name}（${l.choreIntervalEvery(found.intervalDays)}）',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${l.choreNextDate(choreShortDate(context, due))}'
                '（${choreRemainingText(l, left)}）',
                style: isOverdue
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: records.isEmpty
                    ? Text(l.choreHistoryEmpty)
                    : ListView(
                        children: [
                          for (final r in records)
                            ListTile(
                              key: Key('chore-history-row-${r.id}'),
                              title: Text(choreShortDate(context, r.doneDate)),
                              subtitle: r.memo.isNotEmpty ? Text(r.memo) : null,
                              trailing: IconButton(
                                key: Key('chore-edit-record-${r.id}'),
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    showChoreRecordEditDialog(context, r),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
