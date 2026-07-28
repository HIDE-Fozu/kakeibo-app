import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/data/db/category_seeds.dart';
import 'package:kakeibo_app/features/entry/presentation/entry_screen.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store 掲載用スクリーンショット撮影（1ロケール/1実行）。
/// 実行例（6.9インチ iPhone 17 Pro Max・実行前に app を uninstall しておく）:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/store_screenshots_test.dart \
///     --dart-define=SHOT_LOCALE=de -d `<udid>`
///
/// 仕組み: platformDispatcher.localesTestValue で端末ロケールを偽装 →
/// 新規インストールのカテゴリシードもUI言語もそのロケールになる。
/// 通貨をロケール相応に設定 → デモ取引を数件保存 → 主要画面を撮影。

late IntegrationTestWidgetsFlutterBinding binding;

const localeTag = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'ja');

// ロケール→通貨ピッカー行ラベル（null=既定JPYのまま）と小数有無。
const currencyRow = <String, String?>{
  'ja': null,
  'en': r'USD  $',
  'zh': 'CNY  ¥',
  'ko': 'KRW  ₩',
  'es': 'EUR  €',
  'fr': 'EUR  €',
  'de': 'EUR  €',
  'it': 'EUR  €',
  'pt': 'EUR  €',
};
const decimalCurrency = <String>{'en', 'zh', 'es', 'fr', 'de', 'it', 'pt'};

// デモ取引: (カテゴリslug, 整数通貨の額, 小数通貨の額)
const demo = <(String, String, String)>[
  ('food', '1280', '12.80'),
  ('dailyGoods', '3480', '34.80'),
  ('transport', '680', '6.80'),
  ('hobby', '5200', '52.00'),
  ('food', '980', '9.80'),
];

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  await settle(t);
  await binding.takeScreenshot(name);
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)));
  await settle(t);
}

Future<void> goTab(WidgetTester t, IconData icon) async {
  await t.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(icon)));
  await settle(t);
}

Future<void> typeDigits(WidgetTester t, String s) async {
  for (final ch in s.split('')) {
    if (ch == '.') {
      await tapKey(t, 'np-dot');
    } else {
      await t.tap(find
          .descendant(of: find.byType(Numpad), matching: find.text(ch))
          .first);
      await t.pump(const Duration(milliseconds: 40));
    }
  }
  await settle(t);
}

Future<void> tapCategory(WidgetTester t, String slug) async {
  final name = seedCategoryName(slug, localeTag);
  // IndexedStack の裏に居るカレンダーの取引リスト等を拾わないよう入力画面に限定。
  await t.tap(
      find
          .descendant(
              of: find.byType(EntryScreen),
              matching: find.textContaining(name))
          .first,
      warnIfMissed: false);
  await settle(t);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots ($localeTag)', (t) async {
    // 端末ロケールを偽装（シード言語とUI言語の両方に効く）
    t.binding.platformDispatcher.localesTestValue = [Locale(localeTag)];
    t.binding.platformDispatcher.localeTestValue = Locale(localeTag);
    SharedPreferences.setMockInitialValues({'onboardingDone': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 通貨設定（JPY以外のロケールのみ・取引0件のうちに）
    final row = currencyRow[localeTag];
    if (row != null) {
      await goTab(t, Icons.settings);
      await t.scrollUntilVisible(find.byKey(const Key('currency-tile')), 200);
      await settle(t);
      await tapKey(t, 'currency-tile');
      await t.tap(
          find
              .descendant(
                  of: find.byType(SimpleDialog), matching: find.text(row))
              .first,
          warnIfMissed: false);
      await settle(t);
      await goTab(t, Icons.calendar_month);
    }

    // デモ取引を保存
    final dec = decimalCurrency.contains(localeTag);
    for (final (slug, intAmt, decAmt) in demo) {
      await tapKey(t, 'fab-entry');
      await typeDigits(t, dec ? decAmt : intAmt);
      await tapCategory(t, slug);
      await tapKey(t, 'save-btn');
      await t.pumpAndSettle(const Duration(milliseconds: 250));
    }

    // 1) カレンダー（データ入り）
    await shot(t, 'store_${localeTag}_1_calendar');

    // 2) 入力画面（金額＋カテゴリ選択済み・未保存）
    await tapKey(t, 'fab-entry');
    await typeDigits(t, dec ? '23.50' : '2350');
    await tapCategory(t, 'food');
    await shot(t, 'store_${localeTag}_2_entry');

    // 3) 内訳入力
    await t.tap(find.byKey(const Key('start-split')), warnIfMissed: false);
    await settle(t);
    await shot(t, 'store_${localeTag}_3_split');
    await tapKey(t, 'cancel-split');
    await tapKey(t, 'entry-back');

    // 4) サマリ
    await goTab(t, Icons.bar_chart);
    await shot(t, 'store_${localeTag}_4_summary');
  });
}
