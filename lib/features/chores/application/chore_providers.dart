import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/chore_schedule.dart';
import 'chore_actions.dart';

/// 家事の「今日」。clockProvider と違い状態として持ち、home_shell が
/// フォアグラウンド復帰時に refresh する（iOSはアプリが数日メモリに残るため、
/// 日付をまたいでも期日表示が古い「今日」のままにならないように）。
class ChoreToday extends Notifier<CivilDate> {
  @override
  CivilDate build() => ref.watch(clockProvider)();

  void refresh() => state = ref.read(clockProvider)();
}

final choreTodayProvider =
    NotifierProvider<ChoreToday, CivilDate>(ChoreToday.new);

final choreTasksProvider = StreamProvider<List<ChoreTask>>(
  (ref) => ref.watch(choreRepositoryProvider).watchTasks(),
);

final choreRecordsProvider = StreamProvider<List<ChoreRecord>>(
  (ref) => ref.watch(choreRepositoryProvider).watchRecords(),
);

/// アクティブ全タスクの期日状況（期日昇順）。
final choreStatusesProvider = Provider<List<ChoreStatus>>((ref) {
  final tasks = ref.watch(choreTasksProvider).valueOrNull ?? const [];
  final records = ref.watch(choreRecordsProvider).valueOrNull ?? const [];
  final today = ref.watch(choreTodayProvider);
  return buildChoreStatuses(tasks, records, today);
});

/// 月カレンダーの家事ドット情報。(year, month) ごとに導出。
final choreMonthMarksProvider = Provider.autoDispose
    .family<Map<CivilDate, ChoreDayMarks>, (int, int)>((ref, ym) {
  final tasks = ref.watch(choreTasksProvider).valueOrNull ?? const [];
  final records = ref.watch(choreRecordsProvider).valueOrNull ?? const [];
  final today = ref.watch(choreTodayProvider);
  return choreMonthMarks(ym.$1, ym.$2, tasks, records, today);
});

final choreActionsProvider = Provider<ChoreActions>((ref) => ChoreActions(
      ref.watch(choreRepositoryProvider),
      ref.watch(notificationServiceProvider),
      ref.watch(badgeServiceProvider),
      () => ref.read(choreTodayProvider),
      ref.watch(sharedPreferencesProvider),
      () => ref.read(appLocalizationsProvider),
    ));
