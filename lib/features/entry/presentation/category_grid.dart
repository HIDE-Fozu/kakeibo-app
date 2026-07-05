import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/category_emoji.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../settings/application/settings_controller.dart';
import '../application/entry_category_providers.dart';

// --- レイアウト定数 ---
// 4列×2段を1ページ（＝8カテゴリ）とし、行優先で詰める（index0の下はindex4）。
// ページ間には薄い点線を入れて「2ページ目がある」ことを示す。
const int kCatCols = 4;
const int kCatRows = 2;
const int kCatPerPage = kCatCols * kCatRows; // 8
const double kCatTileH = 64;
const double kCatGap = 4;
const double kCatDottedStrip = 16; // ページ境界（点線）に使う横幅
const double kCatGridHeight = kCatTileH * kCatRows + kCatGap; // 132

/// 編集中（ドラッグ中）のジグル振れ幅（ラジアン ≒ 1.3°）。控えめに。
const double kCatJiggleAmplitude = 0.022;

/// 幅に応じてタイル寸法とスロット座標・当たり判定を決める。
class CatGridMetrics {
  final double tileW;
  const CatGridMetrics(this.tileW);

  double get colStride => tileW + kCatGap;
  double get rowStride => kCatTileH + kCatGap;
  double get pageContentW => kCatCols * tileW + (kCatCols - 1) * kCatGap;
  double get pageStride => pageContentW + kCatDottedStrip;

  /// 利用可能幅から4列＋点線余白が収まるタイル幅を決める。
  static CatGridMetrics fit(double availWidth) {
    final w =
        (availWidth - kCatDottedStrip - (kCatCols - 1) * kCatGap) / kCatCols;
    return CatGridMetrics(w.clamp(56.0, 100.0));
  }

  /// index の配置座標（ページ×4列×2段・行優先）。
  Offset slotOffset(int index) {
    final page = index ~/ kCatPerPage;
    final p = index % kCatPerPage;
    return Offset(
      page * pageStride + (p % kCatCols) * colStride,
      (p ~/ kCatCols) * rowStride,
    );
  }

  /// コンテンツ全幅（ページ数ぶん）。
  double contentWidth(int count) {
    if (count == 0) return 0;
    final pages = (count - 1) ~/ kCatPerPage + 1;
    return (pages - 1) * pageStride + pageContentW;
  }

  /// コンテンツ座標→ドロップ先index（0..count-1にクランプ）。
  int slotIndexFromOffset(Offset local, int count) {
    if (count == 0) return 0;
    final maxPage = (count - 1) ~/ kCatPerPage;
    final page = (local.dx / pageStride).floor().clamp(0, maxPage);
    final xInPage = local.dx - page * pageStride;
    final col = (xInPage / colStride).floor().clamp(0, kCatCols - 1);
    final row = (local.dy / rowStride).floor().clamp(0, kCatRows - 1);
    return (page * kCatPerPage + row * kCatCols + col).clamp(0, count - 1);
  }
}

/// index が段の下側（＝下の行）にあるか。内訳オーバーレイを上に出すか下に出すかの判定に使う。
bool catIsBottomRow(int index) => (index % kCatPerPage) ~/ kCatCols == 1;

class CategoryGrid extends ConsumerStatefulWidget {
  final TxnType type;
  final int? selectedId; // 保存されるid（親 or 内訳）
  final void Function({
    required int categoryId,
    required bool hasSubs,
    required bool isSameGroup,
  })
  onTapCategory;

  const CategoryGrid({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onTapCategory,
  });

  @override
  ConsumerState<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends ConsumerState<CategoryGrid>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _contentKey = GlobalKey();

  // 編集中（ドラッグ中）だけ回すジグル用コントローラ（initStateで生成）。
  late final AnimationController _jiggle;

  CatGridMetrics _metrics = const CatGridMetrics(84);
  bool _canScrollRight = false;

  // ドラッグ状態
  int? _dragIndex;
  Offset? _dragLocal; // コンテンツ座標系の指位置
  // ドラッグ中/確定直後の表示順。providerが追いつくまで保持してちらつきを防ぐ。
  List<CategoryEntity>? _workingOrder;
  List<CategoryEntity> _cats = const [];

  @override
  void initState() {
    super.initState();
    _jiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _scroll.addListener(_updateCanScroll);
  }

  void _updateCanScroll() {
    if (!_scroll.hasClients) return;
    final can = _scroll.offset < _scroll.position.maxScrollExtent - 1;
    if (can != _canScrollRight) setState(() => _canScrollRight = can);
  }

  void _scrollRight() {
    if (!_scroll.hasClients) return;
    final page = _scroll.position.viewportDimension * 0.9;
    _scroll.animateTo(
      (_scroll.offset + page).clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _jiggle.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Offset _toContentLocal(Offset globalPosition) {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.globalToLocal(globalPosition);
  }

  void _onDragStart(int index, LongPressStartDetails d) {
    _jiggle.repeat(); // 編集中プルプル開始
    setState(() {
      _workingOrder = List.of(_cats);
      _dragIndex = index;
      _dragLocal = _toContentLocal(d.globalPosition);
    });
  }

  void _onDragUpdate(LongPressMoveUpdateDetails d) {
    final order = _workingOrder;
    if (order == null || _dragIndex == null) return;
    final local = _toContentLocal(d.globalPosition);
    final hovered = _metrics.slotIndexFromOffset(local, order.length);
    setState(() {
      _dragLocal = local;
      if (hovered != _dragIndex) {
        final item = order.removeAt(_dragIndex!);
        order.insert(hovered, item);
        _dragIndex = hovered;
      }
    });
    _maybeAutoScroll(local);
  }

  void _maybeAutoScroll(Offset local) {
    if (!_scroll.hasClients) return;
    final viewportX = local.dx - _scroll.offset;
    final vpWidth = _scroll.position.viewportDimension;
    const edge = 44.0, step = 16.0;
    final max = _scroll.position.maxScrollExtent;
    if (viewportX < edge && _scroll.offset > 0) {
      _scroll.jumpTo((_scroll.offset - step).clamp(0.0, max));
    } else if (viewportX > vpWidth - edge && _scroll.offset < max) {
      _scroll.jumpTo((_scroll.offset + step).clamp(0.0, max));
    }
  }

  Future<void> _onDragEnd() async {
    final order = _workingOrder;
    final index = _dragIndex;
    _jiggle.stop(); // プルプル停止（タイルは直立に戻る）
    setState(() {
      _dragIndex = null;
      _dragLocal = null;
    });
    if (order == null || index == null) return;
    final wasRecent = ref.read(appSettingsProvider).categoryOrder ==
        CategoryOrderMode.recentlyUsed;
    // 並びを保存。最近使った順のままだと反映されないので固定順に切替。
    await ref
        .read(categoryRepositoryProvider)
        .reorder(order.map((c) => c.id).toList());
    if (wasRecent) {
      await ref
          .read(appSettingsProvider.notifier)
          .setCategoryOrder(CategoryOrderMode.manual);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('自分で並べた順にしました（設定で戻せます）')));
      }
    }
    // _workingOrder は provider が追いついた時点で build 内でクリアする。
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appSettingsProvider); // 並び順モード変更で再構築
    final providerCats =
        ref.watch(entryCategoriesProvider(widget.type)).valueOrNull ?? const [];
    final all =
        ref.watch(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];

    // ドラッグ確定後、provider が同じ並びに追いついたら override を解除。
    if (_workingOrder != null &&
        _dragIndex == null &&
        _sameIds(providerCats, _workingOrder!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dragIndex == null) setState(() => _workingOrder = null);
      });
    }
    _cats = _workingOrder ?? providerCats;

    final byId = {for (final c in all) c.id: c};
    final selected = widget.selectedId == null ? null : byId[widget.selectedId];
    final selectedGroupId = selected?.parentId ?? selected?.id;
    final scheme = Theme.of(context).colorScheme;
    final numPages =
        _cats.isEmpty ? 0 : (_cats.length - 1) ~/ kCatPerPage + 1;

    return SizedBox(
      height: kCatGridHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _metrics = CatGridMetrics.fit(constraints.maxWidth);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _updateCanScroll());
          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  key: _contentKey,
                  width: _metrics.contentWidth(_cats.length),
                  height: kCatGridHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ページ境界の薄い点線（2ページ目以降がある時だけ）。
                      for (var p = 0; p < numPages - 1; p++)
                        Positioned(
                          left: p * _metrics.pageStride +
                              _metrics.pageContentW +
                              kCatDottedStrip / 2 -
                              0.6,
                          top: 6,
                          height: kCatGridHeight - 12,
                          width: 1.2,
                          child: _DashedVLine(color: scheme.outlineVariant),
                        ),
                      for (final (i, c) in _cats.indexed)
                        _positionedTile(
                            i, c, scheme, selectedGroupId, selected),
                    ],
                  ),
                ),
              ),
              // 右送りボタン（タイルに重なる。続きが右にある時だけ表示）。
              if (_canScrollRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _scrollRightButton(scheme)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _scrollRightButton(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          elevation: 1,
          child: InkWell(
            key: const Key('cat-scroll-right'),
            customBorder: const CircleBorder(),
            onTap: _scrollRight,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.chevron_right,
                  size: 22, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );

  Widget _positionedTile(
    int i,
    CategoryEntity c,
    ColorScheme scheme,
    int? selectedGroupId,
    CategoryEntity? selected,
  ) {
    final isDragging = i == _dragIndex;
    final pos = (isDragging && _dragLocal != null)
        ? Offset(
            _dragLocal!.dx - _metrics.tileW / 2, _dragLocal!.dy - kCatTileH / 2)
        : _metrics.slotOffset(i);
    final subs =
        ref.watch(entrySubcategoriesProvider(c.id)).valueOrNull ??
        const <CategoryEntity>[];
    final hasSubs = subs.isNotEmpty;
    final isSelectedGroup = c.id == selectedGroupId;
    // 内訳選択中は親タイルのラベルが内訳名に変わる（食費→外食）
    final selectedSubName =
        (isSelectedGroup && selected != null && selected.parentId != null)
            ? selected.name
            : null;
    Widget tile = GestureDetector(
      key: Key('cat-tile-${c.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTapCategory(
        categoryId: c.id,
        hasSubs: hasSubs,
        isSameGroup: isSelectedGroup,
      ),
      // 長押しで持ち上げ→そのままドラッグ→離すと確定（iPhoneホーム画面風）。
      onLongPressStart: (d) => _onDragStart(i, d),
      onLongPressMoveUpdate: _onDragUpdate,
      onLongPressEnd: (_) => _onDragEnd(),
      child: AnimatedScale(
        scale: isDragging ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: _tile(
          context,
          c,
          scheme,
          isSelectedGroup: isSelectedGroup,
          hasSubs: hasSubs,
          selectedSubName: selectedSubName,
          elevated: isDragging,
        ),
      ),
    );
    // 編集中（誰かをドラッグ中）は、掴んでいるタイル以外を小刻みに揺らす。
    // 位相をidでずらして「バラバラに揺れる」iPhone風にする。
    if (_dragIndex != null && !isDragging) {
      final phase = (c.id % 7) / 7 * 2 * pi;
      tile = AnimatedBuilder(
        animation: _jiggle,
        child: tile,
        builder: (_, child) => Transform.rotate(
          angle: kCatJiggleAmplitude * sin(2 * pi * _jiggle.value + phase),
          child: child,
        ),
      );
    }
    return AnimatedPositioned(
      // key で同一タイルを追跡 → 並び替え時に各タイルがスロットへアニメ移動する。
      key: ValueKey('catpos-${c.id}'),
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      left: pos.dx,
      top: pos.dy,
      width: _metrics.tileW,
      height: kCatTileH,
      child: tile,
    );
  }

  Widget _tile(
    BuildContext context,
    CategoryEntity c,
    ColorScheme scheme, {
    required bool isSelectedGroup,
    required bool hasSubs,
    required String? selectedSubName,
    bool elevated = false,
  }) {
    final label = selectedSubName ?? c.name;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelectedGroup
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        border: isSelectedGroup
            ? Border.all(color: scheme.primary, width: 2)
            : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            categoryEmoji(c.icon, c.name),
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            hasSubs ? '$label ▾' : label,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool _sameIds(List<CategoryEntity> a, List<CategoryEntity> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

/// ページ境界に引く薄い縦の点線。
class _DashedVLine extends StatelessWidget {
  final Color color;
  const _DashedVLine({required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _DashedVLinePainter(color));
}

class _DashedVLinePainter extends CustomPainter {
  final Color color;
  _DashedVLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const dash = 4.0, gap = 4.0;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, min(y + dash, size.height)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVLinePainter old) => old.color != color;
}
