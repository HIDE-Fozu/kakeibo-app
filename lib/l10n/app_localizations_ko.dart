// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '가계부';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonSave => '저장';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsCurrency => '통화';

  @override
  String get languageSystemDefault => '기기 언어에 맞춤';

  @override
  String get currencyLockedSubtitle => '거래 내역이 있어 변경할 수 없습니다';

  @override
  String get currencyLockedTitle => '통화를 변경할 수 없습니다';

  @override
  String get currencyLockedBody =>
      '과거 금액을 정확히 유지하기 위해, 거래를 기록한 후에는 통화를 변경할 수 없습니다.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return '자동 백업 $generations개 (기기 내)';
  }

  @override
  String get settingsBackupNowTitle => '지금 백업';

  @override
  String get settingsExportJsonTitle => 'JSON 내보내기';

  @override
  String get settingsExportJsonSubtitle => '패스프레이즈로 선택 암호화 (복원에 사용 가능)';

  @override
  String get settingsExportCsvTitle => 'CSV 내보내기';

  @override
  String get settingsExportCsvSubtitle => '열람용 (복원에는 사용할 수 없습니다)';

  @override
  String get settingsRestoreTitle => '복원';

  @override
  String get settingsRestoreSubtitle => '모든 데이터를 대체합니다';

  @override
  String get settingsTestUploadTitle => '테스트 협력 (자동 전송)';

  @override
  String get settingsTestUploadSubtitle =>
      '영수증 인식 개선을 위해 스캔 기록과 사진을 개발자에게 자동 전송합니다 (테스트 기간 한정). 가계부에 입력한 내용 자체는 전송하지 않습니다';

  @override
  String get settingsShareTestDataTitle => '테스트 데이터 보내기';

  @override
  String get settingsShareTestDataSubtitle => '수동으로 한번에 공유 (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle => '수집 데이터 가져오기 (개발자용)';

  @override
  String get settingsFetchCollectedSubtitle =>
      '모든 기기의 데이터를 이 기기의 exports/ocr-collected로';

  @override
  String get settingsRetainImagesTitle => '영수증 이미지를 기기에 보관';

  @override
  String get settingsRetainImagesSubtitle => '기본적으로 저장 후 삭제됩니다';

  @override
  String get settingsCategoryManageTitle => '카테고리 관리';

  @override
  String get settingsCategoryOrderTitle => '카테고리를 내 순서대로 정렬';

  @override
  String get settingsCategoryOrderSubtitle =>
      '끄기=최근 사용순 / 켜기=고정순 (입력 화면에서 타일 길게 눌러→정렬)';

  @override
  String get settingsPageColorTitle => '페이지 색 (배경)';

  @override
  String get settingsAccentColorTitle => '강조 색';

  @override
  String get settingsAccentColorSubtitle => '버튼과 선택 항목 색';

  @override
  String get settingsDataPolicyTitle => '데이터 처리 안내';

  @override
  String get settingsDataPolicyBody =>
      '・기록은 기기 안에만 저장됩니다. 자동으로 외부에 전송되지 않습니다.\n・기기 내에서 자동 백업을 하지만, 기기 변경이나 고장에 대비해 설정에서 내보내기를 저장하세요.';

  @override
  String get settingsPassphraseFieldLabel => '패스프레이즈 (암호화하는 경우)';

  @override
  String get settingsSaveAsIs => '그대로 저장';

  @override
  String get settingsSaveEncrypted => '암호화하여 저장';

  @override
  String get settingsBackupSuccessSnackbar => '백업을 생성했습니다';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return '백업에 실패했습니다: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return '저장했습니다: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return '내보내기에 실패했습니다: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return '$count건을 가져왔습니다 (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return '가져오기에 실패했습니다: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar => '아직 스캔 기록이 없습니다';

  @override
  String settingsShareTestDataSubject(int count) {
    return '가계부 테스트 데이터 ($count건)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return '전송에 실패했습니다: $error';
  }

  @override
  String get entryTitleCreate => '입력';

  @override
  String get entryTitleReceiptConfirm => '영수증 확인';

  @override
  String get commonEdit => '편집';

  @override
  String get entryTypeExpense => '지출';

  @override
  String get entryTypeIncome => '수입';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$year년 $month월 $day일';
  }

  @override
  String get entryStartSplitButton => '카테고리 추가';

  @override
  String get entryCategoryHeading => '카테고리';

  @override
  String get entryDetailMemoLabel => '상세 메모';

  @override
  String get entryStoreNameLabel => '매장명';

  @override
  String get entryCompanyNameLabel => '회사명';

  @override
  String get entrySaveContinueButton => '저장하고 계속';

  @override
  String get entrySavedSnackbar => '저장했습니다';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      '이 기기에서는 영수증 촬영을 사용할 수 없습니다';

  @override
  String entryOcrFailedSnackbar(String error) {
    return '인식에 실패했습니다: $error';
  }

  @override
  String get entryReceiptSourceCamera => '카메라로 촬영';

  @override
  String get entryReceiptSourceLibrary => '사진에서 선택';

  @override
  String get entryDeleteConfirmTitle => '삭제할까요?';

  @override
  String get entryDeleteConfirmContent => '이 거래를 삭제합니다.';

  @override
  String get commonDelete => '삭제';

  @override
  String get batchPanelTitle => '일괄 내역';

  @override
  String get batchModeSelectAssign => '선택 후 할당';

  @override
  String get batchModePaint => '칠하기';

  @override
  String get batchCancelButton => '그만두기';

  @override
  String get batchThisReceiptLabel => '이 영수증:';

  @override
  String get batchTaxIncluded => '세금 포함';

  @override
  String get batchTaxExclusive8 => '세금 별도 8%';

  @override
  String get batchTaxExclusive10 => '세금 별도 10%';

  @override
  String get batchPaintHintNoCategory => '아래 카테고리를 선택한 뒤, 행을 탭하여 칠하세요';

  @override
  String batchPaintHintActive(String name) {
    return '\"$name\" 칠하는 중 — 행을 탭 (다시 탭하면 해제)';
  }

  @override
  String get batchSelectHint => '행 선택 → 아래 카테고리를 탭하여 할당';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count건 선택 $amount → 아래 카테고리를 탭';
  }

  @override
  String get batchNoAssignmentsYet => '(아직 할당이 없습니다)';

  @override
  String get batchCategoryUnknown => '알 수 없음';

  @override
  String get batchDiffPickCategory => '남은 금액 (차액) — 탭하여 카테고리 선택';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (차액)';
  }

  @override
  String get batchReceiptFallbackLabel => '영수증';

  @override
  String get batchTotalLabel => '합계';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess 초과';
  }

  @override
  String get restorePageTitle => '복원';

  @override
  String get restoreEmptyMessage => '복원할 수 있는 백업이 없습니다';

  @override
  String get restoreConfirmTitle => '복원할까요?';

  @override
  String get restoreConfirmMessage =>
      '현재 데이터가 모두 대체됩니다. 직전 상태는 자동으로 보관되어 나중에 되찾을 수 있습니다.';

  @override
  String get restoreButton => '복원';

  @override
  String get restoreEmptyBackupTitle => '거래가 0건인 백업입니다';

  @override
  String get restoreEmptyBackupMessage => '복원하면 모든 거래가 사라집니다. 그래도 복원할까요?';

  @override
  String get restoreEmptyBackupConfirmButton => '복원하기';

  @override
  String restoreFailedMessage(String error) {
    return '복원에 실패했습니다: $error';
  }

  @override
  String get restoreSuccessMessage => '복원했습니다';

  @override
  String get restorePassphraseTitle => '패스프레이즈 입력';

  @override
  String get commonAdd => '추가';

  @override
  String get categoryRenameAction => '이름 변경';

  @override
  String get categorySubcategoryRenameTitle => '세부 카테고리 이름 변경';

  @override
  String get categoryNameFieldLabel => '이름';

  @override
  String get categorySubcategoryAddTitle => '세부 카테고리 추가';

  @override
  String get categoryIconFieldLabel => '아이콘 (이모지・선택)';

  @override
  String get categoryEditExistingTitle => '기존 항목 편집';

  @override
  String get categoryIconOrderTitle => '아이콘 표시 순서 설정';

  @override
  String get categoryIconOrderHint => '드래그하여 정렬 (내 순서대로 표시됩니다)';

  @override
  String get categoryManageTitle => '카테고리 관리';

  @override
  String get categoryTabExpense => '지출';

  @override
  String get categoryTabIncome => '수입';

  @override
  String get categorySubAddTitle => '세부 카테고리 추가';

  @override
  String get categoryAddTitle => '새 카테고리';

  @override
  String get categorySubRenameTitle => '세부 카테고리 이름 변경';

  @override
  String get categoryRenameTitle => '카테고리 이름 변경';

  @override
  String get categorySubAddTooltip => '세부 카테고리 추가';

  @override
  String get categoryArchiveBlockedSnackbar => '세부 카테고리를 먼저 보관하세요';

  @override
  String get categoryArchivedSectionTitle => '보관됨';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (보관됨)';
  }

  @override
  String get splitStoreNameHint => '매장명';

  @override
  String get splitCancel => '그만두기';

  @override
  String get splitBreakdownLabel => '내역';

  @override
  String get splitTaxLabel => '부가세';

  @override
  String get splitTaxIncludedToggle => '세금 포함';

  @override
  String get splitTaxExcludedToggle => '세금 별도';

  @override
  String get splitTaxIndividual => '개별';

  @override
  String get splitMemoHint => '메모';

  @override
  String get splitCategoryUnselected => '카테고리 미선택';

  @override
  String get splitAmountEmpty => '금액 미입력';

  @override
  String splitTaxIncludedAmount(String amount) {
    return '세금 포함 $amount';
  }

  @override
  String get splitOverLabel => '초과';

  @override
  String get splitRemainingLabel => '남음';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get summaryEmptyTitle => '이번 달 데이터가 아직 없습니다';

  @override
  String get summaryEmptyHint => '캘린더의 ＋에서 입력할 수 있습니다';

  @override
  String get summaryIncomeLabel => '수입';

  @override
  String get summaryExpenseLabel => '지출';

  @override
  String get summaryNetLabel => '차액';

  @override
  String get summaryCategoryBreakdownTitle => '카테고리별 지출';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (보관됨)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ 내역';

  @override
  String get summaryBreakdownExpand => '▼ 내역';

  @override
  String get summaryNoBreakdownLabel => '(내역 없음)';

  @override
  String get entryNoImage => '이미지 없음';

  @override
  String get entryAmountReadFailed => '금액을 인식하지 못했습니다. 직접 입력하세요';

  @override
  String get entryStoreDirectInput => '직접 입력';

  @override
  String get entryStoreNameDialogTitle => '매장명 입력';

  @override
  String get commonOk => '확인';

  @override
  String get calendarWeekdaySun => '일';

  @override
  String get calendarWeekdayMon => '월';

  @override
  String get calendarWeekdayTue => '화';

  @override
  String get calendarWeekdayWed => '수';

  @override
  String get calendarWeekdayThu => '목';

  @override
  String get calendarWeekdayFri => '금';

  @override
  String get calendarWeekdaySat => '토';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return '지출 $expense   수입 $income   차액 $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return '$month월 $day일 기록이 없습니다';
  }

  @override
  String get calendarDayEmptyHintFirst => '오른쪽 아래 \'금액 입력\'에서 첫 기록을 추가할 수 있습니다';

  @override
  String get calendarDayEmptyHint => '오른쪽 아래 \'금액 입력\'에서 추가할 수 있습니다';

  @override
  String get calendarReceiptFallbackLabel => '영수증';

  @override
  String get calendarCategoryUnknown => '알 수 없음';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (보관됨)';
  }

  @override
  String get calendarDeleteSnackbar => '삭제했습니다';

  @override
  String get calendarUndoAction => '실행 취소';

  @override
  String get splitTaxDialogTitle => '품목별 세율';

  @override
  String get commonDone => '완료';

  @override
  String get splitRemainderLabel => '남음';

  @override
  String splitItemNumberLabel(int index) {
    return '품목 $index';
  }

  @override
  String get splitTaxIncludedLabel => '세금 포함';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount (자동)';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → 세금 포함 $net';
  }

  @override
  String get onboardingTitle => '데이터 처리 안내';

  @override
  String get onboardingBody =>
      '・기록은 기기 안에만 저장됩니다. 자동으로 외부에 전송되지 않습니다.\n・기기 내에서 자동 백업을 하지만, 기기 변경이나 고장에 대비해 설정에서 내보내기를 저장하세요.';

  @override
  String get onboardingStartButton => '시작하기';

  @override
  String get homeFabEntryLabel => '금액 입력';

  @override
  String get homeNavCalendar => '캘린더';

  @override
  String get homeNavSummary => '요약';

  @override
  String get homeNavSettings => '설정';

  @override
  String get settingsColorPickerResetDefault => '기본값으로 되돌리기';

  @override
  String get settingsColorPickerConfirm => '확인';

  @override
  String get categoryManualOrderSnackbar =>
      '직접 정렬한 순서로 변경했습니다 (설정에서 되돌릴 수 있습니다)';

  @override
  String get entryHintEnterAmount => '금액을 입력하세요';

  @override
  String get entryHintAssignItemCategory => '품목에 카테고리를 할당하세요';

  @override
  String get entryHintAssignExceedsTotal => '할당이 합계를 초과했습니다';

  @override
  String get entryHintPickDiffCategory => '차액의 카테고리를 선택하세요';

  @override
  String get entryHintSplitExceedsTotal => '내역이 합계를 초과했습니다';

  @override
  String get entryHintPickCategory => '카테고리를 선택하세요';

  @override
  String get entryHintEnterAmountAndCategory => '금액과 카테고리를 입력하세요';

  @override
  String get entryHintEnterRemainingAmount => '남은 금액도 입력하세요';

  @override
  String get settingsBackupNever => '백업 없음';

  @override
  String get settingsBackupToday => '마지막 백업: 오늘';

  @override
  String settingsBackupDaysAgo(int days) {
    return '마지막 백업: $days일 전';
  }

  @override
  String get recurringPageTitle => '매월 고정 지출·수입';

  @override
  String get settingsRecurringSubtitle => '월세, 급여 등을 매월 자동으로 기록';

  @override
  String get recurringEmptyMessage =>
      '아직 등록된 항목이 없습니다.\n오른쪽 위 ＋로 월세, 급여 등 매월 기록을 자동화할 수 있습니다';

  @override
  String get recurringAddTitle => '고정 지출·수입 추가';

  @override
  String get recurringEditTitle => '고정 지출·수입 편집';

  @override
  String get recurringAmountLabel => '금액';

  @override
  String get recurringDayLabel => '반복 입력일';

  @override
  String recurringEveryMonthDay(int day) {
    return '매월 $day일';
  }

  @override
  String dayOfMonthItem(int day) {
    return '$day일';
  }

  @override
  String get recurringDayClampNote => '31일을 선택하면 그 달의 마지막 날에 입력됩니다(예: 2월은 28일)';

  @override
  String get recurringStartMonthLabel => '시작';

  @override
  String get recurringStartThisMonth => '이번 달부터';

  @override
  String get recurringStartNextMonth => '다음 달부터';

  @override
  String get recurringActiveTitle => '사용';

  @override
  String get recurringActiveSubtitle => '끄면 자동 기록을 일시 중지합니다';

  @override
  String get recurringPausedLabel => '중지됨';

  @override
  String get recurringDeleteConfirmTitle => '삭제할까요?';

  @override
  String get recurringDeleteConfirmContent =>
      '이 고정 지출·수입을 삭제합니다. 이미 기록된 거래는 남습니다.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return '품목 $n의 카테고리를 선택하세요';
  }

  @override
  String get entryHintPickCategoryRemainder => '\'남음\' 행의 카테고리를 선택하세요';

  @override
  String get splitMemoDialogTitle => '메모 입력';

  @override
  String choreNotificationBody(int day) {
    return '매월 $day일 예정입니다';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return '지난번부터 $days일이 지났습니다';
  }

  @override
  String get homeNavMonthly => '매월';

  @override
  String get hubUpcomingSection => '이번 달 예정';

  @override
  String get hubUpcomingEmpty => '이번 달 남은 예정이 없습니다';

  @override
  String get hubRulesSection => '고정 지출·수입';

  @override
  String get hubRulesEmpty => '+로 월세나 급여 같은 매월 기록을 자동화할 수 있어요';

  @override
  String get hubChoresSection => '주기적 집안일';

  @override
  String get hubChoresEmpty => '+로 칫솔 교체 같은 집안일을 등록할 수 있어요';

  @override
  String get hubChoreTimelineLabel => '집안일';

  @override
  String get ghostBadgeLabel => '예정';

  @override
  String get forecastLabelMonthEnd => '예상 수지(월말)';

  @override
  String forecastLabelAtDate(String date) {
    return '예상 수지($date 기준)';
  }

  @override
  String choreOverdueDays(int days) {
    return '$days일 지남';
  }

  @override
  String get choreDueToday => '오늘';

  @override
  String choreDaysLeft(int days) {
    return '$days일 남음';
  }

  @override
  String choreNextDate(String date) {
    return '다음: $date';
  }

  @override
  String get choreDoneButton => '했어요';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ 기록했어요. 다음은 $date';
  }

  @override
  String get choreDupConfirmTitle => '확인';

  @override
  String choreDupConfirmBody(String name) {
    return '\"$name\"은(는) 이 날 이미 기록이 있어요. 추가할까요?';
  }

  @override
  String get choreDupConfirmAdd => '추가';

  @override
  String get choreFormNewTitle => '새 항목';

  @override
  String get choreFormEditTitle => '항목 편집';

  @override
  String get choreFormNameLabel => '항목 이름';

  @override
  String get choreRepeatUnitLabel => '반복';

  @override
  String get choreRepeatUnitMonthly => '매월';

  @override
  String get choreRepeatUnitEveryDays => '며칠마다';

  @override
  String get choreFormDayLabel => '예정일';

  @override
  String get choreFormIntervalLabel => '간격';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days일';
  }

  @override
  String choreIntervalEvery(int days) {
    return '$days일마다';
  }

  @override
  String get choreFormEmojiLabel => '이모지 (비우면 📌)';

  @override
  String get choreFormArchiveButton => '보관하기';

  @override
  String get choreFormDeleteButton => '이 항목 삭제';

  @override
  String choreDeleteConfirmBody(int count) {
    return '기록 $count건도 모두 삭제됩니다';
  }

  @override
  String get choreHistoryTitle => '기록';

  @override
  String get choreHistoryEmpty => '아직 기록이 없습니다';

  @override
  String get choreRecordEditTitle => '기록 편집';

  @override
  String get choreRecordDeleteConfirm => '기록을 삭제할까요?';

  @override
  String get choreMemoLabel => '메모';

  @override
  String get settingsChoresTitle => '주기적 집안일';

  @override
  String get settingsChoresSubtitle => '알림 시각과 보관된 항목 관리';

  @override
  String get choreNotifyTimeLabel => '알림 시각';

  @override
  String get chorePermissionChecking => '알림 권한 확인 중…';

  @override
  String get chorePermissionNotAsked => '알림 권한은 첫 기록 때 요청됩니다';

  @override
  String get chorePermissionGranted => '알림이 켜져 있어요';

  @override
  String get chorePermissionDenied => '알림이 허용되지 않았어요';

  @override
  String get chorePermissionOpenSettings => '설정 열기';

  @override
  String get choreArchivedSection => '보관된 항목';

  @override
  String get choreArchivedEmpty => '보관된 항목이 없습니다';

  @override
  String get choreUnarchiveButton => '되돌리기';

  @override
  String get forecastAnchorSheetTitle => '예상 수지 기준일';

  @override
  String get forecastAnchorSheetNote => '오늘부터 기준일까지의 예정을 실적에 더해 표시합니다(기준일 포함)';

  @override
  String get forecastAnchorMonthEnd => '월말';

  @override
  String get calendarLegendChoreDone => '했어요';

  @override
  String get calendarLegendChoreDue => '집안일 예정일';

  @override
  String get calendarLegendChoreOverdue => '기한 지남';

  @override
  String get calendarLegendGhost => '고정비 예정';

  @override
  String get entryRecurringExpense => '매월 지출';

  @override
  String get entryRecurringIncome => '매월 수입';

  @override
  String get entrySaveWithRuleExpense => '저장 (+매월 지출)';

  @override
  String get entrySaveWithRuleIncome => '저장 (+매월 수입)';

  @override
  String get entryRecurringNotePrefix => '매월';

  @override
  String get entryRecurringNoteSuffix => '일에 자동으로 기록됩니다';

  @override
  String get entrySubcategoryAddButton => '하위 카테고리 추가';
}
