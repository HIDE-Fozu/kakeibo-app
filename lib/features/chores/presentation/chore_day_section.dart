import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/money/civil_date.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chore_providers.dart';
import 'chore_history_page.dart';
import 'chore_ui_common.dart';

/// カレンダー日パネルに差し込む家事の行（統合カレンダーの家事レーン）。
///
/// 出すもの:
/// - その日に「やった」記録（✓・タップで履歴へ）
/// - その日が期日のタスク
/// - 選択日が今日なら期日超過のタスクも（救済導線。過去日の期日行は出さない）
///
/// 「やった」ボタンは選択日が今日のときだけ表示する（未来日への記録は不可・
/// 過去日への遡り記録は履歴画面の日付編集で代替する現仕様）。
List<Widget> buildChoreDayRows(
    BuildContext context, WidgetRef ref, CivilDate day) {
  final l = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final today = ref.watch(choreTodayProvider);
  final isToday = day == today;
  final statuses = ref.watch(choreStatusesProvider);
  final records = ref.watch(choreRecordsProvider).valueOrNull ?? const [];
  final tasks = ref.watch(choreTasksProvider).valueOrNull ?? const [];
  final taskById = {for (final t in tasks) t.id: t};

  final rows = <Widget>[];

  // その日の実施記録（アーカイブ済みタスクの記録は出さない）
  for (final r in records.where((r) => r.doneDate == day)) {
    final task = taskById[r.taskId];
    if (task == null || task.archived) continue;
    rows.add(ListTile(
      key: Key('chore-done-${r.id}'),
      leading: Text(task.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(task.name),
      subtitle: r.memo.isNotEmpty ? Text(r.memo) : null,
      trailing: Icon(Icons.check_circle, color: scheme.primary, size: 20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChoreHistoryPage(taskId: task.id)),
      ),
    ));
  }

  // 期日行: その日が期日 or（今日の場合のみ）超過中
  final dueHere = statuses.where((s) =>
      s.due == day || (isToday && s.isOverdue));
  for (final s in dueHere) {
    rows.add(ListTile(
      key: Key('chore-due-${s.task.id}'),
      leading: Text(s.task.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(s.task.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            choreRemainingText(l, s.daysLeft),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: s.isOverdue ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            FilledButton(
              key: Key('chore-done-btn-${s.task.id}'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => handleChoreDone(context, ref, s),
              child: Text(l.choreDoneButton),
            ),
          ],
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChoreHistoryPage(taskId: s.task.id)),
      ),
    ));
  }

  return rows;
}
