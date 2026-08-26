/// 永続化される enum。順序変更に強い textEnum(.name) で保存する。
/// 要素の追加は末尾/任意位置に可（.name 保存のため既存行は壊れない）。
/// 要素の「リネーム」は既存データを壊すのでマイグレーション必須。
enum TxnType { expense, income }

enum CategoryType { expense, income }

enum PaymentMethod { cash, creditCard, eMoney, bankDraft, other }

enum TxnSource { manual, receiptOcr, recurring }

/// カードの支払日が休業日（土日祝）に当たったときの寄せ方（v12で追加）。
/// next=翌営業日（日本のカードの主流）/ previous=前営業日 / none=調整しない。
enum BusinessDayRule { none, next, previous }

/// つきいちタスクの繰り返し方（v9で追加）。
/// monthlyDay=毎月N日（dayOfMonth を使う）/ everyDays=N日ごと（intervalDays を使う）。
enum ChoreRepeatUnit { monthlyDay, everyDays }

CategoryType categoryTypeOf(TxnType t) =>
    t == TxnType.expense ? CategoryType.expense : CategoryType.income;
