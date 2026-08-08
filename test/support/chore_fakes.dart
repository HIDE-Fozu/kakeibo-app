import 'package:kakeibo_app/data/notifications/badge_service.dart';
import 'package:kakeibo_app/data/notifications/notification_service.dart';

/// 呼び出し内容を記録するテスト用NotificationService
/// （routine-reminder の fakes.dart を移植）。
class FakeNotificationService implements NotificationService {
  final List<List<ScheduledNotification>> rescheduleCalls = [];
  int? lastHour;
  int? lastMinute;
  int requestCount = 0;

  /// trueにするとrequestPermission()が例外を投げる（iOS実機のplatform channel
  /// 例外=MissingPluginException/PlatformException相当の回帰テスト用）。
  bool throwOnRequestPermission = false;

  /// requestPermission()の戻り値（既定true＝許可済み）。
  bool permissionResult = true;

  /// checkPermissionStatus()の戻り値（既定true＝許可済み）。false=拒否、
  /// null=判定不能をシミュレートできる（設定画面テスト用）。
  bool? checkResult = true;

  /// checkPermissionStatus()の呼び出し回数（「OSを呼んでいない」ことの証明用）。
  int checkCount = 0;

  /// trueにするとcheckPermissionStatus()が例外を投げる。
  bool throwOnCheck = false;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    if (throwOnRequestPermission) {
      throw Exception('requestPermission failed (simulated platform error)');
    }
    return permissionResult;
  }

  @override
  Future<bool?> checkPermissionStatus() async {
    checkCount++;
    if (throwOnCheck) {
      throw Exception('checkPermissions failed (simulated platform error)');
    }
    return checkResult;
  }

  @override
  Future<void> rescheduleAll(
    List<ScheduledNotification> plans, {
    required int hour,
    required int minute,
  }) async {
    rescheduleCalls.add(plans);
    lastHour = hour;
    lastMinute = minute;
  }
}

/// 呼び出し内容を記録するテスト用BadgeService。
class FakeBadgeService implements BadgeService {
  final List<int> setCalls = [];

  @override
  Future<void> setCount(int count) async {
    setCalls.add(count);
  }
}
