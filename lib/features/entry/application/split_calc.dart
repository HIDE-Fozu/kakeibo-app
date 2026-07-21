/// 詳細入力（分割）の電卓式評価。
///
/// 規則（ユーザー確定仕様）:
/// - 対応トークン: 数字（小数点可）と ＋ − × ÷。
/// - **左から順に計算**（× ÷ の優先なし・電卓式）。
/// - 先頭の ＋ は無視（「+100+100」OK）。先頭の − は 0−n（結果が負なら無効）。
/// - 末尾の演算子は入力途中とみなして無視（「100+」→ 100）。
/// - ÷ の端数・負値・0除算・空・不正文字は null（無効）。
/// - 結果は通貨の最小単位（minor unit）に換算し**切り捨て**（0以下は null）。
///   [decimals]=0（JPY等）は従来通り整数。=2（USD等）は「12.50」→1250 のように
///   ×100 して cent 整数にする（浮動小数の誤差は微小εで吸収）。
int? evalCalcExpr(String expr, {int decimals = 0}) {
  final s = expr.replaceAll(' ', '');
  if (s.isEmpty) return null;
  final matches = RegExp(r'(\d+(?:\.\d+)?)|([+\-×÷])').allMatches(s).toList();
  if (matches.map((m) => m.group(0)!).join() != s) return null; // 不正文字

  double? acc;
  String? pendingOp = '+'; // 先頭は暗黙の +0 に対する演算
  for (final m in matches) {
    final digits = m.group(1);
    if (digits != null) {
      if (pendingOp == null) return null; // 数字の連続（正規表現上は起きない）
      final n = double.parse(digits);
      switch (pendingOp) {
        case '+':
          acc = (acc ?? 0) + n;
        case '-':
          acc = (acc ?? 0) - n;
        case '×':
          if (acc == null) return null; // 先頭に×は置けない
          acc = acc * n;
        case '÷':
          if (acc == null || n == 0) return null;
          acc = acc / n;
      }
      pendingOp = null;
    } else {
      final op = m.group(2)!;
      if (pendingOp != null) {
        // 演算子の連続は先頭の +/− のみ許容（「+100」「−100」）
        if (acc == null && pendingOp == '+' && (op == '+' || op == '-')) {
          pendingOp = op;
          continue;
        }
        return null;
      }
      pendingOp = op;
    }
  }
  if (acc == null) return null;
  if (decimals == 0) {
    final v = acc.floor(); // 切り捨て（確定仕様・JPYは従来と完全一致）
    return v <= 0 ? null : v;
  }
  var scale = 1;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  // minor unit化。0.29×100=28.9999… のような二進誤差を微小εで吸収してから切り捨て。
  final v = (acc * scale + 1e-6).floor();
  return v <= 0 ? null : v;
}

/// 外税の適用: 税抜額 × (100+税率)/100 を**切り捨て**（確定仕様）。
/// taxPercent 0 = 内税（そのまま）。整数演算なので丸め誤差なし。
int applyTax(int amountYen, int taxPercent) =>
    taxPercent == 0 ? amountYen : (amountYen * (100 + taxPercent)) ~/ 100;
