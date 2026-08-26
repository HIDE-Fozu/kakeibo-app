import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../l10n/app_localizations.dart';

/// 支払い区分（カード）の一覧と編集。
/// 名称・引き落とし日・休業日の寄せ方・あとから分割の既定年率を持つ。
/// 未払金から使われているカードは削除できず、アーカイブで隠す。
class PaymentCardsPage extends ConsumerWidget {
  const PaymentCardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cards =
        ref.watch(paymentCardsProvider).valueOrNull ??
        const <PaymentCardEntity>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.paymentCardsTitle),
        actions: [
          IconButton(
            key: const Key('payment-card-add'),
            icon: const Icon(Icons.add),
            onPressed: () => _edit(context, ref, null),
          ),
        ],
      ),
      body: cards.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l.paymentCardsEmptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView(
              children: [
                for (final c in cards)
                  ListTile(
                    key: Key('payment-card-${c.id}'),
                    leading: const Icon(Icons.credit_card),
                    title: Text(c.name),
                    subtitle: Text([
                      l.paymentCardBillingDaySummary(c.payDay),
                      _ruleLabel(l, c.businessDayRule),
                    ].join(' / ')),
                    onTap: () => _edit(context, ref, c),
                  ),
              ],
            ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, PaymentCardEntity? card) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PaymentCardEditPage(card: card)),
    );
  }
}

String _ruleLabel(AppLocalizations l, BusinessDayRule r) => switch (r) {
      BusinessDayRule.next => l.businessDayRuleNext,
      BusinessDayRule.previous => l.businessDayRulePrevious,
      BusinessDayRule.none => l.businessDayRuleNone,
    };

/// カードの追加・編集。
class PaymentCardEditPage extends ConsumerStatefulWidget {
  /// null = 新規。
  final PaymentCardEntity? card;
  const PaymentCardEditPage({super.key, this.card});

  @override
  ConsumerState<PaymentCardEditPage> createState() =>
      _PaymentCardEditPageState();
}

class _PaymentCardEditPageState extends ConsumerState<PaymentCardEditPage> {
  late final _name = TextEditingController(text: widget.card?.name ?? '');
  late final _rate = TextEditingController(
      text: widget.card == null || widget.card!.annualRatePercent == 0
          ? ''
          : _fmtRate(widget.card!.annualRatePercent));
  // カードの引き落としは27日が多い（楽天・エポス等）。
  late int _payDay = widget.card?.payDay ?? 27;
  late BusinessDayRule _rule =
      widget.card?.businessDayRule ?? BusinessDayRule.next;

  static String _fmtRate(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  /// 空=0%（無金利）。不正な文字列は null（保存不可）。
  double? get _ratePercent {
    final t = _rate.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    return (v == null || v < 0) ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isNew = widget.card == null;
    final canSave = _name.text.trim().isNotEmpty && _ratePercent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l.paymentCardAddTitle : l.paymentCardEditTitle),
        actions: [
          if (!isNew)
            IconButton(
              key: const Key('payment-card-delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const Key('payment-card-name'),
              controller: _name,
              decoration: InputDecoration(
                labelText: l.paymentCardNameLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l.paymentCardPayDayLabel,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  key: const Key('payment-card-payday'),
                  isExpanded: true,
                  value: _payDay,
                  items: [
                    for (var d = 1; d <= 31; d++)
                      DropdownMenuItem(
                          value: d, child: Text(l.paymentCardBillingDaySummary(d))),
                  ],
                  onChanged: (v) => setState(() => _payDay = v ?? _payDay),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l.paymentCardBusinessDayLabel,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BusinessDayRule>(
                  key: const Key('payment-card-rule'),
                  isExpanded: true,
                  value: _rule,
                  items: [
                    for (final r in BusinessDayRule.values)
                      DropdownMenuItem(value: r, child: Text(_ruleLabel(l, r))),
                  ],
                  onChanged: (v) => setState(() => _rule = v ?? _rule),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('payment-card-rate'),
              controller: _rate,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l.paymentCardRateLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('payment-card-save'),
              onPressed: canSave ? _save : null,
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final repo = ref.read(paymentCardRepositoryProvider);
    final entity = PaymentCardEntity(
      id: widget.card?.id,
      name: _name.text.trim(),
      payDay: _payDay,
      businessDayRule: _rule,
      annualRatePercent: _ratePercent ?? 0,
      sortOrder: widget.card?.sortOrder ?? 0,
      isArchived: widget.card?.isArchived ?? false,
    );
    if (widget.card == null) {
      await repo.add(entity);
    } else {
      await repo.update(entity);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.card!.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel)),
          FilledButton(
            key: const Key('payment-card-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(paymentCardRepositoryProvider).delete(widget.card!.id!);
      if (mounted) Navigator.pop(context);
    } on StateError {
      // 未払金から使われている。消さずにその旨だけ伝える（アーカイブは別操作）。
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.paymentCardInUseDeleteError)),
      );
    }
  }
}
