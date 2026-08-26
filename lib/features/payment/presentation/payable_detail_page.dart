import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cell_dropdown.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/installment_calc.dart';
import '../../../domain/services/payable_builder.dart';
import '../../../domain/services/payment_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../application/payment_providers.dart';

/// 未払金の詳細＝「あとから分割」。
///
/// 1万円の買い物という**ひとつのオブジェクト**に対して、回数と開始月を
/// 変えるだけ。10回にした後で3回に変えるのも同じ操作で、そのたびに
/// 支払い予定を作り直す（合計＝総額はリポジトリが必ず検証する）。
/// 「未払金をやめる」を選ぶと予定ごと消え、購入取引はその場に残る。
class PayableDetailPage extends ConsumerStatefulWidget {
  final TransactionEntity transaction;
  final PayableEntity payable;
  const PayableDetailPage({
    super.key,
    required this.transaction,
    required this.payable,
  });

  @override
  ConsumerState<PayableDetailPage> createState() => _PayableDetailPageState();
}

class _PayableDetailPageState extends ConsumerState<PayableDetailPage> {
  late int _count = widget.payable.installmentCount;
  late int _cardId = widget.payable.cardId;
  late int _startYm = widget.payable.schedule.first.ym;

  /// 元本（購入額）。手数料は回数と率から都度計算し直す。
  int get _principal => widget.transaction.amountYen;

  double _rateOf(List<PaymentCardEntity> cards) {
    if (_count <= 1) return 0; // 1回払いは手数料なし（日本のカード慣行）
    return cards
            .where((c) => c.id == _cardId)
            .firstOrNull
            ?.annualRatePercent ??
        widget.payable.annualRatePercent;
  }

  /// いま画面で選んでいる条件のプレビュー。保存するとこの内容で置き換わる。
  PayableEntity _preview(List<PaymentCardEntity> cards) => _count <= 1
      ? PayableEntity(
          id: widget.payable.id,
          transactionId: widget.payable.transactionId,
          cardId: _cardId,
          installmentCount: 1,
          annualRatePercent: 0,
          totalMinor: _principal,
          schedule: [
            PayableInstallment(ym: _startYm, amountMinor: _principal),
          ],
        )
      : buildInstallmentPayable(
          id: widget.payable.id,
          transactionId: widget.payable.transactionId,
          cardId: _cardId,
          principalMinor: _principal,
          count: _count,
          annualRatePercent: _rateOf(cards),
          startYm: _startYm,
        );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final cards =
        ref.watch(paymentCardsProvider).valueOrNull ??
        const <PaymentCardEntity>[];
    final preview = _preview(cards);
    final fee = preview.totalMinor - _principal;

    // 開始月の選択肢: 購入月の翌月を基準に前後（「9月分じゃなく10月分」）。
    final base = defaultPaymentYmOf(widget.transaction.date);
    final ymChoices = [
      for (var i = -1; i <= 11; i++) _shiftYm(base, i),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.payableDetailTitle),
        actions: [
          IconButton(
            key: const Key('payable-remove'),
            icon: const Icon(Icons.money_off),
            tooltip: l.payableMakeImmediate,
            onPressed: _confirmRemove,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(widget.transaction.storeName ?? ''),
              subtitle: Text(widget.transaction.date.toIso()),
              trailing: Text(
                mf.format(_principal),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(),
            // 部品は分割払い画面と同じ CellDropdownField に揃える
            // （回数の選択肢は70件近くあり、この部品向けに作られている）。
            CellDropdownField<int>(
              key: const Key('payable-card'),
              value: _cardId,
              decoration: InputDecoration(
                labelText: l.payableCardLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final c in cards) CellDropdownItem(c.id!, c.name),
              ],
              onChanged: (v) => setState(() => _cardId = v),
            ),
            const SizedBox(height: 16),
            CellDropdownField<int>(
              key: const Key('payable-count'),
              value: _count,
              decoration: InputDecoration(
                labelText: l.payableCountLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                CellDropdownItem(1, l.payableOnceOption),
                for (final n in kInstallmentCountChoices)
                  CellDropdownItem(n, l.payableTimesOption(n)),
              ],
              onChanged: (v) => setState(() => _count = v),
            ),
            const SizedBox(height: 16),
            CellDropdownField<int>(
              key: const Key('payable-start-ym'),
              value: ymChoices.contains(_startYm) ? _startYm : ymChoices.first,
              decoration: InputDecoration(
                labelText: l.payableStartYmLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final ym in ymChoices)
                  CellDropdownItem(ym, l.payableYmFormat(ym ~/ 100, ym % 100)),
              ],
              onChanged: (v) => setState(() => _startYm = v),
            ),
            const SizedBox(height: 20),
            _summaryRow(l.payableTotalLabel, mf.format(preview.totalMinor),
                bold: true),
            if (fee > 0) _summaryRow(l.payableFeeLabel, mf.format(fee)),
            const SizedBox(height: 12),
            Text(l.payableScheduleHeading,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final s in preview.schedule)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.payableYmFormat(s.ym ~/ 100, s.ym % 100),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(mf.format(s.amountMinor),
                        style: const TextStyle(
                            fontFeatures: kTabularFigures)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('payable-save'),
              onPressed: () => _save(preview),
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontFeatures: kTabularFigures,
              ),
            ),
          ],
        ),
      );

  Future<void> _save(PayableEntity preview) async {
    await ref.read(payableRepositoryProvider).replace(preview);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmRemove() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.payableMakeImmediate),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel)),
          FilledButton(
            key: const Key('payable-remove-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(payableRepositoryProvider).delete(widget.payable.id!);
    if (mounted) Navigator.pop(context);
  }
}

/// YYYYMM を n ヶ月ずらす（負なら過去）。
int _shiftYm(int ym, int n) {
  final total = (ym ~/ 100) * 12 + (ym % 100) - 1 + n;
  return (total ~/ 12) * 100 + (total % 12) + 1;
}
