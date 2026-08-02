import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/domain/money/civil_date.dart';
import 'package:kakeibo_app/domain/services/recurring_schedule.dart';

void main() {
  test('ymOf / nextYm: 年またぎを正しく進める', () {
    expect(ymOf(const CivilDate(2026, 8, 3)), 202608);
    expect(nextYm(202608), 202609);
    expect(nextYm(202612), 202701);
  });

  test('dueDateIn: 短い月は末日に丸める', () {
    expect(dueDateIn(202608, 31), const CivilDate(2026, 8, 31));
    expect(dueDateIn(202602, 31), const CivilDate(2026, 2, 28));
    expect(dueDateIn(202802, 31), const CivilDate(2028, 2, 29)); // 閏年
    expect(dueDateIn(202609, 31), const CivilDate(2026, 9, 30));
    expect(dueDateIn(202609, 15), const CivilDate(2026, 9, 15));
  });

  test('未起票ルール: 開始月から今日まで（期日到来分のみ）', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, [const CivilDate(2026, 8, 1)]);
    expect(p.newLastYm, 202608);
  });

  test('当月の期日がまだ来ていなければ起票しない', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 25,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, isEmpty);
    expect(p.newLastYm, isNull);
  });

  test('数か月ぶりに開くと未起票分をさかのぼって起票（キャッチアップ）', () {
    final p = pendingOccurrences(
      startYm: 202605,
      endYm: null,
      lastGeneratedYm: 202605,
      dayOfMonth: 10,
      today: const CivilDate(2026, 8, 3), // 8/10はまだ
    );
    expect(p.due, [const CivilDate(2026, 6, 10), const CivilDate(2026, 7, 10)]);
    expect(p.newLastYm, 202607);
  });

  test('年またぎキャッチアップ＋2月の末日丸め', () {
    final p = pendingOccurrences(
      startYm: 202512,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 31,
      today: const CivilDate(2026, 3, 31),
    );
    expect(p.due, [
      const CivilDate(2025, 12, 31),
      const CivilDate(2026, 1, 31),
      const CivilDate(2026, 2, 28),
      const CivilDate(2026, 3, 31),
    ]);
    expect(p.newLastYm, 202603);
  });

  test('endYm（両端含む）以降は起票しない', () {
    final p = pendingOccurrences(
      startYm: 202605,
      endYm: 202606,
      lastGeneratedYm: null,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, [const CivilDate(2026, 5, 1), const CivilDate(2026, 6, 1)]);
    expect(p.newLastYm, 202606);
  });

  test('開始月が未来なら何もしない', () {
    final p = pendingOccurrences(
      startYm: 202609,
      endYm: null,
      lastGeneratedYm: null,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, isEmpty);
    expect(p.newLastYm, isNull);
  });

  test('lastGeneratedYm が startYm より前でも startYm より前は起票しない', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: 202601, // 再開時の前進などで過去を指すケース
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, [const CivilDate(2026, 8, 1)]);
    expect(p.newLastYm, 202608);
  });

  test('起票済みの月は二重起票しない（冪等）', () {
    final p = pendingOccurrences(
      startYm: 202608,
      endYm: null,
      lastGeneratedYm: 202608,
      dayOfMonth: 1,
      today: const CivilDate(2026, 8, 3),
    );
    expect(p.due, isEmpty);
    expect(p.newLastYm, 202608);
  });
}
