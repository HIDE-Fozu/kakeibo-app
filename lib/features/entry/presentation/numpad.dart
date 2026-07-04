import 'package:flutter/material.dart';

/// テンキー。高さは親（SizedBox）が決める。各行は残余を等分して埋める。
class Numpad extends StatelessWidget {
  final void Function(int digit) onDigit;
  final VoidCallback onDoubleZero;
  final VoidCallback onBackspace;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onDoubleZero,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child, VoidCallback onTap, {Key? key}) => Expanded(
          child: InkWell(
            key: key,
            onTap: onTap,
            child: Center(child: child),
          ),
        );
    Widget digit(int d, {Key? key}) => cell(
        Text('$d', style: const TextStyle(fontSize: 24)), () => onDigit(d),
        key: key);
    Widget row(List<Widget> cells) => Expanded(child: Row(children: cells));

    return Column(children: [
      row([digit(1), digit(2), digit(3)]),
      row([digit(4), digit(5), digit(6)]),
      row([digit(7), digit(8), digit(9)]),
      row([
        cell(const Text('00', style: TextStyle(fontSize: 24)), onDoubleZero,
            key: const Key('np-00')),
        digit(0, key: const Key('np-0')),
        cell(const Icon(Icons.backspace_outlined), onBackspace,
            key: const Key('np-back')),
      ]),
    ]);
  }
}
