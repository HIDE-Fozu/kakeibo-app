import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n_providers.dart';
import '../../../app/providers.dart';
import '../../../domain/entities.dart';
import '../../../domain/money/civil_date.dart';
import '../../../domain/services/payable_builder.dart';
import '../../../domain/services/payment_schedule.dart';
import '../../../domain/services/recurring_schedule.dart' show ymOf;
import '../../calendar/application/calendar_providers.dart'
    show monthTransactionsProvider;
import '../../chores/application/chore_providers.dart';
import '../../settings/application/settings_controller.dart';

/// その月のカード引き落とし1本ぶん。取引としては起票されず、未払金の
/// 支払い予定から**導出**する（購入と二重計上しないため）。
class CardPaymentLine {
  final PaymentCardEntity card;
  final CivilDate date; // 営業日調整後の実際の引き落とし日
  final int amountMinor;
  const CardPaymentLine({
    required this.card,
    required this.date,
    required this.amountMinor,
  });
}

/// 支払い区分モードがONか（OFFなら以下の provider は全て空を返す）。
final paymentModeEnabledProvider = Provider<bool>(
    (ref) => ref.watch(appSettingsProvider).paymentModeEnabled);

/// 日本の祝日で引き落とし日をずらすか。通貨がJPYのときだけ適用する
/// （日本の銀行の慣行なので、他通貨で使うユーザーの日付をずらさない）。
final useJapaneseHolidaysProvider =
    Provider<bool>((ref) => ref.watch(currencyProvider).code == 'JPY');

/// その支払い月に引き落とされる未払金。
final payablesDueProvider =
    StreamProvider.autoDispose.family<List<PayableEntity>, int>((ref, ym) {
  if (!ref.watch(paymentModeEnabledProvider)) return Stream.value(const []);
  return ref.watch(payableRepositoryProvider).watchForPaymentYm(ym);
});

/// その月に「買った」カード購入の取引ID。現金主義で購入を支払いから外すのに使う。
final cardPurchaseTxIdsProvider = StreamProvider.autoDispose
    .family<Set<int>, (int, int)>((ref, key) {
  if (!ref.watch(paymentModeEnabledProvider)) return Stream.value(const {});
  return ref
      .watch(payableRepositoryProvider)
      .watchCardPurchaseTxIdsIn(key.$1, key.$2);
});

/// その月のカード引き落とし（カードごとに1行）。金額0のカードは出さない。
final cardPaymentsProvider = Provider.autoDispose
    .family<List<CardPaymentLine>, (int, int)>((ref, key) {
  if (!ref.watch(paymentModeEnabledProvider)) return const [];
  final ym = key.$1 * 100 + key.$2;
  final due = ref.watch(payablesDueProvider(ym)).valueOrNull ?? const [];
  if (due.isEmpty) return const [];
  final cards = ref.watch(paymentCardsProvider).valueOrNull ?? const [];
  final jp = ref.watch(useJapaneseHolidaysProvider);

  final out = <CardPaymentLine>[];
  for (final c in cards) {
    final amount = cardTotalDueIn(due, c.id!, ym);
    if (amount <= 0) continue;
    out.add(CardPaymentLine(
      card: c,
      date: paymentDateIn(
        ym: ym,
        payDay: c.payDay,
        rule: c.businessDayRule,
        japaneseHolidays: jp,
      ),
      amountMinor: amount,
    ));
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
});

/// その日に引き落とされるカード（日別リストの行に出す）。
final cardPaymentsOnDayProvider =
    Provider.autoDispose.family<List<CardPaymentLine>, CivilDate>((ref, day) {
  final lines = ref.watch(cardPaymentsProvider((day.year, day.month)));
  return [for (final l in lines) if (l.date == day) l];
});

/// 上部サマリで「今日まで」に数えるカード引き落としの合計。
/// 当月は引き落とし日が today 以前のものだけ（実績の定義を購入側と揃える）。
final cardPaymentsToDateProvider =
    Provider.autoDispose.family<int, (int, int)>((ref, key) {
  final lines = ref.watch(cardPaymentsProvider(key));
  if (lines.isEmpty) return 0;
  final today = ref.watch(choreTodayProvider);
  final bounded = key.$1 == today.year && key.$2 == today.month;
  var sum = 0;
  for (final l in lines) {
    if (bounded && l.date.isAfter(today)) continue;
    sum += l.amountMinor;
  }
  return sum;
});

/// 行のバッジ（いつ払うか）。取引IDごとに1つ。
final payableBadgesOnMonthProvider = Provider.autoDispose
    .family<Map<int, PayableBadge>, (int, int)>((ref, key) {
  if (!ref.watch(paymentModeEnabledProvider)) return const {};
  final byTx = ref.watch(payablesPurchasedInProvider(key)).valueOrNull;
  if (byTx == null || byTx.isEmpty) return const {};
  final txs = ref.watch(monthTransactionsProvider(key)).valueOrNull;
  if (txs == null) return const {};
  final dateById = {for (final t in txs) t.id: t.date};
  return {
    for (final e in byTx.entries)
      if (dateById[e.key] != null)
        e.key: payableBadgeOf(e.value, dateById[e.key]!),
  };
});

final payablesPurchasedInProvider = StreamProvider.autoDispose
    .family<Map<int, PayableEntity>, (int, int)>((ref, key) {
  if (!ref.watch(paymentModeEnabledProvider)) return Stream.value(const {});
  return ref
      .watch(payableRepositoryProvider)
      .watchPayablesPurchasedIn(key.$1, key.$2);
});

/// 購入日に「未払」と出すための、その日のカード購入の取引ID。
final cardPurchaseTxIdsOnMonthProvider =
    Provider.autoDispose.family<Set<int>, (int, int)>((ref, key) =>
        ref.watch(cardPurchaseTxIdsProvider(key)).valueOrNull ?? const {});

/// 未払金の支払い月から、その未払金が属する「引き落とし日」を出す補助。
CivilDate? paymentDateOf(
  PayableEntity payable,
  PaymentCardEntity card, {
  required int ym,
  required bool japaneseHolidays,
}) {
  if (amountDueIn(payable, ym) <= 0) return null;
  return paymentDateIn(
    ym: ym,
    payDay: card.payDay,
    rule: card.businessDayRule,
    japaneseHolidays: japaneseHolidays,
  );
}

/// 購入日から決まる既定の支払い月（UIから使う薄いラッパ）。
int defaultPaymentYmOf(CivilDate purchaseDate) =>
    defaultPaymentYm(purchaseDate);

/// CivilDate → YYYYMM（UIから使う薄いラッパ）。
int ymOfDate(CivilDate d) => ymOf(d);
