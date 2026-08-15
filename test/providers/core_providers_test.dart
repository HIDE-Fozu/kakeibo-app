import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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

  test('テーマ色の既定と永続化（null=既定・キー削除で常に既定へ追従）', () async {
    // 未設定なら null（= 既定パレット）
    expect(container.read(appSettingsProvider).themeColor, isNull);

    const custom = Color(0xFF4F80B0);
    await container.read(appSettingsProvider.notifier).setThemeColor(custom);
    expect(container.read(appSettingsProvider).themeColor?.toARGB32(),
        custom.toARGB32());

    // null を渡すとキーごと消える（値を焼き込まない）
    await container.read(appSettingsProvider.notifier).setThemeColor(null);
    expect(container.read(appSettingsProvider).themeColor, isNull);
    expect(h.prefs.getInt('themeColor'), isNull);
  });

  test('旧2本立ての色設定（pageColor/accentColor）は起動時に破棄される', () async {
    final h2 = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'accentColor': 0xFF2F7A6A,
      'pageColor': 0xFFFFFCF7,
    });
    addTearDown(h2.dispose);
    final c2 = ProviderContainer(overrides: h2.overrides());
    addTearDown(c2.dispose);
    expect(c2.read(appSettingsProvider).themeColor, isNull);
    expect(h2.prefs.getInt('accentColor'), isNull);
    expect(h2.prefs.getInt('pageColor'), isNull);
  });

  test('カテゴリ並び順モードの既定と永続化', () async {
    // 既定は「最近使った順」
    expect(container.read(appSettingsProvider).categoryOrder,
        CategoryOrderMode.recentlyUsed);
    await container
        .read(appSettingsProvider.notifier)
        .setCategoryOrder(CategoryOrderMode.manual);
    expect(container.read(appSettingsProvider).categoryOrder,
        CategoryOrderMode.manual);
  });

  test('allCategoriesProviderがシード済みカテゴリを流す', () async {
    final cats = await waitForData(container, allCategoriesProvider);
    expect(cats.map((c) => c.name), contains('食費'));
  });
}
