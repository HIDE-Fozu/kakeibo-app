import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// キーボード直上に出す「完了」バー（iOSのアクセサリバー相当・右寄せ）。
/// テンキーには確定キーが無く、メモ等のテキスト欄もキーボードを閉じる手段が
/// 分かりにくいため、タップで unfocus してキーボードを閉じる。
///
/// 表示判定は MediaQuery.viewInsets ではなく「テキスト欄にフォーカスがあるか」
/// （FocusManager 監視）で行う。viewInsets はネストした Scaffold
/// （HomeShell の body 内の EntryScreen 等）だと外側の Scaffold が消費して
/// 常に0になり、実機でバーが出ない。フォーカスはその影響を受けない。
class KeyboardDoneBar extends StatefulWidget {
  const KeyboardDoneBar({super.key});

  @override
  State<KeyboardDoneBar> createState() => _KeyboardDoneBarState();
}

class _KeyboardDoneBarState extends State<KeyboardDoneBar> {
  @override
  void initState() {
    super.initState();
    // FocusManager は primaryFocus の変化で notify する ChangeNotifier。
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  /// テキスト入力欄（EditableText）がフォーカスを持っているか。
  /// タッチ操作ではボタン類にフォーカスは移らないので、実質「キーボードが
  /// 開いているか」と一致する（ハードウェアキーボード接続時も無害）。
  bool get _editingText {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_editingText) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      alignment: Alignment.centerRight,
      child: TextButton(
        key: const Key('kb-done'),
        onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Text(
          AppLocalizations.of(context).commonDone,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
