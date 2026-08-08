import 'package:app_badge_plus/app_badge_plus.dart';

/// アプリアイコンのバッジ数を抽象化する（routine-reminder から移植）。
abstract class BadgeService {
  /// バッジ数を設定する（0でクリア）。
  Future<void> setCount(int count);
}

/// iOS向け実装。
class AppBadgePlusBadgeService implements BadgeService {
  @override
  Future<void> setCount(int count) => AppBadgePlus.updateBadge(count);
}

/// iOS以外・テスト向けの何もしない実装（providerの既定値）。
class NoopBadgeService implements BadgeService {
  @override
  Future<void> setCount(int count) async {}
}
