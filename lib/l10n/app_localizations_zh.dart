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
  String get entryStartSplitButton => '添加类别';

  @override
  String get entryCategoryHeading => '分类';

  @override
  String get entryDetailMemoLabel => '备注';

  @override
  String get entryStoreNameLabel => '店铺名称';

  @override
  String get entryCompanyNameLabel => '公司名称';

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
  String get categoryAddTitle => '新建类别';

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
  String get splitCategoryUnselected => '未选择分类';

  @override
  String get splitAmountEmpty => '未输入金额';

  @override
  String splitTaxIncludedAmount(String amount) {
    return '含税 $amount';
  }

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
  String get calendarDayEmptyTitle => '这一天还没有记录';

  @override
  String get calendarDayEmptyHint => '通过按钮记录支出或收入';

  @override
  String get calendarAddExpense => '添加支出';

  @override
  String get calendarAddIncome => '添加收入';

  @override
  String get calendarChoreTab => '家务';

  @override
  String get calendarChoreTabEmpty => '这一天没有家务';

  @override
  String get calendarMemoTab => '备忘';

  @override
  String get shoppingMemoHint => '购物备忘（例如：牛奶、卫生纸）';

  @override
  String get settingsBudgetTitle => '每月预算';

  @override
  String get settingsBudgetSubtitle => '开启后在日历上方显示预算余额';

  @override
  String get settingsBudgetAmountTitle => '预算金额';

  @override
  String get budgetRemainingLabel => '预算余额';

  @override
  String get settingsPaymentModeTitle => '支付方式';

  @override
  String get settingsPaymentModeSubtitle => '将刷卡消费记为未付款，并在扣款日汇总';

  @override
  String get summaryPaymentLabel => '支付';

  @override
  String get summaryBasisTitle => '更改计算方式';

  @override
  String get summaryBasisCashName => '收付实现制';

  @override
  String get summaryBasisCashOption => '在付款时计算。';

  @override
  String get summaryBasisAccrualName => '权责发生制';

  @override
  String get summaryBasisAccrualOption => '在消费时计算。';

  @override
  String get summaryGearBudget => '预算设置';

  @override
  String get paymentCardClosingDayLabel => '结账日';

  @override
  String get closingDayMonthEnd => '月末';

  @override
  String closingDayNth(int day) {
    return '$day日';
  }

  @override
  String get payableBadgeNextMonth => '次月';

  @override
  String get payableBadgeMonthAfterNext => '第三月';

  @override
  String payableBadgeMonth(int month) {
    return '$month月';
  }

  @override
  String get payableDetailTitle => '未付款项';

  @override
  String get payableCardLabel => '卡片';

  @override
  String get payableCountLabel => '付款次数';

  @override
  String get payableStartYmLabel => '首次付款月份';

  @override
  String get payableOnceOption => '一次性';

  @override
  String payableTimesOption(int count) {
    return '$count次';
  }

  @override
  String get payableTotalLabel => '应付总额';

  @override
  String get payableFeeLabel => '其中手续费';

  @override
  String get payableScheduleHeading => '付款计划';

  @override
  String get payableMakeImmediate => '取消未付款，改为即时支付';

  @override
  String payableYmFormat(int year, int month) {
    return '$year年$month月';
  }

  @override
  String cardPaymentRowLabel(String card) {
    return '$card 扣款';
  }

  @override
  String get paymentCash => '现金';

  @override
  String get entryPaymentPickerTitle => '支付方式';

  @override
  String get paymentCardsTitle => '卡片管理';

  @override
  String get paymentCardsEmptyMessage => '还没有卡片。点击右上角 + 添加名称和扣款日。';

  @override
  String get paymentCardAddTitle => '添加卡片';

  @override
  String get paymentCardEditTitle => '编辑卡片';

  @override
  String get paymentCardNameLabel => '名称';

  @override
  String get paymentCardPayDayLabel => '扣款日';

  @override
  String get paymentCardRateLabel => '事后分期的年利率（%）';

  @override
  String get paymentCardBusinessDayLabel => '扣款日为非营业日时';

  @override
  String get businessDayRuleNext => '顺延至下一营业日';

  @override
  String get businessDayRulePrevious => '提前至上一营业日';

  @override
  String get businessDayRuleNone => '保持不变';

  @override
  String get paymentCardInUseDeleteError => '该卡片有未付款项，无法删除';

  @override
  String paymentCardBillingDaySummary(int day) {
    return '每月$day日';
  }

  @override
  String get calendarReceiptFallbackLabel => '小票';

  @override
  String get calendarCategoryUnknown => '未知';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name（已归档）';
  }

  @override
  String get calendarUndoAction => '撤销';

  @override
  String get trashMovedSnack => '已移至回收站（可在设置中恢复）';

  @override
  String get trashTitle => '回收站';

  @override
  String get settingsTrashSubtitle => '已删除的交易保留30天';

  @override
  String get trashEmpty => '回收站是空的';

  @override
  String get trashRestore => '恢复';

  @override
  String get trashRestoredSnack => '已恢复';

  @override
  String trashDeletedOn(String date) {
    return '删除于 $date';
  }

  @override
  String get trashEmptyAction => '清空回收站';

  @override
  String get trashEmptyConfirmTitle => '要清空回收站吗？';

  @override
  String get trashEmptyConfirmContent => '所有项目将被永久删除。此操作无法撤销。';

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
  String get homeFabEntryLabel => '记一笔';

  @override
  String get homeNavCalendar => '日历';

  @override
  String get homeNavSummary => '汇总';

  @override
  String get homeNavSettings => '设置';

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
  String get recurringDayLabel => '重复记录日';

  @override
  String recurringEveryMonthDay(int day) {
    return '每月$day日';
  }

  @override
  String dayOfMonthItem(int day) {
    return '$day日';
  }

  @override
  String get recurringDayClampNote => '选择31日时，将在当月最后一天记录（例如2月记在28日）';

  @override
  String get recurringStartMonthLabel => '开始';

  @override
  String get recurringStartThisMonth => '本月开始';

  @override
  String get recurringStartNextMonth => '下月开始';

  @override
  String get recurringEndMonthLabel => '结束';

  @override
  String get recurringEndNone => '无结束（持续）';

  @override
  String get recurringEndMonthNote => '记录到该月为止，之后停止';

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
  String choreNotificationBody(int day) {
    return '每月$day日的例行安排';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return '距离上次已经$days天了';
  }

  @override
  String get homeNavMonthly => '每月';

  @override
  String get hubUpcomingSection => '本月接下来';

  @override
  String get hubUpcomingEmpty => '本月没有更多安排';

  @override
  String get hubRulesSection => '固定支出·收入';

  @override
  String get hubRulesEmpty => '点＋可自动记录房租、工资等每月固定项目';

  @override
  String get hubChoresSection => '定期家务';

  @override
  String get hubChoresEmpty => '点＋可添加换牙刷等家务提醒';

  @override
  String get hubChoreTimelineLabel => '家务';

  @override
  String get ghostBadgeLabel => '预定';

  @override
  String get forecastLabelMonthEnd => '预计结余（月末）';

  @override
  String choreOverdueDays(int days) {
    return '已超期$days天';
  }

  @override
  String get choreDueToday => '今天';

  @override
  String choreDaysLeft(int days) {
    return '还有$days天';
  }

  @override
  String choreNextDate(String date) {
    return '下次：$date';
  }

  @override
  String get choreDoneButton => '完成';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ 已记录。下次：$date';
  }

  @override
  String get choreDupConfirmTitle => '确认';

  @override
  String choreDupConfirmBody(String name) {
    return '“$name”当天已有记录，仍要添加吗？';
  }

  @override
  String get choreDupConfirmAdd => '添加';

  @override
  String get choreFormNewTitle => '新项目';

  @override
  String get choreFormEditTitle => '编辑项目';

  @override
  String get choreFormNameLabel => '项目名称';

  @override
  String get choreRepeatUnitLabel => '重复';

  @override
  String get choreRepeatUnitMonthly => '每月';

  @override
  String get choreRepeatUnitEveryDays => '每隔几天';

  @override
  String get choreFormDayLabel => '日期';

  @override
  String get choreFormIntervalLabel => '间隔';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days天';
  }

  @override
  String choreIntervalEvery(int days) {
    return '每$days天';
  }

  @override
  String get choreFormEmojiLabel => '表情（留空则为📌）';

  @override
  String get choreFormArchiveButton => '归档';

  @override
  String get choreFormDeleteButton => '删除此项目';

  @override
  String choreDeleteConfirmBody(int count) {
    return '$count条历史记录也将一并删除';
  }

  @override
  String get choreHistoryTitle => '历史';

  @override
  String get choreHistoryEmpty => '还没有记录';

  @override
  String get choreRecordEditTitle => '编辑记录';

  @override
  String get choreRecordDeleteConfirm => '要删除这条记录吗？';

  @override
  String get choreMemoLabel => '备注';

  @override
  String get settingsChoresTitle => '定期家务';

  @override
  String get settingsChoresSubtitle => '提醒时间与已归档项目';

  @override
  String get choreNotifyTimeLabel => '提醒时间';

  @override
  String get chorePermissionChecking => '正在检查通知权限…';

  @override
  String get chorePermissionNotAsked => '首次记录后会请求通知权限';

  @override
  String get chorePermissionGranted => '通知已开启';

  @override
  String get chorePermissionDenied => '通知未被允许';

  @override
  String get chorePermissionOpenSettings => '打开设置';

  @override
  String get choreArchivedSection => '已归档项目';

  @override
  String get choreArchivedEmpty => '没有已归档的项目';

  @override
  String get choreUnarchiveButton => '恢复';

  @override
  String get calendarLegendChoreDone => '已完成';

  @override
  String get calendarLegendChoreDue => '家务到期';

  @override
  String get calendarLegendChoreOverdue => '已超期';

  @override
  String get entryRecurringExpense => '每月支出';

  @override
  String get entryRecurringIncome => '每月收入';

  @override
  String get entrySaveWithRuleExpense => '保存（+每月支出）';

  @override
  String get entrySaveWithRuleIncome => '保存（+每月收入）';

  @override
  String get entryRecurringNotePrefix => '每月';

  @override
  String get entryRecurringNoteSuffix => '日自动记录';

  @override
  String get entrySubcategoryAddButton => '添加子类别';

  @override
  String get settingsColorTitle => '颜色';

  @override
  String get settingsColorSubtitle => '背景、线条和强调色会根据所选颜色自动调整';

  @override
  String get settingsColorPreset => '预设';

  @override
  String get settingsColorCustom => '自定义';

  @override
  String get settingsColorApply => '应用';

  @override
  String get settingsColorDefaultBadge => '默认';

  @override
  String get settingsColorBlue => '蓝色';

  @override
  String get settingsColorGreen => '绿色';

  @override
  String get settingsColorTeal => '青色';

  @override
  String get settingsColorPurple => '紫色';

  @override
  String get settingsColorRose => '玫瑰红';

  @override
  String get settingsColorOrange => '橙色';

  @override
  String get settingsColorMustard => '芥末黄';

  @override
  String get settingsColorGray => '灰色';

  @override
  String get settingsColorTerracotta => '陶土色';

  @override
  String get settingsColorNavy => '藏青色';

  @override
  String get installmentTitle => '登记分期付款';

  @override
  String get installmentAddButton => '分期付款';

  @override
  String get installmentPrincipalLabel => '购买金额';

  @override
  String get installmentCountLabel => '期数';

  @override
  String installmentCountItem(int n) {
    return '$n期';
  }

  @override
  String get installmentRateLabel => '实际年利率（%）';

  @override
  String get installmentCardPickLabel => '已保存的卡';

  @override
  String get installmentCardNameLabel => '卡片名称（可选）';

  @override
  String get installmentDayLabel => '还款日';

  @override
  String get installmentMonthlyLabel => '每月还款';

  @override
  String get installmentFirstLabel => '首期';

  @override
  String get installmentFeeLabel => '手续费合计';

  @override
  String get installmentTotalLabel => '支付总额';

  @override
  String installmentTxnMemo(int index, int count) {
    return '分期 $index/$count期';
  }

  @override
  String get installmentEditTitle => '编辑分期付款';

  @override
  String get installmentDeleteConfirmContent => '将删除此分期付款及其所有已登记的付款。';

  @override
  String get hubInstallmentEmpty => '还没有分期付款';
}
