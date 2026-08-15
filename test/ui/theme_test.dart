import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/theme.dart';

import '../support/test_app.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('既定テーマの導出パレットは現行トークンとバイト一致', () {
    final t = buildKakeiboTheme();
    final p = t.extension<KakeiboPalette>()!;
    expect(p.fill.toARGB32(), kPrimaryFill.toARGB32());
    expect(p.dark.toARGB32(), kPrimary.toARGB32());
    expect(p.soft.toARGB32(), kPrimarySoft.toARGB32());
    expect(p.line.toARGB32(), kLine.toARGB32());
    expect(p.bg.toARGB32(), kPaper.toARGB32());
    expect(p.chrome.toARGB32(), kChrome.toARGB32());
    expect(t.scaffoldBackgroundColor, kPaper);
    expect(t.colorScheme.primary, kPrimary);
  });

  test('derivePalette: どんな色でもコントラスト下限を満たす', () {
    // 明るすぎ・暗すぎ・無彩色・原色を含む代表色で導出規則を検証。
    const seeds = [
      Color(0xFFFFF176), // 明るい黄
      Color(0xFF111111), // ほぼ黒
      Color(0xFFCCCCCC), // 無彩色の明るいグレー
      Color(0xFFFF0000), // 原色の赤
      Color(0xFF4A7FB5), // 既定ブルー
      Color(0xFF2F8570), // プリセットのグリーン
    ];
    for (final seed in seeds) {
      final p = derivePalette(seed);
      // CTAの白文字が読める塗り
      expect(_contrast(Colors.white, p.fill), greaterThanOrEqualTo(3.5),
          reason: 'fill of $seed');
      // 白地で読める文字・枠
      expect(_contrast(p.dark, Colors.white), greaterThanOrEqualTo(4.5),
          reason: 'dark of $seed');
      // 面は薄い（本文の下地として成立する明るさ）
      expect(p.soft.computeLuminance(), greaterThan(0.6),
          reason: 'soft of $seed');
      expect(p.bg.computeLuminance(), greaterThan(0.8),
          reason: 'bg of $seed');
    }
  });

  testWidgets('生成りの背景・深緑primary・拡張色（紅/藍）が適用される', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h); // home指定なし=KakeiboApp（テーマが乗る）

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, kPaper);
    expect(theme.colorScheme.primary, kPrimary);
    expect(theme.colorScheme.error, kExpense);
    final ext = theme.extension<KakeiboColors>();
    expect(ext, isNotNull);
    expect(ext!.expense, kExpense);
    expect(ext.income, kIncome);
  });
}
