import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/data/db/enums.dart';
import 'package:kakeibo_app/domain/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ごみ箱＋分割払い回数拡張の目視確認（使い捨て・2026-08-19）。

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('trash + installment counts shots', (t) async {
    SharedPreferences.setMockInitialValues(
        {'onboardingDone': true, 'chorePermissionAsked': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 今日の取引を1件仕込む（実DB・実時計の今日 → カレンダーの既定選択日に出る）
    final c = ProviderScope.containerOf(
        t.element(find.byType(MaterialApp).first),
        listen: false);
    final cats = await c.read(categoryRepositoryProvider).active();
    final food = cats.firstWhere((x) => x.name == '食費');
    await c.read(transactionRepositoryProvider).add(TransactionEntity(
          type: TxnType.expense,
          amountYen: 800,
          date: c.read(clockProvider)(),
          categoryId: food.id,
          storeName: 'コンビニ',
          source: TxnSource.manual,
        ));
    await settle(t);

    // swipe削除 → ×付き・Undoなしの SnackBar
    await t.drag(find.text('コンビニ').last, const Offset(-500, 0));
    await settle(t);
    await shot(t, 'trash_1_delete_snackbar');

    // 設定 → ごみ箱タイル
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.settings)));
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('trash-tile')));
    await shot(t, 'trash_2_settings_tile');

    // ごみ箱ページ（1件）
    await t.tap(find.byKey(const Key('trash-tile')));
    await settle(t);
    await shot(t, 'trash_3_trash_page');

    // 復元 → SnackBar＋空状態
    await t.tap(find.byIcon(Icons.restore));
    await settle(t);
    await shot(t, 'trash_4_restored');
    await t.tap(find.byType(BackButton));
    await settle(t);

    // 分割払いの回数メニュー: 先頭〜60は1刻み → 末尾に420回（35年）
    await t.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_repeat)));
    await settle(t);
    await t.tap(find.byKey(const Key('hub-installment-add')));
    await settle(t);
    await t.tap(find.byKey(const Key('installment-count')),
        warnIfMissed: false);
    await settle(t);
    await shot(t, 'trash_5_counts_top');
    // メニュー内を下までスクロールして間引き刻み〜420回を見せる
    // （項目は遅延構築なのでScrollable自体をドラッグする）
    for (var i = 0; i < 4; i++) {
      await t.drag(find.byType(Scrollable).last, const Offset(0, -900));
      await settle(t);
    }
    await shot(t, 'trash_6_counts_tail');
  });
}
