import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/category_icon.dart';
import '../../../app/cell_dropdown.dart';
import '../../../app/keyboard_done_bar.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/category_emoji.dart';
import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/recurring_schedule.dart';
import '../../../l10n/app_localizations.dart';

/// 設定 → 毎月の固定費・収入。ルールの一覧（タップで編集・＋で追加）。
class RecurringRulesPage extends ConsumerWidget {
  const RecurringRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rules =
        ref.watch(recurringRulesProvider).valueOrNull ??
        const <RecurringRuleEntity>[];
    final cats =
        ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final catById = {for (final c in cats) c.id: c};
    final mf = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.recurringPageTitle),
        actions: [
          IconButton(
            key: const Key('recurring-add'),
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RecurringRuleEditPage(rule: null),
              ),
            ),
          ),
        ],
      ),
      body: rules.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l.recurringEmptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView(
              children: [
                for (final r in rules)
                  ListTile(
                    key: Key('recurring-rule-${r.id}'),
                    leading: CategoryIcon(
                      icon: catById[r.categoryId]?.icon,
                      slug: catById[r.categoryId]?.slug,
                    ),
                    title: Text(
                      catById[r.categoryId]?.name ?? l.calendarCategoryUnknown,
                    ),
                    subtitle: Text(
                      [
                        l.recurringEveryMonthDay(r.dayOfMonth),
                        if (r.storeName != null && r.storeName!.isNotEmpty)
                          r.storeName!,
                        if (!r.isActive) l.recurringPausedLabel,
                      ].join(' ・ '),
                    ),
                    trailing: Text(
                      mf.signed(r.type, r.amountMinor),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: !r.isActive
                            ? Theme.of(context).colorScheme.outline
                            : r.type == TxnType.expense
                            ? context.kakeiboColors.expense
                            : context.kakeiboColors.income,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecurringRuleEditPage(rule: r),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// 定期ルールの追加（rule=null）／編集ページ。
class RecurringRuleEditPage extends ConsumerStatefulWidget {
  final RecurringRuleEntity? rule;
  const RecurringRuleEditPage({super.key, required this.rule});

  @override
  ConsumerState<RecurringRuleEditPage> createState() =>
      _RecurringRuleEditPageState();
}

class _RecurringRuleEditPageState extends ConsumerState<RecurringRuleEditPage> {
  late TxnType _type = widget.rule?.type ?? TxnType.expense;
  late final TextEditingController _amount = TextEditingController(
    text: widget.rule == null
        ? ''
        : amountMinorToText(
            widget.rule!.amountMinor,
            ref.read(currencyProvider),
          ),
  );
  late int? _categoryId = widget.rule?.categoryId;
  late int _day = widget.rule?.dayOfMonth ?? 1;
  bool _startNextMonth = false;
  late final TextEditingController _store = TextEditingController(
    text: widget.rule?.storeName ?? '',
  );
  late final TextEditingController _memo = TextEditingController(
    text: widget.rule?.memo ?? '',
  );
  late bool _isActive = widget.rule?.isActive ?? true;

  @override
  void dispose() {
    _amount.dispose();
    _store.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final isNew = widget.rule == null;
    final cats =
        ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    // 選択肢: 現在のtypeの非アーカイブ・非システム。watchAllは階層整列済み
    // （親→その内訳の順）なので、そのまま並べて内訳だけ字下げする。
    final selectable = cats
        .where(
          (c) =>
              c.type == categoryTypeOf(_type) && !c.isArchived && !c.isSystem,
        )
        .toList();
    // 編集中ルールのカテゴリがアーカイブ済み等で選択肢に無い場合も、
    // Dropdownのvalue不整合assertを踏まないよう現在値を選択肢に含める。
    final current = cats.where((c) => c.id == _categoryId).firstOrNull;
    if (current != null && !selectable.any((c) => c.id == current.id)) {
      selectable.insert(0, current);
    }
    final amountMinor = parseAmountMinor(_amount.text, currency);
    final canSave =
        amountMinor != null && amountMinor > 0 && _categoryId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l.recurringAddTitle : l.recurringEditTitle),
        actions: [
          if (!isNew)
            IconButton(
              key: const Key('recurring-delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<TxnType>(
                    key: const Key('recurring-type'),
                    segments: [
                      ButtonSegment(
                        value: TxnType.expense,
                        label: Text(l.entryTypeExpense),
                      ),
                      ButtonSegment(
                        value: TxnType.income,
                        label: Text(l.entryTypeIncome),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _categoryId = null; // typeが変わったらカテゴリは選び直し
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('recurring-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: currency.decimals > 0,
                    ),
                    decoration: InputDecoration(
                      labelText: l.recurringAmountLabel,
                      prefixText: '${currency.symbol} ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  CellDropdownField<int>(
                    // typeを切り替えたらウィジェットごと作り直す（選択リセット）。
                    key: Key('recurring-category-${_type.name}'),
                    value: _categoryId,
                    decoration: InputDecoration(
                      labelText: l.entryCategoryHeading,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in selectable)
                        CellDropdownItem(
                          c.id,
                          '${c.parentId != null ? '└ ' : ''}${categoryEmoji(c.icon, c.slug)} ${c.name}',
                        ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 16),
                  // 項目は「1日」のみ（「毎月」は一覧側の表記が担う・2026-08-09 FB）。
                  CellDropdownField<int>(
                    key: const Key('recurring-day'),
                    value: _day,
                    decoration: InputDecoration(
                      labelText: l.recurringDayLabel,
                      helperText: l.recurringDayClampNote,
                      helperMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (var d = 1; d <= 31; d++)
                        CellDropdownItem(d, l.dayOfMonthItem(d)),
                    ],
                    onChanged: (v) => setState(() => _day = v),
                  ),
                  if (isNew) ...[
                    const SizedBox(height: 16),
                    CellDropdownField<bool>(
                      key: const Key('recurring-start'),
                      value: _startNextMonth,
                      decoration: InputDecoration(
                        labelText: l.recurringStartMonthLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        CellDropdownItem(false, l.recurringStartThisMonth),
                        CellDropdownItem(true, l.recurringStartNextMonth),
                      ],
                      onChanged: (v) =>
                          setState(() => _startNextMonth = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('recurring-store'),
                    controller: _store,
                    decoration: InputDecoration(
                      // 収入は店ではなく勤め先なので「会社名」（2026-08-09 FB）。
                      labelText: _type == TxnType.income
                          ? l.entryCompanyNameLabel
                          : l.entryStoreNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('recurring-memo'),
                    controller: _memo,
                    decoration: InputDecoration(
                      labelText: l.entryDetailMemoLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (!isNew)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SwitchListTile(
                        key: const Key('recurring-active'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.recurringActiveTitle),
                        subtitle: Text(l.recurringActiveSubtitle),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('recurring-save'),
                    onPressed: canSave ? () => _save(amountMinor) : null,
                    child: Text(l.commonSave),
                  ),
                ],
              ),
            ),
            // キーボード直上の「完了」バー（金額のテンキーには確定キーが無い）。
            const KeyboardDoneBar(),
          ],
        ),
      ),
    );
  }

  Future<void> _save(int amountMinor) async {
    final repo = ref.read(recurringRuleRepositoryProvider);
    final today = ref.read(clockProvider)();
    final old = widget.rule;
    final storeName = _store.text.trim();
    final memo = _memo.text.trim();
    final rule = RecurringRuleEntity(
      id: old?.id,
      type: _type,
      amountMinor: amountMinor,
      categoryId: _categoryId!,
      dayOfMonth: _day,
      storeName: storeName.isEmpty ? null : storeName,
      memo: memo.isEmpty ? null : memo,
      isActive: _isActive,
      startYm:
          old?.startYm ?? (_startNextMonth ? nextYm(ymOf(today)) : ymOf(today)),
      endYm: old?.endYm,
      lastGeneratedYm: old?.lastGeneratedYm,
    );
    if (old == null) {
      await repo.add(rule);
    } else {
      await repo.update(rule, today: today);
    }
    // 期日到来分（今月から開始で期日が過ぎているルール等）を即起票して、
    // カレンダーにすぐ反映されるようにする。
    await repo.applyDue(today);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.recurringDeleteConfirmTitle),
        content: Text(l.recurringDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: const Key('recurring-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(recurringRuleRepositoryProvider).delete(widget.rule!.id!);
    if (mounted) Navigator.pop(context);
  }
}
