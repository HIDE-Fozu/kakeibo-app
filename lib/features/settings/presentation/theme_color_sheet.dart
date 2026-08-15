import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';

/// プリセット（null = 既定ブルー。値はモックで確定した10色）。
const _presets = <Color?>[
  null,
  Color(0xFF2F8570), // グリーン
  Color(0xFF2A8FA5), // ティール
  Color(0xFF7A6BC0), // パープル
  Color(0xFFC86B8F), // ローズ
  Color(0xFFC97B3C), // オレンジ
  Color(0xFFB08A1E), // マスタード
  Color(0xFF5F6B76), // グレー
  Color(0xFFB35A4C), // テラコッタ
  Color(0xFF3D5170), // ネイビー
];

/// 設定の「色」。1色選ぶと背景・罫線・強調色まで自動導出する（モック準拠）。
/// タップ即 setThemeColor でアプリ全体がライブプレビューになり、
/// 「適用」以外で閉じたら元の色に戻す。
Future<void> showThemeColorSheet(BuildContext context, WidgetRef ref) async {
  final initial = ref.read(appSettingsProvider).themeColor;
  var applied = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ThemeColorSheet(onApplied: () => applied = true),
  );
  if (!applied) {
    await ref.read(appSettingsProvider.notifier).setThemeColor(initial);
  }
}

class _ThemeColorSheet extends ConsumerStatefulWidget {
  final VoidCallback onApplied;
  const _ThemeColorSheet({required this.onApplied});

  @override
  ConsumerState<_ThemeColorSheet> createState() => _ThemeColorSheetState();
}

class _ThemeColorSheetState extends ConsumerState<_ThemeColorSheet> {
  // カスタム操作の作業値（HSV）。プリセットタップで色相だけ追従させる。
  late HSVColor _hsv;
  bool _customActive = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(appSettingsProvider).themeColor ?? kPrimaryFill;
    _hsv = HSVColor.fromColor(current);
  }

  void _pick(Color? c) {
    if (c != null) _hsv = HSVColor.fromColor(c);
    _customActive = false;
    ref.read(appSettingsProvider.notifier).setThemeColor(c);
    setState(() {});
  }

  void _pickCustom(HSVColor v) {
    _hsv = v;
    _customActive = true;
    ref.read(appSettingsProvider.notifier).setThemeColor(v.toColor());
    setState(() {});
  }

  String _presetName(AppLocalizations l, int i) => switch (i) {
        0 => l.settingsColorBlue,
        1 => l.settingsColorGreen,
        2 => l.settingsColorTeal,
        3 => l.settingsColorPurple,
        4 => l.settingsColorRose,
        5 => l.settingsColorOrange,
        6 => l.settingsColorMustard,
        7 => l.settingsColorGray,
        8 => l.settingsColorTerracotta,
        _ => l.settingsColorNavy,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(appSettingsProvider).themeColor;
    final custom = _hsv.toColor();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.settingsColorTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(l.settingsColorSubtitle,
                style: TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 14),
            Text(l.settingsColorPreset,
                style: TextStyle(
                    fontSize: 12,
                    color: kMuted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, c) in _presets.indexed)
                  _PresetSwatch(
                    key: Key('theme-preset-$i'),
                    color: c ?? kPrimaryFill,
                    name: _presetName(l, i),
                    isDefault: c == null,
                    selected: !_customActive &&
                        (c?.toARGB32() == current?.toARGB32()),
                    onTap: () => _pick(c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l.settingsColorCustom,
                style: TextStyle(
                    fontSize: 12,
                    color: kMuted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _SvSquare(
              key: const Key('theme-sv'),
              hsv: _hsv,
              onChanged: _pickCustom,
            ),
            const SizedBox(height: 12),
            _HueBar(
              key: const Key('theme-hue'),
              hue: _hsv.hue,
              onChanged: (h) => _pickCustom(_hsv.withHue(h)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  color: custom,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kLine),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '#${custom.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                    fontSize: 12, color: kMuted, fontFeatures: kTabularFigures),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('theme-cancel'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonCancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const Key('theme-apply'),
                  onPressed: () {
                    widget.onApplied();
                    Navigator.pop(context);
                  },
                  child: Text(l.settingsColorApply),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  final Color color;
  final String name;
  final bool isDefault;
  final bool selected;
  final VoidCallback onTap;
  const _PresetSwatch({
    super.key,
    required this.color,
    required this.name,
    required this.isDefault,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        child: Column(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? kInk : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 3),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: selected ? kInk : kMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (isDefault)
            Text(AppLocalizations.of(context).settingsColorDefaultBadge,
                style: TextStyle(fontSize: 9, color: kMuted)),
        ]),
      ),
    );
  }
}

/// 彩度×明度の正方形。横=彩度、縦=明度（上が明るい）。
class _SvSquare extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  const _SvSquare({super.key, required this.hsv, required this.onChanged});

  void _handle(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = 1 - (local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final size = Size(cons.maxWidth, 150);
      return GestureDetector(
        onPanDown: (d) => _handle(d.localPosition, size),
        onPanUpdate: (d) => _handle(d.localPosition, size),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            size: size,
            painter: _SvPainter(hsv),
          ),
        ),
      );
    });
  }
}

class _SvPainter extends CustomPainter {
  final HSVColor hsv;
  _SvPainter(this.hsv);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 白→純色（横）に黒（縦）を重ねるとHSVのSV面になる。
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: [Colors.white, hueColor])
            .createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    // 現在位置のリング
    final pos = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
        pos,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white);
    canvas.drawCircle(
        pos,
        9.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black38);
  }

  @override
  bool shouldRepaint(_SvPainter old) => old.hsv != hsv;
}

/// 色相バー。
class _HueBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;
  const _HueBar({super.key, required this.hue, required this.onChanged});

  void _handle(Offset local, double width) =>
      onChanged(((local.dx / width).clamp(0.0, 1.0) * 360) % 360);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      return GestureDetector(
        onPanDown: (d) => _handle(d.localPosition, w),
        onPanUpdate: (d) => _handle(d.localPosition, w),
        child: SizedBox(
          width: w,
          height: 22,
          child: Stack(children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(colors: [
                    for (var h = 0; h <= 360; h += 30)
                      HSVColor.fromAHSV(1, h.toDouble() % 360, 1, 1).toColor(),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: (hue / 360 * w - 11).clamp(0.0, w - 22),
              top: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3)
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
