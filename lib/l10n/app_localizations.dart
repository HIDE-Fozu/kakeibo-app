import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Application title shown in the OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Kakeibo'**
  String get appTitle;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Settings row title for choosing the app language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings row title for choosing the currency
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// Option to follow the device system language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Currency row subtitle shown when currency can no longer be changed
  ///
  /// In en, this message translates to:
  /// **'Locked — transactions already exist'**
  String get currencyLockedSubtitle;

  /// Title of the dialog explaining why currency is locked
  ///
  /// In en, this message translates to:
  /// **'Currency can\'t be changed'**
  String get currencyLockedTitle;

  /// Body of the dialog explaining why currency is locked
  ///
  /// In en, this message translates to:
  /// **'To keep past amounts consistent, the currency can\'t be changed once transactions have been recorded.'**
  String get currencyLockedBody;

  /// No description provided for @settingsAutoBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto backup: {generations} generations (on device)'**
  String settingsAutoBackupSubtitle(int generations);

  /// No description provided for @settingsBackupNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get settingsBackupNowTitle;

  /// No description provided for @settingsExportJsonTitle.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get settingsExportJsonTitle;

  /// No description provided for @settingsExportJsonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally encrypt with a passphrase (usable for restore)'**
  String get settingsExportJsonSubtitle;

  /// No description provided for @settingsExportCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCsvTitle;

  /// No description provided for @settingsExportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For viewing only (cannot be used to restore)'**
  String get settingsExportCsvSubtitle;

  /// No description provided for @settingsRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestoreTitle;

  /// No description provided for @settingsRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replaces all data'**
  String get settingsRestoreSubtitle;

  /// No description provided for @settingsTestUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Test cooperation (auto-send)'**
  String get settingsTestUploadTitle;

  /// No description provided for @settingsTestUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To improve receipt scanning, scan records and photos are automatically sent to the developer (testing period only). Your household ledger entries themselves are never sent.'**
  String get settingsTestUploadSubtitle;

  /// No description provided for @settingsShareTestDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Send test data'**
  String get settingsShareTestDataTitle;

  /// No description provided for @settingsShareTestDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share manually all at once (LINE/AirDrop)'**
  String get settingsShareTestDataSubtitle;

  /// No description provided for @settingsFetchCollectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Import collected data (developer only)'**
  String get settingsFetchCollectedTitle;

  /// No description provided for @settingsFetchCollectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import data from all devices into this device\'s exports/ocr-collected'**
  String get settingsFetchCollectedSubtitle;

  /// No description provided for @settingsRetainImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep receipt images on device'**
  String get settingsRetainImagesTitle;

  /// No description provided for @settingsRetainImagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discarded after saving by default'**
  String get settingsRetainImagesSubtitle;

  /// No description provided for @settingsCategoryManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get settingsCategoryManageTitle;

  /// No description provided for @settingsCategoryOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrange categories in my own order'**
  String get settingsCategoryOrderTitle;

  /// No description provided for @settingsCategoryOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off = most recently used / On = fixed order (long-press a tile on the entry screen to reorder)'**
  String get settingsCategoryOrderSubtitle;

  /// No description provided for @settingsPageColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Page color (background)'**
  String get settingsPageColorTitle;

  /// No description provided for @settingsAccentColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentColorTitle;

  /// No description provided for @settingsAccentColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Color for buttons and selections'**
  String get settingsAccentColorSubtitle;

  /// No description provided for @settingsDataPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'About data handling'**
  String get settingsDataPolicyTitle;

  /// No description provided for @settingsDataPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'• Your records are stored only on this device. They are never sent externally automatically.\n• Automatic backups are made on this device, but please also save an export from Settings in case you switch devices or your device breaks.'**
  String get settingsDataPolicyBody;

  /// No description provided for @settingsPassphraseFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (if encrypting)'**
  String get settingsPassphraseFieldLabel;

  /// No description provided for @settingsSaveAsIs.
  ///
  /// In en, this message translates to:
  /// **'Save as is'**
  String get settingsSaveAsIs;

  /// No description provided for @settingsSaveEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypt and save'**
  String get settingsSaveEncrypted;

  /// No description provided for @settingsBackupSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get settingsBackupSuccessSnackbar;

  /// No description provided for @settingsBackupFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String settingsBackupFailedSnackbar(String error);

  /// No description provided for @settingsExportSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved: {fileName}'**
  String settingsExportSavedSnackbar(String fileName);

  /// No description provided for @settingsExportFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailedSnackbar(String error);

  /// No description provided for @settingsFetchCollectedSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} items (exports/ocr-collected)'**
  String settingsFetchCollectedSuccessSnackbar(int count);

  /// No description provided for @settingsFetchCollectedFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsFetchCollectedFailedSnackbar(String error);

  /// No description provided for @settingsNoScanRecordsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No scan records yet'**
  String get settingsNoScanRecordsSnackbar;

  /// No description provided for @settingsShareTestDataSubject.
  ///
  /// In en, this message translates to:
  /// **'Household ledger test data ({count} items)'**
  String settingsShareTestDataSubject(int count);

  /// No description provided for @settingsShareTestDataFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String settingsShareTestDataFailedSnackbar(String error);

  /// No description provided for @entryTitleCreate.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entryTitleCreate;

  /// No description provided for @entryTitleReceiptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receipt'**
  String get entryTitleReceiptConfirm;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @entryTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get entryTypeExpense;

  /// No description provided for @entryTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get entryTypeIncome;

  /// No description provided for @entryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}/{year}'**
  String entryDateLabel(int year, int month, int day);

  /// No description provided for @entryStartSplitButton.
  ///
  /// In en, this message translates to:
  /// **'Select multiple categories'**
  String get entryStartSplitButton;

  /// No description provided for @entryCategoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get entryCategoryHeading;

  /// No description provided for @entryDetailMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get entryDetailMemoLabel;

  /// No description provided for @entryStoreNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get entryStoreNameLabel;

  /// No description provided for @entryCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get entryCompanyNameLabel;

  /// No description provided for @entrySaveContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get entrySaveContinueButton;

  /// No description provided for @entrySavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get entrySavedSnackbar;

  /// No description provided for @entryReceiptCaptureUnavailableSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Receipt capture isn\'t available on this device'**
  String get entryReceiptCaptureUnavailableSnackbar;

  /// No description provided for @entryOcrFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Failed to read receipt: {error}'**
  String entryOcrFailedSnackbar(String error);

  /// No description provided for @entryReceiptSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get entryReceiptSourceCamera;

  /// No description provided for @entryReceiptSourceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get entryReceiptSourceLibrary;

  /// No description provided for @entryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get entryDeleteConfirmTitle;

  /// No description provided for @entryDeleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This transaction will be deleted.'**
  String get entryDeleteConfirmContent;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @batchPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Itemize'**
  String get batchPanelTitle;

  /// No description provided for @batchModeSelectAssign.
  ///
  /// In en, this message translates to:
  /// **'Select & assign'**
  String get batchModeSelectAssign;

  /// No description provided for @batchModePaint.
  ///
  /// In en, this message translates to:
  /// **'Paint'**
  String get batchModePaint;

  /// No description provided for @batchCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get batchCancelButton;

  /// No description provided for @batchThisReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'This receipt:'**
  String get batchThisReceiptLabel;

  /// No description provided for @batchTaxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Tax incl.'**
  String get batchTaxIncluded;

  /// No description provided for @batchTaxExclusive8.
  ///
  /// In en, this message translates to:
  /// **'Tax excl. 8%'**
  String get batchTaxExclusive8;

  /// No description provided for @batchTaxExclusive10.
  ///
  /// In en, this message translates to:
  /// **'Tax excl. 10%'**
  String get batchTaxExclusive10;

  /// No description provided for @batchPaintHintNoCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category below, then tap rows to paint'**
  String get batchPaintHintNoCategory;

  /// No description provided for @batchPaintHintActive.
  ///
  /// In en, this message translates to:
  /// **'Painting \"{name}\" — tap rows (tap again to undo)'**
  String batchPaintHintActive(String name);

  /// No description provided for @batchSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select rows → tap a category below to assign'**
  String get batchSelectHint;

  /// No description provided for @batchSelectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} selected, {amount} → tap a category below'**
  String batchSelectionSummary(int count, String amount);

  /// No description provided for @batchNoAssignmentsYet.
  ///
  /// In en, this message translates to:
  /// **'(No assignments yet)'**
  String get batchNoAssignmentsYet;

  /// No description provided for @batchCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get batchCategoryUnknown;

  /// No description provided for @batchDiffPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Remainder (difference) — tap to pick a category'**
  String get batchDiffPickCategory;

  /// No description provided for @batchDiffCategorySuffix.
  ///
  /// In en, this message translates to:
  /// **'{category} (difference)'**
  String batchDiffCategorySuffix(String category);

  /// No description provided for @batchReceiptFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get batchReceiptFallbackLabel;

  /// No description provided for @batchTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get batchTotalLabel;

  /// No description provided for @batchExcessAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} ✗ {excess} over'**
  String batchExcessAmount(String amount, String excess);

  /// No description provided for @restorePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restorePageTitle;

  /// No description provided for @restoreEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No backups available to restore'**
  String get restoreEmptyMessage;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All current data will be replaced. The previous state is saved automatically and can be recovered later.'**
  String get restoreConfirmMessage;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @restoreEmptyBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'This backup has 0 transactions'**
  String get restoreEmptyBackupTitle;

  /// No description provided for @restoreEmptyBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Restoring will delete all your existing transactions. Restore anyway?'**
  String get restoreEmptyBackupMessage;

  /// No description provided for @restoreEmptyBackupConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Restore anyway'**
  String get restoreEmptyBackupConfirmButton;

  /// No description provided for @restoreFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailedMessage(String error);

  /// No description provided for @restoreSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreSuccessMessage;

  /// No description provided for @restorePassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter passphrase'**
  String get restorePassphraseTitle;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @categoryRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get categoryRenameAction;

  /// No description provided for @categorySubcategoryRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename subcategory'**
  String get categorySubcategoryRenameTitle;

  /// No description provided for @categoryNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryNameFieldLabel;

  /// No description provided for @categorySubcategoryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subcategory'**
  String get categorySubcategoryAddTitle;

  /// No description provided for @categoryIconFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji, optional)'**
  String get categoryIconFieldLabel;

  /// No description provided for @categoryEditExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit existing items'**
  String get categoryEditExistingTitle;

  /// No description provided for @categoryIconOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Icon display order settings'**
  String get categoryIconOrderTitle;

  /// No description provided for @categoryIconOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder (shown in your custom order)'**
  String get categoryIconOrderHint;

  /// No description provided for @categoryManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get categoryManageTitle;

  /// No description provided for @categoryTabExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoryTabExpense;

  /// No description provided for @categoryTabIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryTabIncome;

  /// No description provided for @categorySubAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Sub-category'**
  String get categorySubAddTitle;

  /// No description provided for @categoryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categoryAddTitle;

  /// No description provided for @categorySubRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Sub-category'**
  String get categorySubRenameTitle;

  /// No description provided for @categoryRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Category'**
  String get categoryRenameTitle;

  /// No description provided for @categorySubAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add sub-category'**
  String get categorySubAddTooltip;

  /// No description provided for @categoryArchiveBlockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Archive its sub-categories first'**
  String get categoryArchiveBlockedSnackbar;

  /// No description provided for @categoryArchivedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get categoryArchivedSectionTitle;

  /// No description provided for @categoryArchivedItemLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} (Archived)'**
  String categoryArchivedItemLabel(String name);

  /// No description provided for @splitStoreNameHint.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get splitStoreNameHint;

  /// No description provided for @splitCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get splitCancel;

  /// No description provided for @splitBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get splitBreakdownLabel;

  /// No description provided for @splitTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get splitTaxLabel;

  /// No description provided for @splitTaxIncludedToggle.
  ///
  /// In en, this message translates to:
  /// **'Tax incl.'**
  String get splitTaxIncludedToggle;

  /// No description provided for @splitTaxExcludedToggle.
  ///
  /// In en, this message translates to:
  /// **'Tax excl.'**
  String get splitTaxExcludedToggle;

  /// No description provided for @splitTaxIndividual.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get splitTaxIndividual;

  /// No description provided for @splitMemoHint.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get splitMemoHint;

  /// No description provided for @splitAddCategoryChip.
  ///
  /// In en, this message translates to:
  /// **'+ Category'**
  String get splitAddCategoryChip;

  /// No description provided for @splitTaxIncludedAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax incl. {amount}'**
  String splitTaxIncludedAmount(String amount);

  /// No description provided for @splitAddCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get splitAddCategoryLabel;

  /// No description provided for @splitOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get splitOverLabel;

  /// No description provided for @splitRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get splitRemainingLabel;

  /// No description provided for @summaryMonthHeader.
  ///
  /// In en, this message translates to:
  /// **'{month}/{year}'**
  String summaryMonthHeader(int year, int month);

  /// No description provided for @summaryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data for this month yet'**
  String get summaryEmptyTitle;

  /// No description provided for @summaryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + on the calendar to add an entry'**
  String get summaryEmptyHint;

  /// No description provided for @summaryIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get summaryIncomeLabel;

  /// No description provided for @summaryExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get summaryExpenseLabel;

  /// No description provided for @summaryNetLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get summaryNetLabel;

  /// No description provided for @summaryCategoryBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get summaryCategoryBreakdownTitle;

  /// No description provided for @summaryArchivedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (Archived)'**
  String summaryArchivedSuffix(String name);

  /// No description provided for @summaryBreakdownCollapse.
  ///
  /// In en, this message translates to:
  /// **'▲ Details'**
  String get summaryBreakdownCollapse;

  /// No description provided for @summaryBreakdownExpand.
  ///
  /// In en, this message translates to:
  /// **'▼ Details'**
  String get summaryBreakdownExpand;

  /// No description provided for @summaryNoBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'(No breakdown)'**
  String get summaryNoBreakdownLabel;

  /// No description provided for @entryNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get entryNoImage;

  /// No description provided for @entryAmountReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the amount. Please enter it manually.'**
  String get entryAmountReadFailed;

  /// No description provided for @entryStoreDirectInput.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get entryStoreDirectInput;

  /// No description provided for @entryStoreNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter store name'**
  String get entryStoreNameDialogTitle;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @calendarWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calendarWeekdaySun;

  /// No description provided for @calendarWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calendarWeekdayMon;

  /// No description provided for @calendarWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calendarWeekdayTue;

  /// No description provided for @calendarWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calendarWeekdayWed;

  /// No description provided for @calendarWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calendarWeekdayThu;

  /// No description provided for @calendarWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calendarWeekdayFri;

  /// No description provided for @calendarWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calendarWeekdaySat;

  /// No description provided for @calendarMonthYearHeader.
  ///
  /// In en, this message translates to:
  /// **'{month}/{year}'**
  String calendarMonthYearHeader(int year, int month);

  /// No description provided for @calendarMonthSummary.
  ///
  /// In en, this message translates to:
  /// **'Expense {expense}   Income {income}   Net {net}'**
  String calendarMonthSummary(String expense, String income, String net);

  /// No description provided for @calendarDayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries on {month}/{day}'**
  String calendarDayEmptyTitle(int month, int day);

  /// No description provided for @calendarDayEmptyHintFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first entry using \"Enter Amount\" in the bottom right'**
  String get calendarDayEmptyHintFirst;

  /// No description provided for @calendarDayEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add an entry using \"Enter Amount\" in the bottom right'**
  String get calendarDayEmptyHint;

  /// No description provided for @calendarReceiptFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get calendarReceiptFallbackLabel;

  /// No description provided for @calendarCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get calendarCategoryUnknown;

  /// No description provided for @calendarCategoryArchivedLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} (Archived)'**
  String calendarCategoryArchivedLabel(String name);

  /// No description provided for @calendarDeleteSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get calendarDeleteSnackbar;

  /// No description provided for @calendarUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get calendarUndoAction;

  /// No description provided for @splitTaxDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax rate per item'**
  String get splitTaxDialogTitle;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @splitRemainderLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get splitRemainderLabel;

  /// No description provided for @splitItemNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Item {index}'**
  String splitItemNumberLabel(int index);

  /// No description provided for @splitTaxIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Incl. tax'**
  String get splitTaxIncludedLabel;

  /// No description provided for @splitRemainderAutoAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} (auto)'**
  String splitRemainderAutoAmount(String amount);

  /// No description provided for @splitAmountWithTax.
  ///
  /// In en, this message translates to:
  /// **'{entered} → incl. tax {net}'**
  String splitAmountWithTax(String entered, String net);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'About Your Data'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'• Your records are stored only on this device. Nothing is sent externally.\n• The app backs up automatically on this device, but please save an export from Settings in case you switch or lose your device.'**
  String get onboardingBody;

  /// No description provided for @onboardingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStartButton;

  /// No description provided for @homeFabEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get homeFabEntryLabel;

  /// No description provided for @homeNavCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get homeNavCalendar;

  /// No description provided for @homeNavSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get homeNavSummary;

  /// No description provided for @homeNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeNavSettings;

  /// No description provided for @settingsColorPickerResetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get settingsColorPickerResetDefault;

  /// No description provided for @settingsColorPickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsColorPickerConfirm;

  /// No description provided for @categoryManualOrderSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Switched to your custom order (you can change this back in Settings).'**
  String get categoryManualOrderSnackbar;

  /// No description provided for @entryHintEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get entryHintEnterAmount;

  /// No description provided for @entryHintAssignItemCategory.
  ///
  /// In en, this message translates to:
  /// **'Assign a category to each item'**
  String get entryHintAssignItemCategory;

  /// No description provided for @entryHintAssignExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Assignments exceed the total'**
  String get entryHintAssignExceedsTotal;

  /// No description provided for @entryHintPickDiffCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category for the difference'**
  String get entryHintPickDiffCategory;

  /// No description provided for @entryHintSplitExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'The breakdown exceeds the total'**
  String get entryHintSplitExceedsTotal;

  /// No description provided for @entryHintPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get entryHintPickCategory;

  /// No description provided for @entryHintEnterAmountAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount and a category'**
  String get entryHintEnterAmountAndCategory;

  /// No description provided for @entryHintEnterRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the remaining amount too'**
  String get entryHintEnterRemainingAmount;

  /// No description provided for @settingsBackupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get settingsBackupNever;

  /// No description provided for @settingsBackupToday.
  ///
  /// In en, this message translates to:
  /// **'Last backup: today'**
  String get settingsBackupToday;

  /// No description provided for @settingsBackupDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {days} days ago'**
  String settingsBackupDaysAgo(int days);

  /// Title of the monthly recurring transactions page and its settings tile
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringPageTitle;

  /// Settings tile subtitle for recurring transactions
  ///
  /// In en, this message translates to:
  /// **'Auto-record monthly fixed costs like rent or salary'**
  String get settingsRecurringSubtitle;

  /// Empty state on the recurring list page
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.\nTap + to automate monthly entries like rent or salary.'**
  String get recurringEmptyMessage;

  /// Title when adding a recurring transaction
  ///
  /// In en, this message translates to:
  /// **'Add recurring transaction'**
  String get recurringAddTitle;

  /// Title when editing a recurring transaction
  ///
  /// In en, this message translates to:
  /// **'Edit recurring transaction'**
  String get recurringEditTitle;

  /// Label of the amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recurringAmountLabel;

  /// Label of the day-of-month picker
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get recurringDayLabel;

  /// Recurrence description, e.g. 'Day 5 every month'
  ///
  /// In en, this message translates to:
  /// **'Day {day} every month'**
  String recurringEveryMonthDay(int day);

  /// Short day-of-month item, e.g. 'Day 5'
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayOfMonthItem(int day);

  /// Helper text: days beyond a month's end clamp to the last day
  ///
  /// In en, this message translates to:
  /// **'In shorter months it falls on the last day (e.g. the 31st → Feb 28).'**
  String get recurringDayClampNote;

  /// Label of the start month picker (new rules only)
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get recurringStartMonthLabel;

  /// Start month option: current month
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get recurringStartThisMonth;

  /// Start month option: next month
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get recurringStartNextMonth;

  /// Active/paused switch title on the edit page
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringActiveTitle;

  /// Active/paused switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Turn off to pause automatic entries'**
  String get recurringActiveSubtitle;

  /// Shown in the list when a rule is paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringPausedLabel;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get recurringDeleteConfirmTitle;

  /// Delete confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'This recurring transaction will be deleted. Entries already recorded will remain.'**
  String get recurringDeleteConfirmContent;

  /// Save hint in split mode pointing at the numbered item row that lacks a category
  ///
  /// In en, this message translates to:
  /// **'Pick a category for item {n}'**
  String entryHintPickCategoryForItem(int n);

  /// Save hint in split mode when the Remaining row lacks a category
  ///
  /// In en, this message translates to:
  /// **'Pick a category for the “Remaining” row'**
  String get entryHintPickCategoryRemainder;

  /// Title of the per-item memo input dialog in split mode
  ///
  /// In en, this message translates to:
  /// **'Enter a memo'**
  String get splitMemoDialogTitle;

  /// Local notification body for a monthly chore due today
  ///
  /// In en, this message translates to:
  /// **'Monthly task scheduled for day {day}'**
  String choreNotificationBody(int day);

  /// Local notification body for an interval-based chore due today
  ///
  /// In en, this message translates to:
  /// **'It\'s been {days} days since last time'**
  String choreNotificationBodyInterval(int days);

  /// Bottom navigation label for the Monthly hub tab
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get homeNavMonthly;

  /// Monthly hub: section header for the rest-of-month timeline
  ///
  /// In en, this message translates to:
  /// **'Coming up this month'**
  String get hubUpcomingSection;

  /// Monthly hub: empty state for the timeline section
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for the rest of this month'**
  String get hubUpcomingEmpty;

  /// Monthly hub: section header for recurring transaction rules
  ///
  /// In en, this message translates to:
  /// **'Fixed costs & income'**
  String get hubRulesSection;

  /// Monthly hub: empty state for the rules section
  ///
  /// In en, this message translates to:
  /// **'Tap + to automate monthly entries like rent or salary'**
  String get hubRulesEmpty;

  /// Monthly hub: section header for chore tasks
  ///
  /// In en, this message translates to:
  /// **'Recurring chores'**
  String get hubChoresSection;

  /// Monthly hub: empty state for the chores section
  ///
  /// In en, this message translates to:
  /// **'Tap + to add chores like replacing your toothbrush'**
  String get hubChoresEmpty;

  /// Monthly hub timeline: trailing label marking a chore row
  ///
  /// In en, this message translates to:
  /// **'Chore'**
  String get hubChoreTimelineLabel;

  /// Badge on a not-yet-posted recurring transaction (ghost row)
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get ghostBadgeLabel;

  /// Forecast line label when the anchor is the end of month
  ///
  /// In en, this message translates to:
  /// **'Projected balance (end of month)'**
  String get forecastLabelMonthEnd;

  /// Forecast line label when the anchor is a specific day
  ///
  /// In en, this message translates to:
  /// **'Projected balance (as of {date})'**
  String forecastLabelAtDate(String date);

  /// Chore status: overdue by N days
  ///
  /// In en, this message translates to:
  /// **'{days}d overdue'**
  String choreOverdueDays(int days);

  /// Chore status: due today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get choreDueToday;

  /// Chore status: due in N days
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String choreDaysLeft(int days);

  /// Next due date of a chore
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String choreNextDate(String date);

  /// Button that records a chore as done today
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get choreDoneButton;

  /// Snackbar after recording a chore, with the next due date
  ///
  /// In en, this message translates to:
  /// **'✓ Recorded. Next: {date}'**
  String choreDoneSnackbar(String date);

  /// Title of the duplicate-record confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Already recorded'**
  String get choreDupConfirmTitle;

  /// Body of the duplicate-record confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already has a record on this day. Add another?'**
  String choreDupConfirmBody(String name);

  /// Confirm button of the duplicate-record dialog
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get choreDupConfirmAdd;

  /// Chore form title (create)
  ///
  /// In en, this message translates to:
  /// **'New chore'**
  String get choreFormNewTitle;

  /// Chore form title (edit)
  ///
  /// In en, this message translates to:
  /// **'Edit chore'**
  String get choreFormEditTitle;

  /// Chore form: name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get choreFormNameLabel;

  /// Label for the repeat-unit picker (monthly / every N days)
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get choreRepeatUnitLabel;

  /// No description provided for @choreRepeatUnitMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get choreRepeatUnitMonthly;

  /// No description provided for @choreRepeatUnitEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get choreRepeatUnitEveryDays;

  /// Label for the day-of-month picker in the chore form
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get choreFormDayLabel;

  /// Label for the interval picker in the chore form
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get choreFormIntervalLabel;

  /// Day-count item in the interval picker, e.g. '14 days'
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String choreIntervalDaysItem(int days);

  /// Interval description, e.g. 'Every 14 days'
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String choreIntervalEvery(int days);

  /// Chore form: emoji field label
  ///
  /// In en, this message translates to:
  /// **'Emoji (📌 if empty)'**
  String get choreFormEmojiLabel;

  /// Chore form: archive button (edit mode)
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get choreFormArchiveButton;

  /// Chore form: delete button (edit mode)
  ///
  /// In en, this message translates to:
  /// **'Delete this chore'**
  String get choreFormDeleteButton;

  /// Chore delete confirmation body
  ///
  /// In en, this message translates to:
  /// **'{count} history records will also be deleted'**
  String choreDeleteConfirmBody(int count);

  /// Chore history page title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get choreHistoryTitle;

  /// Chore history page empty state
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get choreHistoryEmpty;

  /// Chore record edit dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get choreRecordEditTitle;

  /// Chore record delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get choreRecordDeleteConfirm;

  /// Chore record memo field label
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get choreMemoLabel;

  /// Settings tile leading to chore notification settings
  ///
  /// In en, this message translates to:
  /// **'Recurring chores'**
  String get settingsChoresTitle;

  /// Settings tile subtitle for chore settings
  ///
  /// In en, this message translates to:
  /// **'Notification time and archived chores'**
  String get settingsChoresSubtitle;

  /// Chore settings: notification time row
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get choreNotifyTimeLabel;

  /// Chore settings: permission status unknown/loading
  ///
  /// In en, this message translates to:
  /// **'Checking notification permission…'**
  String get chorePermissionChecking;

  /// Chore settings: permission not requested yet
  ///
  /// In en, this message translates to:
  /// **'You\'ll be asked to allow notifications after your first record'**
  String get chorePermissionNotAsked;

  /// Chore settings: permission granted
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled'**
  String get chorePermissionGranted;

  /// Chore settings: permission denied
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed'**
  String get chorePermissionDenied;

  /// Chore settings: button opening the OS notification settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get chorePermissionOpenSettings;

  /// Chore settings: archived chores section header
  ///
  /// In en, this message translates to:
  /// **'Archived chores'**
  String get choreArchivedSection;

  /// Chore settings: archived chores empty state
  ///
  /// In en, this message translates to:
  /// **'No archived chores'**
  String get choreArchivedEmpty;

  /// Chore settings: unarchive button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get choreUnarchiveButton;

  /// Bottom sheet title for choosing the forecast anchor date
  ///
  /// In en, this message translates to:
  /// **'Anchor date for the projected balance'**
  String get forecastAnchorSheetTitle;

  /// Bottom sheet explanation of the forecast anchor
  ///
  /// In en, this message translates to:
  /// **'Planned amounts up to and including the anchor date are added to the actual balance.'**
  String get forecastAnchorSheetNote;

  /// Forecast anchor option: end of month (default)
  ///
  /// In en, this message translates to:
  /// **'End of month'**
  String get forecastAnchorMonthEnd;

  /// Calendar legend: green dot = chore recorded that day
  ///
  /// In en, this message translates to:
  /// **'chore done'**
  String get calendarLegendChoreDone;

  /// Calendar legend: orange dot = chore due date
  ///
  /// In en, this message translates to:
  /// **'chore due'**
  String get calendarLegendChoreDue;

  /// Calendar legend: red dot = chore overdue
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get calendarLegendChoreOverdue;

  /// Calendar legend: grey amount = not-yet-posted recurring transaction
  ///
  /// In en, this message translates to:
  /// **'planned fixed cost'**
  String get calendarLegendGhost;

  /// Entry screen toggle that also creates a recurring rule (expense)
  ///
  /// In en, this message translates to:
  /// **'Monthly expense'**
  String get entryRecurringExpense;

  /// Entry screen toggle that also creates a recurring rule (income)
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get entryRecurringIncome;

  /// Save button label while the monthly expense toggle is on
  ///
  /// In en, this message translates to:
  /// **'Save + monthly expense'**
  String get entrySaveWithRuleExpense;

  /// Save button label while the monthly income toggle is on
  ///
  /// In en, this message translates to:
  /// **'Save + monthly income'**
  String get entrySaveWithRuleIncome;

  /// Monthly-toggle note: text before the inline day dropdown
  ///
  /// In en, this message translates to:
  /// **'Recorded automatically on day'**
  String get entryRecurringNotePrefix;

  /// Monthly-toggle note: text after the inline day dropdown
  ///
  /// In en, this message translates to:
  /// **'of every month'**
  String get entryRecurringNoteSuffix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
