// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Kakeibo';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsCurrency => 'Moeda';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get currencyLockedSubtitle => 'Bloqueado — já existem transações';

  @override
  String get currencyLockedTitle => 'Não é possível alterar a moeda';

  @override
  String get currencyLockedBody =>
      'Para manter os valores anteriores consistentes, a moeda não pode ser alterada depois de registrar transações.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return 'Backup automático: $generations versões (no dispositivo)';
  }

  @override
  String get settingsBackupNowTitle => 'Fazer backup agora';

  @override
  String get settingsExportJsonTitle => 'Exportar JSON';

  @override
  String get settingsExportJsonSubtitle =>
      'Criptografe com uma senha (opcional; serve para restaurar)';

  @override
  String get settingsExportCsvTitle => 'Exportar CSV';

  @override
  String get settingsExportCsvSubtitle =>
      'Apenas para visualização (não serve para restaurar)';

  @override
  String get settingsRestoreTitle => 'Restaurar';

  @override
  String get settingsRestoreSubtitle => 'Substitui todos os dados';

  @override
  String get settingsTestUploadTitle =>
      'Colaborar com o teste (envio automático)';

  @override
  String get settingsTestUploadSubtitle =>
      'Para melhorar a leitura de recibos, os registros e fotos das leituras são enviados automaticamente ao desenvolvedor (apenas durante o período de testes). As entradas do seu orçamento nunca são enviadas.';

  @override
  String get settingsShareTestDataTitle => 'Enviar dados de teste';

  @override
  String get settingsShareTestDataSubtitle =>
      'Compartilhar tudo manualmente (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle =>
      'Importar dados coletados (só desenvolvedor)';

  @override
  String get settingsFetchCollectedSubtitle =>
      'Importar os dados de todos os dispositivos para exports/ocr-collected deste aparelho';

  @override
  String get settingsRetainImagesTitle =>
      'Manter imagens dos recibos no dispositivo';

  @override
  String get settingsRetainImagesSubtitle =>
      'Por padrão, são descartadas após salvar';

  @override
  String get settingsCategoryManageTitle => 'Gerenciar categorias';

  @override
  String get settingsCategoryOrderTitle => 'Ordenar categorias do meu jeito';

  @override
  String get settingsCategoryOrderSubtitle =>
      'Desligado = mais usadas recentemente / Ligado = ordem fixa (na tela de entrada, mantenha um bloco pressionado → reordenar)';

  @override
  String get settingsPageColorTitle => 'Cor da página (fundo)';

  @override
  String get settingsAccentColorTitle => 'Cor de destaque';

  @override
  String get settingsAccentColorSubtitle => 'Cor de botões e seleções';

  @override
  String get settingsDataPolicyTitle => 'Sobre o tratamento dos dados';

  @override
  String get settingsDataPolicyBody =>
      '• Seus registros ficam salvos apenas neste dispositivo. Nunca são enviados para fora automaticamente.\n• O backup automático é feito no dispositivo, mas salve uma exportação nas configurações para o caso de trocar de aparelho ou de ele quebrar.';

  @override
  String get settingsPassphraseFieldLabel => 'Senha (se for criptografar)';

  @override
  String get settingsSaveAsIs => 'Salvar como está';

  @override
  String get settingsSaveEncrypted => 'Criptografar e salvar';

  @override
  String get settingsBackupSuccessSnackbar => 'Backup criado';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'Falha no backup: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return 'Salvo: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Falha ao exportar: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return '$count itens importados (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar =>
      'Ainda não há registros de leitura';

  @override
  String settingsShareTestDataSubject(int count) {
    return 'Dados de teste do orçamento ($count itens)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get entryTitleCreate => 'Entrada';

  @override
  String get entryTitleReceiptConfirm => 'Conferir recibo';

  @override
  String get commonEdit => 'Editar';

  @override
  String get entryTypeExpense => 'Despesa';

  @override
  String get entryTypeIncome => 'Receita';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$day/$month/$year';
  }

  @override
  String get entryStartSplitButton => 'Selecionar várias categorias';

  @override
  String get entryCategoryHeading => 'Categoria';

  @override
  String get entryDetailMemoLabel => 'Observações';

  @override
  String get entryStoreNameLabel => 'Nome da loja';

  @override
  String get entrySaveContinueButton => 'Salvar e continuar';

  @override
  String get entrySavedSnackbar => 'Salvo';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      'A captura de recibos não está disponível neste dispositivo';

  @override
  String entryOcrFailedSnackbar(String error) {
    return 'Falha na leitura: $error';
  }

  @override
  String get entryReceiptSourceCamera => 'Tirar foto';

  @override
  String get entryReceiptSourceLibrary => 'Escolher das fotos';

  @override
  String get entryDeleteConfirmTitle => 'Excluir este lançamento?';

  @override
  String get entryDeleteConfirmContent => 'Esta transação será excluída.';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get batchPanelTitle => 'Detalhar em lote';

  @override
  String get batchModeSelectAssign => 'Selecionar e atribuir';

  @override
  String get batchModePaint => 'Pintar';

  @override
  String get batchCancelButton => 'Cancelar';

  @override
  String get batchThisReceiptLabel => 'Este recibo:';

  @override
  String get batchTaxIncluded => 'Imp. incluso';

  @override
  String get batchTaxExclusive8 => 'Imp. à parte 8%';

  @override
  String get batchTaxExclusive10 => 'Imp. à parte 10%';

  @override
  String get batchPaintHintNoCategory =>
      'Escolha uma categoria abaixo e toque nas linhas para pintar';

  @override
  String batchPaintHintActive(String name) {
    return 'Pintando \"$name\" — toque nas linhas (toque de novo para desfazer)';
  }

  @override
  String get batchSelectHint =>
      'Selecione linhas → toque em uma categoria abaixo para atribuir';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count selecionados, $amount → toque em uma categoria abaixo';
  }

  @override
  String get batchNoAssignmentsYet => '(Nenhuma atribuição ainda)';

  @override
  String get batchCategoryUnknown => 'Desconhecida';

  @override
  String get batchDiffPickCategory =>
      'Restante (diferença) — toque para escolher uma categoria';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (diferença)';
  }

  @override
  String get batchReceiptFallbackLabel => 'Recibo';

  @override
  String get batchTotalLabel => 'Total';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess a mais';
  }

  @override
  String get restorePageTitle => 'Restaurar';

  @override
  String get restoreEmptyMessage => 'Nenhum backup disponível para restaurar';

  @override
  String get restoreConfirmTitle => 'Restaurar este backup?';

  @override
  String get restoreConfirmMessage =>
      'Todos os dados atuais serão substituídos. O estado anterior é salvo automaticamente e pode ser recuperado depois.';

  @override
  String get restoreButton => 'Restaurar';

  @override
  String get restoreEmptyBackupTitle => 'Este backup tem 0 transações';

  @override
  String get restoreEmptyBackupMessage =>
      'Restaurar vai apagar todas as suas transações atuais. Restaurar mesmo assim?';

  @override
  String get restoreEmptyBackupConfirmButton => 'Restaurar mesmo assim';

  @override
  String restoreFailedMessage(String error) {
    return 'Falha ao restaurar: $error';
  }

  @override
  String get restoreSuccessMessage => 'Restauração concluída';

  @override
  String get restorePassphraseTitle => 'Digite a senha';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get categoryRenameAction => 'Renomear';

  @override
  String get categorySubcategoryRenameTitle => 'Renomear subcategoria';

  @override
  String get categoryNameFieldLabel => 'Nome';

  @override
  String get categorySubcategoryAddTitle => 'Adicionar subcategoria';

  @override
  String get categoryIconFieldLabel => 'Ícone (emoji, opcional)';

  @override
  String get categoryEditExistingTitle => 'Editar itens existentes';

  @override
  String get categoryIconOrderTitle => 'Ordem de exibição dos ícones';

  @override
  String get categoryIconOrderHint =>
      'Arraste para reordenar (exibido na sua ordem)';

  @override
  String get categoryManageTitle => 'Gerenciar categorias';

  @override
  String get categoryTabExpense => 'Despesa';

  @override
  String get categoryTabIncome => 'Receita';

  @override
  String get categorySubAddTitle => 'Adicionar subcategoria';

  @override
  String get categoryAddTitle => 'Adicionar categoria';

  @override
  String get categorySubRenameTitle => 'Renomear subcategoria';

  @override
  String get categoryRenameTitle => 'Renomear categoria';

  @override
  String get categorySubAddTooltip => 'Adicionar subcategoria';

  @override
  String get categoryArchiveBlockedSnackbar =>
      'Arquive as subcategorias primeiro';

  @override
  String get categoryArchivedSectionTitle => 'Arquivadas';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (Arquivada)';
  }

  @override
  String get splitStoreNameHint => 'Nome da loja';

  @override
  String get splitCancel => 'Cancelar';

  @override
  String get splitBreakdownLabel => 'Detalhamento';

  @override
  String get splitTaxLabel => 'Imposto';

  @override
  String get splitTaxIncludedToggle => 'Imp. incluso';

  @override
  String get splitTaxExcludedToggle => 'Imp. à parte';

  @override
  String get splitTaxIndividual => 'Individual';

  @override
  String get splitMemoHint => 'Nota';

  @override
  String get splitAddCategoryChip => '＋ Categoria';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'C/ imposto $amount';
  }

  @override
  String get splitAddCategoryLabel => 'Adicionar categoria';

  @override
  String get splitOverLabel => 'Excedente';

  @override
  String get splitRemainingLabel => 'Restante';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get summaryEmptyTitle => 'Ainda não há dados deste mês';

  @override
  String get summaryEmptyHint => 'Toque no ＋ do calendário para adicionar';

  @override
  String get summaryIncomeLabel => 'Receita';

  @override
  String get summaryExpenseLabel => 'Despesa';

  @override
  String get summaryNetLabel => 'Saldo';

  @override
  String get summaryCategoryBreakdownTitle => 'Gastos por categoria';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (Arquivada)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ Detalhes';

  @override
  String get summaryBreakdownExpand => '▼ Detalhes';

  @override
  String get summaryNoBreakdownLabel => '(Sem detalhamento)';

  @override
  String get entryNoImage => 'Sem imagem';

  @override
  String get entryAmountReadFailed =>
      'Não foi possível ler o valor. Digite manualmente.';

  @override
  String get entryStoreDirectInput => 'Digitar manualmente';

  @override
  String get entryStoreNameDialogTitle => 'Digite o nome da loja';

  @override
  String get commonOk => 'OK';

  @override
  String get calendarWeekdaySun => 'Dom';

  @override
  String get calendarWeekdayMon => 'Seg';

  @override
  String get calendarWeekdayTue => 'Ter';

  @override
  String get calendarWeekdayWed => 'Qua';

  @override
  String get calendarWeekdayThu => 'Qui';

  @override
  String get calendarWeekdayFri => 'Sex';

  @override
  String get calendarWeekdaySat => 'Sáb';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return 'Despesa $expense   Receita $income   Saldo $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return 'Sem registros em $day/$month';
  }

  @override
  String get calendarDayEmptyHintFirst =>
      'Adicione seu primeiro registro em \"Inserir valor\" no canto inferior direito';

  @override
  String get calendarDayEmptyHint =>
      'Adicione um registro em \"Inserir valor\" no canto inferior direito';

  @override
  String get calendarReceiptFallbackLabel => 'Recibo';

  @override
  String get calendarCategoryUnknown => 'Desconhecida';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (Arquivada)';
  }

  @override
  String get calendarDeleteSnackbar => 'Excluído';

  @override
  String get calendarUndoAction => 'Desfazer';

  @override
  String get splitTaxDialogTitle => 'Imposto por item';

  @override
  String get commonDone => 'Concluído';

  @override
  String get splitRemainderLabel => 'Restante';

  @override
  String splitItemNumberLabel(int index) {
    return 'Item $index';
  }

  @override
  String get splitTaxIncludedLabel => 'Imp. incluso';

  @override
  String splitRemainderAutoAmount(String amount) {
    return '$amount (auto)';
  }

  @override
  String splitAmountWithTax(String entered, String net) {
    return '$entered → c/ imposto $net';
  }

  @override
  String get onboardingTitle => 'Sobre os seus dados';

  @override
  String get onboardingBody =>
      '• Seus registros ficam salvos apenas neste dispositivo. Nada é enviado para fora.\n• O app faz backup automático neste dispositivo, mas salve uma exportação nas configurações caso troque ou perca o aparelho.';

  @override
  String get onboardingStartButton => 'Começar';

  @override
  String get homeFabEntryLabel => 'Inserir valor';

  @override
  String get homeNavCalendar => 'Calendário';

  @override
  String get homeNavSummary => 'Resumo';

  @override
  String get homeNavSettings => 'Configurações';

  @override
  String get settingsColorPickerResetDefault => 'Restaurar padrão';

  @override
  String get settingsColorPickerConfirm => 'Confirmar';

  @override
  String get categoryManualOrderSnackbar =>
      'Agora usando sua ordem personalizada (você pode reverter nas configurações)';

  @override
  String get entryHintEnterAmount => 'Digite um valor';

  @override
  String get entryHintAssignItemCategory => 'Atribua uma categoria a cada item';

  @override
  String get entryHintAssignExceedsTotal =>
      'As atribuições ultrapassam o total';

  @override
  String get entryHintPickDiffCategory =>
      'Escolha uma categoria para a diferença';

  @override
  String get entryHintSplitExceedsTotal => 'O detalhamento ultrapassa o total';

  @override
  String get entryHintPickCategory => 'Escolha uma categoria';

  @override
  String get entryHintEnterAmountAndCategory =>
      'Digite um valor e uma categoria';

  @override
  String get entryHintEnterRemainingAmount => 'Digite também o valor restante';

  @override
  String get settingsBackupNever => 'Nenhum backup ainda';

  @override
  String get settingsBackupToday => 'Último backup: hoje';

  @override
  String settingsBackupDaysAgo(int days) {
    return 'Último backup: há $days dias';
  }

  @override
  String get recurringPageTitle => 'Lançamentos fixos mensais';

  @override
  String get settingsRecurringSubtitle =>
      'Registre aluguel, salário etc. automaticamente todo mês';

  @override
  String get recurringEmptyMessage =>
      'Nada por aqui ainda.\nToque em + para automatizar lançamentos mensais como aluguel ou salário.';

  @override
  String get recurringAddTitle => 'Adicionar lançamento fixo';

  @override
  String get recurringEditTitle => 'Editar lançamento fixo';

  @override
  String get recurringAmountLabel => 'Valor';

  @override
  String get recurringDayLabel => 'Dia do mês';

  @override
  String recurringEveryMonthDay(int day) {
    return 'Dia $day de cada mês';
  }

  @override
  String get recurringDayClampNote =>
      'Em meses mais curtos, é registrado no último dia (ex.: dia 31 → 28 de fevereiro).';

  @override
  String get recurringStartMonthLabel => 'Início';

  @override
  String get recurringStartThisMonth => 'Este mês';

  @override
  String get recurringStartNextMonth => 'Mês que vem';

  @override
  String get recurringActiveTitle => 'Ativo';

  @override
  String get recurringActiveSubtitle =>
      'Desative para pausar o registro automático';

  @override
  String get recurringPausedLabel => 'Pausado';

  @override
  String get recurringDeleteConfirmTitle => 'Excluir?';

  @override
  String get recurringDeleteConfirmContent =>
      'Este lançamento fixo será excluído. Os registros já criados serão mantidos.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return 'Escolha uma categoria para o item $n';
  }

  @override
  String get entryHintPickCategoryRemainder =>
      'Escolha uma categoria para a linha “Restante”';

  @override
  String get splitMemoDialogTitle => 'Digite uma nota';

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

  @override
  String get entryRecurringExpense => 'Monthly expense';

  @override
  String get entryRecurringIncome => 'Monthly income';

  @override
  String entryRecurringNote(int day) {
    return 'Will be recorded automatically on day $day every month (this entry is the first)';
  }

  @override
  String get entrySaveWithRuleExpense => 'Save + monthly expense';

  @override
  String get entrySaveWithRuleIncome => 'Save + monthly income';
}
