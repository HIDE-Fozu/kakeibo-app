import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cell_dropdown.dart';
import '../../../app/keyboard_done_bar.dart';
import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../core/category_emoji.dart';
import '../../../core/money.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/services/installment_calc.dart';
import '../../../domain/services/recurring_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/application/settings_controller.dart';

/// 分割払いの登録（FB 2026-08-16「まずは機能だけ」）。
/// 例:「33,000円を10回払い・実質年率17%」＋支払い開始 → N ヶ月分の支出を
/// 一括で取引登録する（計算は installment_calc.dart・端数は初回）。
/// カード名称を入れて保存すると名称＋年率が端末に記憶され、次回から
/// 「登録済みカード」で選ぶだけで年率入力を省略できる。
class InstallmentPage extends ConsumerStatefulWidget {
  const InstallmentPage({super.key});

  @override
  ConsumerState<InstallmentPage> createState() => _InstallmentPageState();
}

class _InstallmentPageState extends ConsumerState<InstallmentPage> {
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _cardName = TextEditingController();
  int _count = 10;
  int? _categoryId;
  late int _day = ref.read(clockProvider)().day;
  // カードの支払いは翌月からが普通なので既定は「来月から」。
  bool _startNextMonth = true;

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _cardName.dispose();
    super.dispose();
  }

  /// 率欄のパース。空=0%（無金利）。不正な文字列は null（保存不可）。
  double? get _ratePercent {
    final t = _rate.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    return (v == null || v < 0) ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final mf = ref.watch(moneyFormatterProvider);
    final cats = ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    final selectable = cats
        .where((c) =>
            c.type == CategoryType.expense && !c.isArchived && !c.isSystem)
        .toList();
    final cards = ref.watch(appSettingsProvider).installmentCards;

    final principal = parseAmountMinor(_amount.text, currency);
    final rate = _ratePercent;
    final plan = (principal != null && principal > 0 && rate != null)
        ? computeInstallment(
            principalMinor: principal,
            count: _count,
            annualRatePercent: rate)
        : null;
    final canSave = plan != null && _categoryId != null;

    return Scaffold(
      appBar: AppBar(title: Text(l.installmentTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    key: const Key('installment-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: currency.decimals > 0,
                    ),
                    decoration: InputDecoration(
                      labelText: l.installmentPrincipalLabel,
                      prefixText: '${currency.symbol} ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  CellDropdownField<int>(
                    key: const Key('installment-count'),
                    value: _count,
                    decoration: InputDecoration(
                      labelText: l.installmentCountLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (var n = 2; n <= 36; n++)
                        CellDropdownItem(n, l.installmentCountItem(n)),
                    ],
                    onChanged: (v) => setState(() => _count = v),
                  ),
                  const SizedBox(height: 16),
                  // 登録済みカード: 選ぶと名称と年率が入る（入力の省略）。
                  if (cards.isNotEmpty) ...[
                    CellDropdownField<String>(
                      key: const Key('installment-card-pick'),
                      value: cards.any((c) => c.name == _cardName.text)
                          ? _cardName.text
                          : null,
                      decoration: InputDecoration(
                        labelText: l.installmentCardPickLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in cards)
                          CellDropdownItem(c.name,
                              '${c.name}（${_fmtRate(c.annualRatePercent)}%）'),
                      ],
                      onChanged: (name) => setState(() {
                        final c = cards.firstWhere((c) => c.name == name);
                        _cardName.text = c.name;
                        _rate.text = _fmtRate(c.annualRatePercent);
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    key: const Key('installment-rate'),
                    controller: _rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.installmentRateLabel,
                      suffixText: '%',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('installment-card-name'),
                    controller: _cardName,
                    decoration: InputDecoration(
                      labelText: l.installmentCardNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CellDropdownField<int>(
                    key: const Key('installment-category'),
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
                  CellDropdownField<int>(
                    key: const Key('installment-day'),
                    value: _day,
                    decoration: InputDecoration(
                      labelText: l.installmentDayLabel,
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
                  const SizedBox(height: 16),
                  CellDropdownField<bool>(
                    key: const Key('installment-start'),
                    value: _startNextMonth,
                    decoration: InputDecoration(
                      labelText: l.recurringStartMonthLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      CellDropdownItem(false, l.recurringStartThisMonth),
                      CellDropdownItem(true, l.recurringStartNextMonth),
                    ],
                    onChanged: (v) => setState(() => _startNextMonth = v),
                  ),
                  // 支払い計画のプレビュー（月々・初回・手数料・総額）。
                  if (plan != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('installment-preview'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Column(
                        children: [
                          _previewRow(
                              l.installmentMonthlyLabel,
                              '${mf.format(plan.monthlyMinor)} × '
                              '${l.installmentCountItem(plan.count)}'),
                          if (plan.firstMinor != plan.monthlyMinor)
                            _previewRow(l.installmentFirstLabel,
                                mf.format(plan.firstMinor)),
                          _previewRow(
                              l.installmentFeeLabel, mf.format(plan.feeMinor)),
                          _previewRow(l.installmentTotalLabel,
                              mf.format(plan.totalMinor),
                              emphasized: true),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('installment-save'),
                    onPressed: canSave ? () => _save(plan) : null,
                    child: Text(l.commonSave),
                  ),
                ],
              ),
            ),
            const KeyboardDoneBar(),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool emphasized = false}) {
    final style = TextStyle(
      fontSize: emphasized ? 15 : 13,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }

  /// 17.0 → "17"、17.5 → "17.5"（表示・カード保存の往復用）。
  static String _fmtRate(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  Future<void> _save(InstallmentPlan plan) async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(transactionRepositoryProvider);
    final today = ref.read(clockProvider)();
    final cardName = _cardName.text.trim();
    var ym = _startNextMonth ? nextYm(ymOf(today)) : ymOf(today);
    for (var i = 0; i < plan.count; i++) {
      await repo.add(TransactionEntity(
        type: TxnType.expense,
        amountYen: plan.payments[i],
        date: dueDateIn(ym, _day),
        categoryId: _categoryId!,
        storeName: cardName.isEmpty ? null : cardName,
        memo: l.installmentTxnMemo(i + 1, plan.count),
        source: TxnSource.manual,
      ));
      ym = nextYm(ym);
    }
    if (cardName.isNotEmpty) {
      await ref
          .read(appSettingsProvider.notifier)
          .saveInstallmentCard(cardName, plan.annualRatePercent);
    }
    if (mounted) Navigator.pop(context);
  }
}
