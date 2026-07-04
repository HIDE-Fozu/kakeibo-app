import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/calendar/application/calendar_providers.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/entry/application/entry_form_controller.dart';
import '../features/entry/presentation/entry_screen.dart';
import '../features/settings/application/backup_controller.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/presentation/onboarding_dialog.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/summary/presentation/summary_screen.dart';
import 'navigation.dart';
import 'providers.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
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
    });
  }

  void _onSelect(int i) {
    if (i == kInputTabIndex) _ensureCreate();
    ref.read(homeTabIndexProvider.notifier).set(i);
  }

  /// 入力タブは新規作成で開く（編集/レシート状態を持ち越さない）。
  /// 既に新規作成の途中なら維持する（タブ往復で入力中の内容を失わない）。
  void _ensureCreate() {
    final s = ref.read(entryFormControllerProvider);
    if (s == null || s.mode != EntryMode.create) {
      ref
          .read(entryFormControllerProvider.notifier)
          .startCreate(ref.read(clockProvider)());
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabIndexProvider);
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
          ? FloatingActionButton(
              key: const Key('fab-entry'),
              onPressed: () {
                // 選択日を既定に入力タブへ
                ref
                    .read(entryFormControllerProvider.notifier)
                    .startCreate(ref.read(selectedDayProvider));
                ref.read(homeTabIndexProvider.notifier).set(kInputTabIndex);
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onSelect,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'カレンダー'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: '入力'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'サマリ'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
