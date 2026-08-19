import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/category_icon.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../calendar/presentation/day_transaction_list.dart'
    show txDisplayLabel;

/// ごみ箱（最近削除した取引）。取引の削除はここに30日保管され、復元できる
/// （FB 2026-08-16: SnackBarの「元に戻す」撤去の受け皿）。
/// 開いたときに保持期間切れの行をパージする。
class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  @override
  void initState() {
    super.initState();
    // 30日超の行はページを開いたときに消す（buildの外で1回だけ）。
    Future.microtask(() => ref.read(trashRepositoryProvider).purgeExpired());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries =
        ref.watch(trashEntriesProvider).valueOrNull ?? const <TrashEntry>[];
    final cats = ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final byId = {for (final c in cats) c.id: c};
    return Scaffold(
      appBar: AppBar(
        title: Text(l.trashTitle),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              key: const Key('trash-empty'),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l.trashEmptyAction,
              onPressed: () => _confirmEmpty(context),
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.trashEmpty),
                  const SizedBox(height: 4),
                  Text(l.settingsTrashSubtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView(
              children: [for (final e in entries) _row(context, e, byId)],
            ),
    );
  }

  Widget _row(
      BuildContext context, TrashEntry e, Map<int, CategoryEntity> byId) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final tx = e.tx;
    final cat = byId[tx.categoryId];
    final label = txDisplayLabel(tx);
    final txDate = DateFormat.yMd(tag)
        .format(DateTime(tx.date.year, tx.date.month, tx.date.day));
    final deleted = DateFormat.Md(tag).format(e.deletedAt.toLocal());
    return ListTile(
      key: ValueKey('trash-${e.id}'),
      leading: CategoryIcon(icon: cat?.icon, slug: cat?.slug),
      title: Text(cat?.name ?? '—'),
      subtitle: Text('$txDate${label == null ? '' : ' · $label'}\n'
          '${l.trashDeletedOn(deleted)}'),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mf.signed(tx.type, tx.amountYen),
            style: TextStyle(
              color: tx.type == TxnType.expense
                  ? context.kakeiboColors.expense
                  : context.kakeiboColors.income,
              fontWeight: FontWeight.w600,
              fontFeatures: kTabularFigures,
            ),
          ),
          IconButton(
            key: ValueKey('trash-restore-${e.id}'),
            icon: const Icon(Icons.restore),
            tooltip: l.trashRestore,
            onPressed: () => _restore(e.id),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(int trashId) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(trashRepositoryProvider).restore(trashId);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(l.trashRestoredSnack),
      showCloseIcon: true,
    ));
  }

  Future<void> _confirmEmpty(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.trashEmptyConfirmTitle),
        content: Text(l.trashEmptyConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: const Key('trash-empty-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(trashRepositoryProvider).emptyTrash();
  }
}
