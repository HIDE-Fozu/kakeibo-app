import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/app/bootstrap.dart';
import 'package:kakeibo_app/features/entry/presentation/numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// i18n 目視QAスイープ（docs/i18n-handoff.md 手順3）。
/// 9言語×主要画面を実simで描画してスクリーンショットを撮る。
/// 通貨も言語ごとに切替え、小数入力・JPY限定UI（OCR/税）の出し分けを assert する。
/// レイアウトオーバーフローは失敗にせず収集し、最後にまとめて報告する。
///
/// 実行前に sim からアプリを削除しておくこと（通貨変更は取引0件が前提）:
///   xcrun simctl uninstall `<udid>` com.hidefozu.kakeibo

late IntegrationTestWidgetsFlutterBinding binding;

/// (localeTag, ピッカー上の自言語名, 通貨ピッカー行ラベル, 小数通貨か, JPYか)
const sweeps = <(String, String, String, bool, bool)>[
  ('ja', '日本語', 'JPY  ¥', false, true),
  ('en', 'English', r'USD  $', true, false),
  ('zh', '中文（简体）', 'CNY  ¥', true, false),
  ('ko', '한국어', 'KRW  ₩', false, false),
  ('es', 'Español', 'EUR  €', true, false),
  ('fr', 'Français', 'EUR  €', true, false),
  ('de', 'Deutsch', 'EUR  €', true, false),
  ('it', 'Italiano', 'EUR  €', true, false),
  ('pt', 'Português', 'EUR  €', true, false),
];

String currentScreen = 'boot';
final overflows = <String>[];

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100));

Future<void> shot(WidgetTester t, String name) async {
  currentScreen = name;
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

Future<void> pickFromDialog(WidgetTester t, String label) async {
  await t.tap(
      find
          .descendant(
              of: find.byType(SimpleDialog), matching: find.text(label))
          .first,
      warnIfMissed: false);
  await settle(t);
}

/// 設定画面で言語と通貨を切り替える（設定タブに居なければ移動する）。
Future<void> setLanguageAndCurrency(
    WidgetTester t, String nativeName, String currencyRow) async {
  await goTab(t, Icons.settings);
  await t.scrollUntilVisible(find.byKey(const Key('language-tile')), 200);
  await settle(t);
  await tapKey(t, 'language-tile');
  await pickFromDialog(t, nativeName);
  await tapKey(t, 'currency-tile');
  await pickFromDialog(t, currencyRow);
}

/// テンキーで数字列を打つ（'.' は np-dot キー）。
Future<void> typeDigits(WidgetTester t, String s) async {
  for (final ch in s.split('')) {
    if (ch == '.') {
      await tapKey(t, 'np-dot');
    } else {
      await t.tap(find
          .descendant(of: find.byType(Numpad), matching: find.text(ch))
          .first);
      await t.pump(const Duration(milliseconds: 50));
    }
  }
  await settle(t);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('i18n 9言語×主要画面 目視QAスイープ', (t) async {
    SharedPreferences.setMockInitialValues({'onboardingDone': true});
    await bootstrap();
    await t.pumpAndSettle(const Duration(seconds: 1));

    // オーバーフローは落とさず収集（目視QAなので全ロケール分を回収したい）。
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed by')) {
        overflows.add('[$currentScreen] $msg');
        return;
      }
      origOnError?.call(details);
    };

    try {
      for (var i = 0; i < sweeps.length; i++) {
        final (tag, nativeName, currencyRow, hasDecimal, isJpy) = sweeps[i];

        await setLanguageAndCurrency(t, nativeName, currencyRow);
        await shot(t, '${i}_${tag}_1_settings');

        await goTab(t, Icons.calendar_month);
        await shot(t, '${i}_${tag}_2_calendar');

        // 入力画面: 金額を打ってから撮る（start-split は金額>0 で出現）。
        await tapKey(t, 'fab-entry');
        if (isJpy) {
          expect(find.byKey(const Key('scan-receipt')), findsOneWidget,
              reason: '$tag/JPY: OCRボタンが出るべき');
        } else {
          expect(find.byKey(const Key('scan-receipt')), findsNothing,
              reason: '$tag: 非JPYではOCRボタンを隠す');
        }
        if (hasDecimal) {
          expect(find.byKey(const Key('np-dot')), findsOneWidget,
              reason: '$tag: 小数通貨は「.」キー');
          expect(find.byKey(const Key('np-00')), findsNothing);
          await typeDigits(t, '12.50');
          // 小数点記号はロケール依存（en=12.50 / es,fr,de,it,pt=12,50）。
          expect(
              find.descendant(
                  of: find.byKey(const Key('amount-display')),
                  matching: find.textContaining(RegExp(r'12[.,]50'))),
              findsOneWidget,
              reason: '$tag: 12.50（または12,50）が金額表示に出るべき');
        } else {
          expect(find.byKey(const Key('np-dot')), findsNothing,
              reason: '$tag: 0桁通貨に「.」キーは出さない');
          expect(find.byKey(const Key('np-00')), findsOneWidget);
          await typeDigits(t, '1200');
          expect(
              find.descendant(
                  of: find.byKey(const Key('amount-display')),
                  matching: find.textContaining('1,200')),
              findsOneWidget,
              reason: '$tag: 1,200 が金額表示に出るべき');
        }
        await shot(t, '${i}_${tag}_3_entry');

        // 内訳入力（分割）: JPYのみ税トグルが出る（見た目はスクショで確認）。
        await tapKey(t, 'start-split');
        await shot(t, '${i}_${tag}_4_split');
        await tapKey(t, 'cancel-split');
        await tapKey(t, 'entry-back');
      }

      // --- 最終: ja+JPY 保存回帰（保存すると通貨ロックが掛かるため最後） ---
      await setLanguageAndCurrency(t, '日本語', 'JPY  ¥');
      await goTab(t, Icons.calendar_month);
      await tapKey(t, 'fab-entry');
      await typeDigits(t, '12000');
      // タイル表示は「食費 ▾」（内訳ありマーク付き）なので部分一致で探す。
      await t.tap(find.textContaining('食費').first);
      await settle(t);
      await tapKey(t, 'save-btn');
      await t.pumpAndSettle(const Duration(milliseconds: 300));
      // 保存後はカレンダーへ戻り、セルは万表記（1.2万）になる。
      expect(find.textContaining('1.2万'), findsWidgets,
          reason: 'JPY回帰: カレンダーの万表記');
      await shot(t, '9_final_1_calendar_saved');
      await goTab(t, Icons.bar_chart);
      await shot(t, '9_final_2_summary');
    } finally {
      FlutterError.onError = origOnError;
    }

    debugPrint('QA-OVERFLOWS count=${overflows.length}');
    for (final o in overflows) {
      debugPrint('QA-OVERFLOW: $o');
    }
  });
}
