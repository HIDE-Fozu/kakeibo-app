import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kakeibo_app/app/providers.dart';
import 'package:kakeibo_app/app/theme.dart';
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

  test('ページ色/アクセント色の既定と永続化', () async {
    // 未設定なら既定（kPaper / kPrimary）
    expect(container.read(appSettingsProvider).pageColor.toARGB32(),
        kPaper.toARGB32());
    expect(container.read(appSettingsProvider).accentColor.toARGB32(),
        kPrimary.toARGB32());

    const newPage = Color(0xFFEAF4EF);
    const newAccent = Color(0xFF4F80B0);
    await container.read(appSettingsProvider.notifier).setPageColor(newPage);
    await container.read(appSettingsProvider.notifier).setAccentColor(newAccent);
    expect(container.read(appSettingsProvider).pageColor.toARGB32(),
        newPage.toARGB32());
    expect(container.read(appSettingsProvider).accentColor.toARGB32(),
        newAccent.toARGB32());
  });

  test('旧既定色が保存されていたら未設定に移行し、新パレットに追従する', () async {
    // ピッカーの「既定に戻す」は当時の既定値をそのまま保存するため、
    // 旧既定（深緑など）が残っているとパレット更新が反映されない。
    final h2 = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'accentColor': 0xFF2F7A6A, // build 41-42 の既定緑
      'pageColor': 0xFFFFFCF7, // build 40 の既定背景
    });
    addTearDown(h2.dispose);
    final c2 = ProviderContainer(overrides: h2.overrides());
    addTearDown(c2.dispose);
    expect(c2.read(appSettingsProvider).accentColor.toARGB32(),
        kPrimary.toARGB32());
    expect(c2.read(appSettingsProvider).pageColor.toARGB32(),
        kPaper.toARGB32());
    // キーごと消えている（次回以降も既定に追従）
    expect(h2.prefs.getInt('accentColor'), isNull);
    expect(h2.prefs.getInt('pageColor'), isNull);

    // 旧既定と一致しないカスタム色は移行されない
    final h3 = await createHarness(prefs: {
      'onboardingDone': true,
      'locale': 'ja',
      'accentColor': 0xFF4F80B0,
    });
    addTearDown(h3.dispose);
    final c3 = ProviderContainer(overrides: h3.overrides());
    addTearDown(c3.dispose);
    expect(c3.read(appSettingsProvider).accentColor.toARGB32(), 0xFF4F80B0);
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
