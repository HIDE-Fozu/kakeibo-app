import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/services/ocr/ocr_types.dart';

/// レシート写真の「行の切り抜き」。
/// 品名は半角カタカナ略称が多くOCRテキストは判読に不向きなので、
/// OCRの行座標（正準空間0..1）で**写真そのもの**を切り出して見せる。
/// 画像が無い/壊れている場合は fallbackText（OCRテキスト）に落ちる。
class ReceiptLineStrip extends StatelessWidget {
  final String? imagePath;
  final OcrRect rect;
  final String fallbackText;
  final double height;

  const ReceiptLineStrip({
    super.key,
    required this.imagePath,
    required this.rect,
    required this.fallbackText,
    this.height = 26,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null) return _fallback(context);
    return FutureBuilder<ui.Image>(
      future: _loadUiImage(path),
      builder: (context, snap) {
        final img = snap.data;
        if (img == null) return _fallback(context);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(painter: _StripPainter(img, rect)),
          ),
        );
      },
    );
  }

  Widget _fallback(BuildContext context) => SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            fallbackText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
}

/// 同じレシート画像を行ごとに何度もデコードしないためのセッションキャッシュ。
final _cache = <String, Future<ui.Image>>{};

Future<ui.Image> _loadUiImage(String path) {
  if (_cache.length > 8) _cache.clear(); // 撮影ごとに1枚なので小さくてよい
  return _cache[path] ??= () async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }();
}

class _StripPainter extends CustomPainter {
  final ui.Image image;
  final OcrRect rect;
  _StripPainter(this.image, this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    // 行の上下に行高の40%の余白を足して切り出す（行間のかすれ対策）
    final padY = rect.h * 0.4 * h;
    final padX = 0.01 * w;
    final src = Rect.fromLTRB(
      (rect.x * w - padX).clamp(0, w),
      (rect.y * h - padY).clamp(0, h),
      (rect.right * w + padX).clamp(0, w),
      (rect.bottom * h + padY).clamp(0, h),
    );
    // 紙面らしい下地（画像の余白が透けても白）
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFFDFDFA));
    canvas.drawImageRect(image, src, Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.image != image ||
      old.rect.x != rect.x ||
      old.rect.y != rect.y ||
      old.rect.w != rect.w ||
      old.rect.h != rect.h;
}
