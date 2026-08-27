import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';

/// 予算額の入力。設定画面と、カレンダー上部サマリの歯車の両方から開く
/// （2026-08-27要望「予算の設定もこの設定ボタンから開けるように」）ので、
/// 片方に埋めずここに出してある。
///
/// 入力は主単位（円・ドル）で、保存は最小単位。
Future<void> editMonthlyBudget(
  BuildContext context,
  WidgetRef ref,
  SettingsState settings,
  Currency currency,
) async {
  final per = currency.minorPerUnit;
  final entered = await showDialog<String>(
    context: context,
    builder: (_) => BudgetAmountDialog(
      initialMajor: settings.monthlyBudgetMinor == 0
          ? ''
          : (settings.monthlyBudgetMinor ~/ per).toString(),
      currency: currency,
    ),
  );
  if (entered == null) return;
  final major = int.tryParse(entered) ?? 0;
  await ref.read(appSettingsProvider.notifier).setMonthlyBudget(major * per);
}

/// 予算額の入力ダイアログ。controller はダイアログ自身が持つ
///（呼び出し側で dispose すると閉じるアニメーション中に使われて落ちる）。
class BudgetAmountDialog extends StatefulWidget {
  final String initialMajor;
  final Currency currency;
  const BudgetAmountDialog({
    super.key,
    required this.initialMajor,
    required this.currency,
  });

  @override
  State<BudgetAmountDialog> createState() => _BudgetAmountDialogState();
}

class _BudgetAmountDialogState extends State<BudgetAmountDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialMajor);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.settingsBudgetAmountTitle),
      content: TextField(
        key: const Key('budget-amount-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(prefixText: '${widget.currency.symbol} '),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        FilledButton(
          key: const Key('budget-amount-save'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
