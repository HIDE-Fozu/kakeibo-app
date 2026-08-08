// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Budget';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get languageSystemDefault => 'Langue du système';

  @override
  String get currencyLockedSubtitle =>
      'Verrouillé — des transactions existent déjà';

  @override
  String get currencyLockedTitle => 'Impossible de changer la devise';

  @override
  String get currencyLockedBody =>
      'Pour préserver la cohérence des montants passés, la devise ne peut plus être modifiée une fois des transactions enregistrées.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return 'Sauvegarde auto : $generations versions (sur l\'appareil)';
  }

  @override
  String get settingsBackupNowTitle => 'Sauvegarder maintenant';

  @override
  String get settingsExportJsonTitle => 'Exporter en JSON';

  @override
  String get settingsExportJsonSubtitle =>
      'Chiffrement par phrase secrète en option (utilisable pour la restauration)';

  @override
  String get settingsExportCsvTitle => 'Exporter en CSV';

  @override
  String get settingsExportCsvSubtitle =>
      'Pour consultation uniquement (ne permet pas la restauration)';

  @override
  String get settingsRestoreTitle => 'Restaurer';

  @override
  String get settingsRestoreSubtitle => 'Remplace toutes les données';

  @override
  String get settingsTestUploadTitle =>
      'Participer aux tests (envoi automatique)';

  @override
  String get settingsTestUploadSubtitle =>
      'Pour améliorer la lecture des reçus, les enregistrements de scan et les photos sont envoyés automatiquement au développeur (période de test uniquement). Vos saisies du budget elles-mêmes ne sont jamais envoyées.';

  @override
  String get settingsShareTestDataTitle => 'Envoyer les données de test';

  @override
  String get settingsShareTestDataSubtitle =>
      'Partage manuel groupé (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle =>
      'Importer les données collectées (développeur)';

  @override
  String get settingsFetchCollectedSubtitle =>
      'Importer les données de tous les appareils vers exports/ocr-collected de cet appareil';

  @override
  String get settingsRetainImagesTitle =>
      'Conserver les images des reçus sur l\'appareil';

  @override
  String get settingsRetainImagesSubtitle =>
      'Supprimées après l\'enregistrement par défaut';

  @override
  String get settingsCategoryManageTitle => 'Gérer les catégories';

  @override
  String get settingsCategoryOrderTitle =>
      'Classer les catégories dans mon ordre';

  @override
  String get settingsCategoryOrderSubtitle =>
      'Désactivé = ordre d\'utilisation récente / Activé = ordre fixe (appui long sur une tuile de l\'écran de saisie pour réorganiser)';

  @override
  String get settingsPageColorTitle => 'Couleur de la page (arrière-plan)';

  @override
  String get settingsAccentColorTitle => 'Couleur d\'accentuation';

  @override
  String get settingsAccentColorSubtitle =>
      'Couleur des boutons et des sélections';

  @override
  String get settingsDataPolicyTitle => 'À propos du traitement des données';

  @override
  String get settingsDataPolicyBody =>
      '• Vos données sont stockées uniquement sur cet appareil. Elles ne sont jamais envoyées à l\'extérieur automatiquement.\n• Des sauvegardes automatiques sont créées sur l\'appareil, mais pensez aussi à enregistrer un export depuis les réglages en cas de changement ou de panne d\'appareil.';

  @override
  String get settingsPassphraseFieldLabel => 'Phrase secrète (si chiffrement)';

  @override
  String get settingsSaveAsIs => 'Enregistrer tel quel';

  @override
  String get settingsSaveEncrypted => 'Chiffrer et enregistrer';

  @override
  String get settingsBackupSuccessSnackbar => 'Sauvegarde créée';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'Échec de la sauvegarde : $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return 'Enregistré : $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return '$count éléments importés (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar =>
      'Aucun enregistrement de scan pour le moment';

  @override
  String settingsShareTestDataSubject(int count) {
    return 'Données de test du budget ($count éléments)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get entryTitleCreate => 'Saisie';

  @override
  String get entryTitleReceiptConfirm => 'Vérifier le reçu';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get entryTypeExpense => 'Dépense';

  @override
  String get entryTypeIncome => 'Revenu';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$day/$month/$year';
  }

  @override
  String get entryStartSplitButton => 'Choisir plusieurs catégories';

  @override
  String get entryCategoryHeading => 'Catégorie';

  @override
  String get entryDetailMemoLabel => 'Notes';

  @override
  String get entryStoreNameLabel => 'Nom du magasin';

  @override
  String get entrySaveContinueButton => 'Enregistrer et continuer';

  @override
  String get entrySavedSnackbar => 'Enregistré';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      'La capture de reçu n\'est pas disponible sur cet appareil';

  @override
  String entryOcrFailedSnackbar(String error) {
    return 'Échec de la lecture : $error';
  }

  @override
  String get entryReceiptSourceCamera => 'Prendre une photo';

  @override
  String get entryReceiptSourceLibrary => 'Choisir dans les photos';

  @override
  String get entryDeleteConfirmTitle => 'Supprimer cette entrée ?';

  @override
  String get entryDeleteConfirmContent => 'Cette transaction sera supprimée.';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get batchPanelTitle => 'Détail groupé';

  @override
  String get batchModeSelectAssign => 'Sélectionner et affecter';

  @override
  String get batchModePaint => 'Peindre';

  @override
  String get batchCancelButton => 'Annuler';

  @override
  String get batchThisReceiptLabel => 'Ce reçu :';

  @override
  String get batchTaxIncluded => 'TTC';

  @override
  String get batchTaxExclusive8 => 'HT 8 %';

  @override
  String get batchTaxExclusive10 => 'HT 10 %';

  @override
  String get batchPaintHintNoCategory =>
      'Choisissez une catégorie ci-dessous, puis touchez les lignes pour les peindre';

  @override
  String batchPaintHintActive(String name) {
    return 'Peinture de « $name » — touchez les lignes (retouchez pour annuler)';
  }

  @override
  String get batchSelectHint =>
      'Sélectionnez des lignes → touchez une catégorie ci-dessous pour l\'affecter';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count sélectionnées, $amount → touchez une catégorie ci-dessous';
  }

  @override
  String get batchNoAssignmentsYet => '(Aucune affectation pour le moment)';

  @override
  String get batchCategoryUnknown => 'Inconnu';

  @override
  String get batchDiffPickCategory =>
      'Reste (différence) — touchez pour choisir une catégorie';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (différence)';
  }

  @override
  String get batchReceiptFallbackLabel => 'Reçu';

  @override
  String get batchTotalLabel => 'Total';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess en trop';
  }

  @override
  String get restorePageTitle => 'Restaurer';

  @override
  String get restoreEmptyMessage => 'Aucune sauvegarde à restaurer';

  @override
  String get restoreConfirmTitle => 'Restaurer cette sauvegarde ?';

  @override
  String get restoreConfirmMessage =>
      'Toutes les données actuelles seront remplacées. L\'état précédent est sauvegardé automatiquement et pourra être récupéré plus tard.';

  @override
  String get restoreButton => 'Restaurer';

  @override
  String get restoreEmptyBackupTitle =>
      'Cette sauvegarde ne contient aucune transaction';

  @override
  String get restoreEmptyBackupMessage =>
      'La restauration supprimera toutes vos transactions. Restaurer quand même ?';

  @override
  String get restoreEmptyBackupConfirmButton => 'Restaurer quand même';

  @override
  String restoreFailedMessage(String error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get restoreSuccessMessage => 'Restauration terminée';

  @override
  String get restorePassphraseTitle => 'Saisir la phrase secrète';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get categoryRenameAction => 'Renommer';

  @override
  String get categorySubcategoryRenameTitle => 'Renommer la sous-catégorie';

  @override
  String get categoryNameFieldLabel => 'Nom';

  @override
  String get categorySubcategoryAddTitle => 'Ajouter une sous-catégorie';

  @override
  String get categoryIconFieldLabel => 'Icône (emoji, facultatif)';

  @override
  String get categoryEditExistingTitle => 'Modifier les éléments existants';

  @override
  String get categoryIconOrderTitle => 'Ordre d\'affichage des icônes';

  @override
  String get categoryIconOrderHint =>
      'Glissez pour réorganiser (affiché dans votre ordre)';

  @override
  String get categoryManageTitle => 'Gérer les catégories';

  @override
  String get categoryTabExpense => 'Dépenses';

  @override
  String get categoryTabIncome => 'Revenus';

  @override
  String get categorySubAddTitle => 'Ajouter une sous-catégorie';

  @override
  String get categoryAddTitle => 'Ajouter une catégorie';

  @override
  String get categorySubRenameTitle => 'Renommer la sous-catégorie';

  @override
  String get categoryRenameTitle => 'Renommer la catégorie';

  @override
  String get categorySubAddTooltip => 'Ajouter une sous-catégorie';

  @override
  String get categoryArchiveBlockedSnackbar =>
      'Archivez d\'abord ses sous-catégories';

  @override
  String get categoryArchivedSectionTitle => 'Archivées';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (archivée)';
  }

  @override
  String get splitStoreNameHint => 'Nom du magasin';

  @override
  String get splitCancel => 'Annuler';

  @override
  String get splitBreakdownLabel => 'Détail';

  @override
  String get splitTaxLabel => 'TVA';

  @override
  String get splitTaxIncludedToggle => 'TTC';

  @override
  String get splitTaxExcludedToggle => 'HT';

  @override
  String get splitTaxIndividual => 'Individuel';

  @override
  String get splitMemoHint => 'Note';

  @override
  String get splitAddCategoryChip => '＋ Catégorie';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'TTC $amount';
  }

  @override
  String get splitAddCategoryLabel => 'Ajouter une catégorie';

  @override
  String get splitOverLabel => 'Dépassement';

  @override
  String get splitRemainingLabel => 'Reste';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get summaryEmptyTitle => 'Aucune donnée pour ce mois';

  @override
  String get summaryEmptyHint =>
      'Touchez ＋ sur le calendrier pour ajouter une entrée';

  @override
  String get summaryIncomeLabel => 'Revenus';

  @override
  String get summaryExpenseLabel => 'Dépenses';

  @override
  String get summaryNetLabel => 'Solde';

  @override
  String get summaryCategoryBreakdownTitle => 'Dépenses par catégorie';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (archivée)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ Détail';

  @override
  String get summaryBreakdownExpand => '▼ Détail';

  @override
  String get summaryNoBreakdownLabel => '(Aucun détail)';

  @override
  String get entryNoImage => 'Aucune image';

  @override
  String get entryAmountReadFailed =>
      'Impossible de lire le montant. Veuillez le saisir manuellement.';

  @override
  String get entryStoreDirectInput => 'Saisie manuelle';

  @override
  String get entryStoreNameDialogTitle => 'Saisir le nom du magasin';

  @override
  String get commonOk => 'OK';

  @override
  String get calendarWeekdaySun => 'Dim';

  @override
  String get calendarWeekdayMon => 'Lun';

  @override
  String get calendarWeekdayTue => 'Mar';

  @override
  String get calendarWeekdayWed => 'Mer';

  @override
  String get calendarWeekdayThu => 'Jeu';

  @override
  String get calendarWeekdayFri => 'Ven';

  @override
  String get calendarWeekdaySat => 'Sam';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return 'Dépenses $expense   Revenus $income   Solde $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return 'Aucune entrée le $day/$month';
  }

  @override
  String get calendarDayEmptyHintFirst =>
      'Ajoutez votre première entrée via « Saisir le montant » en bas à droite';

  @override
  String get calendarDayEmptyHint =>
      'Ajoutez une entrée via « Saisir le montant » en bas à droite';

  @override
  String get calendarReceiptFallbackLabel => 'Reçu';

  @override
  String get calendarCategoryUnknown => 'Inconnu';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (archivée)';
  }

  @override
  String get calendarDeleteSnackbar => 'Supprimé';

  @override
  String get calendarUndoAction => 'Annuler';

  @override
  String get splitTaxDialogTitle => 'Taux de TVA par article';

  @override
  String get commonDone => 'Terminé';

  @override
  String get splitRemainderLabel => 'Reste';

  @override
  String splitItemNumberLabel(int index) {
    return 'Article $index';
  }

  @override
  String get splitTaxIncludedLabel => 'TTC';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount (auto)';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → TTC $net';
  }

  @override
  String get onboardingTitle => 'À propos de vos données';

  @override
  String get onboardingBody =>
      '• Vos données sont stockées uniquement sur cet appareil. Rien n\'est envoyé à l\'extérieur.\n• L\'application sauvegarde automatiquement sur cet appareil, mais pensez à enregistrer un export depuis les réglages en cas de changement ou de perte d\'appareil.';

  @override
  String get onboardingStartButton => 'Commencer';

  @override
  String get homeFabEntryLabel => 'Saisir le montant';

  @override
  String get homeNavCalendar => 'Calendrier';

  @override
  String get homeNavSummary => 'Résumé';

  @override
  String get homeNavSettings => 'Réglages';

  @override
  String get settingsColorPickerResetDefault => 'Réinitialiser';

  @override
  String get settingsColorPickerConfirm => 'Confirmer';

  @override
  String get categoryManualOrderSnackbar =>
      'Passé à votre ordre personnalisé (modifiable dans les réglages)';

  @override
  String get entryHintEnterAmount => 'Saisissez un montant';

  @override
  String get entryHintAssignItemCategory =>
      'Attribuez une catégorie à chaque article';

  @override
  String get entryHintAssignExceedsTotal =>
      'Les affectations dépassent le total';

  @override
  String get entryHintPickDiffCategory =>
      'Choisissez une catégorie pour la différence';

  @override
  String get entryHintSplitExceedsTotal => 'Le détail dépasse le total';

  @override
  String get entryHintPickCategory => 'Choisissez une catégorie';

  @override
  String get entryHintEnterAmountAndCategory =>
      'Saisissez un montant et une catégorie';

  @override
  String get entryHintEnterRemainingAmount =>
      'Saisissez aussi le montant restant';

  @override
  String get settingsBackupNever => 'Aucune sauvegarde';

  @override
  String get settingsBackupToday => 'Dernière sauvegarde : aujourd\'hui';

  @override
  String settingsBackupDaysAgo(int days) {
    return 'Dernière sauvegarde : il y a $days jours';
  }

  @override
  String get recurringPageTitle => 'Opérations fixes mensuelles';

  @override
  String get settingsRecurringSubtitle =>
      'Enregistre chaque mois le loyer, le salaire, etc. automatiquement';

  @override
  String get recurringEmptyMessage =>
      'Rien pour l\'instant.\nTouchez + pour automatiser les écritures mensuelles comme le loyer ou le salaire.';

  @override
  String get recurringAddTitle => 'Ajouter une opération fixe';

  @override
  String get recurringEditTitle => 'Modifier l\'opération fixe';

  @override
  String get recurringAmountLabel => 'Montant';

  @override
  String get recurringDayLabel => 'Jour du mois';

  @override
  String recurringEveryMonthDay(int day) {
    return 'Le $day de chaque mois';
  }

  @override
  String get recurringDayClampNote =>
      'Les mois plus courts, l\'écriture est datée du dernier jour (ex. : le 31 → 28 février).';

  @override
  String get recurringStartMonthLabel => 'Début';

  @override
  String get recurringStartThisMonth => 'Ce mois-ci';

  @override
  String get recurringStartNextMonth => 'Le mois prochain';

  @override
  String get recurringActiveTitle => 'Actif';

  @override
  String get recurringActiveSubtitle =>
      'Désactivez pour suspendre l\'enregistrement automatique';

  @override
  String get recurringPausedLabel => 'En pause';

  @override
  String get recurringDeleteConfirmTitle => 'Supprimer ?';

  @override
  String get recurringDeleteConfirmContent =>
      'Cette opération fixe sera supprimée. Les écritures déjà créées seront conservées.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return 'Choisissez une catégorie pour l\'article $n';
  }

  @override
  String get entryHintPickCategoryRemainder =>
      'Choisissez une catégorie pour la ligne « Reste »';

  @override
  String get splitMemoDialogTitle => 'Saisir une note';

  @override
  String choreNotificationBody(int days) {
    return '$days jours se sont écoulés depuis la dernière fois';
  }

  @override
  String get homeNavMonthly => 'Mensuel';

  @override
  String get hubUpcomingSection => 'À venir ce mois-ci';

  @override
  String get hubUpcomingEmpty => 'Rien de prévu pour le reste du mois';

  @override
  String get hubRulesSection => 'Charges fixes et revenus';

  @override
  String get hubRulesEmpty =>
      'Avec +, automatisez les écritures mensuelles comme le loyer ou le salaire';

  @override
  String get hubChoresSection => 'Tâches récurrentes';

  @override
  String get hubChoresEmpty =>
      'Avec +, ajoutez des tâches comme changer de brosse à dents';

  @override
  String get hubChoreTimelineLabel => 'Tâche';

  @override
  String get ghostBadgeLabel => 'Prévu';

  @override
  String get forecastLabelMonthEnd => 'Prévision (fin de mois)';

  @override
  String forecastLabelAtDate(String date) {
    return 'Prévision (au $date)';
  }

  @override
  String choreIntervalEvery(int days) {
    return 'Tous les $days jours';
  }

  @override
  String choreOverdueDays(int days) {
    return '$days j de retard';
  }

  @override
  String get choreDueToday => 'Aujourd\'hui';

  @override
  String choreDaysLeft(int days) {
    return 'dans $days jours';
  }

  @override
  String choreNextDate(String date) {
    return 'Prochaine : $date';
  }

  @override
  String get choreDoneButton => 'Fait';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ Enregistré. Prochaine : $date';
  }

  @override
  String get choreDupConfirmTitle => 'Déjà enregistré';

  @override
  String choreDupConfirmBody(String name) {
    return '« $name » a déjà un enregistrement ce jour-là. En ajouter un autre ?';
  }

  @override
  String get choreDupConfirmAdd => 'Ajouter';

  @override
  String get choreFormNewTitle => 'Nouvelle tâche';

  @override
  String get choreFormEditTitle => 'Modifier la tâche';

  @override
  String get choreFormNameLabel => 'Nom';

  @override
  String get choreFormIntervalLabel => 'Intervalle en jours (1–999)';

  @override
  String get choreFormEmojiLabel => 'Émoji (📌 si vide)';

  @override
  String get choreFormArchiveButton => 'Archiver';

  @override
  String get choreFormDeleteButton => 'Supprimer cette tâche';

  @override
  String choreDeleteConfirmBody(int count) {
    return '$count enregistrements de l\'historique seront aussi supprimés';
  }

  @override
  String get choreHistoryTitle => 'Historique';

  @override
  String get choreHistoryEmpty => 'Aucun enregistrement pour l\'instant';

  @override
  String get choreRecordEditTitle => 'Modifier l\'enregistrement';

  @override
  String get choreRecordDeleteConfirm => 'Supprimer cet enregistrement ?';

  @override
  String get choreMemoLabel => 'Note';

  @override
  String get settingsChoresTitle => 'Tâches récurrentes';

  @override
  String get settingsChoresSubtitle => 'Heure de rappel et tâches archivées';

  @override
  String get choreNotifyTimeLabel => 'Heure du rappel';

  @override
  String get chorePermissionChecking =>
      'Vérification de l\'autorisation de notification…';

  @override
  String get chorePermissionNotAsked =>
      'L\'autorisation sera demandée après le premier enregistrement';

  @override
  String get chorePermissionGranted => 'Les notifications sont activées';

  @override
  String get chorePermissionDenied =>
      'Les notifications ne sont pas autorisées';

  @override
  String get chorePermissionOpenSettings => 'Ouvrir les réglages';

  @override
  String get choreArchivedSection => 'Tâches archivées';

  @override
  String get choreArchivedEmpty => 'Aucune tâche archivée';

  @override
  String get choreUnarchiveButton => 'Restaurer';

  @override
  String get forecastAnchorSheetTitle => 'Date de référence de la prévision';

  @override
  String get forecastAnchorSheetNote =>
      'Les montants prévus jusqu\'à la date de référence incluse s\'ajoutent au solde réel.';

  @override
  String get forecastAnchorMonthEnd => 'Fin de mois';

  @override
  String get calendarLegendChoreDone => 'fait';

  @override
  String get calendarLegendChoreDue => 'tâche à faire';

  @override
  String get calendarLegendChoreOverdue => 'en retard';

  @override
  String get calendarLegendGhost => 'charge fixe prévue';

  @override
  String get entryRecurringExpense => 'Dépense mensuelle';

  @override
  String get entryRecurringIncome => 'Revenu mensuel';

  @override
  String entryRecurringNote(int day) {
    return 'Sera enregistré automatiquement le $day de chaque mois (cette saisie est la première)';
  }

  @override
  String get entrySaveWithRuleExpense => 'Enregistrer (+ mensuel)';

  @override
  String get entrySaveWithRuleIncome => 'Enregistrer (+ mensuel)';

  @override
  String get entryRecurringChangeDay => 'Changer le jour';
}
