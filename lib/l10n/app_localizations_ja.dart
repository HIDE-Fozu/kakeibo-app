// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '家計簿';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonSave => '保存';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsCurrency => '通貨';

  @override
  String get languageSystemDefault => '端末の言語に合わせる';

  @override
  String get currencyLockedSubtitle => '取引があるため変更できません';

  @override
  String get currencyLockedTitle => '通貨は変更できません';

  @override
  String get currencyLockedBody => '過去の金額を正しく保つため、取引を記録した後は通貨を変更できません。';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return '自動バックアップ $generations世代（端末内）';
  }

  @override
  String get settingsBackupNowTitle => '今すぐバックアップ';

  @override
  String get settingsExportJsonTitle => 'JSONエクスポート';

  @override
  String get settingsExportJsonSubtitle => '任意でパスフレーズ暗号化（復元に使えます）';

  @override
  String get settingsExportCsvTitle => 'CSVエクスポート';

  @override
  String get settingsExportCsvSubtitle => '閲覧用（復元には使えません）';

  @override
  String get settingsRestoreTitle => '復元';

  @override
  String get settingsRestoreSubtitle => '全データを置き換えます';

  @override
  String get settingsTestUploadTitle => 'テスト協力（自動送信）';

  @override
  String get settingsTestUploadSubtitle =>
      'レシート読み取りの改善のため、スキャンの記録と写真を開発者へ自動送信します（テスト期間限定）。家計簿の入力内容そのものは送信しません';

  @override
  String get settingsShareTestDataTitle => 'テストデータを送る';

  @override
  String get settingsShareTestDataSubtitle => '手動でまとめて共有（LINE/AirDrop）';

  @override
  String get settingsFetchCollectedTitle => '収集データを取り込む（開発者用）';

  @override
  String get settingsFetchCollectedSubtitle =>
      '全端末分をこの端末の exports/ocr-collected へ';

  @override
  String get settingsRetainImagesTitle => 'レシート画像をローカル保持';

  @override
  String get settingsRetainImagesSubtitle => '既定では保存後に破棄します';

  @override
  String get settingsCategoryManageTitle => 'カテゴリ管理';

  @override
  String get settingsCategoryOrderTitle => 'カテゴリを自分の順で並べる';

  @override
  String get settingsCategoryOrderSubtitle =>
      'オフ=最近使った順 / オン=固定順（入力画面でタイル長押し→並べ替え）';

  @override
  String get settingsDataPolicyTitle => 'データの取り扱いについて';

  @override
  String get settingsDataPolicyBody =>
      '・記録は端末の中だけに保存されます。自動で外部に送信されることはありません。\n・端末内で自動バックアップを取りますが、機種変更や端末の故障に備えて、設定からエクスポートを保存してください。';

  @override
  String get settingsPassphraseFieldLabel => 'パスフレーズ（暗号化する場合）';

  @override
  String get settingsSaveAsIs => 'そのまま保存';

  @override
  String get settingsSaveEncrypted => '暗号化して保存';

  @override
  String get settingsBackupSuccessSnackbar => 'バックアップを作成しました';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'バックアップに失敗しました: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return '保存しました: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return '$count 件を取り込みました（exports/ocr-collected）';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return '取り込みに失敗しました: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar => 'まだスキャンの記録がありません';

  @override
  String settingsShareTestDataSubject(int count) {
    return '家計簿テストデータ（$count件）';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return '送信に失敗しました: $error';
  }

  @override
  String get entryTitleCreate => '入力';

  @override
  String get entryTitleReceiptConfirm => 'レシート確認';

  @override
  String get commonEdit => '編集';

  @override
  String get entryTypeExpense => '支出';

  @override
  String get entryTypeIncome => '収入';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get entryStartSplitButton => 'カテゴリを追加';

  @override
  String get entryCategoryHeading => 'カテゴリ';

  @override
  String get entryDetailMemoLabel => '詳細メモ';

  @override
  String get entryStoreNameLabel => '店舗名';

  @override
  String get entryCompanyNameLabel => '会社名';

  @override
  String get entrySaveContinueButton => '保存して続ける';

  @override
  String get entrySavedSnackbar => '保存しました';

  @override
  String get entryReceiptCaptureUnavailableSnackbar => 'この端末ではレシート撮影を利用できません';

  @override
  String entryOcrFailedSnackbar(String error) {
    return '読み取りに失敗しました: $error';
  }

  @override
  String get entryReceiptSourceCamera => 'カメラで撮影';

  @override
  String get entryReceiptSourceLibrary => '写真から選ぶ';

  @override
  String get entryDeleteConfirmTitle => '削除しますか？';

  @override
  String get entryDeleteConfirmContent => 'この取引を削除します。';

  @override
  String get commonDelete => '削除';

  @override
  String get batchPanelTitle => '一括内訳';

  @override
  String get batchModeSelectAssign => '選んで割当';

  @override
  String get batchModePaint => '塗り分け';

  @override
  String get batchCancelButton => 'やめる';

  @override
  String get batchThisReceiptLabel => 'このレシート:';

  @override
  String get batchTaxIncluded => '内税';

  @override
  String get batchTaxExclusive8 => '外税8%';

  @override
  String get batchTaxExclusive10 => '外税10%';

  @override
  String get batchPaintHintNoCategory => '下のカテゴリを選んでから、行をタップして塗り分け';

  @override
  String batchPaintHintActive(String name) {
    return '「$name」を塗り中 — 行をタップ（もう一度で解除）';
  }

  @override
  String get batchSelectHint => '行を選択 → 下のカテゴリをタップして割当';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '選択中 $count件 $amount → 下のカテゴリをタップ';
  }

  @override
  String get batchNoAssignmentsYet => '（まだ割当がありません）';

  @override
  String get batchCategoryUnknown => '不明';

  @override
  String get batchDiffPickCategory => '残り（差額）— タップしてカテゴリを選ぶ';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category（差額）';
  }

  @override
  String get batchReceiptFallbackLabel => 'レシート';

  @override
  String get batchTotalLabel => '合計';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess 超過';
  }

  @override
  String get restorePageTitle => '復元';

  @override
  String get restoreEmptyMessage => '復元できるバックアップがありません';

  @override
  String get restoreConfirmTitle => '復元しますか？';

  @override
  String get restoreConfirmMessage =>
      '現在のデータはすべて置き換えられます。直前の状態は自動退避され、あとで取り出せます。';

  @override
  String get restoreButton => '復元';

  @override
  String get restoreEmptyBackupTitle => '取引が0件のバックアップです';

  @override
  String get restoreEmptyBackupMessage => '復元するとすべての取引が消えます。それでも復元しますか？';

  @override
  String get restoreEmptyBackupConfirmButton => '復元する';

  @override
  String restoreFailedMessage(String error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get restoreSuccessMessage => '復元しました';

  @override
  String get restorePassphraseTitle => 'パスフレーズを入力';

  @override
  String get commonAdd => '追加';

  @override
  String get categoryRenameAction => '名前を変更';

  @override
  String get categorySubcategoryRenameTitle => '内訳を改名';

  @override
  String get categoryNameFieldLabel => '名前';

  @override
  String get categorySubcategoryAddTitle => '内訳を追加';

  @override
  String get categoryIconFieldLabel => 'アイコン（絵文字・任意）';

  @override
  String get categoryEditExistingTitle => '既存の内容を編集';

  @override
  String get categoryIconOrderTitle => 'アイコンの表示順設定';

  @override
  String get categoryIconOrderHint => 'ドラッグで並べ替え（自分の順で表示されます）';

  @override
  String get categoryManageTitle => 'カテゴリ管理';

  @override
  String get categoryTabExpense => '支出';

  @override
  String get categoryTabIncome => '収入';

  @override
  String get categorySubAddTitle => '内訳を追加';

  @override
  String get categoryAddTitle => '新しいカテゴリ';

  @override
  String get categorySubRenameTitle => '内訳を改名';

  @override
  String get categoryRenameTitle => 'カテゴリを改名';

  @override
  String get categorySubAddTooltip => '内訳を追加';

  @override
  String get categoryArchiveBlockedSnackbar => '内訳を先にアーカイブしてください';

  @override
  String get categoryArchivedSectionTitle => 'アーカイブ済み';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name（アーカイブ）';
  }

  @override
  String get splitCancel => 'やめる';

  @override
  String get splitBreakdownLabel => '内訳';

  @override
  String get splitTaxLabel => '消費税';

  @override
  String get splitTaxIncludedToggle => '内税';

  @override
  String get splitTaxExcludedToggle => '外税';

  @override
  String get splitTaxIndividual => '個別';

  @override
  String get splitMemoHint => 'メモ';

  @override
  String get splitCategoryUnselected => 'カテゴリ未選択';

  @override
  String get splitAmountEmpty => '金額未入力';

  @override
  String splitTaxIncludedAmount(String amount) {
    return '税込 $amount';
  }

  @override
  String get splitOverLabel => '超過';

  @override
  String get splitRemainingLabel => '残り';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get summaryEmptyTitle => 'この月のデータはまだありません';

  @override
  String get summaryEmptyHint => 'カレンダーの＋から入力できます';

  @override
  String get summaryIncomeLabel => '収入';

  @override
  String get summaryExpenseLabel => '支出';

  @override
  String get summaryNetLabel => '差引';

  @override
  String get summaryCategoryBreakdownTitle => 'カテゴリ別支出';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name（アーカイブ）';
  }

  @override
  String get summaryBreakdownCollapse => '▲ 内訳';

  @override
  String get summaryBreakdownExpand => '▼ 内訳';

  @override
  String get summaryNoBreakdownLabel => '（内訳なし）';

  @override
  String get entryNoImage => '画像なし';

  @override
  String get entryAmountReadFailed => '金額を読み取れませんでした。手入力してください';

  @override
  String get entryStoreDirectInput => '直接入力';

  @override
  String get entryStoreNameDialogTitle => '店舗名を入力';

  @override
  String get commonOk => '決定';

  @override
  String get calendarWeekdaySun => '日';

  @override
  String get calendarWeekdayMon => '月';

  @override
  String get calendarWeekdayTue => '火';

  @override
  String get calendarWeekdayWed => '水';

  @override
  String get calendarWeekdayThu => '木';

  @override
  String get calendarWeekdayFri => '金';

  @override
  String get calendarWeekdaySat => '土';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$year年$month月';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return '支出 $expense　収入 $income　差引 $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return '$month月$day日の記録はありません';
  }

  @override
  String get calendarDayEmptyHintFirst => '右下の「金額を入力する」から最初の記録を追加できます';

  @override
  String get calendarDayEmptyHint => '右下の「金額を入力する」から追加できます';

  @override
  String get calendarReceiptFallbackLabel => 'レシート';

  @override
  String get calendarCategoryUnknown => '不明';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name（アーカイブ）';
  }

  @override
  String get calendarUndoAction => '元に戻す';

  @override
  String get trashMovedSnack => 'ごみ箱に移動しました（設定から復元できます）';

  @override
  String get trashTitle => 'ごみ箱';

  @override
  String get settingsTrashSubtitle => '削除した取引を30日間保管します';

  @override
  String get trashEmpty => 'ごみ箱は空です';

  @override
  String get trashRestore => '復元';

  @override
  String get trashRestoredSnack => '復元しました';

  @override
  String trashDeletedOn(String date) {
    return '$date に削除';
  }

  @override
  String get trashEmptyAction => 'ごみ箱を空にする';

  @override
  String get trashEmptyConfirmTitle => 'ごみ箱を空にしますか？';

  @override
  String get trashEmptyConfirmContent => 'すべての項目が完全に削除されます。この操作は取り消せません。';

  @override
  String get splitTaxDialogTitle => '品目ごとの税率';

  @override
  String get commonDone => '完了';

  @override
  String get splitRemainderLabel => '残り';

  @override
  String splitItemNumberLabel(int index) {
    return '品目$index';
  }

  @override
  String get splitTaxIncludedLabel => '内税';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount（自動）';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → 税込 $net';
  }

  @override
  String get onboardingTitle => 'データの取り扱いについて';

  @override
  String get onboardingBody =>
      '・記録は端末の中だけに保存されます。自動で外部に送信されることはありません。\n・端末内で自動バックアップを取りますが、機種変更や端末の故障に備えて、設定からエクスポートを保存してください。';

  @override
  String get onboardingStartButton => 'はじめる';

  @override
  String get homeFabEntryLabel => '金額を入力する';

  @override
  String get homeNavCalendar => 'カレンダー';

  @override
  String get homeNavSummary => 'サマリ';

  @override
  String get homeNavSettings => '設定';

  @override
  String get categoryManualOrderSnackbar => '自分で並べた順にしました（設定で戻せます）';

  @override
  String get entryHintEnterAmount => '金額を入力してください';

  @override
  String get entryHintAssignItemCategory => '品目にカテゴリを割り当ててください';

  @override
  String get entryHintAssignExceedsTotal => '割り当てが合計を超えています';

  @override
  String get entryHintPickDiffCategory => '差額のカテゴリを選んでください';

  @override
  String get entryHintSplitExceedsTotal => '内訳が合計を超えています';

  @override
  String get entryHintPickCategory => 'カテゴリを選んでください';

  @override
  String get entryHintEnterAmountAndCategory => '金額とカテゴリを入力してください';

  @override
  String get entryHintEnterRemainingAmount => '残りの金額も入力してください';

  @override
  String get settingsBackupNever => 'バックアップ未作成';

  @override
  String get settingsBackupToday => '前回バックアップ: 今日';

  @override
  String settingsBackupDaysAgo(int days) {
    return '前回バックアップ: $days日前';
  }

  @override
  String get recurringPageTitle => '毎月の固定費・収入';

  @override
  String get settingsRecurringSubtitle => '家賃や給料などを毎月自動で記録';

  @override
  String get recurringEmptyMessage =>
      'まだ登録がありません。\n右上の＋から、家賃や給料など毎月の記録を自動化できます';

  @override
  String get recurringAddTitle => '固定費・収入を追加';

  @override
  String get recurringEditTitle => '固定費・収入を編集';

  @override
  String get recurringAmountLabel => '金額';

  @override
  String get recurringDayLabel => '繰り返し入力する日';

  @override
  String recurringEveryMonthDay(int day) {
    return '毎月$day日';
  }

  @override
  String dayOfMonthItem(int day) {
    return '$day日';
  }

  @override
  String get recurringDayClampNote => '31日で入力した場合は月末日に入力されます。例：2月は28日に入力';

  @override
  String get recurringStartMonthLabel => '開始';

  @override
  String get recurringStartThisMonth => '今月から';

  @override
  String get recurringStartNextMonth => '来月から';

  @override
  String get recurringEndMonthLabel => '終了';

  @override
  String get recurringEndNone => '終了なし（ずっと）';

  @override
  String get recurringEndMonthNote => 'この月まで記帳して、以降は止まります';

  @override
  String get recurringActiveTitle => '有効';

  @override
  String get recurringActiveSubtitle => 'オフにすると自動記録を一時停止します';

  @override
  String get recurringPausedLabel => '停止中';

  @override
  String get recurringDeleteConfirmTitle => '削除しますか？';

  @override
  String get recurringDeleteConfirmContent =>
      'この固定費・収入を削除します。作成済みの取引はそのまま残ります。';

  @override
  String entryHintPickCategoryForItem(int n) {
    return '品目$nのカテゴリを選んでください';
  }

  @override
  String get entryHintPickCategoryRemainder => '「残り」の行のカテゴリを選んでください';

  @override
  String get splitMemoDialogTitle => 'メモを入力';

  @override
  String choreNotificationBody(int day) {
    return '毎月$day日の予定です';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return '前回から$days日たちました';
  }

  @override
  String get homeNavMonthly => '毎月';

  @override
  String get hubUpcomingSection => '今月のこれから';

  @override
  String get hubUpcomingEmpty => '今月の残りの予定はありません';

  @override
  String get hubRulesSection => '固定費・収入';

  @override
  String get hubRulesEmpty => '＋から家賃や給料など毎月の記録を自動化できます';

  @override
  String get hubChoresSection => 'つきいちタスク';

  @override
  String get hubChoresEmpty => '＋からハブラシ交換などの家事を登録できます';

  @override
  String get hubChoreTimelineLabel => '家事';

  @override
  String get ghostBadgeLabel => '予定';

  @override
  String get forecastLabelMonthEnd => '見込み収支（月末）';

  @override
  String forecastLabelAtDate(String date) {
    return '見込み収支（$date時点）';
  }

  @override
  String choreOverdueDays(int days) {
    return '$days日超過';
  }

  @override
  String get choreDueToday => '今日';

  @override
  String choreDaysLeft(int days) {
    return 'あと$days日';
  }

  @override
  String choreNextDate(String date) {
    return '次回: $date';
  }

  @override
  String get choreDoneButton => 'やった';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ 記録しました。次回は$date';
  }

  @override
  String get choreDupConfirmTitle => '確認';

  @override
  String choreDupConfirmBody(String name) {
    return '「$name」はこの日はすでに記録があります。追加しますか？';
  }

  @override
  String get choreDupConfirmAdd => '追加';

  @override
  String get choreFormNewTitle => '新しい項目';

  @override
  String get choreFormEditTitle => '項目を編集';

  @override
  String get choreFormNameLabel => '項目名';

  @override
  String get choreRepeatUnitLabel => '繰り返し';

  @override
  String get choreRepeatUnitMonthly => '毎月';

  @override
  String get choreRepeatUnitEveryDays => '日ごと';

  @override
  String get choreFormDayLabel => '予定日';

  @override
  String get choreFormIntervalLabel => '間隔';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days日';
  }

  @override
  String choreIntervalEvery(int days) {
    return '$days日ごと';
  }

  @override
  String get choreFormEmojiLabel => '絵文字（未入力なら📌）';

  @override
  String get choreFormArchiveButton => 'アーカイブする';

  @override
  String get choreFormDeleteButton => 'この項目を削除';

  @override
  String choreDeleteConfirmBody(int count) {
    return '履歴$count件もすべて削除されます';
  }

  @override
  String get choreHistoryTitle => '履歴';

  @override
  String get choreHistoryEmpty => '記録はまだありません';

  @override
  String get choreRecordEditTitle => '記録を編集';

  @override
  String get choreRecordDeleteConfirm => '記録を削除しますか？';

  @override
  String get choreMemoLabel => 'メモ';

  @override
  String get settingsChoresTitle => 'つきいちタスク';

  @override
  String get settingsChoresSubtitle => '通知時刻とアーカイブの管理';

  @override
  String get choreNotifyTimeLabel => '通知時刻';

  @override
  String get chorePermissionChecking => '通知の許可状況を確認中…';

  @override
  String get chorePermissionNotAsked => '通知の確認は最初の記録時に行われます';

  @override
  String get chorePermissionGranted => '通知は有効です';

  @override
  String get chorePermissionDenied => '通知が許可されていません';

  @override
  String get chorePermissionOpenSettings => '設定を開く';

  @override
  String get choreArchivedSection => 'アーカイブ済みの項目';

  @override
  String get choreArchivedEmpty => 'アーカイブ済みの項目はありません';

  @override
  String get choreUnarchiveButton => '元に戻す';

  @override
  String get forecastAnchorSheetTitle => '見込み収支の基準日';

  @override
  String get forecastAnchorSheetNote => '今日から基準日までの予定を実績に足して表示します（基準日当日を含む）';

  @override
  String get forecastAnchorMonthEnd => '月末';

  @override
  String get calendarLegendChoreDone => 'やった';

  @override
  String get calendarLegendChoreDue => '家事の期日';

  @override
  String get calendarLegendChoreOverdue => '期日超過';

  @override
  String get entryRecurringExpense => '毎月の費用';

  @override
  String get entryRecurringIncome => '毎月の収入';

  @override
  String get entrySaveWithRuleExpense => '保存（＋毎月の費用に登録）';

  @override
  String get entrySaveWithRuleIncome => '保存（＋毎月の収入に登録）';

  @override
  String get entryRecurringNotePrefix => '毎月';

  @override
  String get entryRecurringNoteSuffix => '日に自動で記帳します';

  @override
  String get entrySubcategoryAddButton => 'サブカテゴリを追加';

  @override
  String get settingsColorTitle => '色';

  @override
  String get settingsColorSubtitle => '選んだ色に合わせて、背景・罫線・強調色を自動で調整します';

  @override
  String get settingsColorPreset => 'プリセット';

  @override
  String get settingsColorCustom => 'カスタム';

  @override
  String get settingsColorApply => '適用';

  @override
  String get settingsColorDefaultBadge => '既定';

  @override
  String get settingsColorBlue => 'ブルー';

  @override
  String get settingsColorGreen => 'グリーン';

  @override
  String get settingsColorTeal => 'ティール';

  @override
  String get settingsColorPurple => 'パープル';

  @override
  String get settingsColorRose => 'ローズ';

  @override
  String get settingsColorOrange => 'オレンジ';

  @override
  String get settingsColorMustard => 'マスタード';

  @override
  String get settingsColorGray => 'グレー';

  @override
  String get settingsColorTerracotta => 'テラコッタ';

  @override
  String get settingsColorNavy => 'ネイビー';

  @override
  String get installmentTitle => '分割払いを登録';

  @override
  String get installmentAddButton => '分割払い';

  @override
  String get installmentPrincipalLabel => '購入金額';

  @override
  String get installmentCountLabel => '支払い回数';

  @override
  String installmentCountItem(int n) {
    return '$n回';
  }

  @override
  String get installmentRateLabel => '実質年率（%）';

  @override
  String get installmentCardPickLabel => '登録済みカード';

  @override
  String get installmentCardNameLabel => 'カード名称（任意）';

  @override
  String get installmentDayLabel => '支払日';

  @override
  String get installmentMonthlyLabel => '月々の支払い';

  @override
  String get installmentFirstLabel => '初回';

  @override
  String get installmentFeeLabel => '手数料合計';

  @override
  String get installmentTotalLabel => '支払い総額';

  @override
  String installmentTxnMemo(int index, int count) {
    return '分割払い $index/$count回';
  }

  @override
  String get installmentEditTitle => '分割払いを編集';

  @override
  String get installmentDeleteConfirmContent => 'この分割払いと、登録済みの支払い取引をすべて削除します。';

  @override
  String get hubInstallmentEmpty => '分割払いはまだありません';
}
