import 'dart:async' show unawaited;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/services/chore_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chore_actions.dart';
import '../application/chore_providers.dart';

/// 設定 → つきいちタスク。通知時刻の変更・通知許可状態の表示・
/// アーカイブ済み項目の復元（routine-reminder の settings_screen.dart を移植）。
class ChoreNotificationSettingsPage extends ConsumerStatefulWidget {
  const ChoreNotificationSettingsPage({super.key});

  @override
  ConsumerState<ChoreNotificationSettingsPage> createState() =>
      _ChoreNotificationSettingsPageState();
}

/// 許可タイルの表示状態。
enum _PermissionUi {
  /// 判定中/判定不能（checkPermissionStatus()完了前・例外・null応答）。
  unknown,

  /// 許可要求（初回記録直後）がまだ行われていない。OSは一切呼ばず案内のみ。
  notAskedYet,

  granted,
  denied,
}

class _ChoreNotificationSettingsPageState
    extends ConsumerState<ChoreNotificationSettingsPage> {
  _PermissionUi _permission = _PermissionUi.unknown;
  late (int, int) _notifyTime;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _notifyTime = (
      prefs.getInt(kChoreNotifyHourPrefsKey) ?? kChoreDefaultNotifyHour,
      prefs.getInt(kChoreNotifyMinutePrefsKey) ?? kChoreDefaultNotifyMinute,
    );
    // 「許可ダイアログは初回記録直後の一度だけ」との整合:
    // requestPermission()は未確定(notDetermined)だとその場でOSダイアログを出して
    // しまうため、設定画面では絶対に呼ばない。まだ要求していなければOSにも触れず
    // 案内文のみ、要求済みなら読み取り専用のcheckPermissionStatus()で判定する。
    final asked = prefs.getBool(kChorePermissionAskedPrefsKey) ?? false;
    if (asked) {
      unawaited(_checkPermission());
    } else {
      _permission = _PermissionUi.notAskedYet;
    }
  }

  /// 許可状態をダイアログなしで読み取る。platform channel例外等で失敗しても
  /// 画面をクラッシュさせず未判定（確認中…）表示のままにする。
  Future<void> _checkPermission() async {
    try {
      final enabled =
          await ref.read(notificationServiceProvider).checkPermissionStatus();
      if (!mounted) return;
      setState(() {
        _permission = switch (enabled) {
          true => _PermissionUi.granted,
          false => _PermissionUi.denied,
          null => _PermissionUi.unknown,
        };
      });
    } catch (_) {
      // 未判定表示のまま（クラッシュさせない）。
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifyTime.$1, minute: _notifyTime.$2),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(choreActionsProvider)
        .setNotifyTime(picked.hour, picked.minute);
    if (!mounted) return;
    setState(() => _notifyTime = (picked.hour, picked.minute));
  }

  String _permissionText(AppLocalizations l) => switch (_permission) {
        _PermissionUi.unknown => l.chorePermissionChecking,
        _PermissionUi.notAskedYet => l.chorePermissionNotAsked,
        _PermissionUi.granted => l.chorePermissionGranted,
        _PermissionUi.denied => l.chorePermissionDenied,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tasks = ref.watch(choreTasksProvider).valueOrNull ?? const [];
    final archivedTasks = tasks.where((t) => t.archived).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsChoresTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              key: const Key('chore-notify-time-tile'),
              leading: const Icon(Icons.schedule),
              title: Text(l.choreNotifyTimeLabel),
              trailing: Text(
                '${_notifyTime.$1}:${_notifyTime.$2.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => unawaited(_pickTime()),
            ),
            ListTile(
              key: const Key('chore-permission-tile'),
              leading: const Icon(Icons.notifications_outlined),
              title: Text(_permissionText(l)),
              subtitle: _permission == _PermissionUi.denied
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () => unawaited(
                          AppSettings.openAppSettings(
                            type: AppSettingsType.notification,
                          ),
                        ),
                        child: Text(l.chorePermissionOpenSettings),
                      ),
                    )
                  : null,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l.choreArchivedSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (archivedTasks.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(l.choreArchivedEmpty),
              )
            else
              ...archivedTasks.map(
                (t) => ListTile(
                  title: Text('${t.emoji} ${t.name}'),
                  trailing: TextButton(
                    key: Key('chore-unarchive-${t.id}'),
                    onPressed: () => unawaited(
                      ref
                          .read(choreActionsProvider)
                          .setArchived(t.id, false),
                    ),
                    child: Text(l.choreUnarchiveButton),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
