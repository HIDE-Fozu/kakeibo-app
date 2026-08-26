import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// ★既知の不具合の再現テスト（2026-08-27・未修正）
///
/// メモを書こうとするとキーボードがすぐ引っ込む。
///
/// 原因はここで特定済み: キーボードが出て縦が縮むと calendar_screen の
/// `tight`/`overlay` が切り替わり、`_DaySection` が Column のスロットから
/// Stack のオーバーレイへ**ツリー上の別の場所に移動する**。位置が変わると
/// State は作り直されるので `_ShoppingMemoPadState` が破棄され、FocusNode も
/// 作り直されてフォーカスが外れる＝キーボードが閉じる。
/// （このテストを一度 skip なしで走らせると SAME_FOCUSNODE=false になる）
///
/// 直し方の方針は docs/handoff-2026-08-27-memo-keyboard.md を参照。
/// 修正したら skip を外すこと。
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
    // 未修正: キーボードでフォーカスが落ちる（2026-08-27）。
    // 直したら skip を外す（testWidgets の skip は bool のみ）。
  }, skip: true);
}
