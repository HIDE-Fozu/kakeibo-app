import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/category_emoji.dart';
import '../../../core/format.dart';
import '../../../domain/entities.dart';
import '../application/entry_form_controller.dart';
import 'receipt_line_strip.dart';

/// 一括内訳モード（OCR明細ベース）。
/// - 行はレシート写真の切り抜き（receipt_line_strip）＋実効税率チップ＋税込額
/// - D1（選んで割当）/ D2（塗り分け）を上部トグルで切替（両方試せる）
/// - 税はヘッダーで一括指定（内税/外税8%/外税10%）、行の%チップで上書き
/// - 下部にB2「レシート紙」: カテゴリ集約と差額、合計照合
class BatchItemizePanel extends ConsumerWidget {
  final EntryFormState state;
  final Map<int, CategoryEntity> categoriesById;
  final List<CategoryEntity> pickableCategories; // 差額行ピッカー用（同type）

  const BatchItemizePanel({
    super.key,
    required this.state,
    required this.categoriesById,
    required this.pickableCategories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final items = state.batchItems!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.call_split, size: 16, color: scheme.outline),
            const SizedBox(width: 4),
            // 合計はすぐ上の金額表示に出ているので、ここは短く
            Expanded(
              child: Text('一括内訳',
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis),
            ),
            SegmentedButton<bool>(
              key: const Key('batch-mode-toggle'),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(value: false, label: Text('選んで割当')),
                ButtonSegment(value: true, label: Text('塗り分け')),
              ],
              selected: {state.batchPaintMode},
              onSelectionChanged: (s) => ctrl.setBatchPaintMode(s.single),
            ),
            TextButton(
              key: const Key('cancel-batch'),
              onPressed: ctrl.cancelBatchItemize,
              child: const Text('やめる'),
            ),
          ],
        ),
        // 税ヘッダー: レシート単位で一括指定
        Row(
          children: [
            Text('このレシート:',
                style: TextStyle(fontSize: 11, color: scheme.outline)),
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SegmentedButton<int>(
                    key: const Key('batch-header-tax'),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('内税')),
                      ButtonSegment(value: 8, label: Text('外税8%')),
                      ButtonSegment(value: 10, label: Text('外税10%')),
                    ],
                    selected: {state.batchHeaderTax},
                    onSelectionChanged: (s) =>
                        ctrl.setBatchHeaderTax(s.single),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < items.length; i++) _itemRow(context, ref, i),
        const SizedBox(height: 6),
        _hintBar(context),
        const SizedBox(height: 8),
        _paper(context, ref),
      ],
    );
  }

  Widget _itemRow(BuildContext context, WidgetRef ref, int i) {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final b = state.batchItems![i];
    final cat = b.categoryId == null ? null : categoriesById[b.categoryId];
    final effTax = state.batchItemTax(b);
    final highlighted = state.batchPaintMode
        ? b.categoryId != null && b.categoryId == state.batchPaintCategoryId
        : b.selected;

    Widget leading;
    if (state.batchPaintMode) {
      leading = Text(
        cat == null ? '○' : categoryEmoji(cat.icon, cat.name),
        style: TextStyle(
            fontSize: 15,
            color: cat == null ? scheme.outline : null),
      );
    } else {
      leading = Icon(
        b.selected ? Icons.check_box : Icons.check_box_outline_blank,
        size: 19,
        color: b.selected ? scheme.primary : scheme.outline,
      );
    }

    Widget taxChip(int percent) {
      final selected = effTax == percent;
      return Padding(
        padding: const EdgeInsets.only(left: 3),
        child: InkWell(
          key: Key('batch-tax$percent-$i'),
          onTap: () => ctrl.setBatchItemTax(i, percent),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : null,
              border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$percent%',
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? scheme.onPrimary : scheme.outline)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        key: Key('batch-item-$i'),
        onTap: () => ctrl.tapBatchItem(i),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: highlighted
                ? scheme.primaryContainer.withValues(alpha: 0.4)
                : null,
            border: Border.all(
                color: highlighted ? scheme.primary : scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 6),
              Expanded(
                child: ReceiptLineStrip(
                  imagePath: state.imagePath,
                  rect: b.item.rect,
                  fallbackText: b.item.text,
                ),
              ),
              if (!state.batchPaintMode && cat != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(categoryEmoji(cat.icon, cat.name),
                      style: const TextStyle(fontSize: 14)),
                ),
              taxChip(8),
              taxChip(10),
              const SizedBox(width: 6),
              Text(
                formatYen(state.batchItemAmount(b)),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: kTabularFigures),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String text;
    if (state.batchPaintMode) {
      final paint = state.batchPaintCategoryId == null
          ? null
          : categoriesById[state.batchPaintCategoryId];
      text = paint == null
          ? '下のカテゴリを選んでから、行をタップして塗り分け'
          : '「${paint.name}」を塗り中 — 行をタップ（もう一度で解除）';
    } else {
      final sel = state.batchSelectedIndexes;
      if (sel.isEmpty) {
        text = '行を選択 → 下のカテゴリをタップして割当';
      } else {
        final sum = sel.fold(
            0, (a, i) => a + state.batchItemAmount(state.batchItems![i]));
        text = '選択中 ${sel.length}件 ${formatYen(sum)} → 下のカテゴリをタップ';
      }
    }
    return Container(
      key: const Key('batch-hint'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface)),
    );
  }

  /// B2: レシート紙風の集約＋合計照合＋差額行。
  Widget _paper(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final groups = state.batchGroups;
    final diff = state.batchDiff;
    final diffCat = state.batchDiffCategoryId == null
        ? null
        : categoriesById[state.batchDiffCategoryId];
    // ヘッダは「店舗名 - 詳細メモ」。どちらも空なら「レシート」。
    final headerLabel = [state.storeName.trim(), state.memo.trim()]
        .where((s) => s.isNotEmpty)
        .join(' - ');

    Widget row(String label, String value, {Color? color, Key? key}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            key: key,
            children: [
              Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: 12.5, color: color),
                      overflow: TextOverflow.ellipsis)),
              Text(value,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: color,
                      fontFeatures: kTabularFigures)),
            ],
          ),
        );

    return Container(
      key: const Key('batch-paper'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14202420), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🧾 ${headerLabel.isEmpty ? 'レシート' : headerLabel}　${state.date.toIso()}',
            style: TextStyle(fontSize: 11, color: scheme.outline),
            overflow: TextOverflow.ellipsis,
          ),
          Divider(height: 10, color: scheme.outlineVariant),
          if (groups.isEmpty)
            row('（まだ割当がありません）', '', color: scheme.outline),
          for (final e in groups.entries)
            row(
              '${categoryEmoji(categoriesById[e.key]?.icon, categoriesById[e.key]?.name)} '
              '${categoriesById[e.key]?.name ?? '不明'}',
              formatYen(e.value),
            ),
          if (diff > 0)
            InkWell(
              key: const Key('batch-diff-row'),
              onTap: () => _pickDiffCategory(context, ref),
              child: row(
                diffCat == null
                    ? '残り（差額）— タップしてカテゴリを選ぶ'
                    : '${categoryEmoji(diffCat.icon, diffCat.name)} '
                        '${diffCat.name}（差額）',
                formatYen(diff),
                color: diffCat == null ? scheme.error : null,
              ),
            ),
          Divider(height: 10, color: scheme.outlineVariant),
          row(
            '合計',
            diff < 0
                ? '${formatYen(state.amountYen)} ✗ ${formatYen(-diff)} 超過'
                : '${formatYen(state.amountYen)}${state.canSave ? ' ✓' : ''}',
            color: diff < 0
                ? scheme.error
                : state.canSave
                    ? scheme.primary
                    : null,
            key: const Key('batch-total-row'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDiffCategory(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(entryFormControllerProvider.notifier);
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in pickableCategories)
              ListTile(
                dense: true,
                leading: Text(categoryEmoji(c.icon, c.name),
                    style: const TextStyle(fontSize: 18)),
                title: Text(c.name),
                onTap: () => Navigator.pop(ctx, c.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) ctrl.setBatchDiffCategory(picked);
  }
}
