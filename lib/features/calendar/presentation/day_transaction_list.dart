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
    final scheme = Theme.of(context).colorScheme;
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
            TextButton.icon(
              key: const Key('add-on-day'),
              icon: const Icon(Icons.add),
              label: const Text('この日に追加'),
              onPressed: () => _openCreate(context, ref),
            ),
            if (monthEmpty)
              Text('右下の＋から最初の記録を追加できます',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (context, i) {
        final tx = txs[i];
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
            leading: Text(categoryEmoji(cat?.icon, cat?.name),
                style: const TextStyle(fontSize: 20)),
            title: Text(name),
            subtitle:
                (tx.memo != null && tx.memo!.isNotEmpty) ? Text(tx.memo!) : null,
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
                    fullscreenDialog: true,
                    builder: (_) => const EntryScreen()),
              );
            },
          ),
        );
      },
    );
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    ref.read(entryFormControllerProvider.notifier).startCreate(day);
    Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => const EntryScreen()),
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
