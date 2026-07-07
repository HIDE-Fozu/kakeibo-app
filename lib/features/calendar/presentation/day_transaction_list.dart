import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_emoji.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../entry/application/entry_form_controller.dart';
import '../../entry/presentation/entry_screen.dart';
import '../application/calendar_providers.dart';

class DayTransactionList extends ConsumerWidget {
  final CivilDate day;
  const DayTransactionList({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(dayTransactionsProvider(day)).valueOrNull ?? const [];
    final cats =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <CategoryEntity>[];
    final byId = {for (final c in cats) c.id: c};
    // 月全体が空＝初回/空カレンダー状態。FABへの誘導CTAを足す（spec §5.5）
    final monthEmpty = (ref
                .watch(monthTransactionsProvider((day.year, day.month)))
                .valueOrNull ??
            const [])
        .isEmpty;

    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${day.month}月${day.day}日の記録はありません'),
            const SizedBox(height: 4),
            Text(
              monthEmpty
                  ? '右下の「金額を入力する」から最初の記録を追加できます'
                  : '右下の「金額を入力する」から追加できます',
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

    return ListView.builder(
      itemCount: units.length,
      itemBuilder: (context, i) {
        final unit = units[i];
        if (unit is TransactionEntity) return _txTile(context, ref, byId, unit);
        final group = grouped[unit as String]!;
        if (group.length == 1) return _txTile(context, ref, byId, group.single);
        return _groupCard(context, ref, byId, group);
      },
    );
  }

  /// C1: レシート1枚=1カード。ヘッダに店名メモと合計、中に内訳行。
  /// ヘッダタップ→詳細入力で開き直し（置換保存）。行は従来どおり個別編集/削除。
  Widget _groupCard(BuildContext context, WidgetRef ref,
      Map<int, CategoryEntity> byId, List<TransactionEntity> group) {
    final scheme = Theme.of(context).colorScheme;
    final sum = group.fold(0, (a, t) => a + t.amountYen);
    final memo = group.first.memo;
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
                      (memo == null || memo.isEmpty) ? 'レシート' : memo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    signedYen(group.first.type, sum),
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
    final scheme = Theme.of(context).colorScheme;
    final cat = byId[tx.categoryId];
    final name = cat == null
        ? '不明'
        : cat.isArchived
            ? '${cat.name}（アーカイブ）'
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
        leading: Text(categoryEmoji(cat?.icon, cat?.name),
            style: TextStyle(fontSize: dense ? 17 : 20)),
        title: Text(name),
        subtitle: !dense && (tx.memo != null && tx.memo!.isNotEmpty)
            ? Text(tx.memo!)
            : null,
        trailing: Text(
          signedYen(tx.type, tx.amountYen),
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
    final repo = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    repo.delete(tx.id!);
    messenger.showSnackBar(SnackBar(
      content: const Text('削除しました'),
      action: SnackBarAction(label: '元に戻す', onPressed: () => repo.add(tx)),
    ));
  }
}
