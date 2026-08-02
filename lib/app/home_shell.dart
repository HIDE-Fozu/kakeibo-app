import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ocr/ocr_fixture_recorder.dart';
import '../features/calendar/application/calendar_providers.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/entry/application/entry_form_controller.dart';
import '../features/entry/presentation/entry_screen.dart';
import '../features/settings/application/backup_controller.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/presentation/onboarding_dialog.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/summary/presentation/summary_screen.dart';
import '../l10n/app_localizations.dart';
import 'navigation.dart';
import 'providers.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 初回のみ: オフライン方針とバックアップ責任の軽量オンボーディング（spec §5.5）
      if (!ref.read(appSettingsProvider).onboardingDone && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingDialog(),
        );
      }
      // 起動時バックアップ（spec §2.1「定期」）。失敗しても起動を妨げない。
      ref
          .read(backupControllerProvider.notifier)
          .runStartupBackupIfStale()
          .catchError((_) => false);
      // 定期ルール（毎月の固定費・収入）の期日到来分を起票。
      _applyRecurringDue();
      // 【テスト期間限定・オプトイン】未送信の収集データを再送
      if (kCollectReceiptPhotosDuringTest &&
          ref.read(appSettingsProvider).autoUploadTestData) {
        ref
            .read(cloudFixtureUploaderProvider)
            .syncPending()
            .catchError((_) => 0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // iOSはアプリが数日メモリに残る。起動時だけだと月をまたいでも起票されない
    // ため、フォアグラウンド復帰でも期日到来分を確認する（冪等なので安全）。
    if (state == AppLifecycleState.resumed) _applyRecurringDue();
  }

  void _applyRecurringDue() {
    ref
        .read(recurringRuleRepositoryProvider)
        .applyDue(ref.read(clockProvider)())
        .catchError((_) => 0);
  }

  /// ボトムタブに出す並び → IndexedStack の index。
  /// 入力(1)はタブに出さず、カレンダーのFABから開く（保存/戻るでカレンダーへ）。
  static const _navToShell = [0, 2, 3];

  void _onSelect(int navIndex) {
    ref.read(homeTabIndexProvider.notifier).set(_navToShell[navIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = ref.watch(homeTabIndexProvider);
    // 入力画面(1)表示中はタブ選択なし → カレンダーを選択表示にしておく。
    final navSelected = _navToShell.indexOf(index);
    // 内訳入力（分割）中かどうか。コンパクト化で隙間ができたためタブを出す。
    final splitActive = ref.watch(
        entryFormControllerProvider.select((s) => s?.splits != null));
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          CalendarScreen(),
          EntryScreen(embedded: true),
          SummaryScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              key: const Key('fab-entry'),
              onPressed: () {
                // 選択日を既定に入力画面へ
                ref
                    .read(entryFormControllerProvider.notifier)
                    .startCreate(ref.read(selectedDayProvider));
                ref.read(homeTabIndexProvider.notifier).set(kInputTabIndex);
              },
              icon: const Icon(Icons.add),
              label: Text(l.homeFabEntryLabel),
            )
          : null,
      // 入力画面表示中は下部タブを隠して縦スペースを空ける（戻るは入力画面の「←」）。
      // ただし内訳入力（分割）中はレイアウトがコンパクトなのでタブを出す（モックv4）。
      bottomNavigationBar: index == kInputTabIndex && !splitActive
          ? null
          : NavigationBar(
              selectedIndex: navSelected < 0 ? 0 : navSelected,
              onDestinationSelected: _onSelect,
              destinations: [
                NavigationDestination(
                    icon: const Icon(Icons.calendar_month),
                    label: l.homeNavCalendar),
                NavigationDestination(
                    icon: const Icon(Icons.bar_chart),
                    label: l.homeNavSummary),
                NavigationDestination(
                    icon: const Icon(Icons.settings),
                    label: l.homeNavSettings),
              ],
            ),
    );
  }
}
