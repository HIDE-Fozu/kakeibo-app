import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dates.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/chore_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chore_actions.dart';
import '../application/chore_providers.dart';

/// M/D のロケール依存短縮表記（ja: 8/25、en: 8/25、de: 25.8. など）。
String choreShortDate(BuildContext context, CivilDate d) =>
    DateFormat.Md(Localizations.localeOf(context).toLanguageTag())
        .format(dateTimeOfCivil(d));

/// 繰り返し設定の表示文言（毎月N日 / N日ごと）。一覧・履歴で共通。
String choreRepeatText(AppLocalizations l, ChoreTask task) =>
    switch (task.repeatUnit) {
      ChoreRepeatUnit.monthlyDay => l.recurringEveryMonthDay(task.dayOfMonth),
      ChoreRepeatUnit.everyDays => l.choreIntervalEvery(task.intervalDays),
    };

/// 残り日数の表示文言（N日超過 / 今日 / あとN日）。
String choreRemainingText(AppLocalizations l, int daysLeft) {
  if (daysLeft < 0) return l.choreOverdueDays(-daysLeft);
  if (daysLeft == 0) return l.choreDueToday;
  return l.choreDaysLeft(daysLeft);
}

/// 同日重複の確認ダイアログ。true=追加する。
Future<bool> confirmChoreDuplicate(BuildContext context, String taskName) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.choreDupConfirmTitle),
      content: Text(l.choreDupConfirmBody(taskName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.commonCancel),
        ),
        TextButton(
          key: const Key('chore-dup-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.choreDupConfirmAdd),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 「やった」記録の共通フロー: 記録→（同日重複なら確認→force）→
/// 次回期日入りスナックバー＋元に戻す。
Future<void> handleChoreDone(
  BuildContext context,
  WidgetRef ref,
  ChoreStatus status, {
  CivilDate? date,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(choreActionsProvider);
  final CivilDate doneDate = date ?? ref.read(choreTodayProvider);

  var result = await actions.recordDone(status.task.id, doneDate);
  if (result.outcome == ChoreRecordOutcome.needsConfirm) {
    if (!context.mounted) return;
    final ok = await confirmChoreDuplicate(context, status.task.name);
    if (!ok) return;
    result = await actions.recordDone(status.task.id, doneDate, force: true);
  }
  if (result.outcome != ChoreRecordOutcome.done || result.recordId == null) {
    return;
  }
  if (!context.mounted) return;
  // 次回期日 = 記録した月の翌月の毎月N日（過去日に記録した場合、より新しい
  // 記録が既にあれば実際の次回はそちら基準になるが、直後の resync で正しい
  // 値に再計算される。表示は分かりやすさ優先の近似）。
  final next = choreDueAfterDone(status.task, doneDate);
  final recordId = result.recordId!;
  messenger.showSnackBar(SnackBar(
    duration: const Duration(seconds: 5),
    content: Text(l.choreDoneSnackbar(
        context.mounted ? choreShortDate(context, next) : next.toIso())),
    action: SnackBarAction(
      label: l.calendarUndoAction,
      onPressed: () => actions.undo(recordId),
    ),
  ));
}
