import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/enums.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/receipt/receipt_parser.dart';
import '../../settings/application/settings_controller.dart';

enum EntryMode { create, receiptConfirm, edit }

class EntryFormState {
  final EntryMode mode;
  final int? editingId;
  final TxnType type;
  final int amountYen;
  final int? categoryId;
  final CivilDate date;
  final String memo;
  final TxnSource source;
  final ParsedReceipt? receipt;
  final String? imagePath;
  final bool memoExpanded;

  /// 内訳チップ列を開いている親カテゴリ（null=閉）。選択とは独立。
  final int? expandedParentId;

  const EntryFormState({
    required this.mode,
    this.editingId,
    required this.type,
    required this.amountYen,
    this.categoryId,
    required this.date,
    required this.memo,
    required this.source,
    this.receipt,
    this.imagePath,
    this.memoExpanded = false,
    this.expandedParentId,
  });

  bool get canSave => amountYen > 0 && categoryId != null;

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
    String? memo,
    TxnSource? source,
    Object? receipt = _unset,
    Object? imagePath = _unset,
    bool? memoExpanded,
    Object? expandedParentId = _unset,
  }) =>
      EntryFormState(
        mode: mode ?? this.mode,
        editingId:
            identical(editingId, _unset) ? this.editingId : editingId as int?,
        type: type ?? this.type,
        amountYen: amountYen ?? this.amountYen,
        categoryId:
            identical(categoryId, _unset) ? this.categoryId : categoryId as int?,
        date: date ?? this.date,
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
      );
}

/// 入力フォームの状態機械。keepAlive（非autoDispose）: 画面push前のstart*()と
/// 画面buildの間で破棄されないようにする（画面は同時に1つしか開かない前提）。
class EntryFormController extends Notifier<EntryFormState?> {
  static const int maxAmount = 9999999;

  @override
  EntryFormState? build() => null;

  void startCreate(CivilDate date) {
    state = EntryFormState(
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
      mode: EntryMode.edit,
      editingId: tx.id,
      type: tx.type,
      amountYen: tx.amountYen,
      categoryId: tx.categoryId,
      date: tx.date,
      memo: tx.memo ?? '',
      source: tx.source,
      imagePath: tx.imagePath,
      memoExpanded: (tx.memo ?? '').isNotEmpty,
    );
  }

  void startReceipt(ParsedReceipt parsed, {String? imagePath}) {
    state = EntryFormState(
      mode: EntryMode.receiptConfirm,
      type: TxnType.expense,
      amountYen: parsed.total?.yen ?? 0,
      date: parsed.date.date,
      memo: '',
      source: TxnSource.receiptOcr,
      receipt: parsed,
      imagePath: imagePath,
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
    state = _s.copyWith(
      categoryId: categoryId,
      expandedParentId: hasSubs ? categoryId : null,
    );
  }

  /// 内訳チップのタップ。選択中チップの再タップは親（チップ列の親）に戻す。
  /// どちらの場合もチップ列は格納する（オーバーレイを閉じて即テンキーに戻る）。
  void toggleSubcategory(int subId) {
    final parent = _s.expandedParentId;
    if (parent == null) return; // チップ列が閉じているときは呼ばれない
    state = _s.copyWith(
      categoryId: _s.categoryId == subId ? parent : subId,
      expandedParentId: null,
    );
  }

  void setDate(CivilDate date) => state = _s.copyWith(date: date);

  void setMemo(String memo) => state = _s.copyWith(memo: memo);

  void toggleMemoExpanded() =>
      state = _s.copyWith(memoExpanded: !_s.memoExpanded);

  void selectTotalCandidate(AmountCandidate c) =>
      state = _s.copyWith(amountYen: c.yen);

  void selectDateCandidate(DateCandidate c) => state = _s.copyWith(date: c.date);

  Future<void> save() async {
    final s = _s;
    if (!s.canSave) throw StateError('金額とカテゴリが必要です');
    final repo = ref.read(transactionRepositoryProvider);
    final memo = s.memo.trim();
    if (s.mode == EntryMode.edit) {
      await repo.update(TransactionEntity(
        id: s.editingId,
        type: s.type,
        amountYen: s.amountYen,
        date: s.date,
        categoryId: s.categoryId!,
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
      memo: memo.isEmpty ? null : memo,
      source: s.source,
      imagePath: storedImage,
    ));
  }

  Future<void> saveAndContinue() async {
    await save();
    final s = _s;
    state = EntryFormState(
      mode: EntryMode.create,
      type: s.type,
      amountYen: 0,
      date: s.date,
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

final entryFormControllerProvider =
    NotifierProvider<EntryFormController, EntryFormState?>(
        EntryFormController.new);
