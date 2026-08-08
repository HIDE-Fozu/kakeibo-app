import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/money/civil_date.dart';

/// 予約する通知1件分（文言は組み立て済み）。
/// 文言の組み立ては ChoreActions（l10n）が行い、この層は予約に徹する。
class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final CivilDate date;

  /// 発火時にアイコンへ表示するバッジ数。
  final int badge;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.badge,
  });
}

/// 通知の許可要求と一括再予約を抽象化する（routine-reminder から移植）。
abstract class NotificationService {
  /// 通知の許可をユーザーに要求する（初回記録直後に一度だけ呼ぶ）。
  Future<bool> requestPermission();

  /// 現在の許可状態を**ダイアログを出さずに**読み取る（設定画面用）。
  /// true=許可済み / false=拒否 / null=判定不能（プラットフォーム非対応等）。
  Future<bool?> checkPermissionStatus();

  /// [plans]の内容で予約済み通知を全キャンセル→全予約し直す。
  /// 差分管理はしない（単純さ優先）。[hour]/[minute]はアプリ全体の通知時刻。
  Future<void> rescheduleAll(
    List<ScheduledNotification> plans, {
    required int hour,
    required int minute,
  });
}

/// iOS向け実装。flutter_local_notificationsの`zonedSchedule`で予約する。
///
/// tzデータベースの初期化（`tz.initializeTimeZones`等）はbootstrap側の責務。
/// このクラスは初期化済みの`tz.local`を使うだけにする。
class IosNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initFuture;

  /// プラグインの初期化を一度だけ行う。許可要求フラグは全falseにし、
  /// 許可の要求は[requestPermission]で明示的に行う。
  Future<void> _ensureInitialized() {
    return _initFuture ??= _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          requestProvisionalPermission: false,
          requestCriticalPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  @override
  Future<bool?> checkPermissionStatus() async {
    await _ensureInitialized();
    final options = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return options?.isEnabled;
  }

  @override
  Future<void> rescheduleAll(
    List<ScheduledNotification> plans, {
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final plan in plans) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        plan.date.year,
        plan.date.month,
        plan.date.day,
        hour,
        minute,
      );
      // 予約時点ですでに経過したdatetimeはskip（過去分は再通知しない方針）。
      if (!scheduledDate.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: plan.id,
        title: plan.title,
        body: plan.body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            badgeNumber: plan.badge,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }
}

/// iOS以外・テスト向けの何もしない実装（providerの既定値）。
class NoopNotificationService implements NotificationService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool?> checkPermissionStatus() async => false;

  @override
  Future<void> rescheduleAll(
    List<ScheduledNotification> plans, {
    required int hour,
    required int minute,
  }) async {}
}
