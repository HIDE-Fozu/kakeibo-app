/// 支払い区分モードの SharedPreferences キー（バックアップと共用）。
///
/// [kPaymentModeEnabledPrefsKey] オフなら未払金の仕組みは一切動かず、
/// これまでどおり全部が即時払いとして扱われる。
/// [kSummaryBasisCashPrefsKey] は上部サマリの数え方:
/// true = 現金主義（引き落とし日で数える・見出しは「支払い」）/
/// false = 発生主義（買った日で数える・見出しは「支出」）。
/// モードがオフのときは常に発生主義＝従来どおりの表示になる。
library;

const String kPaymentModeEnabledPrefsKey = 'paymentModeEnabled';
const String kSummaryBasisCashPrefsKey = 'summaryBasisCash';
