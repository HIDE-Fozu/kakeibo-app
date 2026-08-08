import 'dart:math' as math;

import 'package:flutter/material.dart';

/// セル幅・直下展開のプルダウン（アプリ全体のプルダウン共通の文法）。
///
/// Flutter標準の DropdownButton は選択項目を中心に画面いっぱいの
/// メニューを重ねて出すため、「押したセルと同じ幅で、セルの直下にだけ
/// 広がる」動きをここで自作する（ユーザー指定のデザイン・2026-08-09）。
/// 下に収まらないときだけセルの上に開く。

const double kCellDropdownItemHeight = 44;

class CellDropdownItem<T> {
  final T value;
  final String label;
  const CellDropdownItem(this.value, this.label);
}

/// [anchorContext] のRenderBoxをセルとみなし、その幅・直下にメニューを開く。
/// 選択されたら値を、外タップで閉じたら null を返す。
Future<T?> showCellDropdown<T>(
  BuildContext anchorContext, {
  required List<CellDropdownItem<T>> items,
  T? value,
  bool centerItems = false,
}) {
  final navigator = Navigator.of(anchorContext);
  final box = anchorContext.findRenderObject()! as RenderBox;
  final overlay =
      navigator.overlay!.context.findRenderObject()! as RenderBox;
  final anchor = Rect.fromPoints(
    box.localToGlobal(Offset.zero, ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  return navigator.push(_CellDropdownRoute<T>(
    anchor: anchor,
    items: items,
    value: value,
    centerItems: centerItems,
    capturedThemes:
        InheritedTheme.capture(from: anchorContext, to: navigator.context),
  ));
}

class _CellDropdownRoute<T> extends PopupRoute<T> {
  _CellDropdownRoute({
    required this.anchor,
    required this.items,
    required this.value,
    required this.centerItems,
    required this.capturedThemes,
  });

  final Rect anchor;
  final List<CellDropdownItem<T>> items;
  final T? value;
  final bool centerItems;
  final CapturedThemes capturedThemes;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    const margin = 8.0;
    final contentHeight = items.length * kCellDropdownItemHeight + 12;
    // 6項目目が半分見える高さ＝スクロールできることが分かる上限。
    final preferred =
        math.min(contentHeight, 5.5 * kCellDropdownItemHeight);
    final below =
        screen.height - media.viewInsets.bottom - anchor.bottom - margin;
    final above = anchor.top - media.padding.top - margin;
    // 原則は直下。下に3項目も出せず、上のほうが広いときだけ上に開く。
    final openDown = below >= math.min(preferred, 3 * kCellDropdownItemHeight) ||
        below >= above;
    final maxHeight = math.max(
        kCellDropdownItemHeight, math.min(preferred, openDown ? below : above));
    final left =
        anchor.left.clamp(margin, math.max(margin, screen.width - anchor.width - margin));

    final selectedIndex = items.indexWhere((e) => e.value == value);
    final controller = ScrollController(
      initialScrollOffset: selectedIndex < 0
          ? 0
          : (selectedIndex * kCellDropdownItemHeight -
                  (maxHeight - kCellDropdownItemHeight) / 2)
              .clamp(0, math.max(0.0, contentHeight - maxHeight)),
    );

    final scheme = Theme.of(context).colorScheme;
    final menu = Material(
      elevation: 4,
      // 白ピルと同じ「白く浮く」見た目にする（elevationのsurfaceTintで
      // 緑がかるのを避ける）。
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemExtent: kCellDropdownItemHeight,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final selected = i == selectedIndex;
          return InkWell(
            onTap: () => Navigator.pop(context, item.value),
            child: Container(
              color: selected
                  ? scheme.primary.withValues(alpha: .10)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment:
                  centerItems ? Alignment.center : Alignment.centerLeft,
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: left.toDouble(),
          width: anchor.width,
          top: openDown ? anchor.bottom + 2 : null,
          bottom: openDown ? null : screen.height - anchor.top + 2,
          child: capturedThemes.wrap(
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: menu,
            ),
          ),
        ),
      ],
    );
  }
}

/// フォーム用のプルダウンセル（DropdownButtonFormField の置き換え）。
/// 見た目は OutlineInputBorder の入力欄のまま、メニューだけ
/// [showCellDropdown] のセル幅・直下展開になる。
class CellDropdownField<T> extends StatelessWidget {
  const CellDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.centerItems = false,
  });

  final T? value;
  final List<CellDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final InputDecoration decoration;
  final bool centerItems;

  @override
  Widget build(BuildContext context) {
    final current = items.where((e) => e.value == value).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        FocusScope.of(context).unfocus(); // キーボードの上に開かない
        final picked = await showCellDropdown<T>(
          context,
          items: items,
          value: value,
          centerItems: centerItems,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: decoration.copyWith(
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: current == null,
        child: Text(
          current?.label ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
