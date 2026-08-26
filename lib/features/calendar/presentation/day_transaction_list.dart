import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/category_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/navigation.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../entry/application/entry_form_controller.dart';
import '../../entry/presentation/entry_screen.dart';
import '../../recurring/presentation/recurring_rules_page.dart';
import '../application/calendar_providers.dart';
import '../../payment/application/payment_providers.dart';
import '../../payment/presentation/payable_detail_page.dart';

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
    // その日のゴースト（まだ起票されていない固定費・収入）。
    final dayGhosts = ref
        .watch(monthGhostsProvider((day.year, day.month)))
        .where((g) => g.date == day)
        .toList();
    // その日のカード引き落とし（取引ではなく未払金からの導出）。
    final cardPayments = ref.watch(cardPaymentsOnDayProvider(day));
    // 空判定は取引・予定の2レーンが空のとき
    //（家事の行は「つきいち」タブへ移設・FB 2026-08-20・calendar_screen）。2026-08-20 モック: 日付は日付タブが示すので文言から
    // 外し、支出/収入の追加ボタンをカード内に置く（開くのはFABと同じ入力画面）。
    if (txs.isEmpty && dayGhosts.isEmpty && cardPayments.isEmpty) {
      // 2026-08-20 モック: 日付は日付タブが示すので文言から外し、支出/収入の
      // 追加ボタンを置く。6週ある月はカードが〜90pxしかないため、高さに応じて
      // 2段構え（広い月=アイコン付き中央寄せ / 狭い月=文言＋ボタンのみ）。
      // どちらもスクロール可能にして低い画面高でも溢れない。
      final buttons = Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          _addButton(context, ref,
              key: const Key('day-add-expense'),
              label: l.calendarAddExpense,
              color: context.kakeiboColors.expense,
              type: TxnType.expense),
          _addButton(context, ref,
              key: const Key('day-add-income'),
              label: l.calendarAddIncome,
              color: context.kakeiboColors.income,
              type: TxnType.income),
        ],
      );
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxHeight < 120) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.calendarDayEmptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                buttons,
              ],
            ),
          );
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_outlined,
                    size: 28, color: kMuted.withValues(alpha: 0.55)),
                const SizedBox(height: 6),
                Text(l.calendarDayEmptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(l.calendarDayEmptyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                buttons,
              ],
            ),
          ),
        );
      });
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
        for (final p in cardPayments) _cardPaymentTile(context, ref, p),
      ],
    );
  }

  /// 「未払」バッジから未払金の詳細（あとから分割）へ。
  /// 取引の編集（金額・カテゴリ）は行タップ側のまま変えない。
  Future<void> _openPayable(
      BuildContext context, WidgetRef ref, TransactionEntity tx) async {
    final payable =
        await ref.read(payableRepositoryProvider).forTransaction(tx.id!);
    if (payable == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            PayableDetailPage(transaction: tx, payable: payable),
      ),
    );
  }

  /// カードの引き落とし行。取引ではないので削除も編集もできない
  /// （中身を変えたいのは購入の側＝未払金なので、そちらから直す）。
  Widget _cardPaymentTile(
      BuildContext context, WidgetRef ref, CardPaymentLine line) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    return ListTile(
      key: ValueKey('card-payment-${line.card.id}'),
      leading: const Icon(Icons.credit_card),
      title: Text(l.cardPaymentRowLabel(line.card.name)),
      trailing: Text(
        mf.format(line.amountMinor),
        style: TextStyle(
          color: context.kakeiboColors.expense,
          fontWeight: FontWeight.w600,
          fontFeatures: kTabularFigures,
        ),
      ),
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
      leading: CategoryIcon(icon: cat?.icon, slug: cat?.slug),
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
    final cardPurchaseIds =
        ref.watch(cardPurchaseTxIdsOnMonthProvider((day.year, day.month)));
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
      onDismissed: (_) => _deleteToTrash(context, ref, tx),
      child: ListTile(
        dense: dense,
        visualDensity: dense ? VisualDensity.compact : null,
        leading: CategoryIcon(
          icon: cat?.icon,
          slug: cat?.slug,
          size: dense ? 24 : 28,
        ),
        title: Text(name),
        subtitle: !dense && txDisplayLabel(tx) != null
            ? Text(txDisplayLabel(tx)!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // カードで買った分は「未払」。現金が動くのは引き落とし日。
            // タップで「あとから分割」（回数・開始月の変更）へ。
            if (tx.id != null && cardPurchaseIds.contains(tx.id))
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  key: ValueKey('payable-badge-${tx.id}'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _openPayable(context, ref, tx),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.payableBadge,
                      style: TextStyle(
                          fontSize: 10, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
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
          ],
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

  /// 削除はごみ箱へ移す（復元は設定の「ごみ箱」から）。SnackBarは×ボタン付きで
  /// 10秒後に必ず消える。アクション付きSnackBarは accessibleNavigation
  /// （VoiceOver等）だと自動で消えないFlutter仕様があるため「元に戻す」は
  /// 置かない（FB 2026-08-16）。
  void _deleteToTrash(BuildContext context, WidgetRef ref, TransactionEntity tx) {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    ref.read(trashRepositoryProvider).moveToTrash(tx.id!);
    messenger.clearSnackBars(); // 連続削除で10秒×件数ぶん滞留させない
    messenger.showSnackBar(SnackBar(
      content: Text(l.trashMovedSnack),
      showCloseIcon: true,
      duration: const Duration(seconds: 10),
    ));
  }

  /// 空状態の「支出を追加 / 収入を追加」。FABと同じ経路で入力画面を開き、
  /// 種別だけ先に切り替える（入口の追加であり新機能ではない）。
  Widget _addButton(BuildContext context, WidgetRef ref,
      {required Key key,
      required String label,
      required Color color,
      required TxnType type}) {
    return OutlinedButton.icon(
      key: key,
      onPressed: () {
        final entry = ref.read(entryFormControllerProvider.notifier);
        entry.startCreate(day);
        entry.setType(type);
        ref.read(homeTabIndexProvider.notifier).set(kInputTabIndex);
      },
      icon: const Icon(Icons.add, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.65)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
