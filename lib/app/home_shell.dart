import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/calendar/application/calendar_providers.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/entry/application/entry_form_controller.dart';
import '../features/entry/presentation/entry_screen.dart';
import '../features/summary/presentation/summary_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            CalendarScreen(),
            SummaryScreen(),
            _PlaceholderTab('(設定 準備中)'), // Task 12 で SettingsScreen に差し替え
          ],
        ),
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                key: const Key('fab-entry'),
                onPressed: () {
                  ref
                      .read(entryFormControllerProvider.notifier)
                      .startCreate(ref.read(selectedDayProvider));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const EntryScreen()),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'カレンダー'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'サマリ'),
            NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
          ],
        ),
      );
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab(this.label);

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
