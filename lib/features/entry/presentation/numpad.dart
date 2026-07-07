import 'package:flutter/material.dart';

class Numpad extends StatelessWidget {
  final void Function(int digit) onDigit;
  final VoidCallback onDoubleZero;
  final VoidCallback onBackspace;

  /// 非null時は右端に演算子列（＋−×÷）を出す（詳細入力=分割モード）。
  /// 渡される op は '+', '-', '×', '÷'。
  final void Function(String op)? onOperator;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onDoubleZero,
    required this.onBackspace,
    this.onOperator,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child, VoidCallback onTap, {Key? key}) => Expanded(
          child: InkWell(
            key: key,
            onTap: onTap,
            child: SizedBox(height: 56, child: Center(child: child)),
          ),
        );
    Widget digit(int d, {Key? key}) => cell(
        Text('$d', style: const TextStyle(fontSize: 24)), () => onDigit(d),
        key: key);
    // 表示は数学記号（−）、コントローラへはASCIIハイフン（式の内部表現）
    Widget op(String opChar, String label) => cell(
          Text(label,
              style: TextStyle(
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.primary)),
          () => onOperator!(opChar),
          key: Key('np-op-$opChar'),
        );

    final ops = onOperator != null;
    return Column(children: [
      Row(children: [digit(1), digit(2), digit(3), if (ops) op('+', '＋')]),
      Row(children: [digit(4), digit(5), digit(6), if (ops) op('-', '−')]),
      Row(children: [digit(7), digit(8), digit(9), if (ops) op('×', '×')]),
      Row(children: [
        cell(const Text('00', style: TextStyle(fontSize: 24)), onDoubleZero,
            key: const Key('np-00')),
        digit(0, key: const Key('np-0')),
        cell(const Icon(Icons.backspace_outlined), onBackspace,
            key: const Key('np-back')),
        if (ops) op('÷', '÷'),
      ]),
    ]);
  }
}
