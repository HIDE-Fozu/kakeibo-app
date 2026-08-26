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

  /// FB 2026-08-27「メモからカレンダーに戻ったときホワイトアウトしてる時間が
  /// 長すぎる。カレンダーが表示されるのを待つ体感が悪い」。
  ///
  /// 原因は背景を落とす覆いをキーボードにも連動させていたこと。カードはもう
  /// 通常位置に戻っているのに、キーボードが閉じ切るまで（実機で数百ms）
  /// カレンダーが白く飛んだままになっていた。
  /// 覆い（＝タップして戻る面）は浮いている間ずっと要るが、**落とす**のは
  /// 自分でドラッグして広げたときだけにする。
  testWidgets('キーボードで浮いているだけのときはカレンダーを白く落とさない',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();

    /// 覆いの中に「落とす」ColoredBox があるか。
    bool dimmed() => find
        .descendant(
          of: find.byKey(const Key('day-sheet-scrim')),
          matching: find.byType(ColoredBox),
        )
        .evaluate()
        .isNotEmpty;

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    // 覆いはある（背景タップで戻れる）が、落としてはいない
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget,
        reason: '背景タップで戻る面は要る');
    expect(dimmed(), isFalse, reason: 'カレンダーが白く飛ぶ');

    // 自分でドラッグして広げたときは従来どおり落とす
    await tester.drag(
        find.byKey(const Key('day-sheet-drag')), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(dimmed(), isTrue, reason: '広げたときは落として戻り先を示す');
  });
}
