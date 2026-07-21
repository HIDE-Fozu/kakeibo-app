import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/home_shell.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('初回のみオンボーディング表示→はじめるで永続化', (tester) async {
    setPhoneSurface(tester);
    // onboardingDone未設定=false（オンボーディング表示）。locale は ja に固定して
    // 日本語UIアサートを決定的にする（prefsを渡すと既定のlocale固定が外れるため）。
    final h = await createHarness(prefs: {'locale': 'ja'});
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.text('データの取り扱いについて'), findsOneWidget);

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(find.text('データの取り扱いについて'), findsNothing);
    final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)), listen: false);
    expect(c.read(appSettingsProvider).onboardingDone, isTrue);
  });

  testWidgets('2回目以降は出ない', (tester) async {
    setPhoneSurface(tester);
    final h = await createHarness(); // 既定 onboardingDone:true
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.text('データの取り扱いについて'), findsNothing);
  });
}
