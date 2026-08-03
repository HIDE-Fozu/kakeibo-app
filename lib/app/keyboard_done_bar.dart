import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// キーボード直上に出す「完了」バー（iOSのアクセサリバー相当・右寄せ）。
/// テンキーには確定キーが無く、メモ等のテキスト欄もキーボードを閉じる手段が
/// 分かりにくいため、タップで unfocus してキーボードを閉じる。
///
/// 表示条件（キーボードが開いているか）は Scaffold より上の context で
/// MediaQuery.viewInsets を見て呼び出し側が判定する（Scaffold の body 内では
/// resize 済みで viewInsets が 0 になるため、この widget 自身では判定できない）。
class KeyboardDoneBar extends StatelessWidget {
  const KeyboardDoneBar({super.key});

  @override
  Widget build(BuildContext context) {
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
