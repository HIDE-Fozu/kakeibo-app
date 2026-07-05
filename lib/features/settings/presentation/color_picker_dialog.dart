import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// パッケージ非依存のフルカラーピッカー（RGBスライダ＋プレビュー）。
/// 任意の色を自由に選べる。決定でその色を返し、キャンセルで null を返す。
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initial,
  required String title,
  required Color defaultColor,
}) =>
    showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(
        initial: initial,
        title: title,
        defaultColor: defaultColor,
      ),
    );

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  final String title;
  final Color defaultColor;
  const _ColorPickerDialog({
    required this.initial,
    required this.title,
    required this.defaultColor,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _r = (widget.initial.r * 255).roundToDouble();
  late double _g = (widget.initial.g * 255).roundToDouble();
  late double _b = (widget.initial.b * 255).roundToDouble();

  Color get _color => Color.fromARGB(255, _r.round(), _g.round(), _b.round());

  String get _hex =>
      '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('color-preview'),
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kLine),
            ),
            child: Text(
              _hex,
              style: TextStyle(
                color: _color.computeLuminance() > 0.5 ? kInk : Colors.white,
                fontFeatures: kTabularFigures,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _channel('R', _r, const Color(0xFFD05C55), (v) => setState(() => _r = v)),
          _channel('G', _g, const Color(0xFF4E9A6B), (v) => setState(() => _g = v)),
          _channel('B', _b, const Color(0xFF4F80B0), (v) => setState(() => _b = v)),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('color-reset'),
          onPressed: () => setState(() {
            _r = (widget.defaultColor.r * 255).roundToDouble();
            _g = (widget.defaultColor.g * 255).roundToDouble();
            _b = (widget.defaultColor.b * 255).roundToDouble();
          }),
          child: const Text('既定に戻す'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('color-apply'),
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('決定'),
        ),
      ],
    );
  }

  Widget _channel(
    String label,
    double value,
    Color tint,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: tint,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontFeatures: kTabularFigures),
          ),
        ),
      ],
    );
  }
}
