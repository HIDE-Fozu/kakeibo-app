import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/receipt/receipt_parser.dart';
import '../../settings/application/settings_controller.dart';
import 'split_calc.dart';

enum EntryMode { create, receiptConfirm, edit }

/// 詳細入力（分割）の1行。合計をカテゴリ別に分けて複数取引として保存する。
/// 税は2軸: taxIncluded(税込/税抜) と rate(8/10)。税抜なら rate を乗せ、
/// 税込ならそのまま（rateは記録のみ）。
class SplitLine {
  final String expr; // 電卓式（evalCalcExpr が評価。空=残額行/未入力）
  final bool taxIncluded; // true=税込(そのまま) / false=税抜(rateを乗せる・切り捨て)
  final int rate; // 8 / 10（税抜時に適用。税込時は記録のみ）
  final bool taxTouched; // 手で税を変えたか（カテゴリ自動で上書きしないため）
  final int? categoryId;
  const SplitLine({
    this.expr = '',
    this.taxIncluded = false,
    this.rate = 10,
    this.taxTouched = false,
    this.categoryId,
  });

  SplitLine copyWith({
    String? expr,
    bool? taxIncluded,
    int? rate,
    bool? taxTouched,
    int? categoryId,
  }) =>
      SplitLine(
        expr: expr ?? this.expr,
        taxIncluded: taxIncluded ?? this.taxIncluded,
        rate: rate ?? this.rate,
        taxTouched: taxTouched ?? this.taxTouched,
        categoryId: categoryId ?? this.categoryId,
      );

  /// 入力額（生の値・税抜/税込どちらでも）。式が空/不正なら null。
  int? get enteredYen => evalCalcExpr(expr);

  /// 合計に効く税込値。税込ならそのまま、税抜なら rate を乗せる（切り捨て）。
  int? get amountYen {
    final v = evalCalcExpr(expr);
    if (v == null) return null;
    return taxIncluded ? v : applyTax(v, rate);
  }
}

/// 一括内訳の1品目（OCR明細行＋割り当て状態）。
class BatchItem {
  final ReceiptItem item;
  final int? categoryId; // null=未割当
  final int? taxOverride; // null=ヘッダ既定に従う / 0,8,10=行上書き
  final bool selected; // D1（選んで割当）のチェック
  const BatchItem({
    required this.item,
    this.categoryId,
    this.taxOverride,
    this.selected = false,
  });

  static const _unset = Object();
  BatchItem copyWith({
    Object? categoryId = _unset,
    Object? taxOverride = _unset,
    bool? selected,
  }) =>
      BatchItem(
        item: item,
        categoryId:
            identical(categoryId, _unset) ? this.categoryId : categoryId as int?,
        taxOverride: identical(taxOverride, _unset)
            ? this.taxOverride
            : taxOverride as int?,
        selected: selected ?? this.selected,
      );
}

class EntryFormState {
  final EntryMode mode;
  final int? editingId;
  final TxnType type;
  final int amountYen;
  final int? categoryId;
  final CivilDate date;
  final String storeName; // 店舗名（memoとは別。空=未設定）
  final String memo; // 自由記述の詳細メモ
  final TxnSource source;
  final ParsedReceipt? receipt;
  final String? imagePath;
  final bool memoExpanded;

  /// 内訳チップ列を開いている親カテゴリ（null=閉）。選択とは独立。
  final int? expandedParentId;

  /// 詳細入力（分割）の行。null=通常モード。amountYen が分割対象の合計。
  final List<SplitLine>? splits;
  final int activeSplitIndex;

  /// 一括内訳モード（OCR明細ベース）。null=非表示。amountYen が対象の合計。
  final List<BatchItem>? batchItems;
  final int batchHeaderTax; // レシート単位の税方式: 0=内税 / 8 / 10
  final bool batchPaintMode; // false=D1選んで割当 / true=D2塗り分け
  final int? batchPaintCategoryId; // D2で塗るカテゴリ
  final int? batchDiffCategoryId; // 差額行のカテゴリ（null=未設定）

  /// グループの開き直し編集: 保存時に置換削除する既存取引と再利用するgroupId。
  final List<int>? replacesTxIds;
  final String? reuseSplitGroupId;

  /// このフォームの元になったOCRフィクスチャ（保存時に正解ラベルを書き戻す）。
  final String? fixturePath;

  /// フォーム世代。start*/saveAndContinueごとに増える。
  /// 常時表示のメモ欄をリセットするためのwidget keyに使う。
  final int formSeq;

  const EntryFormState({
    required this.mode,
    this.editingId,
    required this.type,
    required this.amountYen,
    this.categoryId,
    required this.date,
    this.storeName = '',
    required this.memo,
    required this.source,
    this.receipt,
    this.imagePath,
    this.memoExpanded = false,
    this.expandedParentId,
    this.splits,
    this.activeSplitIndex = 0,
    this.batchItems,
    this.batchHeaderTax = 0,
    this.batchPaintMode = false,
    this.batchPaintCategoryId,
    this.batchDiffCategoryId,
    this.replacesTxIds,
    this.reuseSplitGroupId,
    this.fixturePath,
    this.formSeq = 0,
  });

  bool get canSave => batchItems != null
      ? _batchValid
      : splits != null
          ? _splitsValid
          : amountYen > 0 && categoryId != null;

  /// 保存できない理由（canSave=false時）。null=理由なし。UIのヒント表示に使う。
  String? get saveHint {
    if (canSave) return null;
    if (amountYen <= 0) return '金額を入力してください';
    if (batchItems != null) {
      if (batchGroups.isEmpty) return '品目にカテゴリを割り当ててください';
      if (batchDiff < 0) return '割り当てが合計を超えています';
      if (batchDiff > 0 && batchDiffCategoryId == null) {
        return '差額のカテゴリを選んでください';
      }
      return null;
    }
    if (splits != null) {
      if (splitRemainder < 0) return '内訳が合計を超えています';
      for (var i = 0; i < splits!.length; i++) {
        final a = splitLineAmount(i);
        if (a != null && a > 0 && splits![i].categoryId == null) {
          return 'カテゴリを選んでください';
        }
      }
      if (splitFixedSum <= 0) return '金額とカテゴリを入力してください';
      // 金額はあるが合計に届かない（残りの行を追加/入力）
      if (splitRemainder > 0) return '残りの金額も入力してください';
      return '金額とカテゴリを入力してください';
    }
    if (categoryId == null) return 'カテゴリを選んでください';
    return null;
  }

  // --- 一括内訳の導出 ---

  /// 行の実効税率: 上書き > (※マーク かつ ヘッダ外税10% → 8%) > ヘッダ。
  int batchItemTax(BatchItem b) =>
      b.taxOverride ??
      (b.item.reducedTaxMark && batchHeaderTax == 10 ? 8 : batchHeaderTax);

  /// 行の税適用後金額。
  int batchItemAmount(BatchItem b) => applyTax(b.item.yen, batchItemTax(b));

  /// カテゴリ→金額の集約（割当順）。
  Map<int, int> get batchGroups {
    final out = <int, int>{};
    for (final b in batchItems ?? const <BatchItem>[]) {
      final cat = b.categoryId;
      if (cat == null) continue;
      out[cat] = (out[cat] ?? 0) + batchItemAmount(b);
    }
    return out;
  }

  /// 差額 = レシート合計 − 割当済み合計。正なら差額行が担う。負=割り過ぎ。
  int get batchDiff =>
      amountYen - batchGroups.values.fold(0, (a, v) => a + v);

  bool get _batchValid {
    if (amountYen <= 0) return false;
    final groups = batchGroups;
    if (groups.isEmpty) return false;
    final diff = batchDiff;
    if (diff < 0) return false; // 割当がレシート合計を超えている
    if (diff > 0 && batchDiffCategoryId == null) return false;
    return true;
  }

  /// D1で選択中の品目index。
  List<int> get batchSelectedIndexes => [
        for (final (i, b) in (batchItems ?? const <BatchItem>[]).indexed)
          if (b.selected) i
      ];

  /// 式あり行の金額合計（不正行は0扱い＝保存不可側で検出される）。
  int get splitFixedSum =>
      (splits ?? const []).fold(0, (a, l) => a + (l.amountYen ?? 0));

  /// 残額（合計 − 式あり行合計）。末尾の空行がこれを担う。マイナス=入れ過ぎ。
  int get splitRemainder => amountYen - splitFixedSum;

  /// 行の実効金額。空の式は「末尾の行だけ」残額を自動で担う。ただし1件も
  /// 手入力が無いうち（＝先頭行だけの初期状態）は自動額を入れない。残額は
  /// 「ユーザーが1行目を入れて初めて2行目以降に現れる」。他の空/不正行は null。
  int? splitLineAmount(int i) {
    final lines = splits!;
    final l = lines[i];
    if (l.expr.isEmpty) {
      final hasFilled = lines.any((x) =>
          x.expr.isNotEmpty && (x.amountYen ?? 0) > 0);
      return (i == lines.length - 1 && hasFilled && splitRemainder > 0)
          ? splitRemainder
          : null;
    }
    return l.amountYen;
  }

  bool get _splitsValid {
    final lines = splits;
    if (lines == null || amountYen <= 0) return false;
    var sum = 0;
    var count = 0;
    for (var i = 0; i < lines.length; i++) {
      final a = splitLineAmount(i);
      if (a == null) continue; // 空の行は無視（2行開始や「追加」の空枠）
      if (a <= 0 || lines[i].categoryId == null) return false; // 金額ありでカテゴリ無し
      sum += a;
      count++;
    }
    return count > 0 && sum == amountYen;
  }

  AmountCandidate? get matchedTotalCandidate {
    final r = receipt;
    if (r == null) return null;
    for (final cand in r.totalCandidates) {
      if (cand.yen == amountYen) return cand;
    }
    return null;
  }

  DateCandidate? get matchedDateCandidate {
    final r = receipt;
    if (r == null) return null;
    for (final cand in r.dateCandidates) {
      if (cand.date == date) return cand;
    }
    return null;
  }

  static const _unset = Object();

  EntryFormState copyWith({
    EntryMode? mode,
    Object? editingId = _unset,
    TxnType? type,
    int? amountYen,
    Object? categoryId = _unset,
    CivilDate? date,
    String? storeName,
    String? memo,
    TxnSource? source,
    Object? receipt = _unset,
    Object? imagePath = _unset,
    bool? memoExpanded,
    Object? expandedParentId = _unset,
    Object? splits = _unset,
    int? activeSplitIndex,
    Object? batchItems = _unset,
    int? batchHeaderTax,
    bool? batchPaintMode,
    Object? batchPaintCategoryId = _unset,
    Object? batchDiffCategoryId = _unset,
    Object? replacesTxIds = _unset,
    Object? reuseSplitGroupId = _unset,
    Object? fixturePath = _unset,
    int? formSeq,
  }) =>
      EntryFormState(
        formSeq: formSeq ?? this.formSeq,
        mode: mode ?? this.mode,
        editingId:
            identical(editingId, _unset) ? this.editingId : editingId as int?,
        type: type ?? this.type,
        amountYen: amountYen ?? this.amountYen,
        categoryId:
            identical(categoryId, _unset) ? this.categoryId : categoryId as int?,
        date: date ?? this.date,
        storeName: storeName ?? this.storeName,
        memo: memo ?? this.memo,
        source: source ?? this.source,
        receipt: identical(receipt, _unset)
            ? this.receipt
            : receipt as ParsedReceipt?,
        imagePath:
            identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
        memoExpanded: memoExpanded ?? this.memoExpanded,
        expandedParentId: identical(expandedParentId, _unset)
            ? this.expandedParentId
            : expandedParentId as int?,
        splits: identical(splits, _unset)
            ? this.splits
            : splits as List<SplitLine>?,
        activeSplitIndex: activeSplitIndex ?? this.activeSplitIndex,
        batchItems: identical(batchItems, _unset)
            ? this.batchItems
            : batchItems as List<BatchItem>?,
        batchHeaderTax: batchHeaderTax ?? this.batchHeaderTax,
        batchPaintMode: batchPaintMode ?? this.batchPaintMode,
        batchPaintCategoryId: identical(batchPaintCategoryId, _unset)
            ? this.batchPaintCategoryId
            : batchPaintCategoryId as int?,
        batchDiffCategoryId: identical(batchDiffCategoryId, _unset)
            ? this.batchDiffCategoryId
            : batchDiffCategoryId as int?,
        replacesTxIds: identical(replacesTxIds, _unset)
            ? this.replacesTxIds
            : replacesTxIds as List<int>?,
        reuseSplitGroupId: identical(reuseSplitGroupId, _unset)
            ? this.reuseSplitGroupId
            : reuseSplitGroupId as String?,
        fixturePath: identical(fixturePath, _unset)
            ? this.fixturePath
            : fixturePath as String?,
      );
}

/// 入力フォームの状態機械。keepAlive（非autoDispose）: 画面push前のstart*()と
/// 画面buildの間で破棄されないようにする（画面は同時に1つしか開かない前提）。
class EntryFormController extends Notifier<EntryFormState?> {
  static const int maxAmount = 9999999;

  int _seq = 0;

  @override
  EntryFormState? build() => null;

  void startCreate(CivilDate date) {
    state = EntryFormState(
      formSeq: ++_seq,
      mode: EntryMode.create,
      type: TxnType.expense,
      amountYen: 0,
      date: date,
      memo: '',
      source: TxnSource.manual,
    );
  }

  void startEdit(TransactionEntity tx) {
    state = EntryFormState(
      formSeq: ++_seq,
      mode: EntryMode.edit,
      editingId: tx.id,
      type: tx.type,
      amountYen: tx.amountYen,
      categoryId: tx.categoryId,
      date: tx.date,
      storeName: tx.storeName ?? '',
      memo: tx.memo ?? '',
      source: tx.source,
      imagePath: tx.imagePath,
      memoExpanded: (tx.memo ?? '').isNotEmpty,
    );
  }

  void startReceipt(ParsedReceipt parsed,
      {String? imagePath, String? fixturePath}) {
    state = EntryFormState(
      formSeq: ++_seq,
      mode: EntryMode.receiptConfirm,
      type: TxnType.expense,
      amountYen: parsed.total?.yen ?? 0,
      date: parsed.date.date,
      // 店名が読めていれば店舗名にプリフィル（候補チップ/直接入力で修正可）。
      // 詳細メモは空のまま（店名と詳細を混ぜない）。
      storeName: parsed.storeName ?? '',
      memo: '',
      source: TxnSource.receiptOcr,
      receipt: parsed,
      imagePath: imagePath,
      fixturePath: fixturePath,
    );
  }

  EntryFormState get _s => state!;

  void tapDigit(int digit) {
    assert(digit >= 0 && digit <= 9);
    final next = _s.amountYen * 10 + digit;
    if (next > maxAmount) return;
    state = _s.copyWith(amountYen: next);
  }

  void tapDoubleZero() {
    if (_s.amountYen == 0) return;
    final next = _s.amountYen * 100;
    if (next > maxAmount) return;
    state = _s.copyWith(amountYen: next);
  }

  void backspace() => state = _s.copyWith(amountYen: _s.amountYen ~/ 10);

  void setType(TxnType type) {
    // 編集では型不変: updateFieldsはtypeを書かないため、許すと型/カテゴリdesyncが
    // 永続化する（spec §4.3の不変条件を破る）
    if (_s.mode == EntryMode.edit) return;
    if (type == _s.type) return;
    // 候補再フィルタ＋選択クリア＋チップ列も閉じる
    state = _s.copyWith(type: type, categoryId: null, expandedParentId: null);
  }

  void selectCategory(int categoryId) =>
      state = _s.copyWith(categoryId: categoryId);

  /// カテゴリボタンのタップ。isSameGroup=タップした親が現在の選択の属する
  /// グループと同じ（判定はグリッド側がカテゴリツリーから行う）。
  /// - 別グループ: 選択を切り替え、内訳があればチップ列を開く
  /// - 同グループ&内訳あり: チップ列の開閉のみ（選択は維持=モック確定挙動）
  void tapCategory({
    required int categoryId,
    required bool hasSubs,
    required bool isSameGroup,
  }) {
    if (isSameGroup && hasSubs) {
      state = _s.copyWith(
          expandedParentId: _s.expandedParentId == null ? categoryId : null);
      return;
    }
    // 一括内訳モード: D1=選択中の品目へ割当 / D2=塗るカテゴリを切替
    if (_s.batchItems != null) {
      _batchAssignCategory(categoryId,
          expandedParentId: hasSubs ? categoryId : null);
      return;
    }
    // 分割モード中はアクティブ行のカテゴリに書く（食費=8%等を自動適用）
    if (_s.splits != null) {
      _updateActiveSplit((l) => _withSplitCategory(l, categoryId),
          expandedParentId: hasSubs ? categoryId : null);
      return;
    }
    state = _s.copyWith(
      categoryId: categoryId,
      expandedParentId: hasSubs ? categoryId : null,
    );
  }

  /// 内訳チップのタップ。選択中チップの再タップは親（チップ列の親）に戻す。
  /// どちらの場合もチップ列は格納する（テンキーに被せたオーバーレイを閉じる）。
  void toggleSubcategory(int subId) {
    final parent = _s.expandedParentId;
    if (parent == null) return; // チップ列が閉じているときは呼ばれない
    if (_s.batchItems != null) {
      if (_s.batchPaintMode) {
        state = _s.copyWith(
          batchPaintCategoryId:
              _s.batchPaintCategoryId == subId ? parent : subId,
          expandedParentId: null,
        );
      } else {
        // 直前に割り当てた品目群を内訳へ差し替え（親タップ→チップの自然な流れ）
        final items = [..._s.batchItems!];
        for (final i in _lastBatchAssigned) {
          items[i] = items[i].copyWith(
              categoryId: items[i].categoryId == subId ? parent : subId);
        }
        state = _s.copyWith(batchItems: items, expandedParentId: null);
      }
      return;
    }
    if (_s.splits != null) {
      _updateActiveSplit(
          (l) => _withSplitCategory(l, l.categoryId == subId ? parent : subId),
          expandedParentId: null);
      return;
    }
    state = _s.copyWith(
      categoryId: _s.categoryId == subId ? parent : subId,
      expandedParentId: null,
    );
  }

  // --- 一括内訳（OCR明細ベース）。品目を束ねてカテゴリ割当→複数取引で保存 ---

  /// D1=選んで割当（既定）/ D2=塗り分け。UIの切替で両方試せる。
  void startBatchItemize() {
    final r = _s.receipt;
    if (r == null ||
        r.itemLines.isEmpty ||
        _s.amountYen <= 0 ||
        _s.mode == EntryMode.edit ||
        _s.batchItems != null) {
      return;
    }
    _lastBatchAssigned = const [];
    state = _s.copyWith(
      batchItems: [for (final it in r.itemLines) BatchItem(item: it)],
      batchHeaderTax: 0,
      batchPaintMode: false,
      batchPaintCategoryId: null,
      batchDiffCategoryId: null,
      splits: null,
      expandedParentId: null,
    );
  }

  void cancelBatchItemize() => state = _s.copyWith(
        batchItems: null,
        batchPaintCategoryId: null,
        batchDiffCategoryId: null,
      );

  void setBatchHeaderTax(int percent) {
    assert(percent == 0 || percent == 8 || percent == 10);
    state = _s.copyWith(batchHeaderTax: percent);
  }

  /// 行の%チップ: 同じ%を再タップでヘッダ既定に戻す。
  void setBatchItemTax(int index, int percent) {
    assert(percent == 8 || percent == 10);
    final items = [..._s.batchItems!];
    if (index < 0 || index >= items.length) return;
    final cur = items[index].taxOverride;
    items[index] =
        items[index].copyWith(taxOverride: cur == percent ? null : percent);
    state = _s.copyWith(batchItems: items);
  }

  void setBatchPaintMode(bool paint) {
    // モード切替時はD1の選択をクリア（塗り分けと混ざらないように）
    final items = [
      for (final b in _s.batchItems!) b.copyWith(selected: false)
    ];
    state = _s.copyWith(batchItems: items, batchPaintMode: paint);
  }

  /// 品目行のタップ。D1=選択トグル / D2=塗るカテゴリを付与（同色なら剥がす）。
  void tapBatchItem(int index) {
    final items = [..._s.batchItems!];
    if (index < 0 || index >= items.length) return;
    final b = items[index];
    if (_s.batchPaintMode) {
      final paint = _s.batchPaintCategoryId;
      if (paint == null) return; // 塗るカテゴリ未選択
      items[index] = b.copyWith(
          categoryId: b.categoryId == paint ? null : paint);
    } else {
      items[index] = b.copyWith(selected: !b.selected);
    }
    state = _s.copyWith(batchItems: items);
  }

  void setBatchDiffCategory(int categoryId) =>
      state = _s.copyWith(batchDiffCategoryId: categoryId);

  /// カテゴリグリッドのタップ（一括内訳中）。
  /// D2: 塗るカテゴリ切替 / D1: 選択中の品目へ割当（→内訳チップで差し替え可）。
  List<int> _lastBatchAssigned = const [];
  void _batchAssignCategory(int categoryId, {required int? expandedParentId}) {
    if (_s.batchPaintMode) {
      state = _s.copyWith(
        batchPaintCategoryId: categoryId,
        expandedParentId: expandedParentId,
      );
      return;
    }
    final sel = _s.batchSelectedIndexes;
    if (sel.isEmpty) {
      state = _s.copyWith(expandedParentId: expandedParentId);
      return;
    }
    final items = [..._s.batchItems!];
    for (final i in sel) {
      items[i] = items[i].copyWith(categoryId: categoryId, selected: false);
    }
    _lastBatchAssigned = sel;
    state =
        _s.copyWith(batchItems: items, expandedParentId: expandedParentId);
  }

  /// 保存済みグループ（同じsplitGroupIdの取引群）を詳細入力で開き直す。
  /// 保存時に旧取引を置換し、groupIdは引き継ぐ。
  void startEditSplitGroup(List<TransactionEntity> txs) {
    assert(txs.isNotEmpty && txs.every((t) => t.id != null));
    final first = txs.first;
    state = EntryFormState(
      formSeq: ++_seq,
      mode: EntryMode.create,
      type: first.type,
      amountYen: txs.fold(0, (a, t) => a + t.amountYen),
      date: first.date,
      storeName: first.storeName ?? '',
      memo: first.memo ?? '',
      source: first.source,
      imagePath: first.imagePath,
      memoExpanded: (first.memo ?? '').isNotEmpty,
      splits: [
        // 保存済み額は確定済み（税込）。そのまま扱う＝税込・手動扱いで自動税率を効かせない。
        for (final t in txs)
          SplitLine(
              expr: '${t.amountYen}',
              taxIncluded: true,
              taxTouched: true,
              categoryId: t.categoryId)
      ],
      replacesTxIds: [for (final t in txs) t.id!],
      reuseSplitGroupId: first.splitGroupId,
    );
  }

  // --- 詳細入力（分割）。合計をカテゴリ別に分けて複数取引として保存 ---

  void startSplit() {
    if (_s.amountYen <= 0 || _s.mode == EntryMode.edit || _s.splits != null) {
      return;
    }
    state = _s.copyWith(
      // 2行で開始。以降は自動では増やさず「追加」ボタンで足す。
      splits: const [SplitLine(), SplitLine()],
      activeSplitIndex: 0,
      batchItems: null,
      expandedParentId: null,
    );
  }

  /// 「追加」: 空の行を末尾に足してアクティブにする（自動増加はしない）。
  void addSplitLine() {
    final lines = _s.splits;
    if (lines == null) return;
    final last = lines.last;
    final next = [
      ...lines,
      SplitLine(taxIncluded: last.taxIncluded, rate: last.rate),
    ];
    state = _s.copyWith(splits: next, activeSplitIndex: next.length - 1);
  }

  void cancelSplit() =>
      state = _s.copyWith(splits: null, activeSplitIndex: 0);

  void setActiveSplit(int i) {
    final lines = _s.splits;
    if (lines == null || i < 0 || i >= lines.length) return;
    state = _s.copyWith(activeSplitIndex: i);
  }

  void removeSplitLine(int i) {
    final lines = [..._s.splits!];
    if (i < 0 || i >= lines.length) return;
    lines.removeAt(i);
    if (lines.isEmpty) lines.add(const SplitLine());
    state = _s.copyWith(
      splits: lines,
      activeSplitIndex: _s.activeSplitIndex.clamp(0, lines.length - 1),
    );
  }

  /// 行の入力（式）を消してその行をアクティブに。自動で入った残額を上書きして
  /// ユーザーが自分の金額を入れ直せるようにする（「クリア」ボタン）。
  void clearSplitLine(int i) {
    final lines = [..._s.splits!];
    if (i < 0 || i >= lines.length) return;
    lines[i] = lines[i].copyWith(expr: '');
    state = _s.copyWith(
      splits: lines,
      activeSplitIndex: i.clamp(0, lines.length - 1),
    );
  }

  void splitTapDigit(int digit) {
    assert(digit >= 0 && digit <= 9);
    _updateActiveSplit(
        (l) => l.expr.length >= 30 ? l : l.copyWith(expr: '${l.expr}$digit'));
  }

  void splitTapDoubleZero() {
    _updateActiveSplit((l) {
      // 通常モードの00と同じ思想: 数字の後にのみ意味を持つ
      if (!RegExp(r'\d$').hasMatch(l.expr)) return l;
      return l.expr.length >= 29 ? l : l.copyWith(expr: '${l.expr}00');
    });
  }

  /// 演算子キー。空の式には +/− のみ置ける（+100形式）。
  /// 末尾が演算子なら置き換え（連続演算子を作らない＝電卓の標準挙動）。
  void splitTapOperator(String op) {
    assert(const ['+', '-', '×', '÷'].contains(op));
    _updateActiveSplit((l) {
      final e = l.expr;
      if (e.isEmpty) {
        return (op == '+' || op == '-') ? l.copyWith(expr: op) : l;
      }
      if (RegExp(r'[+\-×÷]$').hasMatch(e)) {
        return l.copyWith(expr: e.substring(0, e.length - 1) + op);
      }
      return l.copyWith(expr: '$e$op');
    });
  }

  void splitBackspace() {
    _updateActiveSplit((l) => l.expr.isEmpty
        ? l
        : l.copyWith(expr: l.expr.substring(0, l.expr.length - 1)));
  }

  /// 行の「税込/税抜」を設定（手動＝以後カテゴリ自動で上書きしない）。
  void setSplitIncluded(int index, bool included) => _setLineTax(
      index, (l) => l.copyWith(taxIncluded: included, taxTouched: true));

  /// 行の税率(8/10)を設定（手動＝以後カテゴリ自動で上書きしない）。
  void setSplitRate(int index, int rate) {
    assert(rate == 8 || rate == 10);
    _setLineTax(index, (l) => l.copyWith(rate: rate, taxTouched: true));
  }

  void _setLineTax(int index, SplitLine Function(SplitLine) f) {
    final lines = [..._s.splits!];
    if (index < 0 || index >= lines.length) return;
    lines[index] = f(lines[index]);
    state = _s.copyWith(splits: lines);
  }

  /// 一括: 全行の「税込/税抜」を揃える（詳細入力の横の一括選択）。
  void setSplitBulkIncluded(bool included) {
    if (_s.splits == null) return;
    state = _s.copyWith(
        splits: [for (final l in _s.splits!) l.copyWith(taxIncluded: included)]);
  }

  /// 一括: 全行の税率(8/10)を揃える。
  void setSplitBulkRate(int rate) {
    assert(rate == 8 || rate == 10);
    if (_s.splits == null) return;
    state = _s.copyWith(
        splits: [for (final l in _s.splits!) l.copyWith(rate: rate)]);
  }

  /// カテゴリに対応する軽減税率の自動値（食費=8 / 外食=10 / 他=null）。
  /// 食費は軽減税率8%、外食(店内)は標準10%。手で税を変えた行には効かせない。
  int? _autoRateForCategory(int categoryId) {
    final cats = ref.read(allCategoriesProvider).valueOrNull ??
        const <CategoryEntity>[];
    CategoryEntity? cat;
    CategoryEntity? foodParent;
    for (final c in cats) {
      if (c.id == categoryId) cat = c;
      if (c.name == '食費' && c.parentId == null) foodParent = c;
    }
    if (cat == null) return null;
    if (cat.name == '外食') return 10;
    if (foodParent != null &&
        (cat.id == foodParent.id || cat.parentId == foodParent.id)) {
      return 8;
    }
    return null;
  }

  /// 分割行にカテゴリを割り当て、税未操作なら軽減税率を自動適用したSplitLineを返す。
  SplitLine _withSplitCategory(SplitLine l, int categoryId) {
    var line = l.copyWith(categoryId: categoryId);
    if (!line.taxTouched) {
      final r = _autoRateForCategory(categoryId);
      if (r != null) line = line.copyWith(rate: r);
    }
    return line;
  }

  void _updateActiveSplit(SplitLine Function(SplitLine) f,
      {Object? expandedParentId = const _Keep()}) {
    final lines = [..._s.splits!];
    final i = _s.activeSplitIndex;
    lines[i] = f(lines[i]);
    // 行の増減はしない（開始2行＋「追加」ボタンで手動管理）。
    state = expandedParentId is _Keep
        ? _s.copyWith(splits: lines)
        : _s.copyWith(
            splits: lines,
            expandedParentId: expandedParentId as int?);
  }

  void setDate(CivilDate date) => state = _s.copyWith(date: date);

  void setStoreName(String storeName) =>
      state = _s.copyWith(storeName: storeName);

  void setMemo(String memo) => state = _s.copyWith(memo: memo);

  void toggleMemoExpanded() =>
      state = _s.copyWith(memoExpanded: !_s.memoExpanded);

  void selectTotalCandidate(AmountCandidate c) =>
      state = _s.copyWith(amountYen: c.yen);

  void selectDateCandidate(DateCandidate c) => state = _s.copyWith(date: c.date);

  Future<void> save() async {
    final s = _s;
    if (!s.canSave) throw StateError('金額とカテゴリが必要です');
    if (s.batchItems != null) {
      // 差額は同カテゴリの行があればそこへ合算（食費¥534と食費¥2に分かれない）
      final groups = Map<int, int>.of(s.batchGroups);
      final diff = s.batchDiff;
      if (diff > 0) {
        final cat = s.batchDiffCategoryId!;
        groups[cat] = (groups[cat] ?? 0) + diff;
      }
      return _saveGroupLines(
          s, [for (final e in groups.entries) (e.key, e.value)]);
    }
    if (s.splits != null) {
      final splitLines = s.splits!;
      return _saveGroupLines(s, [
        // 空の行（金額なし）は保存しない。金額ありの行だけ束ねる。
        for (var i = 0; i < splitLines.length; i++)
          if (s.splitLineAmount(i) != null && splitLines[i].categoryId != null)
            (splitLines[i].categoryId!, s.splitLineAmount(i)!),
      ]);
    }
    // 開き直しから通常保存に落ちたケースも置換を保証する
    if (s.replacesTxIds != null) {
      return _saveGroupLines(s, [(s.categoryId!, s.amountYen)]);
    }
    _labelFixture(s, s.amountYen);
    final repo = ref.read(transactionRepositoryProvider);
    final store = s.storeName.trim();
    final memo = s.memo.trim();
    if (s.mode == EntryMode.edit) {
      await repo.update(TransactionEntity(
        id: s.editingId,
        type: s.type,
        amountYen: s.amountYen,
        date: s.date,
        categoryId: s.categoryId!,
        storeName: store.isEmpty ? null : store,
        memo: memo.isEmpty ? null : memo,
        source: s.source,
        imagePath: s.imagePath,
      ));
      return;
    }
    final storedImage = _finalizeReceiptImage(s);
    await repo.add(TransactionEntity(
      type: s.type,
      amountYen: s.amountYen,
      date: s.date,
      categoryId: s.categoryId!,
      storeName: store.isEmpty ? null : store,
      memo: memo.isEmpty ? null : memo,
      source: s.source,
      imagePath: storedImage,
    ));
  }

  /// 分割/一括内訳の保存: 各行を別々の取引として追加し、同じ splitGroupId で
  /// 束ねる（=「1枚のレシート」）。開き直しなら旧取引を置換しIDを引き継ぐ。
  /// 画像は先頭の取引にのみ紐づける（重複参照による削除時の破綻を回避）。
  Future<void> _saveGroupLines(
      EntryFormState s, List<(int categoryId, int amountYen)> lines) async {
    assert(lines.isNotEmpty);
    _labelFixture(s, lines.fold(0, (a, l) => a + l.$2));
    final repo = ref.read(transactionRepositoryProvider);
    final store = s.storeName.trim();
    final memo = s.memo.trim();
    for (final id in s.replacesTxIds ?? const <int>[]) {
      await repo.delete(id);
    }
    final groupId = s.reuseSplitGroupId ??
        '${ref.read(utcNowProvider)().microsecondsSinceEpoch}-${++_seq}';
    var image = _finalizeReceiptImage(s);
    for (final (categoryId, amountYen) in lines) {
      await repo.add(TransactionEntity(
        type: s.type,
        amountYen: amountYen,
        date: s.date,
        categoryId: categoryId,
        storeName: store.isEmpty ? null : store,
        memo: memo.isEmpty ? null : memo,
        source: s.source,
        imagePath: image,
        splitGroupId: groupId,
      ));
      image = null;
    }
  }

  Future<void> saveAndContinue() async {
    await save();
    final s = _s;
    state = EntryFormState(
      formSeq: ++_seq,
      mode: EntryMode.create,
      type: s.type,
      amountYen: 0,
      date: s.date,
      storeName: s.storeName,
      memo: s.memo,
      source: TxnSource.manual,
      memoExpanded: s.memoExpanded,
    );
  }

  Future<void> deleteEditing() async {
    final id = _s.editingId;
    if (id == null) throw StateError('編集中の取引がありません');
    await ref.read(transactionRepositoryProvider).delete(id);
  }

  /// 保存確定＝人間の正解。OCRフィクスチャへラベルを書き戻す
  /// （普通に使うだけで正解付きデータが溜まる）。失敗しても保存は続行。
  void _labelFixture(EntryFormState s, int totalYen) {
    final path = s.fixturePath;
    if (path == null) return;
    try {
      final store = s.storeName.trim();
      ref.read(ocrFixtureRecorderProvider).writeExpected(
            path,
            totalYen: totalYen,
            dateIso: s.date.toIso(),
            store: store.isEmpty ? null : store,
          );
      // オプトイン時のみ: ラベル込みで再送（失敗しても保存は妨げない）
      if (ref.read(appSettingsProvider).autoUploadTestData) {
        unawaited(ref
            .read(cloudFixtureUploaderProvider)
            .resendAfterLabel(path)
            .catchError((_) {}));
      }
    } catch (_) {}
  }

  /// レシート一時画像の後始末（spec §7.6 / §14-C）。
  /// 保持OFF: 削除して null。保持ON: receiptImagesDir へ移動してそのパス。
  /// ファイル操作の失敗は保存をブロックしない（null にフォールバック）。
  String? _finalizeReceiptImage(EntryFormState s) {
    final path = s.imagePath;
    if (s.mode != EntryMode.receiptConfirm || path == null) return null;
    final file = File(path);
    try {
      if (!file.existsSync()) return null;
      if (!ref.read(appSettingsProvider).retainReceiptImages) {
        file.deleteSync();
        return null;
      }
      final dir = ref.read(receiptImagesDirProvider)..createSync(recursive: true);
      final dest =
          '${dir.path}${Platform.pathSeparator}${file.uri.pathSegments.last}';
      file.renameSync(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }
}

/// _updateActiveSplit の「expandedParentIdを触らない」既定値センチネル。
class _Keep {
  const _Keep();
}

final entryFormControllerProvider =
    NotifierProvider<EntryFormController, EntryFormState?>(
        EntryFormController.new);
