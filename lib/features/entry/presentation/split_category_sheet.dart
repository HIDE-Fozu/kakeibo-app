import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../application/entry_form_controller.dart';
import 'category_grid.dart';
import 'subcategory_chips.dart';

/// 分割入力の行カテゴリを、電卓に被せてボトムシートで選ぶ。
/// leafカテゴリ／内訳チップを選んだらアクティブ行へ割り当ててシートを閉じる。
/// 常設のカテゴリグリッドを分割中は出さず、「カテゴリを選択」を押した時だけ出す。
Future<void> openSplitCategorySheet(
  BuildContext context,
  WidgetRef ref,
  int lineIndex,
) async {
  final ctrl = ref.read(entryFormControllerProvider.notifier);
  ctrl.setActiveSplit(lineIndex);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SplitCategorySheet(),
  );
}

class _SplitCategorySheet extends ConsumerWidget {
  const _SplitCategorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryFormControllerProvider);
    if (state == null || state.splits == null) return const SizedBox.shrink();
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final i = state.activeSplitIndex;
    final line = state.splits![i];
    final amount = state.splitLineAmount(i);
    // 対象の額を見出しに出す（残額行なら「残り」を付ける）。
    final title = amount == null
        ? 'カテゴリを選ぶ'
        : line.expr.isEmpty
            ? '残り ${formatYen(amount)} のカテゴリを選ぶ'
            : '${formatYen(amount)} のカテゴリを選ぶ';

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                IconButton(
                  key: const Key('split-cat-sheet-close'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // グリッド＋内訳チップ（押した親の下に薄緑で重ねる）。
            Stack(
              children: [
                CategoryGrid(
                  type: state.type,
                  selectedId: line.categoryId,
                  onTapCategory: ({
                    required int categoryId,
                    required bool hasSubs,
                    required bool isSameGroup,
                  }) {
                    ctrl.tapCategory(
                      categoryId: categoryId,
                      hasSubs: hasSubs,
                      isSameGroup: isSameGroup,
                    );
                    // leaf確定＝割当完了。内訳ありは下のチップ待ちで開いたまま。
                    if (!hasSubs) Navigator.of(context).pop();
                  },
                ),
                if (state.expandedParentId != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 66,
                    child: Container(
                      key: const Key('subcategory-chips'),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4EF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCFE4DB)),
                      ),
                      child: SubcategoryChips(
                        parentId: state.expandedParentId!,
                        selectedId: line.categoryId,
                        onToggle: (subId) {
                          ctrl.toggleSubcategory(subId);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
