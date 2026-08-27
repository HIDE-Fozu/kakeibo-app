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

  /// FB 2026-08-27 の3連発:
  /// ①「ホワイトアウトしてる時間が長すぎる」→ 解除が遅い
  /// ②「メモ開いてる時はスクリム入れよう。解除の動作を早めて」→ 出すのは要る
  /// ③「つきいちではスクリムが入らないのに、メモは移動しない状態でも
  ///    スクリムが入って不自然。カレンダーが見切れてタップできない時のみ」
  ///
  /// 答えは**出るのと消えるを非対称**にすること。
  /// 出る = カードが実際に動いてから（`keyboard`）。フォーカスは一瞬で立つが
  /// カードが動くのはキーボードが上がってからなので、フォーカスで出すと
  /// 「動いていないのにスクリム」になる。
  /// 消える = 編集をやめた瞬間（フォーカス）。insets の 0 を待つと閉じる
  /// アニメーションぶん遅れる。
  testWidgets('スクリムはカードが動いてから出て、やめた瞬間に消える',
      (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const Key('day-tab-memo')));
    await tester.pumpAndSettle();

    /// 升目の上の「落とし」が出ているか（FB 2026-08-27でカレンダーの升目
    /// だけに絞った。月見出し・サマリは落とさない）。
    bool dimmed() =>
        find.byKey(const Key('calendar-dim')).evaluate().isNotEmpty;

    // ①フォーカスは立ったが、キーボードはまだ上がっていない＝カードは
    //   動いていない。ここでスクリムを出してはいけない（つきいちと同じ見え方）。
    await tester.tap(find.byKey(const Key('shopping-memo-pad')));
    await tester.pumpAndSettle();
    expect(dimmed(), isFalse,
        reason: 'カードが動いていないのにスクリムが入る（つきいちと不整合）');

    // ②キーボードが上がってカードが退避した＝カレンダーが見切れた
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-sheet-scrim')), findsOneWidget);
    expect(dimmed(), isTrue, reason: 'カレンダーが見切れたらスクリムを出す');

    // ③背景をタップして戻る。**キーボードはまだ閉じ切っていない**
    //（viewInsets はそのまま）状態で、落としはもう晴れていること。
    await tester.tapAt(const Offset(200, 200));
    await tester.pump();
    expect(MediaQueryData.fromView(tester.view).viewInsets.bottom,
        greaterThan(0),
        reason: 'キーボードが閉じ切る前を再現していない＝この検証は無意味');
    expect(dimmed(), isFalse,
        reason: 'キーボードが閉じ切るまでカレンダーが白いまま待たされる');
  });
}