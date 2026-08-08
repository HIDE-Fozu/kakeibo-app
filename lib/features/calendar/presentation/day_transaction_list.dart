import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_emoji.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../chores/presentation/chore_day_section.dart';
import '../../entry/application/entry_form_controller.dart';
import '../../entry/presentation/entry_screen.dart';
import '../../recurring/presentation/recurring_rules_page.dart';
import '../application/calendar_providers.dart';

/// 一覧の表示ラベル: 「店舗名 - 詳細メモ」。片方だけならその片方。両方空はnull。
String? txDisplayLabel(TransactionEntity tx) {
  final store = tx.storeName?.trim() ?? '';
  final memo = tx.memo?.trim() ?? '';
  if (store.isNotEmpty && memo.isNotEmpty) return '$store - $memo';
  if (store.isNotEmpty) return store;
  if (memo.isNotEmpty) return memo;
  return null;
}

class DayTransactionList extends ConsumerWidget {
  final CivilDate day;
  const DayTransactionList({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final txs = ref.watch(dayTransactionsProvider(day)).valueOrNull ?? const [];
    final cats =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final byId = {for (final c in cats) c.id: c};
    // その日のゴースト（まだ起票されていない固定費・収入）と家事の行。
    final dayGhosts = ref
        .watch(monthGhostsProvider((day.year, day.month)))
        .where((g) => g.date == day)
        .toList();
    final choreRows = buildChoreDayRows(context, ref, day);
    // 月全体が空＝初回/空カレンダー状態。FABへの誘導CTAを足す（spec §5.5）
    final monthEmpty = (ref
                .watch(monthTransactionsProvider((day.year, day.month)))
                .valueOrNull ??
            const [])
        .isEmpty;

    // 空判定は取引・予定・家事の3レーンすべて空のとき（家事行が空状態の裏に
    // 隠れる回帰を防ぐ）。
    if (txs.isEmpty && dayGhosts.isEmpty && choreRows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.calendarDayEmptyTitle(day.month, day.day)),
            const SizedBox(height: 4),
            Text(
              monthEmpty
                  ? l.calendarDayEmptyHintFirst
                  : l.calendarDayEmptyHint,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 「1枚のレシート」（詳細入力）を1単位に束ねる（C1: グループカード）。
    // 2件以上残っているグループだけカード化。1件だけなら通常行に落とす。
    final grouped = <String, List<TransactionEntity>>{};
    final units = <Object>[]; // TransactionEntity | String(groupId)
    for (final tx in txs) {
      final gid = tx.splitGroupId;
      if (gid == null) {
        units.add(tx);
        continue;
      }
      final list = grouped.putIfAbsent(gid, () {
        units.add(gid);
        return [];
      });
      list.add(tx);
    }

    return ListView(
      children: [
        for (final unit in units)
          if (unit is TransactionEntity)
            _txTile(context, ref, byId, unit)
          else if (grouped[unit as String]!.length == 1)
            _txTile(context, ref, byId, grouped[unit]!.single)
          else
            _groupCard(context, ref, byId, grouped[unit]!),
        for (final g in dayGhosts) _ghostTile(context, ref, byId, g),
        ...choreRows,
      ],
    );
  }

  /// まだ起票されていない固定費・収入の「予定」行。グレー+バッジで実績と区別。
  /// タップでルール編集へ（起票前に金額や日を直したいケースの導線）。
  Widget _ghostTile(
      BuildContext context,
      WidgetRef ref,
      Map<int, CategoryEntity> byId,
      ({CivilDate date, RecurringRuleEntity rule}) g) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final cat = byId[g.rule.categoryId];
    final store = g.rule.storeName;
    return ListTile(
      key: ValueKey('ghost-${g.rule.id}'),
      leading: Text(categoryEmoji(cat?.icon, cat?.slug),
          style: const TextStyle(fontSize: 20)),
      title: Text(
        cat?.name ?? l.calendarCategoryUnknown,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      subtitle:
          store != null && store.isNotEmpty ? Text(store) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l.ghostBadgeLabel,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            mf.signed(g.rule.type, g.rule.amountMinor),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecurringRuleEditPage(rule: g.rule)),
      ),
    );
  }

  /// C1: レシート1枚=1カード。ヘッダに店名メモと合計、中に内訳行。
  /// ヘッダタップ→詳細入力で開き直し（置換保存）。行は従来どおり個別編集/削除。
  Widget _groupCard(BuildContext context, WidgetRef ref,
      Map<int, CategoryEntity> byId, List<TransactionEntity> group) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final sum = group.fold(0, (a, t) => a + t.amountYen);
    final label = txDisplayLabel(group.first);
    return Card(
      key: ValueKey('txg-${group.first.splitGroupId}'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      elevation: 0,
      child: Column(
        children: [
          InkWell(
            key: ValueKey('txg-head-${group.first.splitGroupId}'),
            onTap: () {
              ref
                  .read(entryFormControllerProvider.notifier)
                  .startEditSplitGroup(group);
              Navigator.push(
                context,
                MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const EntryScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  const Text('🧾', style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label ?? l.calendarReceiptFallbackLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    mf.signed(group.first.type, sum),
                    style: TextStyle(
                      color: group.first.type == TxnType.expense
                          ? context.kakeiboColors.expense
                          : context.kakeiboColors.income,
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          for (final tx in group)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _txTile(context, ref, byId, tx, dense: true),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _txTile(BuildContext context, WidgetRef ref,
      Map<int, CategoryEntity> byId, TransactionEntity tx,
      {bool dense = false}) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final cat = byId[tx.categoryId];
    final name = cat == null
        ? l.calendarCategoryUnknown
        : cat.isArchived
            ? l.calendarCategoryArchivedLabel(cat.name)
            : cat.name;
    return Dismissible(
      key: ValueKey('tx-${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: scheme.onError),
      ),
      onDismissed: (_) => _deleteWithUndo(context, ref, tx),
      child: ListTile(
        dense: dense,
        visualDensity: dense ? VisualDensity.compact : null,
        leading: Text(categoryEmoji(cat?.icon, cat?.slug),
            style: TextStyle(fontSize: dense ? 17 : 20)),
        title: Text(name),
        subtitle: !dense && txDisplayLabel(tx) != null
            ? Text(txDisplayLabel(tx)!)
            : null,
        trailing: Text(
          mf.signed(tx.type, tx.amountYen),
          style: TextStyle(
            color: tx.type == TxnType.expense
                ? context.kakeiboColors.expense
                : context.kakeiboColors.income,
            fontWeight: FontWeight.w600,
            fontFeatures: kTabularFigures,
          ),
        ),
        onTap: () {
          ref.read(entryFormControllerProvider.notifier).startEdit(tx);
          Navigator.push(
            context,
            MaterialPageRoute(
                fullscreenDialog: true, builder: (_) => const EntryScreen()),
          );
        },
      ),
    );
  }

  /// Undo は同内容の再add（id/createdAtは新規になる: v1の既知の限界）
  void _deleteWithUndo(
      BuildContext context, WidgetRef ref, TransactionEntity tx) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    repo.delete(tx.id!);
    messenger.showSnackBar(SnackBar(
      content: Text(l.calendarDeleteSnackbar),
      action: SnackBarAction(label: l.calendarUndoAction, onPressed: () => repo.add(tx)),
    ));
  }
}
