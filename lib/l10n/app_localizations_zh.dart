// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '家庭账本';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonSave => '保存';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsCurrency => '货币';

  @override
  String get languageSystemDefault => '跟随系统语言';

  @override
  String get currencyLockedSubtitle => '已有交易记录，无法更改';

  @override
  String get currencyLockedTitle => '无法更改货币';

  @override
  String get currencyLockedBody => '为保证以往金额准确，记录交易后将无法更改货币。';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return '自动备份 $generations 份（本机）';
  }

  @override
  String get settingsBackupNowTitle => '立即备份';

  @override
  String get settingsExportJsonTitle => '导出 JSON';

  @override
  String get settingsExportJsonSubtitle => '可选用口令加密（可用于恢复）';

  @override
  String get settingsExportCsvTitle => '导出 CSV';

  @override
  String get settingsExportCsvSubtitle => '仅供查看（无法用于恢复）';

  @override
  String get settingsRestoreTitle => '恢复';

  @override
  String get settingsRestoreSubtitle => '将替换全部数据';

  @override
  String get settingsTestUploadTitle => '协助测试（自动发送）';

  @override
  String get settingsTestUploadSubtitle =>
      '为改进小票识别，扫描记录和照片会自动发送给开发者（仅限测试期间）。账本的录入内容本身不会发送';

  @override
  String get settingsShareTestDataTitle => '发送测试数据';

  @override
  String get settingsShareTestDataSubtitle => '手动批量分享（LINE/AirDrop）';

  @override
  String get settingsFetchCollectedTitle => '导入收集的数据（开发者专用）';

  @override
  String get settingsFetchCollectedSubtitle =>
      '将所有设备的数据导入本机的 exports/ocr-collected';

  @override
  String get settingsRetainImagesTitle => '在本机保留小票图片';

  @override
  String get settingsRetainImagesSubtitle => '默认保存后即删除';

  @override
  String get settingsCategoryManageTitle => '分类管理';

  @override
  String get settingsCategoryOrderTitle => '自定义分类顺序';

  @override
  String get settingsCategoryOrderSubtitle =>
      '关=按最近使用 / 开=固定顺序（在录入界面长按图块→重新排序）';

  @override
  String get settingsPageColorTitle => '页面颜色（背景）';

  @override
  String get settingsAccentColorTitle => '强调色';

  @override
  String get settingsAccentColorSubtitle => '按钮和选中项的颜色';

  @override
  String get settingsDataPolicyTitle => '关于数据处理';

  @override
  String get settingsDataPolicyBody =>
      '・记录仅保存在本机中，不会自动发送到外部。\n・应用会在本机自动备份，但为防止更换机型或设备损坏，请在设置中保存导出文件。';

  @override
  String get settingsPassphraseFieldLabel => '口令（如需加密）';

  @override
  String get settingsSaveAsIs => '直接保存';

  @override
  String get settingsSaveEncrypted => '加密后保存';

  @override
  String get settingsBackupSuccessSnackbar => '已创建备份';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return '备份失败：$error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return '已保存：$fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return '导出失败：$error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return '已导入 $count 条（exports/ocr-collected）';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return '导入失败：$error';
  }

  @override
  String get settingsNoScanRecordsSnackbar => '暂无扫描记录';

  @override
  String settingsShareTestDataSubject(int count) {
    return '账本测试数据（$count 条）';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return '发送失败：$error';
  }

  @override
  String get entryTitleCreate => '记一笔';

  @override
  String get entryTitleReceiptConfirm => '确认小票';

  @override
  String get commonEdit => '编辑';

  @override
  String get entryTypeExpense => '支出';

  @override
  String get entryTypeIncome => '收入';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get entryStartSplitButton => '选择多个分类';

  @override
  String get entryCategoryHeading => '分类';

  @override
  String get entryDetailMemoLabel => '备注';

  @override
  String get entryStoreNameLabel => '店铺名称';

  @override
  String get entrySaveContinueButton => '保存并继续';

  @override
  String get entrySavedSnackbar => '已保存';

  @override
  String get entryReceiptCaptureUnavailableSnackbar => '此设备无法使用小票拍摄功能';

  @override
  String entryOcrFailedSnackbar(String error) {
    return '识别失败：$error';
  }

  @override
  String get entryReceiptSourceCamera => '拍照';

  @override
  String get entryReceiptSourceLibrary => '从相册选择';

  @override
  String get entryDeleteConfirmTitle => '要删除吗？';

  @override
  String get entryDeleteConfirmContent => '将删除这笔交易。';

  @override
  String get commonDelete => '删除';

  @override
  String get batchPanelTitle => '批量拆分';

  @override
  String get batchModeSelectAssign => '选择并分配';

  @override
  String get batchModePaint => '涂色分配';

  @override
  String get batchCancelButton => '取消';

  @override
  String get batchThisReceiptLabel => '这张小票：';

  @override
  String get batchTaxIncluded => '含税';

  @override
  String get batchTaxExclusive8 => '不含税8%';

  @override
  String get batchTaxExclusive10 => '不含税10%';

  @override
  String get batchPaintHintNoCategory => '先在下方选择分类，再点击行进行涂色';

  @override
  String batchPaintHintActive(String name) {
    return '正在涂「$name」— 点击行（再次点击取消）';
  }

  @override
  String get batchSelectHint => '选择行 → 点击下方分类进行分配';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '已选 $count 项 $amount → 点击下方分类';
  }

  @override
  String get batchNoAssignmentsYet => '（尚未分配）';

  @override
  String get batchCategoryUnknown => '未知';

  @override
  String get batchDiffPickCategory => '剩余（差额）— 点击选择分类';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category（差额）';
  }

  @override
  String get batchReceiptFallbackLabel => '小票';

  @override
  String get batchTotalLabel => '合计';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ 超出 $excess';
  }

  @override
  String get restorePageTitle => '恢复';

  @override
  String get restoreEmptyMessage => '没有可恢复的备份';

  @override
  String get restoreConfirmTitle => '要恢复吗？';

  @override
  String get restoreConfirmMessage => '当前全部数据将被替换。之前的状态会自动保存，之后可以找回。';

  @override
  String get restoreButton => '恢复';

  @override
  String get restoreEmptyBackupTitle => '此备份包含 0 笔交易';

  @override
  String get restoreEmptyBackupMessage => '恢复后将删除所有现有交易。仍要恢复吗？';

  @override
  String get restoreEmptyBackupConfirmButton => '仍要恢复';

  @override
  String restoreFailedMessage(String error) {
    return '恢复失败：$error';
  }

  @override
  String get restoreSuccessMessage => '恢复完成';

  @override
  String get restorePassphraseTitle => '输入口令';

  @override
  String get commonAdd => '添加';

  @override
  String get categoryRenameAction => '重命名';

  @override
  String get categorySubcategoryRenameTitle => '重命名子分类';

  @override
  String get categoryNameFieldLabel => '名称';

  @override
  String get categorySubcategoryAddTitle => '添加子分类';

  @override
  String get categoryIconFieldLabel => '图标（表情符号・可选）';

  @override
  String get categoryEditExistingTitle => '编辑现有项目';

  @override
  String get categoryIconOrderTitle => '图标显示顺序设置';

  @override
  String get categoryIconOrderHint => '拖动以重新排序（将按您的顺序显示）';

  @override
  String get categoryManageTitle => '分类管理';

  @override
  String get categoryTabExpense => '支出';

  @override
  String get categoryTabIncome => '收入';

  @override
  String get categorySubAddTitle => '添加子分类';

  @override
  String get categoryAddTitle => '添加分类';

  @override
  String get categorySubRenameTitle => '重命名子分类';

  @override
  String get categoryRenameTitle => '重命名分类';

  @override
  String get categorySubAddTooltip => '添加子分类';

  @override
  String get categoryArchiveBlockedSnackbar => '请先归档其子分类';

  @override
  String get categoryArchivedSectionTitle => '已归档';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name（已归档）';
  }

  @override
  String get splitStoreNameHint => '店名';

  @override
  String get splitCancel => '取消';

  @override
  String get splitBreakdownLabel => '明细';

  @override
  String get splitTaxLabel => '消费税';

  @override
  String get splitTaxIncludedToggle => '含税';

  @override
  String get splitTaxExcludedToggle => '不含税';

  @override
  String get splitTaxIndividual => '单独';

  @override
  String get splitMemoHint => '备注';

  @override
  String get splitAddCategoryChip => '＋ 分类';

  @override
  String splitTaxIncludedAmount(String amount) {
    return '含税 $amount';
  }

  @override
  String get splitAddCategoryLabel => '添加分类';

  @override
  String get splitOverLabel => '超出';

  @override
  String get splitRemainingLabel => '剩余';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get summaryEmptyTitle => '本月还没有数据';

  @override
  String get summaryEmptyHint => '可从日历的 ＋ 添加记录';

  @override
  String get summaryIncomeLabel => '收入';

  @override
  String get summaryExpenseLabel => '支出';

  @override
  String get summaryNetLabel => '结余';

  @override
  String get summaryCategoryBreakdownTitle => '各分类支出';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name（已归档）';
  }

  @override
  String get summaryBreakdownCollapse => '▲ 明细';

  @override
  String get summaryBreakdownExpand => '▼ 明细';

  @override
  String get summaryNoBreakdownLabel => '（无明细）';

  @override
  String get entryNoImage => '无图片';

  @override
  String get entryAmountReadFailed => '无法识别金额，请手动输入';

  @override
  String get entryStoreDirectInput => '手动输入';

  @override
  String get entryStoreNameDialogTitle => '输入店铺名称';

  @override
  String get commonOk => '确定';

  @override
  String get calendarWeekdaySun => '日';

  @override
  String get calendarWeekdayMon => '一';

  @override
  String get calendarWeekdayTue => '二';

  @override
  String get calendarWeekdayWed => '三';

  @override
  String get calendarWeekdayThu => '四';

  @override
  String get calendarWeekdayFri => '五';

  @override
  String get calendarWeekdaySat => '六';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$year年$month月';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return '支出 $expense　收入 $income　结余 $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return '$month月$day日没有记录';
  }

  @override
  String get calendarDayEmptyHintFirst => '可通过右下角的「输入金额」添加第一条记录';

  @override
  String get calendarDayEmptyHint => '可通过右下角的「输入金额」添加记录';

  @override
  String get calendarReceiptFallbackLabel => '小票';

  @override
  String get calendarCategoryUnknown => '未知';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name（已归档）';
  }

  @override
  String get calendarDeleteSnackbar => '已删除';

  @override
  String get calendarUndoAction => '撤销';

  @override
  String get splitTaxDialogTitle => '各品目税率';

  @override
  String get commonDone => '完成';

  @override
  String get splitRemainderLabel => '剩余';

  @override
  String splitItemNumberLabel(int index) {
    return '项目$index';
  }

  @override
  String get splitTaxIncludedLabel => '含税';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount（自动）';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → 含税 $net';
  }

  @override
  String get onboardingTitle => '关于数据处理';

  @override
  String get onboardingBody =>
      '・记录仅保存在本机中，不会自动发送到外部。\n・应用会在本机自动备份，但为防止更换机型或设备损坏，请在设置中保存导出文件。';

  @override
  String get onboardingStartButton => '开始使用';

  @override
  String get homeFabEntryLabel => '输入金额';

  @override
  String get homeNavCalendar => '日历';

  @override
  String get homeNavSummary => '汇总';

  @override
  String get homeNavSettings => '设置';

  @override
  String get settingsColorPickerResetDefault => '恢复默认';

  @override
  String get settingsColorPickerConfirm => '确定';

  @override
  String get categoryManualOrderSnackbar => '已切换为自定义顺序（可在设置中改回）';

  @override
  String get entryHintEnterAmount => '请输入金额';

  @override
  String get entryHintAssignItemCategory => '请为每个项目分配分类';

  @override
  String get entryHintAssignExceedsTotal => '分配金额超出了合计';

  @override
  String get entryHintPickDiffCategory => '请为差额选择分类';

  @override
  String get entryHintSplitExceedsTotal => '明细超出了合计';

  @override
  String get entryHintPickCategory => '请选择分类';

  @override
  String get entryHintEnterAmountAndCategory => '请输入金额和分类';

  @override
  String get entryHintEnterRemainingAmount => '请也输入剩余金额';

  @override
  String get settingsBackupNever => '尚未创建备份';

  @override
  String get settingsBackupToday => '上次备份：今天';

  @override
  String settingsBackupDaysAgo(int days) {
    return '上次备份：$days 天前';
  }

  @override
  String get recurringPageTitle => '每月固定收支';

  @override
  String get settingsRecurringSubtitle => '自动记录房租、工资等每月固定项目';

  @override
  String get recurringEmptyMessage => '还没有登记。\n点右上角的＋，即可自动记录房租、工资等每月项目';

  @override
  String get recurringAddTitle => '添加固定收支';

  @override
  String get recurringEditTitle => '编辑固定收支';

  @override
  String get recurringAmountLabel => '金额';

  @override
  String get recurringDayLabel => '记录日期';

  @override
  String recurringEveryMonthDay(int day) {
    return '每月$day日';
  }

  @override
  String get recurringDayClampNote => '没有该日期的月份将记在月末（例如31日→2月记在28日）';

  @override
  String get recurringStartMonthLabel => '开始';

  @override
  String get recurringStartThisMonth => '本月开始';

  @override
  String get recurringStartNextMonth => '下月开始';

  @override
  String get recurringActiveTitle => '启用';

  @override
  String get recurringActiveSubtitle => '关闭后暂停自动记录';

  @override
  String get recurringPausedLabel => '已暂停';

  @override
  String get recurringDeleteConfirmTitle => '要删除吗？';

  @override
  String get recurringDeleteConfirmContent => '将删除此固定收支。已记录的交易会保留。';

  @override
  String entryHintPickCategoryForItem(int n) {
    return '请为项目$n选择分类';
  }

  @override
  String get entryHintPickCategoryRemainder => '请为“剩余”行选择分类';

  @override
  String get splitMemoDialogTitle => '输入备注';

  @override
  String choreNotificationBody(int days) {
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
  String choreIntervalEvery(int days) {
    return 'Every $days days';
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
  String get choreFormIntervalLabel => 'Interval in days (1–999)';

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
  String get calendarLegendGhost => 'planned fixed cost';
}
