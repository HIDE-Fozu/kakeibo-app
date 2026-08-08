// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Kakeibo';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonSave => 'Salva';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsCurrency => 'Valuta';

  @override
  String get languageSystemDefault => 'Lingua del dispositivo';

  @override
  String get currencyLockedSubtitle => 'Bloccata — esistono già transazioni';

  @override
  String get currencyLockedTitle => 'Impossibile cambiare la valuta';

  @override
  String get currencyLockedBody =>
      'Per mantenere coerenti gli importi passati, non è possibile cambiare la valuta dopo aver registrato delle transazioni.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return 'Backup automatico: $generations versioni (sul dispositivo)';
  }

  @override
  String get settingsBackupNowTitle => 'Esegui backup ora';

  @override
  String get settingsExportJsonTitle => 'Esporta JSON';

  @override
  String get settingsExportJsonSubtitle =>
      'Cifratura con passphrase opzionale (utilizzabile per il ripristino)';

  @override
  String get settingsExportCsvTitle => 'Esporta CSV';

  @override
  String get settingsExportCsvSubtitle =>
      'Solo per la consultazione (non utilizzabile per il ripristino)';

  @override
  String get settingsRestoreTitle => 'Ripristina';

  @override
  String get settingsRestoreSubtitle => 'Sostituisce tutti i dati';

  @override
  String get settingsTestUploadTitle => 'Collabora ai test (invio automatico)';

  @override
  String get settingsTestUploadSubtitle =>
      'Per migliorare la scansione degli scontrini, i dati e le foto delle scansioni vengono inviati automaticamente allo sviluppatore (solo durante il periodo di test). Le voci del tuo bilancio non vengono mai inviate.';

  @override
  String get settingsShareTestDataTitle => 'Invia dati di test';

  @override
  String get settingsShareTestDataSubtitle =>
      'Condivisione manuale in blocco (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle =>
      'Importa dati raccolti (solo sviluppatore)';

  @override
  String get settingsFetchCollectedSubtitle =>
      'Importa i dati di tutti i dispositivi in exports/ocr-collected su questo dispositivo';

  @override
  String get settingsRetainImagesTitle =>
      'Conserva le immagini degli scontrini sul dispositivo';

  @override
  String get settingsRetainImagesSubtitle =>
      'Per impostazione predefinita vengono eliminate dopo il salvataggio';

  @override
  String get settingsCategoryManageTitle => 'Gestisci categorie';

  @override
  String get settingsCategoryOrderTitle => 'Ordina le categorie a modo mio';

  @override
  String get settingsCategoryOrderSubtitle =>
      'Off = più recenti / On = ordine fisso (tieni premuta una casella nella schermata di inserimento → riordina)';

  @override
  String get settingsPageColorTitle => 'Colore pagina (sfondo)';

  @override
  String get settingsAccentColorTitle => 'Colore accento';

  @override
  String get settingsAccentColorSubtitle => 'Colore di pulsanti e selezioni';

  @override
  String get settingsDataPolicyTitle => 'Gestione dei dati';

  @override
  String get settingsDataPolicyBody =>
      '・I tuoi dati vengono salvati solo su questo dispositivo. Non vengono mai inviati all\'esterno in automatico.\n・Il backup automatico viene eseguito sul dispositivo, ma salva anche un\'esportazione dalle impostazioni in caso di cambio o guasto del dispositivo.';

  @override
  String get settingsPassphraseFieldLabel => 'Passphrase (se si cifra)';

  @override
  String get settingsSaveAsIs => 'Salva così com\'è';

  @override
  String get settingsSaveEncrypted => 'Cifra e salva';

  @override
  String get settingsBackupSuccessSnackbar => 'Backup creato';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'Backup non riuscito: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return 'Salvato: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return 'Importati $count elementi (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar =>
      'Ancora nessuna scansione registrata';

  @override
  String settingsShareTestDataSubject(int count) {
    return 'Dati di test del bilancio ($count elementi)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return 'Invio non riuscito: $error';
  }

  @override
  String get entryTitleCreate => 'Inserimento';

  @override
  String get entryTitleReceiptConfirm => 'Conferma scontrino';

  @override
  String get commonEdit => 'Modifica';

  @override
  String get entryTypeExpense => 'Spesa';

  @override
  String get entryTypeIncome => 'Entrata';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$day/$month/$year';
  }

  @override
  String get entryStartSplitButton => 'Scegli più categorie';

  @override
  String get entryCategoryHeading => 'Categoria';

  @override
  String get entryDetailMemoLabel => 'Note';

  @override
  String get entryStoreNameLabel => 'Nome del negozio';

  @override
  String get entrySaveContinueButton => 'Salva e continua';

  @override
  String get entrySavedSnackbar => 'Salvato';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      'La scansione degli scontrini non è disponibile su questo dispositivo';

  @override
  String entryOcrFailedSnackbar(String error) {
    return 'Lettura non riuscita: $error';
  }

  @override
  String get entryReceiptSourceCamera => 'Scatta una foto';

  @override
  String get entryReceiptSourceLibrary => 'Scegli dalle foto';

  @override
  String get entryDeleteConfirmTitle => 'Eliminare questa voce?';

  @override
  String get entryDeleteConfirmContent => 'Questa transazione verrà eliminata.';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get batchPanelTitle => 'Dettaglio in blocco';

  @override
  String get batchModeSelectAssign => 'Seleziona e assegna';

  @override
  String get batchModePaint => 'Colora';

  @override
  String get batchCancelButton => 'Annulla';

  @override
  String get batchThisReceiptLabel => 'Questo scontrino:';

  @override
  String get batchTaxIncluded => 'IVA incl.';

  @override
  String get batchTaxExclusive8 => 'IVA escl. 8%';

  @override
  String get batchTaxExclusive10 => 'IVA escl. 10%';

  @override
  String get batchPaintHintNoCategory =>
      'Scegli una categoria sotto, poi tocca le righe per colorarle';

  @override
  String batchPaintHintActive(String name) {
    return 'Coloro \"$name\" — tocca le righe (tocca di nuovo per annullare)';
  }

  @override
  String get batchSelectHint =>
      'Seleziona le righe → tocca una categoria sotto per assegnarla';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count selezionati, $amount → tocca una categoria sotto';
  }

  @override
  String get batchNoAssignmentsYet => '(Ancora nessuna assegnazione)';

  @override
  String get batchCategoryUnknown => 'Sconosciuta';

  @override
  String get batchDiffPickCategory =>
      'Rimanente (differenza) — tocca per scegliere una categoria';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (differenza)';
  }

  @override
  String get batchReceiptFallbackLabel => 'Scontrino';

  @override
  String get batchTotalLabel => 'Totale';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess in eccesso';
  }

  @override
  String get restorePageTitle => 'Ripristina';

  @override
  String get restoreEmptyMessage =>
      'Nessun backup disponibile per il ripristino';

  @override
  String get restoreConfirmTitle => 'Ripristinare questo backup?';

  @override
  String get restoreConfirmMessage =>
      'Tutti i dati attuali verranno sostituiti. Lo stato precedente viene salvato automaticamente e potrà essere recuperato in seguito.';

  @override
  String get restoreButton => 'Ripristina';

  @override
  String get restoreEmptyBackupTitle =>
      'Questo backup non contiene transazioni';

  @override
  String get restoreEmptyBackupMessage =>
      'Il ripristino eliminerà tutte le transazioni esistenti. Ripristinare comunque?';

  @override
  String get restoreEmptyBackupConfirmButton => 'Ripristina comunque';

  @override
  String restoreFailedMessage(String error) {
    return 'Ripristino non riuscito: $error';
  }

  @override
  String get restoreSuccessMessage => 'Ripristino completato';

  @override
  String get restorePassphraseTitle => 'Inserisci la passphrase';

  @override
  String get commonAdd => 'Aggiungi';

  @override
  String get categoryRenameAction => 'Rinomina';

  @override
  String get categorySubcategoryRenameTitle => 'Rinomina sottocategoria';

  @override
  String get categoryNameFieldLabel => 'Nome';

  @override
  String get categorySubcategoryAddTitle => 'Aggiungi sottocategoria';

  @override
  String get categoryIconFieldLabel => 'Icona (emoji, facoltativa)';

  @override
  String get categoryEditExistingTitle => 'Modifica elementi esistenti';

  @override
  String get categoryIconOrderTitle => 'Ordine di visualizzazione delle icone';

  @override
  String get categoryIconOrderHint =>
      'Trascina per riordinare (visualizzate nel tuo ordine)';

  @override
  String get categoryManageTitle => 'Gestisci categorie';

  @override
  String get categoryTabExpense => 'Spese';

  @override
  String get categoryTabIncome => 'Entrate';

  @override
  String get categorySubAddTitle => 'Aggiungi sottocategoria';

  @override
  String get categoryAddTitle => 'Aggiungi categoria';

  @override
  String get categorySubRenameTitle => 'Rinomina sottocategoria';

  @override
  String get categoryRenameTitle => 'Rinomina categoria';

  @override
  String get categorySubAddTooltip => 'Aggiungi sottocategoria';

  @override
  String get categoryArchiveBlockedSnackbar =>
      'Archivia prima le sottocategorie';

  @override
  String get categoryArchivedSectionTitle => 'Archiviate';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (archiviata)';
  }

  @override
  String get splitStoreNameHint => 'Nome del negozio';

  @override
  String get splitCancel => 'Annulla';

  @override
  String get splitBreakdownLabel => 'Dettaglio';

  @override
  String get splitTaxLabel => 'IVA';

  @override
  String get splitTaxIncludedToggle => 'IVA incl.';

  @override
  String get splitTaxExcludedToggle => 'IVA escl.';

  @override
  String get splitTaxIndividual => 'Per voce';

  @override
  String get splitMemoHint => 'Nota';

  @override
  String get splitAddCategoryChip => '＋ Categoria';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'IVA incl. $amount';
  }

  @override
  String get splitAddCategoryLabel => 'Aggiungi categoria';

  @override
  String get splitOverLabel => 'In eccesso';

  @override
  String get splitRemainingLabel => 'Rimanente';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get summaryEmptyTitle => 'Ancora nessun dato per questo mese';

  @override
  String get summaryEmptyHint =>
      'Tocca ＋ nel calendario per aggiungere una voce';

  @override
  String get summaryIncomeLabel => 'Entrate';

  @override
  String get summaryExpenseLabel => 'Spese';

  @override
  String get summaryNetLabel => 'Saldo';

  @override
  String get summaryCategoryBreakdownTitle => 'Spese per categoria';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (archiviata)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ Dettagli';

  @override
  String get summaryBreakdownExpand => '▼ Dettagli';

  @override
  String get summaryNoBreakdownLabel => '(Nessun dettaglio)';

  @override
  String get entryNoImage => 'Nessuna immagine';

  @override
  String get entryAmountReadFailed =>
      'Impossibile leggere l\'importo. Inseriscilo manualmente.';

  @override
  String get entryStoreDirectInput => 'Inserisci manualmente';

  @override
  String get entryStoreNameDialogTitle => 'Inserisci il nome del negozio';

  @override
  String get commonOk => 'OK';

  @override
  String get calendarWeekdaySun => 'Dom';

  @override
  String get calendarWeekdayMon => 'Lun';

  @override
  String get calendarWeekdayTue => 'Mar';

  @override
  String get calendarWeekdayWed => 'Mer';

  @override
  String get calendarWeekdayThu => 'Gio';

  @override
  String get calendarWeekdayFri => 'Ven';

  @override
  String get calendarWeekdaySat => 'Sab';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return 'Spese $expense  Entrate $income  Saldo $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return 'Nessuna voce il $day/$month';
  }

  @override
  String get calendarDayEmptyHintFirst =>
      'Aggiungi la tua prima voce con \"Inserisci importo\" in basso a destra';

  @override
  String get calendarDayEmptyHint =>
      'Aggiungi una voce con \"Inserisci importo\" in basso a destra';

  @override
  String get calendarReceiptFallbackLabel => 'Scontrino';

  @override
  String get calendarCategoryUnknown => 'Sconosciuta';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (archiviata)';
  }

  @override
  String get calendarDeleteSnackbar => 'Eliminato';

  @override
  String get calendarUndoAction => 'Annulla';

  @override
  String get splitTaxDialogTitle => 'Aliquota IVA per voce';

  @override
  String get commonDone => 'Fatto';

  @override
  String get splitRemainderLabel => 'Rimanente';

  @override
  String splitItemNumberLabel(int index) {
    return 'Voce $index';
  }

  @override
  String get splitTaxIncludedLabel => 'IVA incl.';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount (auto)';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → IVA incl. $net';
  }

  @override
  String get onboardingTitle => 'I tuoi dati';

  @override
  String get onboardingBody =>
      '・I tuoi dati vengono salvati solo su questo dispositivo. Nulla viene inviato all\'esterno.\n・L\'app esegue backup automatici sul dispositivo, ma salva un\'esportazione dalle impostazioni in caso di cambio o smarrimento del dispositivo.';

  @override
  String get onboardingStartButton => 'Inizia';

  @override
  String get homeFabEntryLabel => 'Inserisci importo';

  @override
  String get homeNavCalendar => 'Calendario';

  @override
  String get homeNavSummary => 'Riepilogo';

  @override
  String get homeNavSettings => 'Impostazioni';

  @override
  String get settingsColorPickerResetDefault => 'Ripristina predefinito';

  @override
  String get settingsColorPickerConfirm => 'Conferma';

  @override
  String get categoryManualOrderSnackbar =>
      'Impostato il tuo ordine personalizzato (puoi ripristinarlo nelle impostazioni).';

  @override
  String get entryHintEnterAmount => 'Inserisci un importo';

  @override
  String get entryHintAssignItemCategory => 'Assegna una categoria a ogni voce';

  @override
  String get entryHintAssignExceedsTotal =>
      'Le assegnazioni superano il totale';

  @override
  String get entryHintPickDiffCategory =>
      'Scegli una categoria per la differenza';

  @override
  String get entryHintSplitExceedsTotal => 'Il dettaglio supera il totale';

  @override
  String get entryHintPickCategory => 'Scegli una categoria';

  @override
  String get entryHintEnterAmountAndCategory =>
      'Inserisci un importo e una categoria';

  @override
  String get entryHintEnterRemainingAmount =>
      'Inserisci anche l\'importo rimanente';

  @override
  String get settingsBackupNever => 'Nessun backup';

  @override
  String get settingsBackupToday => 'Ultimo backup: oggi';

  @override
  String settingsBackupDaysAgo(int days) {
    return 'Ultimo backup: $days giorni fa';
  }

  @override
  String get recurringPageTitle => 'Movimenti fissi mensili';

  @override
  String get settingsRecurringSubtitle =>
      'Registra automaticamente ogni mese affitto, stipendio ecc.';

  @override
  String get recurringEmptyMessage =>
      'Ancora nessun elemento.\nTocca + per automatizzare le registrazioni mensili come affitto o stipendio.';

  @override
  String get recurringAddTitle => 'Aggiungi movimento fisso';

  @override
  String get recurringEditTitle => 'Modifica movimento fisso';

  @override
  String get recurringAmountLabel => 'Importo';

  @override
  String get recurringDayLabel => 'Giorno del mese';

  @override
  String recurringEveryMonthDay(int day) {
    return 'Il giorno $day di ogni mese';
  }

  @override
  String get recurringDayClampNote =>
      'Nei mesi più corti viene registrato l\'ultimo giorno (es. il 31 → 28 febbraio).';

  @override
  String get recurringStartMonthLabel => 'Inizio';

  @override
  String get recurringStartThisMonth => 'Questo mese';

  @override
  String get recurringStartNextMonth => 'Il mese prossimo';

  @override
  String get recurringActiveTitle => 'Attivo';

  @override
  String get recurringActiveSubtitle =>
      'Disattiva per sospendere la registrazione automatica';

  @override
  String get recurringPausedLabel => 'In pausa';

  @override
  String get recurringDeleteConfirmTitle => 'Eliminare?';

  @override
  String get recurringDeleteConfirmContent =>
      'Questo movimento fisso verrà eliminato. Le registrazioni già create saranno conservate.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return 'Scegli una categoria per la voce $n';
  }

  @override
  String get entryHintPickCategoryRemainder =>
      'Scegli una categoria per la riga “Rimanente”';

  @override
  String get splitMemoDialogTitle => 'Inserisci una nota';

  @override
  String choreNotificationBody(int days) {
    return 'Sono passati $days giorni dall\'ultima volta';
  }

  @override
  String get homeNavMonthly => 'Mensile';

  @override
  String get hubUpcomingSection => 'In arrivo questo mese';

  @override
  String get hubUpcomingEmpty => 'Niente in programma per il resto del mese';

  @override
  String get hubRulesSection => 'Spese fisse ed entrate';

  @override
  String get hubRulesEmpty =>
      'Con + automatizzi le registrazioni mensili come affitto o stipendio';

  @override
  String get hubChoresSection => 'Faccende ricorrenti';

  @override
  String get hubChoresEmpty =>
      'Con + aggiungi faccende come cambiare lo spazzolino';

  @override
  String get hubChoreTimelineLabel => 'Faccenda';

  @override
  String get ghostBadgeLabel => 'Previsto';

  @override
  String get forecastLabelMonthEnd => 'Previsione (fine mese)';

  @override
  String forecastLabelAtDate(String date) {
    return 'Previsione (al $date)';
  }

  @override
  String choreIntervalEvery(int days) {
    return 'Ogni $days giorni';
  }

  @override
  String choreOverdueDays(int days) {
    return '$days gg di ritardo';
  }

  @override
  String get choreDueToday => 'Oggi';

  @override
  String choreDaysLeft(int days) {
    return 'tra $days giorni';
  }

  @override
  String choreNextDate(String date) {
    return 'Prossima: $date';
  }

  @override
  String get choreDoneButton => 'Fatto';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ Registrato. Prossima: $date';
  }

  @override
  String get choreDupConfirmTitle => 'Già registrato';

  @override
  String choreDupConfirmBody(String name) {
    return '\"$name\" ha già una registrazione in questo giorno. Aggiungerne un\'altra?';
  }

  @override
  String get choreDupConfirmAdd => 'Aggiungi';

  @override
  String get choreFormNewTitle => 'Nuova faccenda';

  @override
  String get choreFormEditTitle => 'Modifica faccenda';

  @override
  String get choreFormNameLabel => 'Nome';

  @override
  String get choreFormIntervalLabel => 'Intervallo in giorni (1–999)';

  @override
  String get choreFormEmojiLabel => 'Emoji (📌 se vuoto)';

  @override
  String get choreFormArchiveButton => 'Archivia';

  @override
  String get choreFormDeleteButton => 'Elimina questa faccenda';

  @override
  String choreDeleteConfirmBody(int count) {
    return 'Verranno eliminate anche $count registrazioni dello storico';
  }

  @override
  String get choreHistoryTitle => 'Storico';

  @override
  String get choreHistoryEmpty => 'Nessuna registrazione';

  @override
  String get choreRecordEditTitle => 'Modifica registrazione';

  @override
  String get choreRecordDeleteConfirm => 'Eliminare questa registrazione?';

  @override
  String get choreMemoLabel => 'Nota';

  @override
  String get settingsChoresTitle => 'Faccende ricorrenti';

  @override
  String get settingsChoresSubtitle =>
      'Ora del promemoria e faccende archiviate';

  @override
  String get choreNotifyTimeLabel => 'Ora del promemoria';

  @override
  String get chorePermissionChecking => 'Controllo del permesso notifiche…';

  @override
  String get chorePermissionNotAsked =>
      'Il permesso verrà chiesto dopo la prima registrazione';

  @override
  String get chorePermissionGranted => 'Le notifiche sono attive';

  @override
  String get chorePermissionDenied => 'Le notifiche non sono consentite';

  @override
  String get chorePermissionOpenSettings => 'Apri Impostazioni';

  @override
  String get choreArchivedSection => 'Faccende archiviate';

  @override
  String get choreArchivedEmpty => 'Nessuna faccenda archiviata';

  @override
  String get choreUnarchiveButton => 'Ripristina';

  @override
  String get forecastAnchorSheetTitle => 'Data di riferimento della previsione';

  @override
  String get forecastAnchorSheetNote =>
      'Gli importi previsti fino alla data di riferimento inclusa si sommano al saldo effettivo.';

  @override
  String get forecastAnchorMonthEnd => 'Fine mese';

  @override
  String get calendarLegendChoreDone => 'fatto';

  @override
  String get calendarLegendChoreDue => 'faccenda in scadenza';

  @override
  String get calendarLegendChoreOverdue => 'in ritardo';

  @override
  String get calendarLegendGhost => 'spesa fissa prevista';

  @override
  String get entryRecurringExpense => 'Spesa mensile';

  @override
  String get entryRecurringIncome => 'Entrata mensile';

  @override
  String get entrySaveWithRuleExpense => 'Salva (+ mensile)';

  @override
  String get entrySaveWithRuleIncome => 'Salva (+ mensile)';

  @override
  String get entryRecurringNotePrefix => 'Registrata automaticamente il giorno';

  @override
  String get entryRecurringNoteSuffix => 'di ogni mese';
}
