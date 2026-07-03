import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/features/settings/application/settings_controller.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  late ProviderContainer container;

  setUp(() async {
    h = await createHarness();
    container = ProviderContainer(overrides: h.overrides());
    addTearDown(container.dispose);
    addTearDown(h.dispose);
  });

  test('override無しのコアproviderはUnimplementedErrorで落ちる（配線忘れ検知）', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    expect(() => bare.read(appDatabaseProvider), throwsUnimplementedError);
    expect(() => bare.read(sharedPreferencesProvider), throwsUnimplementedError);
  });

  test('repo/backupの配線が解決し、exportJsonがformatVersionを含む', () async {
    expect(container.read(transactionRepositoryProvider), isNotNull);
    expect(container.read(categoryRepositoryProvider), isNotNull);
    final json = await container.read(backupServiceProvider).exportJson();
    expect(json, contains('formatVersion'));
  });

  test('clockは固定注入でき、既定harnessでは2026-07-15', () {
    expect(container.read(clockProvider)(), const CivilDate(2026, 7, 15));
  });

  test('AppSettingsの既定と永続化', () async {
    // harness既定は onboardingDone:true（UIテストでダイアログを抑止するため）
    expect(container.read(appSettingsProvider).onboardingDone, isTrue);
    expect(container.read(appSettingsProvider).retainReceiptImages, isFalse);
    await container.read(appSettingsProvider.notifier).setRetainReceiptImages(true);
    expect(container.read(appSettingsProvider).retainReceiptImages, isTrue);
  });

  test('allCategoriesProviderがシード済みカテゴリを流す', () async {
    final cats = await waitForData(container, allCategoriesProvider);
    expect(cats.map((c) => c.name), contains('食費'));
  });
}
