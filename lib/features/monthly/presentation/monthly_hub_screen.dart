import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/category_emoji.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../chores/application/chore_providers.dart';
import '../../chores/presentation/chore_history_page.dart';
import '../../chores/presentation/chore_task_form.dart';
import '../../chores/presentation/chore_ui_common.dart';
import '../../recurring/presentation/recurring_rules_page.dart';

/// 「毎月」タブ = 管理ハブ。
/// 今月のこれから（家事期日+固定費予定+見込み収支）→ 固定費・収入ルール →
/// つきいちタスク の3段構成（モックv3の決定構成）。
class MonthlyHubScreen extends ConsumerWidget {
  const MonthlyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final today = ref.watch(choreTodayProvider);
    final monthKey = (today.year, today.month);
    final ghosts = ref.watch(monthGhostsProvider(monthKey));
    final statuses = ref.watch(choreStatusesProvider);
    final forecast = ref.watch(monthForecastProvider(monthKey));
    final rules =
        ref.watch(recurringRulesProvider).valueOrNull ?? const <RecurringRuleEntity>[];
    final cats =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final catById = {for (final c in cats) c.id: c};
    final mf = ref.watch(moneyFormatterProvider);
    final scheme = Theme.of(context).colorScheme;

    // 今月のこれから: 当月内・今日以降の家事期日 + 固定費予定を日付順にマージ。
    final upcomingChores = statuses
        .where((s) =>
            s.due.year == today.year &&
            s.due.month == today.month &&
            !s.due.isBefore(today))
        .toList();
    final timeline = <(CivilDate, Widget)>[
      for (final s in upcomingChores)
        (
          s.due,
          ListTile(
            key: Key('hub-upcoming-chore-${s.task.id}'),
            dense: true,
            leading: Text(s.task.emoji, style: const TextStyle(fontSize: 20)),
            title: Text(
                '${choreShortDate(context, s.due)}　${s.task.name}'),
            trailing: Text(
              l.hubChoreTimelineLabel,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChoreHistoryPage(taskId: s.task.id)),
            ),
          ),
        ),
      for (final g in ghosts)
        (
          g.date,
          ListTile(
            key: Key('hub-upcoming-ghost-${g.rule.id}'),
            dense: true,
            leading: Text(
              categoryEmoji(
                catById[g.rule.categoryId]?.icon,
                catById[g.rule.categoryId]?.slug,
              ),
              style: const TextStyle(fontSize: 20),
            ),
            title: Text(
              '${choreShortDate(context, g.date)}　'
              '${_ghostLabel(l, g.rule, catById)}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GhostBadge(label: l.ghostBadgeLabel),
                const SizedBox(width: 8),
                Text(
                  mf.signed(g.rule.type, g.rule.amountMinor),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RecurringRuleEditPage(rule: g.rule)),
            ),
          ),
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    return Scaffold(
      appBar: AppBar(title: Text(l.homeNavMonthly)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _SectionHeader(title: l.hubUpcomingSection),
            if (timeline.isEmpty)
              _EmptyNote(text: l.hubUpcomingEmpty)
            else
              ...timeline.map((e) => e.$2),
            if (forecast != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Container(
                  key: const Key('hub-forecast-row'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          forecast.anchorIsMonthEnd
                              ? l.forecastLabelMonthEnd
                              : l.forecastLabelAtDate(
                                  choreShortDate(context, forecast.anchor)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        forecast.forecast >= 0
                            ? '+${mf.format(forecast.forecast)}'
                            : mf.format(forecast.forecast),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: forecast.forecast < 0
                              ? context.kakeiboColors.expense
                              : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 24),
            _SectionHeader(
              title: l.hubRulesSection,
              addKey: const Key('hub-rule-add'),
              onAdd: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RecurringRuleEditPage(rule: null)),
              ),
            ),
            if (rules.isEmpty)
              _EmptyNote(text: l.hubRulesEmpty)
            else
              for (final r in rules)
                ListTile(
                  key: Key('hub-rule-${r.id}'),
                  leading: Text(
                    categoryEmoji(
                      catById[r.categoryId]?.icon,
                      catById[r.categoryId]?.slug,
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(
                      catById[r.categoryId]?.name ?? l.calendarCategoryUnknown),
                  subtitle: Text([
                    l.recurringEveryMonthDay(r.dayOfMonth),
                    if (r.storeName != null && r.storeName!.isNotEmpty)
                      r.storeName!,
                  ].join(' ・ ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mf.signed(r.type, r.amountMinor),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: !r.isActive
                              ? scheme.outline
                              : r.type == TxnType.expense
                                  ? context.kakeiboColors.expense
                                  : context.kakeiboColors.income,
                        ),
                      ),
                      Switch(
                        key: Key('hub-rule-switch-${r.id}'),
                        value: r.isActive,
                        onChanged: (v) => _setRuleActive(ref, r, v),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RecurringRuleEditPage(rule: r)),
                  ),
                ),
            const Divider(height: 24),
            _SectionHeader(
              title: l.hubChoresSection,
              addKey: const Key('hub-chore-add'),
              onAdd: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChoreTaskFormPage(task: null)),
              ),
            ),
            if (statuses.isEmpty)
              _EmptyNote(text: l.hubChoresEmpty)
            else
              for (final s in statuses)
                ListTile(
                  key: Key('hub-chore-${s.task.id}'),
                  leading: Text(s.task.emoji,
                      style: const TextStyle(fontSize: 20)),
                  title: Text(s.task.name),
                  subtitle: Text(choreRepeatText(l, s.task)),
                  trailing: Text(
                    choreRemainingText(l, s.daysLeft),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: s.isOverdue
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChoreHistoryPage(taskId: s.task.id)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _ghostLabel(AppLocalizations l, RecurringRuleEntity rule,
      Map<int, CategoryEntity> catById) {
    final store = rule.storeName;
    if (store != null && store.isNotEmpty) return store;
    return catById[rule.categoryId]?.name ?? l.calendarCategoryUnknown;
  }

  Future<void> _setRuleActive(
      WidgetRef ref, RecurringRuleEntity r, bool active) async {
    final repo = ref.read(recurringRuleRepositoryProvider);
    final today = ref.read(clockProvider)();
    await repo.update(
      RecurringRuleEntity(
        id: r.id,
        type: r.type,
        amountMinor: r.amountMinor,
        categoryId: r.categoryId,
        dayOfMonth: r.dayOfMonth,
        storeName: r.storeName,
        memo: r.memo,
        isActive: active,
        startYm: r.startYm,
        endYm: r.endYm,
        lastGeneratedYm: r.lastGeneratedYm,
      ),
      today: today,
    );
    // 再開で当月分の期日が過ぎていれば即起票（編集ページの_saveと同じ契約）。
    await repo.applyDue(today);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.addKey, this.onAdd});

  final String title;
  final Key? addKey;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          // 「＋」だけでは入口と分かりにくいというFBで「＋ 追加」のラベル付きに、
          // さらに目立つよう緑ベタのボタンに（2026-08-09）。
          if (onAdd != null)
            FilledButton.icon(
              key: addKey,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context).commonAdd),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 「予定」バッジ（未起票の固定費・収入）。
class _GhostBadge extends StatelessWidget {
  const _GhostBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
