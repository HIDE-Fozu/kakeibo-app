// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Haushaltsbuch';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get languageSystemDefault => 'Systemsprache';

  @override
  String get currencyLockedSubtitle =>
      'Gesperrt – es gibt bereits Transaktionen';

  @override
  String get currencyLockedTitle => 'Währung kann nicht geändert werden';

  @override
  String get currencyLockedBody =>
      'Damit frühere Beträge korrekt bleiben, kann die Währung nicht mehr geändert werden, sobald Transaktionen erfasst wurden.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return 'Automatisches Backup: $generations Versionen (auf dem Gerät)';
  }

  @override
  String get settingsBackupNowTitle => 'Jetzt sichern';

  @override
  String get settingsExportJsonTitle => 'JSON exportieren';

  @override
  String get settingsExportJsonSubtitle =>
      'Optional mit Passphrase verschlüsseln (für Wiederherstellung nutzbar)';

  @override
  String get settingsExportCsvTitle => 'CSV exportieren';

  @override
  String get settingsExportCsvSubtitle =>
      'Nur zur Ansicht (nicht zur Wiederherstellung)';

  @override
  String get settingsRestoreTitle => 'Wiederherstellen';

  @override
  String get settingsRestoreSubtitle => 'Ersetzt alle Daten';

  @override
  String get settingsTestUploadTitle => 'Testteilnahme (automatisch senden)';

  @override
  String get settingsTestUploadSubtitle =>
      'Zur Verbesserung der Belegerkennung werden Scan-Protokolle und Fotos automatisch an den Entwickler gesendet (nur während der Testphase). Deine Haushaltsbuch-Einträge selbst werden nie gesendet.';

  @override
  String get settingsShareTestDataTitle => 'Testdaten senden';

  @override
  String get settingsShareTestDataSubtitle =>
      'Manuell alles auf einmal teilen (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle =>
      'Gesammelte Daten importieren (nur Entwickler)';

  @override
  String get settingsFetchCollectedSubtitle =>
      'Daten aller Geräte in exports/ocr-collected dieses Geräts importieren';

  @override
  String get settingsRetainImagesTitle => 'Belegbilder auf dem Gerät behalten';

  @override
  String get settingsRetainImagesSubtitle =>
      'Standardmäßig nach dem Speichern verworfen';

  @override
  String get settingsCategoryManageTitle => 'Kategorien verwalten';

  @override
  String get settingsCategoryOrderTitle => 'Kategorien selbst anordnen';

  @override
  String get settingsCategoryOrderSubtitle =>
      'Aus = zuletzt verwendet / Ein = feste Reihenfolge (Kachel im Eingabebildschirm lang drücken zum Umordnen)';

  @override
  String get settingsDataPolicyTitle => 'Zum Umgang mit Daten';

  @override
  String get settingsDataPolicyBody =>
      '• Deine Aufzeichnungen werden nur auf diesem Gerät gespeichert. Sie werden nie automatisch nach außen gesendet.\n• Automatische Backups werden auf diesem Gerät erstellt. Speichere aber zusätzlich einen Export aus den Einstellungen, falls du das Gerät wechselst oder es defekt ist.';

  @override
  String get settingsPassphraseFieldLabel => 'Passphrase (bei Verschlüsselung)';

  @override
  String get settingsSaveAsIs => 'Unverschlüsselt speichern';

  @override
  String get settingsSaveEncrypted => 'Verschlüsselt speichern';

  @override
  String get settingsBackupSuccessSnackbar => 'Backup erstellt';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'Backup fehlgeschlagen: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return 'Gespeichert: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return '$count Einträge importiert (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar => 'Noch keine Scan-Protokolle';

  @override
  String settingsShareTestDataSubject(int count) {
    return 'Haushaltsbuch-Testdaten ($count Einträge)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get entryTitleCreate => 'Eingabe';

  @override
  String get entryTitleReceiptConfirm => 'Beleg prüfen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get entryTypeExpense => 'Ausgabe';

  @override
  String get entryTypeIncome => 'Einnahme';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$day.$month.$year';
  }

  @override
  String get entryStartSplitButton => 'Kategorie hinzufügen';

  @override
  String get entryCategoryHeading => 'Kategorie';

  @override
  String get entryDetailMemoLabel => 'Notizen';

  @override
  String get entryStoreNameLabel => 'Geschäftsname';

  @override
  String get entryCompanyNameLabel => 'Firmenname';

  @override
  String get entrySaveContinueButton => 'Speichern & weiter';

  @override
  String get entrySavedSnackbar => 'Gespeichert';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      'Belegaufnahme auf diesem Gerät nicht verfügbar';

  @override
  String entryOcrFailedSnackbar(String error) {
    return 'Beleg konnte nicht gelesen werden: $error';
  }

  @override
  String get entryReceiptSourceCamera => 'Foto aufnehmen';

  @override
  String get entryReceiptSourceLibrary => 'Aus Fotos auswählen';

  @override
  String get entryDeleteConfirmTitle => 'Eintrag löschen?';

  @override
  String get entryDeleteConfirmContent => 'Diese Transaktion wird gelöscht.';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get batchPanelTitle => 'Aufteilen';

  @override
  String get batchModeSelectAssign => 'Auswählen & zuweisen';

  @override
  String get batchModePaint => 'Einfärben';

  @override
  String get batchCancelButton => 'Abbrechen';

  @override
  String get batchThisReceiptLabel => 'Dieser Beleg:';

  @override
  String get batchTaxIncluded => 'inkl. MwSt.';

  @override
  String get batchTaxExclusive8 => 'exkl. 8% MwSt.';

  @override
  String get batchTaxExclusive10 => 'exkl. 10% MwSt.';

  @override
  String get batchPaintHintNoCategory =>
      'Unten eine Kategorie wählen, dann Zeilen zum Einfärben antippen';

  @override
  String batchPaintHintActive(String name) {
    return '„$name“ wird eingefärbt – Zeilen antippen (nochmal antippen zum Aufheben)';
  }

  @override
  String get batchSelectHint =>
      'Zeilen auswählen → unten eine Kategorie zum Zuweisen antippen';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count ausgewählt, $amount → unten Kategorie antippen';
  }

  @override
  String get batchNoAssignmentsYet => '(Noch keine Zuweisungen)';

  @override
  String get batchCategoryUnknown => 'Unbekannt';

  @override
  String get batchDiffPickCategory =>
      'Rest (Differenz) – zum Wählen einer Kategorie antippen';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (Differenz)';
  }

  @override
  String get batchReceiptFallbackLabel => 'Beleg';

  @override
  String get batchTotalLabel => 'Summe';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess zu viel';
  }

  @override
  String get restorePageTitle => 'Wiederherstellen';

  @override
  String get restoreEmptyMessage =>
      'Keine Backups zum Wiederherstellen vorhanden';

  @override
  String get restoreConfirmTitle => 'Dieses Backup wiederherstellen?';

  @override
  String get restoreConfirmMessage =>
      'Alle aktuellen Daten werden ersetzt. Der vorherige Stand wird automatisch gesichert und kann später wiederhergestellt werden.';

  @override
  String get restoreButton => 'Wiederherstellen';

  @override
  String get restoreEmptyBackupTitle => 'Dieses Backup enthält 0 Transaktionen';

  @override
  String get restoreEmptyBackupMessage =>
      'Beim Wiederherstellen werden alle vorhandenen Transaktionen gelöscht. Trotzdem wiederherstellen?';

  @override
  String get restoreEmptyBackupConfirmButton => 'Trotzdem wiederherstellen';

  @override
  String restoreFailedMessage(String error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get restoreSuccessMessage => 'Wiederherstellung abgeschlossen';

  @override
  String get restorePassphraseTitle => 'Passphrase eingeben';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get categoryRenameAction => 'Umbenennen';

  @override
  String get categorySubcategoryRenameTitle => 'Unterkategorie umbenennen';

  @override
  String get categoryNameFieldLabel => 'Name';

  @override
  String get categorySubcategoryAddTitle => 'Unterkategorie hinzufügen';

  @override
  String get categoryIconFieldLabel => 'Symbol (Emoji, optional)';

  @override
  String get categoryEditExistingTitle => 'Vorhandene Einträge bearbeiten';

  @override
  String get categoryIconOrderTitle => 'Reihenfolge der Symbole';

  @override
  String get categoryIconOrderHint =>
      'Zum Umordnen ziehen (wird in deiner Reihenfolge angezeigt)';

  @override
  String get categoryManageTitle => 'Kategorien verwalten';

  @override
  String get categoryTabExpense => 'Ausgaben';

  @override
  String get categoryTabIncome => 'Einnahmen';

  @override
  String get categorySubAddTitle => 'Unterkategorie hinzufügen';

  @override
  String get categoryAddTitle => 'Neue Kategorie';

  @override
  String get categorySubRenameTitle => 'Unterkategorie umbenennen';

  @override
  String get categoryRenameTitle => 'Kategorie umbenennen';

  @override
  String get categorySubAddTooltip => 'Unterkategorie hinzufügen';

  @override
  String get categoryArchiveBlockedSnackbar =>
      'Zuerst die Unterkategorien archivieren';

  @override
  String get categoryArchivedSectionTitle => 'Archiviert';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (archiviert)';
  }

  @override
  String get splitCancel => 'Abbrechen';

  @override
  String get splitBreakdownLabel => 'Aufteilung';

  @override
  String get splitTaxLabel => 'MwSt.';

  @override
  String get splitTaxIncludedToggle => 'inkl.';

  @override
  String get splitTaxExcludedToggle => 'exkl.';

  @override
  String get splitTaxIndividual => 'Einzeln';

  @override
  String get splitMemoHint => 'Notiz';

  @override
  String get splitCategoryUnselected => 'Keine Kategorie';

  @override
  String get splitAmountEmpty => 'Kein Betrag';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'inkl. MwSt. $amount';
  }

  @override
  String get splitOverLabel => 'Zu viel';

  @override
  String get splitRemainingLabel => 'Rest';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get summaryEmptyTitle => 'Noch keine Daten für diesen Monat';

  @override
  String get summaryEmptyHint =>
      'Über das ＋ im Kalender einen Eintrag hinzufügen';

  @override
  String get summaryIncomeLabel => 'Einnahmen';

  @override
  String get summaryExpenseLabel => 'Ausgaben';

  @override
  String get summaryNetLabel => 'Saldo';

  @override
  String get summaryCategoryBreakdownTitle => 'Ausgaben nach Kategorie';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (archiviert)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ Details';

  @override
  String get summaryBreakdownExpand => '▼ Details';

  @override
  String get summaryNoBreakdownLabel => '(Keine Aufteilung)';

  @override
  String get entryNoImage => 'Kein Bild';

  @override
  String get entryAmountReadFailed =>
      'Betrag konnte nicht gelesen werden. Bitte manuell eingeben.';

  @override
  String get entryStoreDirectInput => 'Manuell eingeben';

  @override
  String get entryStoreNameDialogTitle => 'Geschäftsname eingeben';

  @override
  String get commonOk => 'OK';

  @override
  String get calendarWeekdaySun => 'So';

  @override
  String get calendarWeekdayMon => 'Mo';

  @override
  String get calendarWeekdayTue => 'Di';

  @override
  String get calendarWeekdayWed => 'Mi';

  @override
  String get calendarWeekdayThu => 'Do';

  @override
  String get calendarWeekdayFri => 'Fr';

  @override
  String get calendarWeekdaySat => 'Sa';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get calendarDayEmptyTitle =>
      'Für diesen Tag gibt es noch keine Einträge';

  @override
  String get calendarDayEmptyHint =>
      'Erfassen Sie über die Schaltflächen eine Ausgabe oder Einnahme';

  @override
  String get calendarAddExpense => 'Ausgabe hinzufügen';

  @override
  String get calendarAddIncome => 'Einnahme hinzufügen';

  @override
  String get calendarChoreTab => 'Aufgaben';

  @override
  String get calendarChoreTabEmpty => 'Keine Aufgaben an diesem Tag';

  @override
  String get calendarMemoTab => 'Notizen';

  @override
  String get shoppingMemoHint =>
      'Einkaufsnotizen (z. B. Milch, Toilettenpapier)';

  @override
  String get settingsBudgetTitle => 'Monatsbudget';

  @override
  String get settingsBudgetSubtitle =>
      'Zeigt das verbleibende Budget über dem Kalender an';

  @override
  String get settingsBudgetAmountTitle => 'Budgetbetrag';

  @override
  String get budgetRemainingLabel => 'Verbleibendes Budget';

  @override
  String get settingsPaymentModeTitle => 'Zahlungsarten';

  @override
  String get settingsPaymentModeSubtitle =>
      'Kartenkäufe als offen führen und am Abbuchungstag bündeln';

  @override
  String get summaryPaymentLabel => 'Gezahlt';

  @override
  String get summaryBasisTitle => 'Wie die Übersicht zählt';

  @override
  String get summaryBasisCashOption => 'Gezahlt (am Abbuchungstag)';

  @override
  String get summaryBasisAccrualOption => 'Ausgegeben (am Kaufdatum)';

  @override
  String get paymentCardClosingDayLabel => 'Abrechnungstag';

  @override
  String get closingDayMonthEnd => 'Monatsende';

  @override
  String closingDayNth(int day) {
    return '$day.';
  }

  @override
  String get payableBadgeNextMonth => 'Nächst. M.';

  @override
  String get payableBadgeMonthAfterNext => 'In 2 M.';

  @override
  String payableBadgeMonth(int month) {
    return '$month.';
  }

  @override
  String get payableDetailTitle => 'Offener Posten';

  @override
  String get payableCardLabel => 'Karte';

  @override
  String get payableCountLabel => 'Anzahl der Zahlungen';

  @override
  String get payableStartYmLabel => 'Erster Zahlungsmonat';

  @override
  String get payableOnceOption => 'Einmalig';

  @override
  String payableTimesOption(int count) {
    return '$count×';
  }

  @override
  String get payableTotalLabel => 'Gesamtbetrag';

  @override
  String get payableFeeLabel => 'davon Gebühren';

  @override
  String get payableScheduleHeading => 'Zahlungsplan';

  @override
  String get payableMakeImmediate => 'Nicht mehr als offen führen';

  @override
  String payableYmFormat(int year, int month) {
    return '$month/$year';
  }

  @override
  String cardPaymentRowLabel(String card) {
    return '$card Abbuchung';
  }

  @override
  String get paymentCash => 'Bar';

  @override
  String get entryPaymentPickerTitle => 'Zahlungsart';

  @override
  String get paymentCardsTitle => 'Karten verwalten';

  @override
  String get paymentCardsEmptyMessage =>
      'Noch keine Karten. Oben mit + Name und Abbuchungstag anlegen.';

  @override
  String get paymentCardAddTitle => 'Karte hinzufügen';

  @override
  String get paymentCardEditTitle => 'Karte bearbeiten';

  @override
  String get paymentCardNameLabel => 'Name';

  @override
  String get paymentCardPayDayLabel => 'Abbuchungstag';

  @override
  String get paymentCardRateLabel => 'Effektivzins für spätere Raten (%)';

  @override
  String get paymentCardBusinessDayLabel =>
      'Wenn der Abbuchungstag kein Geschäftstag ist';

  @override
  String get businessDayRuleNext => 'Nächster Geschäftstag';

  @override
  String get businessDayRulePrevious => 'Vorheriger Geschäftstag';

  @override
  String get businessDayRuleNone => 'Datum beibehalten';

  @override
  String get paymentCardInUseDeleteError =>
      'Diese Karte wird von offenen Posten genutzt und kann nicht gelöscht werden';

  @override
  String paymentCardBillingDaySummary(int day) {
    return 'Jeden $day.';
  }

  @override
  String get calendarReceiptFallbackLabel => 'Beleg';

  @override
  String get calendarCategoryUnknown => 'Unbekannt';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (archiviert)';
  }

  @override
  String get calendarUndoAction => 'Rückgängig';

  @override
  String get trashMovedSnack =>
      'In den Papierkorb verschoben (Wiederherstellen in den Einstellungen)';

  @override
  String get trashTitle => 'Papierkorb';

  @override
  String get settingsTrashSubtitle =>
      'Gelöschte Buchungen werden 30 Tage aufbewahrt';

  @override
  String get trashEmpty => 'Der Papierkorb ist leer';

  @override
  String get trashRestore => 'Wiederherstellen';

  @override
  String get trashRestoredSnack => 'Wiederhergestellt';

  @override
  String trashDeletedOn(String date) {
    return 'Gelöscht am $date';
  }

  @override
  String get trashEmptyAction => 'Papierkorb leeren';

  @override
  String get trashEmptyConfirmTitle => 'Papierkorb leeren?';

  @override
  String get trashEmptyConfirmContent =>
      'Alle Einträge werden endgültig gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get splitTaxDialogTitle => 'Steuersatz pro Posten';

  @override
  String get commonDone => 'Fertig';

  @override
  String get splitRemainderLabel => 'Rest';

  @override
  String splitItemNumberLabel(int index) {
    return 'Posten $index';
  }

  @override
  String get splitTaxIncludedLabel => 'inkl. MwSt.';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount (automatisch)';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → inkl. MwSt. $net';
  }

  @override
  String get onboardingTitle => 'Zu deinen Daten';

  @override
  String get onboardingBody =>
      '• Deine Aufzeichnungen werden nur auf diesem Gerät gespeichert. Es wird nichts nach außen gesendet.\n• Die App sichert automatisch auf diesem Gerät. Speichere aber einen Export aus den Einstellungen, falls du dein Gerät wechselst oder verlierst.';

  @override
  String get onboardingStartButton => 'Los geht\'s';

  @override
  String get homeFabEntryLabel => 'Eintrag erfassen';

  @override
  String get homeNavCalendar => 'Kalender';

  @override
  String get homeNavSummary => 'Übersicht';

  @override
  String get homeNavSettings => 'Einstellungen';

  @override
  String get categoryManualOrderSnackbar =>
      'Auf deine eigene Reihenfolge umgestellt (in den Einstellungen wieder änderbar).';

  @override
  String get entryHintEnterAmount => 'Betrag eingeben';

  @override
  String get entryHintAssignItemCategory =>
      'Jedem Posten eine Kategorie zuweisen';

  @override
  String get entryHintAssignExceedsTotal => 'Zuweisungen übersteigen die Summe';

  @override
  String get entryHintPickDiffCategory => 'Kategorie für die Differenz wählen';

  @override
  String get entryHintSplitExceedsTotal =>
      'Die Aufteilung übersteigt die Summe';

  @override
  String get entryHintPickCategory => 'Kategorie wählen';

  @override
  String get entryHintEnterAmountAndCategory => 'Betrag und Kategorie eingeben';

  @override
  String get entryHintEnterRemainingAmount => 'Auch den Restbetrag eingeben';

  @override
  String get settingsBackupNever => 'Noch kein Backup';

  @override
  String get settingsBackupToday => 'Letztes Backup: heute';

  @override
  String settingsBackupDaysAgo(int days) {
    return 'Letztes Backup: vor $days Tagen';
  }

  @override
  String get recurringPageTitle => 'Monatliche Fixposten';

  @override
  String get settingsRecurringSubtitle =>
      'Miete, Gehalt usw. jeden Monat automatisch erfassen';

  @override
  String get recurringEmptyMessage =>
      'Noch nichts eingerichtet.\nTippe auf +, um monatliche Einträge wie Miete oder Gehalt zu automatisieren.';

  @override
  String get recurringAddTitle => 'Fixposten hinzufügen';

  @override
  String get recurringEditTitle => 'Fixposten bearbeiten';

  @override
  String get recurringAmountLabel => 'Betrag';

  @override
  String get recurringDayLabel => 'Wiederholungstag';

  @override
  String recurringEveryMonthDay(int day) {
    return 'Am $day. jeden Monats';
  }

  @override
  String dayOfMonthItem(int day) {
    return 'Tag $day';
  }

  @override
  String get recurringDayClampNote =>
      'Wenn du den 31. wählst, wird am letzten Tag des Monats gebucht (z. B. 28. Februar).';

  @override
  String get recurringStartMonthLabel => 'Beginn';

  @override
  String get recurringStartThisMonth => 'Diesen Monat';

  @override
  String get recurringStartNextMonth => 'Nächsten Monat';

  @override
  String get recurringEndMonthLabel => 'Endet';

  @override
  String get recurringEndNone => 'Kein Ende (fortlaufend)';

  @override
  String get recurringEndMonthNote =>
      'Bis zu diesem Monat gebucht, danach Stopp';

  @override
  String get recurringActiveTitle => 'Aktiv';

  @override
  String get recurringActiveSubtitle =>
      'Zum Pausieren der automatischen Buchung ausschalten';

  @override
  String get recurringPausedLabel => 'Pausiert';

  @override
  String get recurringDeleteConfirmTitle => 'Löschen?';

  @override
  String get recurringDeleteConfirmContent =>
      'Dieser Fixposten wird gelöscht. Bereits erstellte Buchungen bleiben erhalten.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return 'Wähle eine Kategorie für Posten $n';
  }

  @override
  String get entryHintPickCategoryRemainder =>
      'Wähle eine Kategorie für die Zeile „Rest“';

  @override
  String get splitMemoDialogTitle => 'Notiz eingeben';

  @override
  String choreNotificationBody(int day) {
    return 'Monatliche Aufgabe am Tag $day fällig';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return 'Seit dem letzten Mal sind $days Tage vergangen';
  }

  @override
  String get homeNavMonthly => 'Monatlich';

  @override
  String get hubUpcomingSection => 'Demnächst in diesem Monat';

  @override
  String get hubUpcomingEmpty => 'Für den Rest des Monats ist nichts geplant';

  @override
  String get hubRulesSection => 'Fixkosten & Einkommen';

  @override
  String get hubRulesEmpty =>
      'Mit + automatisierst du monatliche Einträge wie Miete oder Gehalt';

  @override
  String get hubChoresSection => 'Wiederkehrende Aufgaben';

  @override
  String get hubChoresEmpty =>
      'Mit + kannst du Aufgaben wie Zahnbürstenwechsel anlegen';

  @override
  String get hubChoreTimelineLabel => 'Aufgabe';

  @override
  String get ghostBadgeLabel => 'Geplant';

  @override
  String get forecastLabelMonthEnd => 'Prognose (Monatsende)';

  @override
  String choreOverdueDays(int days) {
    return '$days T. überfällig';
  }

  @override
  String get choreDueToday => 'Heute';

  @override
  String choreDaysLeft(int days) {
    return 'in $days Tagen';
  }

  @override
  String choreNextDate(String date) {
    return 'Nächstes Mal: $date';
  }

  @override
  String get choreDoneButton => 'Erledigt';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ Erfasst. Nächstes Mal: $date';
  }

  @override
  String get choreDupConfirmTitle => 'Bereits erfasst';

  @override
  String choreDupConfirmBody(String name) {
    return '„$name“ hat an diesem Tag bereits einen Eintrag. Noch einen hinzufügen?';
  }

  @override
  String get choreDupConfirmAdd => 'Hinzufügen';

  @override
  String get choreFormNewTitle => 'Neue Aufgabe';

  @override
  String get choreFormEditTitle => 'Aufgabe bearbeiten';

  @override
  String get choreFormNameLabel => 'Name';

  @override
  String get choreRepeatUnitLabel => 'Wiederholung';

  @override
  String get choreRepeatUnitMonthly => 'Monatlich';

  @override
  String get choreRepeatUnitEveryDays => 'Alle N Tage';

  @override
  String get choreFormDayLabel => 'Tag';

  @override
  String get choreFormIntervalLabel => 'Intervall';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days Tage';
  }

  @override
  String choreIntervalEvery(int days) {
    return 'Alle $days Tage';
  }

  @override
  String get choreFormEmojiLabel => 'Emoji (📌 wenn leer)';

  @override
  String get choreFormArchiveButton => 'Archivieren';

  @override
  String get choreFormDeleteButton => 'Diese Aufgabe löschen';

  @override
  String choreDeleteConfirmBody(int count) {
    return '$count Verlaufseinträge werden ebenfalls gelöscht';
  }

  @override
  String get choreHistoryTitle => 'Verlauf';

  @override
  String get choreHistoryEmpty => 'Noch keine Einträge';

  @override
  String get choreRecordEditTitle => 'Eintrag bearbeiten';

  @override
  String get choreRecordDeleteConfirm => 'Diesen Eintrag löschen?';

  @override
  String get choreMemoLabel => 'Notiz';

  @override
  String get settingsChoresTitle => 'Wiederkehrende Aufgaben';

  @override
  String get settingsChoresSubtitle =>
      'Erinnerungszeit und archivierte Aufgaben';

  @override
  String get choreNotifyTimeLabel => 'Erinnerungszeit';

  @override
  String get chorePermissionChecking => 'Prüfe Benachrichtigungs-Berechtigung…';

  @override
  String get chorePermissionNotAsked =>
      'Die Berechtigung wird nach dem ersten Eintrag abgefragt';

  @override
  String get chorePermissionGranted => 'Benachrichtigungen sind aktiviert';

  @override
  String get chorePermissionDenied => 'Benachrichtigungen sind nicht erlaubt';

  @override
  String get chorePermissionOpenSettings => 'Einstellungen öffnen';

  @override
  String get choreArchivedSection => 'Archivierte Aufgaben';

  @override
  String get choreArchivedEmpty => 'Keine archivierten Aufgaben';

  @override
  String get choreUnarchiveButton => 'Wiederherstellen';

  @override
  String get calendarLegendChoreDone => 'erledigt';

  @override
  String get calendarLegendChoreDue => 'Aufgabe fällig';

  @override
  String get calendarLegendChoreOverdue => 'überfällig';

  @override
  String get entryRecurringExpense => 'Monatliche Ausgabe';

  @override
  String get entryRecurringIncome => 'Monatliches Einkommen';

  @override
  String get entrySaveWithRuleExpense => 'Speichern (+ monatlich)';

  @override
  String get entrySaveWithRuleIncome => 'Speichern (+ monatlich)';

  @override
  String get entryRecurringNotePrefix => 'Wird monatlich am Tag';

  @override
  String get entryRecurringNoteSuffix => 'automatisch erfasst';

  @override
  String get entrySubcategoryAddButton => 'Unterkategorie hinzufügen';

  @override
  String get settingsColorTitle => 'Farbe';

  @override
  String get settingsColorSubtitle =>
      'Hintergründe, Linien und Akzente passen sich der gewählten Farbe an';

  @override
  String get settingsColorPreset => 'Voreinstellungen';

  @override
  String get settingsColorCustom => 'Benutzerdefiniert';

  @override
  String get settingsColorApply => 'Übernehmen';

  @override
  String get settingsColorDefaultBadge => 'Standard';

  @override
  String get settingsColorBlue => 'Blau';

  @override
  String get settingsColorGreen => 'Grün';

  @override
  String get settingsColorTeal => 'Türkis';

  @override
  String get settingsColorPurple => 'Lila';

  @override
  String get settingsColorRose => 'Rosé';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsColorMustard => 'Senf';

  @override
  String get settingsColorGray => 'Grau';

  @override
  String get settingsColorTerracotta => 'Terrakotta';

  @override
  String get settingsColorNavy => 'Marineblau';

  @override
  String get installmentTitle => 'Ratenzahlung hinzufügen';

  @override
  String get installmentAddButton => 'Ratenzahlung';

  @override
  String get installmentPrincipalLabel => 'Kaufbetrag';

  @override
  String get installmentCountLabel => 'Anzahl der Raten';

  @override
  String installmentCountItem(int n) {
    return '$n Raten';
  }

  @override
  String get installmentRateLabel => 'Effektiver Jahreszins (%)';

  @override
  String get installmentCardPickLabel => 'Gespeicherte Karten';

  @override
  String get installmentCardNameLabel => 'Kartenname (optional)';

  @override
  String get installmentDayLabel => 'Zahltag';

  @override
  String get installmentMonthlyLabel => 'Monatliche Rate';

  @override
  String get installmentFirstLabel => 'Erste Rate';

  @override
  String get installmentFeeLabel => 'Zinsen gesamt';

  @override
  String get installmentTotalLabel => 'Gesamtbetrag';

  @override
  String installmentTxnMemo(int index, int count) {
    return 'Rate $index/$count';
  }

  @override
  String get installmentEditTitle => 'Ratenzahlung bearbeiten';

  @override
  String get installmentDeleteConfirmContent =>
      'Diese Ratenzahlung und alle zugehörigen Buchungen werden gelöscht.';

  @override
  String get hubInstallmentEmpty => 'Noch keine Ratenzahlungen';
}
