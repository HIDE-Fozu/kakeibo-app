/// 毎月の予算（設定でオンオフ・毎月共通の1金額）の SharedPreferences キー。
/// 設定側（AppSettings）とバックアップ（形式v9）が共用する。
/// 金額は最小単位（JPY=円・USD=セント）。
const String kBudgetEnabledPrefsKey = 'budgetEnabled';
const String kMonthlyBudgetMinorPrefsKey = 'monthlyBudgetMinor';
