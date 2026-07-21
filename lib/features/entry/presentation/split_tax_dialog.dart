import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../application/entry_form_controller.dart';

/// 「個別」: 品目ごとに内税/8%/10%を設定するダイアログ。
/// 全行まとめてはパネルのトグルで済むので、ここは行単位の上書きだけを扱う。
/// 行内には税UIを置かない方針（確定モックv4）の受け皿。
class SplitTaxDialog extends ConsumerWidget {
  /// id→表示ラベル（絵文字＋名前）
  final Map<int, String> categoryLabels;

  const SplitTaxDialog({super.key, required this.categoryLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(entryFormControllerProvider);
    if (state == null || state.splits == null) return const SizedBox.shrink();
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final lines = state.splits!;

    return AlertDialog(
      title: Text(l.splitTaxDialogTitle, style: const TextStyle(fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: lines.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => _row(context, ref, ctrl, state, i, l),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('split-tax-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonDone),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, EntryFormController ctrl,
      EntryFormState state, int i, AppLocalizations l) {
    final mf = ref.watch(moneyFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final lines = state.splits!;
    final line = lines[i];
    final isRemainder = i == lines.length - 1;
    final label = isRemainder
        ? l.splitRemainderLabel
        : (categoryLabels[line.categoryId] ?? l.splitItemNumberLabel(i + 1));
    final entered = line.enteredYen;
    final net = state.splitLineAmount(i);
    final String amountText;
    if (isRemainder) {
      amountText = l.splitRemainderAutoAmount(mf.format(state.splitRemainder));
    } else if (entered == null) {
      amountText = '—';
    } else if (!line.taxIncluded && net != null) {
      amountText = l.splitAmountWithTax(mf.format(entered), mf.format(net));
    } else {
      amountText = mf.format(entered);
    }

    Widget seg(String text, bool selected, VoidCallback onTap, Key key) {
      return InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.22) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(amountText,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                seg(l.splitTaxIncludedLabel, line.taxIncluded,
                    () => ctrl.setSplitIncluded(i, true), Key('split-incl-$i')),
                seg('8%', !line.taxIncluded && line.rate == 8, () {
                  ctrl.setSplitIncluded(i, false);
                  ctrl.setSplitRate(i, 8);
                }, Key('split-rate8-$i')),
                seg('10%', !line.taxIncluded && line.rate == 10, () {
                  ctrl.setSplitIncluded(i, false);
                  ctrl.setSplitRate(i, 10);
                }, Key('split-rate10-$i')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
