// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kakeibo';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get currencyLockedSubtitle => 'Locked — transactions already exist';

  @override
  String get currencyLockedTitle => 'Currency can\'t be changed';

  @override
  String get currencyLockedBody =>
      'To keep past amounts consistent, the currency can\'t be changed once transactions have been recorded.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return 'Auto backup: $generations generations (on device)';
  }

  @override
  String get settingsBackupNowTitle => 'Back up now';

  @override
  String get settingsExportJsonTitle => 'Export JSON';

  @override
  String get settingsExportJsonSubtitle =>
      'Optionally encrypt with a passphrase (usable for restore)';

  @override
  String get settingsExportCsvTitle => 'Export CSV';

  @override
  String get settingsExportCsvSubtitle =>
      'For viewing only (cannot be used to restore)';

  @override
  String get settingsRestoreTitle => 'Restore';

  @override
  String get settingsRestoreSubtitle => 'Replaces all data';

  @override
  String get settingsTestUploadTitle => 'Test cooperation (auto-send)';

  @override
  String get settingsTestUploadSubtitle =>
      'To improve receipt scanning, scan records and photos are automatically sent to the developer (testing period only). Your household ledger entries themselves are never sent.';

  @override
  String get settingsShareTestDataTitle => 'Send test data';

  @override
  String get settingsShareTestDataSubtitle =>
      'Share manually all at once (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle =>
      'Import collected data (developer only)';

  @override
  String get settingsFetchCollectedSubtitle =>
      'Import data from all devices into this device\'s exports/ocr-collected';

  @override
  String get settingsRetainImagesTitle => 'Keep receipt images on device';

  @override
  String get settingsRetainImagesSubtitle =>
      'Discarded after saving by default';

  @override
  String get settingsCategoryManageTitle => 'Manage categories';

  @override
  String get settingsCategoryOrderTitle => 'Arrange categories in my own order';

  @override
  String get settingsCategoryOrderSubtitle =>
      'Off = most recently used / On = fixed order (long-press a tile on the entry screen to reorder)';

  @override
  String get settingsDataPolicyTitle => 'About data handling';

  @override
  String get settingsDataPolicyBody =>
      '• Your records are stored only on this device. They are never sent externally automatically.\n• Automatic backups are made on this device, but please also save an export from Settings in case you switch devices or your device breaks.';

  @override
  String get settingsPassphraseFieldLabel => 'Passphrase (if encrypting)';

  @override
  String get settingsSaveAsIs => 'Save as is';

  @override
  String get settingsSaveEncrypted => 'Encrypt and save';

  @override
  String get settingsBackupSuccessSnackbar => 'Backup created';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'Backup failed: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return 'Saved: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return 'Imported $count items (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar => 'No scan records yet';

  @override
  String settingsShareTestDataSubject(int count) {
    return 'Household ledger test data ($count items)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return 'Send failed: $error';
  }

  @override
  String get entryTitleCreate => 'Entry';

  @override
  String get entryTitleReceiptConfirm => 'Confirm Receipt';

  @override
  String get commonEdit => 'Edit';

  @override
  String get entryTypeExpense => 'Expense';

  @override
  String get entryTypeIncome => 'Income';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$month/$day/$year';
  }

  @override
  String get entryStartSplitButton => 'Add category';

  @override
  String get entryCategoryHeading => 'Category';

  @override
  String get entryDetailMemoLabel => 'Notes';

  @override
  String get entryStoreNameLabel => 'Store name';

  @override
  String get entryCompanyNameLabel => 'Company name';

  @override
  String get entrySaveContinueButton => 'Save & Continue';

  @override
  String get entrySavedSnackbar => 'Saved';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      'Receipt capture isn\'t available on this device';

  @override
  String entryOcrFailedSnackbar(String error) {
    return 'Failed to read receipt: $error';
  }

  @override
  String get entryReceiptSourceCamera => 'Take a photo';

  @override
  String get entryReceiptSourceLibrary => 'Choose from photos';

  @override
  String get entryDeleteConfirmTitle => 'Delete this entry?';

  @override
  String get entryDeleteConfirmContent => 'This transaction will be deleted.';

  @override
  String get commonDelete => 'Delete';

  @override
  String get batchPanelTitle => 'Itemize';

  @override
  String get batchModeSelectAssign => 'Select & assign';

  @override
  String get batchModePaint => 'Paint';

  @override
  String get batchCancelButton => 'Cancel';

  @override
  String get batchThisReceiptLabel => 'This receipt:';

  @override
  String get batchTaxIncluded => 'Tax incl.';

  @override
  String get batchTaxExclusive8 => 'Tax excl. 8%';

  @override
  String get batchTaxExclusive10 => 'Tax excl. 10%';

  @override
  String get batchPaintHintNoCategory =>
      'Pick a category below, then tap rows to paint';

  @override
  String batchPaintHintActive(String name) {
    return 'Painting \"$name\" — tap rows (tap again to undo)';
  }

  @override
  String get batchSelectHint => 'Select rows → tap a category below to assign';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count selected, $amount → tap a category below';
  }

  @override
  String get batchNoAssignmentsYet => '(No assignments yet)';

  @override
  String get batchCategoryUnknown => 'Unknown';

  @override
  String get batchDiffPickCategory =>
      'Remainder (difference) — tap to pick a category';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (difference)';
  }

  @override
  String get batchReceiptFallbackLabel => 'Receipt';

  @override
  String get batchTotalLabel => 'Total';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess over';
  }

  @override
  String get restorePageTitle => 'Restore';

  @override
  String get restoreEmptyMessage => 'No backups available to restore';

  @override
  String get restoreConfirmTitle => 'Restore this backup?';

  @override
  String get restoreConfirmMessage =>
      'All current data will be replaced. The previous state is saved automatically and can be recovered later.';

  @override
  String get restoreButton => 'Restore';

  @override
  String get restoreEmptyBackupTitle => 'This backup has 0 transactions';

  @override
  String get restoreEmptyBackupMessage =>
      'Restoring will delete all your existing transactions. Restore anyway?';

  @override
  String get restoreEmptyBackupConfirmButton => 'Restore anyway';

  @override
  String restoreFailedMessage(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get restoreSuccessMessage => 'Restore complete';

  @override
  String get restorePassphraseTitle => 'Enter passphrase';

  @override
  String get commonAdd => 'Add';

  @override
  String get categoryRenameAction => 'Rename';

  @override
  String get categorySubcategoryRenameTitle => 'Rename subcategory';

  @override
  String get categoryNameFieldLabel => 'Name';

  @override
  String get categorySubcategoryAddTitle => 'Add subcategory';

  @override
  String get categoryIconFieldLabel => 'Icon (emoji, optional)';

  @override
  String get categoryEditExistingTitle => 'Edit existing items';

  @override
  String get categoryIconOrderTitle => 'Icon display order settings';

  @override
  String get categoryIconOrderHint =>
      'Drag to reorder (shown in your custom order)';

  @override
  String get categoryManageTitle => 'Manage Categories';

  @override
  String get categoryTabExpense => 'Expense';

  @override
  String get categoryTabIncome => 'Income';

  @override
  String get categorySubAddTitle => 'Add Sub-category';

  @override
  String get categoryAddTitle => 'New category';

  @override
  String get categorySubRenameTitle => 'Rename Sub-category';

  @override
  String get categoryRenameTitle => 'Rename Category';

  @override
  String get categorySubAddTooltip => 'Add sub-category';

  @override
  String get categoryArchiveBlockedSnackbar =>
      'Archive its sub-categories first';

  @override
  String get categoryArchivedSectionTitle => 'Archived';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (Archived)';
  }

  @override
  String get splitCancel => 'Cancel';

  @override
  String get splitBreakdownLabel => 'Breakdown';

  @override
  String get splitTaxLabel => 'Tax';

  @override
  String get splitTaxIncludedToggle => 'Tax incl.';

  @override
  String get splitTaxExcludedToggle => 'Tax excl.';

  @override
  String get splitTaxIndividual => 'Custom';

  @override
  String get splitMemoHint => 'Memo';

  @override
  String get splitCategoryUnselected => 'No category';

  @override
  String get splitAmountEmpty => 'No amount';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'Tax incl. $amount';
  }

  @override
  String get splitOverLabel => 'Over';

  @override
  String get splitRemainingLabel => 'Remaining';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get summaryEmptyTitle => 'No data for this month yet';

  @override
  String get summaryEmptyHint => 'Tap + on the calendar to add an entry';

  @override
  String get summaryIncomeLabel => 'Income';

  @override
  String get summaryExpenseLabel => 'Expense';

  @override
  String get summaryNetLabel => 'Balance';

  @override
  String get summaryCategoryBreakdownTitle => 'Spending by category';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (Archived)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ Details';

  @override
  String get summaryBreakdownExpand => '▼ Details';

  @override
  String get summaryNoBreakdownLabel => '(No breakdown)';

  @override
  String get entryNoImage => 'No image';

  @override
  String get entryAmountReadFailed =>
      'Couldn\'t read the amount. Please enter it manually.';

  @override
  String get entryStoreDirectInput => 'Enter manually';

  @override
  String get entryStoreNameDialogTitle => 'Enter store name';

  @override
  String get commonOk => 'OK';

  @override
  String get calendarWeekdaySun => 'Sun';

  @override
  String get calendarWeekdayMon => 'Mon';

  @override
  String get calendarWeekdayTue => 'Tue';

  @override
  String get calendarWeekdayWed => 'Wed';

  @override
  String get calendarWeekdayThu => 'Thu';

  @override
  String get calendarWeekdayFri => 'Fri';

  @override
  String get calendarWeekdaySat => 'Sat';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return 'Expense $expense   Income $income   Net $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return 'No entries on $month/$day';
  }

  @override
  String get calendarDayEmptyHintFirst =>
      'Add your first entry using \"Enter Amount\" in the bottom right';

  @override
  String get calendarDayEmptyHint =>
      'Add an entry using \"Enter Amount\" in the bottom right';

  @override
  String get calendarReceiptFallbackLabel => 'Receipt';

  @override
  String get calendarCategoryUnknown => 'Unknown';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (Archived)';
  }

  @override
  String get calendarDeleteSnackbar => 'Deleted';

  @override
  String get calendarUndoAction => 'Undo';

  @override
  String get splitTaxDialogTitle => 'Tax rate per item';

  @override
  String get commonDone => 'Done';

  @override
  String get splitRemainderLabel => 'Remaining';

  @override
  String splitItemNumberLabel(int index) {
    return 'Item $index';
  }

  @override
  String get splitTaxIncludedLabel => 'Incl. tax';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount (auto)';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → incl. tax $net';
  }

  @override
  String get onboardingTitle => 'About Your Data';

  @override
  String get onboardingBody =>
      '• Your records are stored only on this device. Nothing is sent externally.\n• The app backs up automatically on this device, but please save an export from Settings in case you switch or lose your device.';

  @override
  String get onboardingStartButton => 'Get Started';

  @override
  String get homeFabEntryLabel => 'Enter amount';

  @override
  String get homeNavCalendar => 'Calendar';

  @override
  String get homeNavSummary => 'Summary';

  @override
  String get homeNavSettings => 'Settings';

  @override
  String get categoryManualOrderSnackbar =>
      'Switched to your custom order (you can change this back in Settings).';

  @override
  String get entryHintEnterAmount => 'Enter an amount';

  @override
  String get entryHintAssignItemCategory => 'Assign a category to each item';

  @override
  String get entryHintAssignExceedsTotal => 'Assignments exceed the total';

  @override
  String get entryHintPickDiffCategory => 'Pick a category for the difference';

  @override
  String get entryHintSplitExceedsTotal => 'The breakdown exceeds the total';

  @override
  String get entryHintPickCategory => 'Pick a category';

  @override
  String get entryHintEnterAmountAndCategory =>
      'Enter an amount and a category';

  @override
  String get entryHintEnterRemainingAmount => 'Enter the remaining amount too';

  @override
  String get settingsBackupNever => 'No backup yet';

  @override
  String get settingsBackupToday => 'Last backup: today';

  @override
  String settingsBackupDaysAgo(int days) {
    return 'Last backup: $days days ago';
  }

  @override
  String get recurringPageTitle => 'Recurring transactions';

  @override
  String get settingsRecurringSubtitle =>
      'Auto-record monthly fixed costs like rent or salary';

  @override
  String get recurringEmptyMessage =>
      'Nothing here yet.\nTap + to automate monthly entries like rent or salary.';

  @override
  String get recurringAddTitle => 'Add recurring transaction';

  @override
  String get recurringEditTitle => 'Edit recurring transaction';

  @override
  String get recurringAmountLabel => 'Amount';

  @override
  String get recurringDayLabel => 'Day to repeat';

  @override
  String recurringEveryMonthDay(int day) {
    return 'Day $day every month';
  }

  @override
  String dayOfMonthItem(int day) {
    return 'Day $day';
  }

  @override
  String get recurringDayClampNote =>
      'If you choose the 31st, the entry falls on the last day of the month (e.g. Feb 28).';

  @override
  String get recurringStartMonthLabel => 'Starts';

  @override
  String get recurringStartThisMonth => 'This month';

  @override
  String get recurringStartNextMonth => 'Next month';

  @override
  String get recurringEndMonthLabel => 'Ends';

  @override
  String get recurringEndNone => 'No end (ongoing)';

  @override
  String get recurringEndMonthNote => 'Recorded through this month, then stops';

  @override
  String get recurringActiveTitle => 'Active';

  @override
  String get recurringActiveSubtitle => 'Turn off to pause automatic entries';

  @override
  String get recurringPausedLabel => 'Paused';

  @override
  String get recurringDeleteConfirmTitle => 'Delete?';

  @override
  String get recurringDeleteConfirmContent =>
      'This recurring transaction will be deleted. Entries already recorded will remain.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return 'Pick a category for item $n';
  }

  @override
  String get entryHintPickCategoryRemainder =>
      'Pick a category for the “Remaining” row';

  @override
  String get splitMemoDialogTitle => 'Enter a memo';

  @override
  String choreNotificationBody(int day) {
    return 'Monthly task scheduled for day $day';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return 'It\'s been $days days since last time';
  }

  @override
  String get homeNavMonthly => 'Monthly';

  @override
  String get hubUpcomingSection => 'Coming up this month';

  @override
  String get hubUpcomingEmpty => 'Nothing scheduled for the rest of this month';

  @override
  String get hubRulesSection => 'Fixed costs & income';

  @override
  String get hubRulesEmpty =>
      'Tap + to automate monthly entries like rent or salary';

  @override
  String get hubChoresSection => 'Recurring chores';

  @override
  String get hubChoresEmpty =>
      'Tap + to add chores like replacing your toothbrush';

  @override
  String get hubChoreTimelineLabel => 'Chore';

  @override
  String get ghostBadgeLabel => 'Planned';

  @override
  String get forecastLabelMonthEnd => 'Projected balance (end of month)';

  @override
  String forecastLabelAtDate(String date) {
    return 'Projected balance (as of $date)';
  }

  @override
  String choreOverdueDays(int days) {
    return '${days}d overdue';
  }

  @override
  String get choreDueToday => 'Today';

  @override
  String choreDaysLeft(int days) {
    return 'in $days days';
  }

  @override
  String choreNextDate(String date) {
    return 'Next: $date';
  }

  @override
  String get choreDoneButton => 'Done';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ Recorded. Next: $date';
  }

  @override
  String get choreDupConfirmTitle => 'Already recorded';

  @override
  String choreDupConfirmBody(String name) {
    return '\"$name\" already has a record on this day. Add another?';
  }

  @override
  String get choreDupConfirmAdd => 'Add';

  @override
  String get choreFormNewTitle => 'New chore';

  @override
  String get choreFormEditTitle => 'Edit chore';

  @override
  String get choreFormNameLabel => 'Name';

  @override
  String get choreRepeatUnitLabel => 'Repeat';

  @override
  String get choreRepeatUnitMonthly => 'Monthly';

  @override
  String get choreRepeatUnitEveryDays => 'Every N days';

  @override
  String get choreFormDayLabel => 'Day';

  @override
  String get choreFormIntervalLabel => 'Interval';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days days';
  }

  @override
  String choreIntervalEvery(int days) {
    return 'Every $days days';
  }

  @override
  String get choreFormEmojiLabel => 'Emoji (📌 if empty)';

  @override
  String get choreFormArchiveButton => 'Archive';

  @override
  String get choreFormDeleteButton => 'Delete this chore';

  @override
  String choreDeleteConfirmBody(int count) {
    return '$count history records will also be deleted';
  }

  @override
  String get choreHistoryTitle => 'History';

  @override
  String get choreHistoryEmpty => 'No records yet';

  @override
  String get choreRecordEditTitle => 'Edit record';

  @override
  String get choreRecordDeleteConfirm => 'Delete this record?';

  @override
  String get choreMemoLabel => 'Memo';

  @override
  String get settingsChoresTitle => 'Recurring chores';

  @override
  String get settingsChoresSubtitle => 'Notification time and archived chores';

  @override
  String get choreNotifyTimeLabel => 'Notification time';

  @override
  String get chorePermissionChecking => 'Checking notification permission…';

  @override
  String get chorePermissionNotAsked =>
      'You\'ll be asked to allow notifications after your first record';

  @override
  String get chorePermissionGranted => 'Notifications are enabled';

  @override
  String get chorePermissionDenied => 'Notifications are not allowed';

  @override
  String get chorePermissionOpenSettings => 'Open Settings';

  @override
  String get choreArchivedSection => 'Archived chores';

  @override
  String get choreArchivedEmpty => 'No archived chores';

  @override
  String get choreUnarchiveButton => 'Restore';

  @override
  String get forecastAnchorSheetTitle =>
      'Anchor date for the projected balance';

  @override
  String get forecastAnchorSheetNote =>
      'Planned amounts up to and including the anchor date are added to the actual balance.';

  @override
  String get forecastAnchorMonthEnd => 'End of month';

  @override
  String get calendarLegendChoreDone => 'chore done';

  @override
  String get calendarLegendChoreDue => 'chore due';

  @override
  String get calendarLegendChoreOverdue => 'overdue';

  @override
  String get entryRecurringExpense => 'Monthly expense';

  @override
  String get entryRecurringIncome => 'Monthly income';

  @override
  String get entrySaveWithRuleExpense => 'Save + monthly expense';

  @override
  String get entrySaveWithRuleIncome => 'Save + monthly income';

  @override
  String get entryRecurringNotePrefix => 'Recorded automatically on day';

  @override
  String get entryRecurringNoteSuffix => 'of every month';

  @override
  String get entrySubcategoryAddButton => 'Add subcategory';

  @override
  String get settingsColorTitle => 'Color';

  @override
  String get settingsColorSubtitle =>
      'Backgrounds, borders, and highlights adjust to the color you choose';

  @override
  String get settingsColorPreset => 'Presets';

  @override
  String get settingsColorCustom => 'Custom';

  @override
  String get settingsColorApply => 'Apply';

  @override
  String get settingsColorDefaultBadge => 'Default';

  @override
  String get settingsColorBlue => 'Blue';

  @override
  String get settingsColorGreen => 'Green';

  @override
  String get settingsColorTeal => 'Teal';

  @override
  String get settingsColorPurple => 'Purple';

  @override
  String get settingsColorRose => 'Rose';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsColorMustard => 'Mustard';

  @override
  String get settingsColorGray => 'Gray';

  @override
  String get settingsColorTerracotta => 'Terracotta';

  @override
  String get settingsColorNavy => 'Navy';

  @override
  String get installmentTitle => 'Add installment plan';

  @override
  String get installmentAddButton => 'Installment plan';

  @override
  String get installmentPrincipalLabel => 'Purchase amount';

  @override
  String get installmentCountLabel => 'Number of payments';

  @override
  String installmentCountItem(int n) {
    return '$n payments';
  }

  @override
  String get installmentRateLabel => 'Annual rate (%)';

  @override
  String get installmentCardPickLabel => 'Saved cards';

  @override
  String get installmentCardNameLabel => 'Card name (optional)';

  @override
  String get installmentDayLabel => 'Payment day';

  @override
  String get installmentMonthlyLabel => 'Monthly payment';

  @override
  String get installmentFirstLabel => 'First payment';

  @override
  String get installmentFeeLabel => 'Total interest';

  @override
  String get installmentTotalLabel => 'Total payment';

  @override
  String installmentTxnMemo(int index, int count) {
    return 'Installment $index/$count';
  }

  @override
  String get installmentEditTitle => 'Edit installment plan';

  @override
  String get installmentDeleteConfirmContent =>
      'This installment plan and all of its payments will be deleted.';

  @override
  String get hubInstallmentEmpty => 'No installment plans yet';
}
