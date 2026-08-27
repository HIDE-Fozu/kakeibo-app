import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/navigation.dart';
import '../../chores/application/chore_providers.dart';
import '../../chores/presentation/chore_day_section.dart';
import '../../entry/application/entry_form_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/budget_amount_dialog.dart';
import '../application/calendar_providers.dart';
import 'backup_banner.dart';
import 'day_transaction_list.dart';
import '../../memo/application/shopping_memo_controller.dart';
import '../../memo/presentation/shopping_memo_pad.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final (year, month) = ref.watch(currentMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    // 上部サマリは「今日までの実績」（FB 2026-08-21）。月全体・月末見込みとは
    // 役割分担: 未来分はセルと見込み収支が受け持つ。
    final summary =
        ref.watch(monthToDateSummaryProvider((year, month))).valueOrNull ??
        const MonthlySummary(income: 0, expense: 0);
    final totals =
        ref.watch(dayExpenseTotalsProvider((year, month))).valueOrNull ??
        const <CivilDate, int>{};
    final incomes =
        ref.watch(dayIncomeTotalsProvider((year, month))).valueOrNull ??
        const <CivilDate, int>{};
    final ghosts = ref.watch(dayGhostTotalsProvider((year, month)));
    final choreMarks = ref.watch(choreMonthMarksProvider((year, month)));
    final mf = ref.watch(moneyFormatterProvider);

    // 日別カードはタブ行を上へドラッグすると広がる（FB 2026-08-27）。
    // 0 なら通常位置。基準の高さは描画後に実測して覚える。
    final raise = ref.watch(daySheetRaiseProvider);
    final baseHeight = ref.watch(daySheetBaseHeightProvider);
    // メモを編集中か。背景を落とす判断はキーボードの insets ではなくこれで
    // 見る（下の dimmed の理由）。メモタブを離れたらフラグの立ち残りは無視する
    //（フラグを畳むのは widget の dispose になり、そこで provider は触れない）。
    final memoEditing = ref.watch(shoppingMemoFocusedProvider) &&
        ref.watch(dayTabProvider) == DayTab.memo;


    return SafeArea(
      // 縦が潰れても崩れないよう、最低高を確保して不足分はスクロールに逃がす。
      // 通常時は maxHeight >= _kMinBodyHeight なので見た目・挙動は従来どおり。
      child: LayoutBuilder(builder: (context, outer) {
        // キーボードが出ているか。Scaffold(resizeToAvoidBottomInset) が body の
        // MediaQuery から viewInsets を抜くので、View から生の値を読む。
        // 「縦が足りない＝キーボード」で代用してはいけない: 小さい端末では
        // 常に true になり、キーボードが無くてもカレンダーが暗いままになる。
        // LayoutBuilder の中で読むのは、キーボードで body が縮むと必ずここが
        // 呼び直されるから（画面が縮まないケースでは判定も要らない）。
        final keyboard =
            MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;
        // キーボードが出たらスクロールに逃がさず（カレンダーごと動いて書き
        // にくい）、カードをキーボードのすぐ上に固定し、背後は切り取って敷く。
        final bodyHeight = keyboard
            ? outer.maxHeight
            : math.max(outer.maxHeight, _kMinBodyHeight);
        // カードが通常位置より上に浮いている状態（背景タップで戻れる）。
        final lifted = raise > 0 || keyboard;
        // 背景を落とす条件。**出るのと消えるのを非対称**にしてある。
        //
        // 出る = カードが実際に動いてカレンダーが見切れたとき。つきいちでは
        //   スクリムが入らないのに、メモだと動いてもいないのに入るのは不自然
        //   （FB 2026-08-27）。フォーカスだけで出すと、フォーカスは一瞬で
        //   立つのにカードが動くのはキーボードが上がってからなので、その間
        //   「動いていないのにスクリムだけ出ている」状態ができる。だから
        //   出す側は `keyboard`（＝カードがキーボードの上へ退避した）で見る。
        // 消える = 編集をやめた瞬間。`keyboard` だけで見ると、insets が 0 に
        //   なるのは閉じるアニメーションが**終わった後**なので解除が必ず
        //   遅れ、カードはもう通常位置なのにカレンダーだけ白いまま待たされる
        //   （FB 2026-08-27「解除の動作を早めて」）。`memoEditing` は
        //   `unfocus()` と同じフレームで false になる＝即座に晴れる。
        //
        // ドラッグで広げたときは指の動きにそのまま追随するので `raise > 0`。
        final dimmed = raise > 0 || (keyboard && memoEditing);
        final backdrop = Column(
        children: [
          const BackupBanner(),
          _MonthHeader(year: year, month: month),
          _SummaryCard(year: year, month: month, summary: summary),
          // 紙デザイン（2026-08-20 モック）: ベース背景（紙）の上に、日セルは
          // 白の角丸カードを敷き詰め（週罫線は廃止）、日別リストは日付タブ付き
          // の白カードとして独立させる。旧「下半分を白いMaterial面」構成は撤去。
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // 落としは**升目の上だけ**（月見出しとサマリは読めるまま・
            // FB 2026-08-27「スクリムはカレンダー部分だけに」）。
            // 覆いの枠は常に置いて中身だけ差し替える。枠を出し入れすると
            // TableCalendar の位置がずれて State ごと作り直される。
            child: Stack(children: [
            LayoutBuilder(builder: (context, box) {
              // セルは正方形・比率1（FB 2026-08-20）: 行高＝セル幅（幅/7）。
              // マージン(_kCellMargin)は四辺同値なので白カード自体も正方形になる。
              final cellSize = box.maxWidth / 7;
              return TableCalendar<int>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: dateTimeOfCivil(CivilDate(year, month, 1)),
            headerVisible: false,
            rowHeight: cellSize,
            // 前後月のはみ出しマスも空の白カードで埋める（モック2枚目）。
            calendarStyle: const CalendarStyle(outsideDaysVisible: true),
            // 曜日ヘッダは日本語（日月火水木金土）。日曜=薄赤 / 土曜=薄青。
            daysOfWeekHeight: 20,
            selectedDayPredicate: (d) => civilOfDateTime(d) == selected,
            onDaySelected: (sel, _) => ref
                .read(selectedDayProvider.notifier)
                .select(civilOfDateTime(sel)),
            onPageChanged: (focused) => ref
                .read(currentMonthProvider.notifier)
                .set(focused.year, focused.month),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final (label, color) = _dowLabelColor(day.weekday, l);
                return Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                );
              },
              // 数字を上・金額を下に分離（選択/今日の丸は数字だけを囲む小さめの丸）。
              defaultBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.normal, totals, incomes, ghosts, choreMarks, mf),
              todayBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.today, totals, incomes, ghosts, choreMarks, mf),
              selectedBuilder: (context, day, _) => _dayCell(context, day,
                  _DayStyle.selected, totals, incomes, ghosts, choreMarks, mf),
              outsideBuilder: (context, day, _) => Container(
                margin: _kCellMargin,
                decoration: _kCellDeco,
              ),
            ),
              );
            }),
            Positioned.fill(
              child: IgnorePointer(
                child: dimmed
                    ? ColoredBox(
                        key: const Key('calendar-dim'),
                        color: kPaper.withValues(alpha: 0.72),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            ]),
          ),
          // 凡例は家事ドットの分だけ。固定費の予定（ゴースト）はルールがある限り
          // 毎月出るため凡例が常時表示になっていた（「ずっと出てる」FB 2026-08-16）。
          // 意味は日別リストの「予定」バッジで伝わるので凡例からは外した。
          if (choreMarks.isNotEmpty)
            _CalendarLegend(hasChores: choreMarks.isNotEmpty),
          // ここはカードの**高さを測るためだけ**の空きスロット。場所は空けた
          // まま測り続けるので、カードを浮かせても基準の高さは変わらない。
          // カード本体は下のオーバーレイが常に描く（基準を測れるまでの初回
          // フレームだけここに出す）。
          Expanded(
            child: _DaySheetSlot(
              // キーボードで縦が縮んでいる間は測り直さない。縮んだ値で基準が
              // 上書きされると、書いている最中にカードが縮む。
              measure: !keyboard,
              child: baseHeight == null
                  ? _DaySection(day: selected)
                  : const SizedBox.expand(),
            ),
          ),
        ],
            );
        // ★Stack の子は「背景 / 覆い / カード」の3枠に固定してある。枠を状態
        // ごとに出し入れすると後ろの子の番号がずれ、Flutter はツリー上の位置で
        // State を同一視するので、カードの State ごと作り直されてフォーカスが
        // 落ちる（＝メモを書こうとするとキーボードが一瞬で引っ込む・2026-08-27）。
        // カード枠だけは基準の高さを測るまで無い＝初回フレームのみ2枠。以後は
        // どの状態でも3枠のまま動かさないこと。
        return SingleChildScrollView(
          // 逃がし先のスクロールは、本来の高さが画面に入りきらないときだけ
          //（小さい端末）。キーボード時はオーバーレイ側で受けるので使わない。
          physics: bodyHeight > outer.maxHeight
              ? null
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: bodyHeight,
            child: Stack(children: [
            // ①背景。本来の高さで組んでから切り取る（縦が足りなくても溢れない）。
            // 切り取りが要らないときも同じ形のまま置く（形が変わるとカレンダー
            // ごと作り直される）。通常時は OverflowBox も ClipRect も素通し。
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: math.max(outer.maxHeight, _kMinBodyHeight),
                child: backdrop,
              ),
            ),
            // ②浮いている間だけ効く「タップして戻る面」。背景のどこを押しても
            // 閉じてカレンダーに戻る（サマリや月見出しを押しても戻れるよう、
            // 面は全面のまま）。**落とす**のは升目の上だけなので、ここは
            // 透明で当たり判定だけを持つ。通常位置では中身を空にする。
            Positioned.fill(
              child: lifted
                  ? GestureDetector(
                      key: const Key('day-sheet-scrim'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // 先にフォーカスを外す。残したままだとキーボードだけ
                        // が出っぱなしで、カードが縮んで書けなくなる。
                        FocusManager.instance.primaryFocus?.unfocus();
                        ref.read(daySheetRaiseProvider.notifier).reset();
                      },
                      child: const SizedBox.expand(),
                    )
                  : const SizedBox.shrink(),
            ),
            // ③日別カード。**ここが唯一の置き場所**（上のスロットは高さを測る
            // ためだけの空箱）。浮いていないときは測った基準の高さそのままで、
            // スロットにぴったり重なる＝見た目は通常位置と同じ。
            // 浮いているときはカレンダーが2行ぶん見えるように残し、そこが
            // 「戻る」ためのタップ面になる。
            if (baseHeight != null)
              Positioned(
                key: const Key('day-sheet-card'),
                left: 0,
                right: 0,
                bottom: 0,
                height: lifted
                    ? math.min(baseHeight + raise,
                        bodyHeight - (keyboard ? 60 : _kMinBackdropHeight))
                    : baseHeight,
                // タブ行の帯は透明なので、紙色で塞がないと後ろのセルの数字が
                // タブの隙間から覗いて雑然とする。
                child: ColoredBox(
                  color: kPaper,
                  child: _DaySection(day: selected),
                ),
              ),
          ]),
          ),
        );
      }),
    );
  }
}

/// ドラッグで広げられる上限（この高さまでカードを伸ばせる）。
double _dragLimit(BuildContext context) =>
    MediaQuery.sizeOf(context).height - _kMinBackdropHeight;

/// 広げたときに上へ残す高さ（サマリ＋カレンダー数行ぶん）。
/// ここが「背景をタップして戻る」ための面になる。
const _kMinBackdropHeight = 150.0;

/// 通常位置での日別カードの高さを測って覚えるだけの入れ物。
/// レイアウト結果からしか分からないので、描画後に一度だけ書き戻す。
///
/// [measure] が false の間は測らない。キーボードで縦が縮んでいるときの値を
/// 覚えてしまうと、基準がずれて書いている最中にカードが縮む（2026-08-27）。
class _DaySheetSlot extends ConsumerWidget {
  final Widget child;
  final bool measure;
  const _DaySheetSlot({required this.measure, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight;
        if (measure && h.isFinite && h > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(daySheetBaseHeightProvider.notifier).set(h);
          });
        }
        return child;
      });
}

/// カレンダー画面が成立する最低の本体高さ。これ未満（キーボード表示中など）は
/// スクロールに切り替える。iPhone縦持ちの通常時はこれを上回る。
const _kMinBodyHeight = 640.0;

/// 日別リストのカード（画像1枚目参考・フラット近似）:
/// 選択日タブと「つきいち」タブ（FB 2026-08-20）で内容を切り替え、
/// 右端の「家計簿を入力」から選択日既定で入力画面へ。
class _DaySection extends ConsumerWidget {
  final CivilDate day;
  const _DaySection({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat.MMMEd(tag).format(dateTimeOfCivil(day));
    final fill = context.kakeiboPalette.fill;
    final tab = ref.watch(dayTabProvider);

    Widget tabButton({
      required Key key,
      required String text,
      required bool selected,
      required VoidCallback onTap,
    }) =>
        InkWell(
          key: key,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? fill : context.kakeiboPalette.soft,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : kMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タブ行を上へドラッグするとカードが広がる（FB 2026-08-27）。
          // タップ＝タブ切り替え / 縦ドラッグ＝広げる、で役割を分ける。
          GestureDetector(
            key: const Key('day-sheet-drag'),
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (d) {
              final base = ref.read(daySheetBaseHeightProvider);
              if (base == null) return;
              final max = math.max(0.0, _dragLimit(context) - base);
              final next = ref.read(daySheetRaiseProvider) - d.delta.dy;
              ref
                  .read(daySheetRaiseProvider.notifier)
                  .set(next.clamp(0.0, max));
            },
            onVerticalDragEnd: (_) {
              // わずかな指のブレで中途半端に浮いたままにしない。
              if (ref.read(daySheetRaiseProvider) < 24) {
                ref.read(daySheetRaiseProvider.notifier).reset();
              }
            },
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ボタンのラベルは切らず、幅が足りないときはタブ側だけ縮む
              //（Flexibleの均等割り上限で日本語まで省略される罠の回避）。
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 3タブとも Flexible（冗長ロケールでも溢れず縮むだけ）。
                    // flex はラベル長の比（日付 8月23日(日) > つきいち > メモ）。
                    // 均等割だと幅が余っていても短タブ側から切れるための重み付け。
                    // 日付・つきいちは**カードの高さを変えない**（メモを開いた
                    // まま中身だけ切り替えられるように・FB 2026-08-27）。
                    Flexible(
                      flex: 4,
                      child: tabButton(
                        key: const Key('day-tab-label'),
                        text: label,
                        selected: tab == DayTab.day,
                        onTap: () =>
                            ref.read(dayTabProvider.notifier).select(DayTab.day),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 3,
                      child: tabButton(
                        key: const Key('day-tab-chores'),
                        text: l.calendarChoreTab,
                        selected: tab == DayTab.chores,
                        onTap: () => ref
                            .read(dayTabProvider.notifier)
                            .select(DayTab.chores),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 買い物メモ。タブを押しただけでは位置は変えず、
                    // メモ欄をタップして書き始めたときにせり上がる
                    //（FB 2026-08-27）。
                    Flexible(
                      flex: 2,
                      child: tabButton(
                        key: const Key('day-tab-memo'),
                        text: l.calendarMemoTab,
                        selected: tab == DayTab.memo,
                        onTap: () => ref
                            .read(dayTabProvider.notifier)
                            .select(DayTab.memo),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 旧FABの後継。「＋だけでは分かりづらい」FBでラベル付きに。
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: FilledButton.icon(
                  key: const Key('fab-entry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: fill,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l.homeFabEntryLabel,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () {
                    ref
                        .read(entryFormControllerProvider.notifier)
                        .startCreate(day);
                    ref
                        .read(homeTabIndexProvider.notifier)
                        .set(kInputTabIndex);
                  },
                ),
              ),
            ],
            ),
          ),
          Expanded(
            // Material にして白カード自体をインク波紋の面にする（旧構成と同じ理由）。
            child: Material(
              color: kCard,
              clipBehavior: Clip.antiAlias,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                side: BorderSide(color: kLine, width: 0.8),
              ),
              child: SizedBox(
                width: double.infinity,
                child: switch (tab) {
                  DayTab.day => DayTransactionList(day: day),
                  DayTab.chores => _ChoreDayList(day: day),
                  DayTab.memo => const ShoppingMemoPad(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「つきいち」タブの中身: その日の実施記録・期日行（やったボタン付き）。
/// 行の実装は日別リストに埋まっていた buildChoreDayRows をそのまま使う。
class _ChoreDayList extends ConsumerWidget {
  final CivilDate day;
  const _ChoreDayList({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = buildChoreDayRows(context, ref, day);
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.calendarChoreTabEmpty,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(children: rows);
  }
}

/// 家事ドットの凡例（該当があるときだけ表示）。
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.hasChores});

  final bool hasChores;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget item(Color color, String label, {bool outlined = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: outlined ? null : color,
                border: outlined ? Border.all(color: color, width: 1.2) : null,
              ),
            ),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: muted)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Wrap(
        spacing: 12,
        children: [
          if (hasChores) ...[
            item(_kDotDue, l.calendarLegendChoreDue),
            item(_kDotOverdue, l.calendarLegendChoreOverdue),
            item(_kDotDone, l.calendarLegendChoreDone),
          ],
        ],
      ),
    );
  }
}

/// 曜日ヘッダの日本語ラベルと色（日曜=薄赤 / 土曜=薄青 / 平日=既定）。
(String, Color?) _dowLabelColor(int weekday, AppLocalizations l) =>
    switch (weekday) {
      DateTime.sunday => (l.calendarWeekdaySun, kSunday),
      DateTime.monday => (l.calendarWeekdayMon, null),
      DateTime.tuesday => (l.calendarWeekdayTue, null),
      DateTime.wednesday => (l.calendarWeekdayWed, null),
      DateTime.thursday => (l.calendarWeekdayThu, null),
      DateTime.friday => (l.calendarWeekdayFri, null),
      _ => (l.calendarWeekdaySat, kSaturday),
    };

enum _DayStyle { normal, selected, today }

/// 日セルの白カード（画像2枚目参考: 罫線ではなく角丸カードを敷き詰める）。
const _kCellMargin = EdgeInsets.all(1.5);
const _kCellDeco = BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.all(Radius.circular(9)),
  boxShadow: [
    BoxShadow(color: Color(0x0D2F3A3D), blurRadius: 3, offset: Offset(0, 1)),
  ],
);

// 家事ドットの色（やった=収入グリーン / 期日=注意アンバー / 超過=支出コーラル）。
const _kDotDone = kIncome;
const _kDotDue = kAttention;
const _kDotOverdue = kExpense;

/// カレンダーの1日セル。数字→家事ドット→支出額→予定額（グレー）の縦積み。
Widget _dayCell(
  BuildContext context,
  DateTime day,
  _DayStyle style,
  Map<CivilDate, int> totals,
  Map<CivilDate, int> incomes,
  Map<CivilDate, int> ghosts,
  Map<CivilDate, ChoreDayMarks> choreMarks,
  MoneyFormatter mf,
) {
  final civil = civilOfDateTime(day);
  final total = totals[civil] ?? 0;
  final income = incomes[civil] ?? 0;
  final ghost = ghosts[civil] ?? 0;
  final marks = choreMarks[civil];
  BoxDecoration? deco;
  var numColor = kInk;
  var weight = FontWeight.w400;
  // 選択/今日のリング色（数字に被らないよう小さめの丸で数字だけを囲む）。
  // 選択=主色塗り＋白数字、今日=主色の輪郭。カスタムテーマに追従させるため
  // 定数ではなくパレットから取る。
  final ring = context.kakeiboPalette.fill;
  switch (style) {
    case _DayStyle.selected:
      deco = BoxDecoration(color: ring, shape: BoxShape.circle);
      numColor = Colors.white;
      weight = FontWeight.w600;
    case _DayStyle.today:
      deco = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 1.6),
      );
      weight = FontWeight.w700;
    case _DayStyle.normal:
      break;
  }
  final iso = civil.toIso();
  // 縦の予算はセル幅-マージン3（SE級の375px幅で約48）。
  // 日付2+20 + ドット4 + 実績額11 + 予定額11 = 48 に収める。
  return Container(
    margin: _kCellMargin,
    decoration: _kCellDeco,
    // alignment を指定して白カードをセル一杯に広げる（無指定だと中身の
    // 高さに縮んで正方形にならない）。
    alignment: Alignment.topCenter,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 日付はセルの左上・金額は右揃え（FB 2026-08-20）
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 3, top: 2),
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: deco,
              child: Text(
                '${day.day}',
                style: TextStyle(
                    fontSize: 11, color: numColor, fontWeight: weight),
              ),
            ),
          ),
        ),
        if (marks != null)
          SizedBox(
            height: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (marks.doneTaskIds.isNotEmpty)
                  _dot(_kDotDone, Key('chore-dot-done-$iso')),
                if (marks.dueTaskIds.isNotEmpty)
                  _dot(
                    marks.hasOverdue ? _kDotOverdue : _kDotDue,
                    Key(marks.hasOverdue
                        ? 'chore-dot-overdue-$iso'
                        : 'chore-dot-due-$iso'),
                  ),
              ],
            ),
          ),
        // 金額レーン: 支出（−赤）→ 収入（+緑）→ 予定（グレー）の優先順で
        // 最大2行（正方形セルの縦予算のため。3つ重なる日は予定を省く）。
        ...[
          if (total > 0)
            _cellAmount('-${mf.compact(total)}',
                context.kakeiboColors.expense),
          if (income > 0)
            _cellAmount('+${mf.compact(income)}',
                context.kakeiboColors.income),
          // まだ起票されていない固定費・収入（予定）。グレーで実績と区別する。
          if (ghost != 0)
            _cellAmount(mf.compact(ghost.abs()), kMuted,
                key: Key('ghost-amount-$iso')),
        ].take(2),
      ],
    ),
  );
}

/// セル内の金額1行（右揃え・9pt）。
Widget _cellAmount(String text, Color color, {Key? key}) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Text(
          text,
          key: key,
          style: TextStyle(
            fontSize: 9,
            height: 1.15,
            fontFeatures: kTabularFigures,
            color: color,
          ),
        ),
      ),
    );

Widget _dot(Color color, Key key) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        key: key,
        width: 4,
        height: 4,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );

class _MonthHeader extends ConsumerWidget {
  final int year;
  final int month;
  const _MonthHeader({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('prev-month'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(currentMonthProvider.notifier).prev(),
          ),
          Expanded(
            child: Center(
              child: Text(
                l.calendarMonthYearHeader(year, month),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontFamily: kLedgerFontFamily),
              ),
            ),
          ),
          IconButton(
            key: const Key('next-month'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(currentMonthProvider.notifier).next(),
          ),
        ],
      ),
    );
  }
}

/// 月サマリのカード（画像1枚目参考・フラット近似）:
/// 支出/収入/差引の3カラム＋見込み収支の行。見込み収支のタップで
/// 基準日（月末/毎月N日）を変更できるのは従来のまま。
class _SummaryCard extends ConsumerWidget {
  final int year;
  final int month;
  final MonthlySummary summary;
  const _SummaryCard({
    required this.year,
    required this.month,
    required this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mf = ref.watch(moneyFormatterProvider);
    final net = summary.net;
    final netLabel = mf.net(net);
    final forecast = ref.watch(monthForecastProvider((year, month)));
    final colors = context.kakeiboColors;
    // 毎月の予算（設定でオンオフ・毎月共通の1金額・2026-08-23要望）。
    // 残り = 予算 − このカードの「支出」。同じカード上の数字で引き算が
    // 成り立つので、ユーザーが見て検算できる（支出の定義は上の列と同じ）。
    final settings = ref.watch(appSettingsProvider);
    final budget = settings.budgetEnabled && settings.monthlyBudgetMinor > 0
        ? settings.monthlyBudgetMinor
        : null;
    // 現金主義なら見出しは「支払い」（引き落とし日で数えている、の意）。
    // 歯車は支払い区分モードON のときだけ出す（切り替える意味があるのはそのときだけ）。
    final cashBasis = settings.summaryUsesCashBasis;
    final expenseLabel =
        cashBasis ? l.summaryPaymentLabel : l.summaryExpenseLabel;

    Widget col(String label, String value, Color valueColor) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kMuted, fontFamily: kLedgerFontFamily)),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  fontFamily: kLedgerFontFamily,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
        );

    Widget vLine() => Container(width: 0.6, height: 40, color: kLine);

    final card = Container(
      key: const Key('month-summary-card'),
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            // 縦幅は広めに（「金額の場所が狭い」FB 2026-08-20）。
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                col(expenseLabel, mf.format(summary.expense),
                    colors.expense),
                vLine(),
                col(l.summaryIncomeLabel, mf.format(summary.income),
                    colors.income),
                vLine(),
                col(
                    l.summaryNetLabel,
                    netLabel,
                    net < 0
                        ? colors.expense
                        : Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          if (budget != null)
            _summaryLine(
              context,
              key: const Key('budget-line'),
              label: l.budgetRemainingLabel,
              // 残高なので＋は付けない（付くのは差引・見込みの符号表示だけ）。
              // 使いすぎのマイナスは format 側が−を付ける。
              value: mf.format(budget - summary.expense),
              negative: budget - summary.expense < 0,
              colors: colors,
            ),
          // 見込み収支 = 月全体の起票済み差引＋月末までの未起票予定。過去月は出ない。
          // （上の差引=今日まで実績とは定義が違う: 分割払いの将来回はこちらに入る）
          // 基準日（毎月N日）切り替えは「不要」FB（2026-08-20）で撤去し常に月末。
          if (forecast != null)
            _summaryLine(
              context,
              key: const Key('forecast-line'),
              label: l.forecastLabelMonthEnd,
              value: mf.net(forecast.forecast),
              negative: forecast.forecast < 0,
              colors: colors,
            ),
        ],
      ),
    );
    // 上部サマリまわりの設定（計算方法・予算）の入口。設定画面まで行かずに
    // ここで変えられるようにする（見ている数字のすぐ横が一番わかりやすい・
    // 2026-08-27要望）。キーは旧名のまま（数え方専用だった名残）。
    return Stack(
      children: [
        card,
        Positioned(
          top: 4,
          right: 16,
          child: InkWell(
            key: const Key('summary-basis-gear'),
            customBorder: const CircleBorder(),
            onTap: () => _openSummarySettings(
                context, ref, cashBasis, settings.paymentModeEnabled),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.settings, size: 16, color: kMuted),
            ),
          ),
        ),
      ],
    );
  }

  /// 歯車の中身。計算方法（支払い区分モードのときだけ）と予算を並べる。
  Future<void> _openSummarySettings(
    BuildContext context,
    WidgetRef ref,
    bool cashBasis,
    bool paymentMode,
  ) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<_SummarySetting>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 計算方法は支払い区分モードのときだけ意味を持つ（カード払いを
            // 未払金として持つかどうかの話なので）。
            if (paymentMode)
              ListTile(
                key: const Key('summary-gear-basis'),
                leading: const Icon(Icons.calculate_outlined),
                title: Text(l.summaryBasisTitle),
                onTap: () => Navigator.pop(ctx, _SummarySetting.basis),
              ),
            ListTile(
              key: const Key('summary-gear-budget'),
              leading: const Icon(Icons.savings_outlined),
              title: Text(l.summaryGearBudget),
              onTap: () => Navigator.pop(ctx, _SummarySetting.budget),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    switch (picked) {
      case _SummarySetting.basis:
        await _pickSummaryBasis(context, ref, cashBasis);
      case _SummarySetting.budget:
        await _editBudget(context);
    }
  }

  /// 予算のオンオフと金額。設定画面の同じ2行をここにも出す
  ///（金額のダイアログは budget_amount_dialog.dart で共有）。
  Future<void> _editBudget(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Consumer(builder: (ctx, ref, _) {
            final l = AppLocalizations.of(ctx);
            final settings = ref.watch(appSettingsProvider);
            final currency = ref.watch(currencyProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  key: const Key('summary-budget-switch'),
                  secondary: const Icon(Icons.savings_outlined),
                  title: Text(l.settingsBudgetTitle),
                  subtitle: Text(l.settingsBudgetSubtitle),
                  value: settings.budgetEnabled,
                  onChanged: (v) => ref
                      .read(appSettingsProvider.notifier)
                      .setBudgetEnabled(v),
                ),
                if (settings.budgetEnabled)
                  ListTile(
                    key: const Key('summary-budget-amount-tile'),
                    contentPadding:
                        const EdgeInsets.only(left: 72, right: 16),
                    title: Text(l.settingsBudgetAmountTitle),
                    trailing: Text(
                      ref
                          .watch(moneyFormatterProvider)
                          .format(settings.monthlyBudgetMinor),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    onTap: () =>
                        editMonthlyBudget(ctx, ref, settings, currency),
                  ),
              ],
            );
          }),
        ),
      );

  Future<void> _pickSummaryBasis(
      BuildContext context, WidgetRef ref, bool cashBasis) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l.summaryBasisTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            // RadioListTile の onChanged は非推奨（RadioGroup へ移行中）。
            // 選んだ瞬間に閉じるだけなので ListTile ＋チェックで足りる。
            ListTile(
              key: const Key('summary-basis-cash'),
              leading: Icon(cashBasis ? Icons.check : null, size: 20),
              title: Text(l.summaryBasisCashOption),
              selected: cashBasis,
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              key: const Key('summary-basis-accrual'),
              leading: Icon(cashBasis ? null : Icons.check, size: 20),
              title: Text(l.summaryBasisAccrualOption),
              selected: !cashBasis,
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await ref.read(appSettingsProvider.notifier).setSummaryBasisCash(picked);
  }

  /// 3カラムの下に積むラベル＋金額の行（予算の残り・見込み収支で共用）。
  Widget _summaryLine(
    BuildContext context, {
    required Key key,
    required String label,
    required String value,
    required bool negative,
    required KakeiboColors colors,
  }) =>
      Column(
        children: [
          const Divider(height: 1, color: kLine),
          Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontFamily: kLedgerFontFamily),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: kLedgerFontFamily,
                    fontFeatures: kTabularFigures,
                    color: negative
                        ? colors.expense
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

/// 上部サマリの歯車から開ける設定。
enum _SummarySetting { basis, budget }
