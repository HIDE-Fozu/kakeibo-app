import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/features/entry/presentation/category_grid.dart';

void main() {
  // tileW=84 → colStride=88, rowStride=68, pageContentW=4*84+3*4=348, pageStride=364
  const m = CatGridMetrics(84);

  test('slotOffset: 4列×2段・行優先（index0の下＝index4）', () {
    expect(m.slotOffset(0), const Offset(0, 0));
    expect(m.slotOffset(1), Offset(m.colStride, 0));
    expect(m.slotOffset(3), Offset(3 * m.colStride, 0));
    // 食費(0)の真下は5番目(index4)
    expect(m.slotOffset(4), Offset(0, m.rowStride));
    expect(m.slotOffset(5), Offset(m.colStride, m.rowStride));
    // 9番目(index8)は2ページ目の左上
    expect(m.slotOffset(8), Offset(m.pageStride, 0));
  });

  test('contentWidth: ページ数ぶんの幅', () {
    expect(m.contentWidth(0), 0);
    expect(m.contentWidth(1), m.pageContentW);
    expect(m.contentWidth(8), m.pageContentW); // 1ページ
    expect(m.contentWidth(9), m.pageStride + m.pageContentW); // 2ページ
  });

  test('slotIndexFromOffset: 座標→index（行優先・0..count-1クランプ）', () {
    expect(m.slotIndexFromOffset(const Offset(10, 5), 8), 0);
    expect(m.slotIndexFromOffset(Offset(10, m.rowStride + 5), 8), 4); // 下段=+4
    expect(m.slotIndexFromOffset(Offset(m.colStride + 5, 5), 8), 1);
    expect(m.slotIndexFromOffset(Offset(m.pageStride + 5, 5), 16), 8); // 2ページ目左上
    // 右外・上段は上段末尾(col3)→index3、下段なら末尾(index4)にクランプ
    expect(m.slotIndexFromOffset(const Offset(99999, 5), 5), 3);
    expect(m.slotIndexFromOffset(Offset(99999, m.rowStride + 5), 5), 4);
    expect(m.slotIndexFromOffset(const Offset(-50, 5), 5), 0); // 左外→先頭
  });

  test('catIsBottomRow: 各ページの下段(index%8>=4)がtrue', () {
    expect(catIsBottomRow(0), isFalse);
    expect(catIsBottomRow(3), isFalse);
    expect(catIsBottomRow(4), isTrue);
    expect(catIsBottomRow(7), isTrue);
    expect(catIsBottomRow(8), isFalse); // 2ページ目の上段
    expect(catIsBottomRow(12), isTrue); // 2ページ目の下段
  });

  test('fit: 4列＋点線余白が収まるタイル幅', () {
    final f = CatGridMetrics.fit(366);
    // (366 - 16 - 3*4) / 4 = 84.5
    expect(f.tileW, closeTo(84.5, 0.01));
  });
}
