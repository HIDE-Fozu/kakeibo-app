import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// メモを書こうとするとキーボードがすぐ引っ込む不具合の回帰テスト
///（2026-08-27 修正済み）。
///
/// 原因: キーボードで縦が縮むと calendar_screen のレイアウトが切り替わり、
/// `_DaySection` が Column のスロットから Stack のオーバーレイへ**ツリー上の
/// 別の場所に移動していた**。位置が変わると State は作り直されるので
/// `_ShoppingMemoPadState` が破棄され、FocusNode も作り直されてフォーカスが
/// 外れる＝キーボードが閉じる。
///
/// 直しかた: カードの置き場所を Stack の1か所に固定し、Column 側は高さを
/// 測るためだけの空きスロットにした。Stack の子の枠数も変えない。
void main() {
  testWidgets('キーボードが出てもメモのフォーカスは外れない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shopping-memo-pad')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('shopping-memo-field'));
    final nodeBefore = tester.widget<TextField>(field).focusNode;
    expect(nodeBefore?.hasFocus, isTrue);

    // キーボードが出た状態（下から食われる）を再現する。
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final nodeAfter = tester.widget<TextField>(field).focusNode;
    // State が作り直されていない＝同じ FocusNode のままであること
    expect(identical(nodeBefore, nodeAfter), isTrue,
        reason: 'メモの State が作り直されている（ツリー上の位置が変わった）');
    expect(nodeAfter?.hasFocus, isTrue, reason: 'キーボードが閉じてしまう');
  });
}
