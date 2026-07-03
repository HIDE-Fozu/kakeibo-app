import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            _PlaceholderTab('(カレンダー 準備中)'), // Task 8 で CalendarScreen に差し替え
            _PlaceholderTab('(サマリ 準備中)'), // Task 9 で SummaryScreen に差し替え
            _PlaceholderTab('(設定 準備中)'), // Task 12 で SettingsScreen に差し替え
          ],
        ),
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
