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
  String get entryStartSplitButton => 'Adicionar categoria';

  @override
  String get entryCategoryHeading => 'Categoria';

  @override
  String get entryDetailMemoLabel => 'Observações';

  @override
  String get entryStoreNameLabel => 'Nome da loja';

  @override
  String get entryCompanyNameLabel => 'Nome da empresa';

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
  String get categoryAddTitle => 'Nova categoria';

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
  String get splitCategoryUnselected => 'Sem categoria';

  @override
  String get splitAmountEmpty => 'Sem valor';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'C/ imposto $amount';
  }

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
  String get recurringDayLabel => 'Dia de repetição';

  @override
  String recurringEveryMonthDay(int day) {
    return 'Dia $day de cada mês';
  }

  @override
  String dayOfMonthItem(int day) {
    return 'Dia $day';
  }

  @override
  String get recurringDayClampNote =>
      'Se você escolher o dia 31, o lançamento ocorre no último dia do mês (ex.: 28 de fevereiro).';

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
  String choreNotificationBody(int day) {
    return 'Tarefa mensal programada para o dia $day';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return 'Já se passaram $days dias desde a última vez';
  }

  @override
  String get homeNavMonthly => 'Mensal';

  @override
  String get hubUpcomingSection => 'Por vir neste mês';

  @override
  String get hubUpcomingEmpty => 'Nada previsto para o resto do mês';

  @override
  String get hubRulesSection => 'Despesas fixas e receitas';

  @override
  String get hubRulesEmpty =>
      'Com + você automatiza registros mensais como aluguel ou salário';

  @override
  String get hubChoresSection => 'Tarefas recorrentes';

  @override
  String get hubChoresEmpty =>
      'Com + você adiciona tarefas como trocar a escova de dentes';

  @override
  String get hubChoreTimelineLabel => 'Tarefa';

  @override
  String get ghostBadgeLabel => 'Previsto';

  @override
  String get forecastLabelMonthEnd => 'Previsão (fim do mês)';

  @override
  String forecastLabelAtDate(String date) {
    return 'Previsão (em $date)';
  }

  @override
  String choreOverdueDays(int days) {
    return '$days dias de atraso';
  }

  @override
  String get choreDueToday => 'Hoje';

  @override
  String choreDaysLeft(int days) {
    return 'em $days dias';
  }

  @override
  String choreNextDate(String date) {
    return 'Próxima: $date';
  }

  @override
  String get choreDoneButton => 'Feito';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ Registrado. Próxima: $date';
  }

  @override
  String get choreDupConfirmTitle => 'Já registrado';

  @override
  String choreDupConfirmBody(String name) {
    return '\"$name\" já tem um registro nesse dia. Adicionar outro?';
  }

  @override
  String get choreDupConfirmAdd => 'Adicionar';

  @override
  String get choreFormNewTitle => 'Nova tarefa';

  @override
  String get choreFormEditTitle => 'Editar tarefa';

  @override
  String get choreFormNameLabel => 'Nome';

  @override
  String get choreRepeatUnitLabel => 'Repetição';

  @override
  String get choreRepeatUnitMonthly => 'Todo mês';

  @override
  String get choreRepeatUnitEveryDays => 'A cada N dias';

  @override
  String get choreFormDayLabel => 'Dia';

  @override
  String get choreFormIntervalLabel => 'Intervalo';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days dias';
  }

  @override
  String choreIntervalEvery(int days) {
    return 'A cada $days dias';
  }

  @override
  String get choreFormEmojiLabel => 'Emoji (📌 se vazio)';

  @override
  String get choreFormArchiveButton => 'Arquivar';

  @override
  String get choreFormDeleteButton => 'Excluir esta tarefa';

  @override
  String choreDeleteConfirmBody(int count) {
    return '$count registros do histórico também serão excluídos';
  }

  @override
  String get choreHistoryTitle => 'Histórico';

  @override
  String get choreHistoryEmpty => 'Ainda não há registros';

  @override
  String get choreRecordEditTitle => 'Editar registro';

  @override
  String get choreRecordDeleteConfirm => 'Excluir este registro?';

  @override
  String get choreMemoLabel => 'Nota';

  @override
  String get settingsChoresTitle => 'Tarefas recorrentes';

  @override
  String get settingsChoresSubtitle =>
      'Horário do lembrete e tarefas arquivadas';

  @override
  String get choreNotifyTimeLabel => 'Horário do lembrete';

  @override
  String get chorePermissionChecking =>
      'Verificando permissão de notificações…';

  @override
  String get chorePermissionNotAsked =>
      'A permissão será pedida após o primeiro registro';

  @override
  String get chorePermissionGranted => 'As notificações estão ativadas';

  @override
  String get chorePermissionDenied => 'As notificações não estão permitidas';

  @override
  String get chorePermissionOpenSettings => 'Abrir Ajustes';

  @override
  String get choreArchivedSection => 'Tarefas arquivadas';

  @override
  String get choreArchivedEmpty => 'Nenhuma tarefa arquivada';

  @override
  String get choreUnarchiveButton => 'Restaurar';

  @override
  String get forecastAnchorSheetTitle => 'Data de referência da previsão';

  @override
  String get forecastAnchorSheetNote =>
      'Os valores previstos até a data de referência (inclusive) são somados ao saldo real.';

  @override
  String get forecastAnchorMonthEnd => 'Fim do mês';

  @override
  String get calendarLegendChoreDone => 'feito';

  @override
  String get calendarLegendChoreDue => 'tarefa a vencer';

  @override
  String get calendarLegendChoreOverdue => 'atrasada';

  @override
  String get calendarLegendGhost => 'despesa fixa prevista';

  @override
  String get entryRecurringExpense => 'Despesa mensal';

  @override
  String get entryRecurringIncome => 'Receita mensal';

  @override
  String get entrySaveWithRuleExpense => 'Salvar (+ mensal)';

  @override
  String get entrySaveWithRuleIncome => 'Salvar (+ mensal)';

  @override
  String get entryRecurringNotePrefix => 'Registrado automaticamente no dia';

  @override
  String get entryRecurringNoteSuffix => 'de cada mês';

  @override
  String get entrySubcategoryAddButton => 'Adicionar subcategoria';

  @override
  String get settingsColorTitle => 'Cor';

  @override
  String get settingsColorSubtitle =>
      'O fundo, as linhas e os destaques se ajustam à cor escolhida';

  @override
  String get settingsColorPreset => 'Predefinições';

  @override
  String get settingsColorCustom => 'Personalizado';

  @override
  String get settingsColorApply => 'Aplicar';

  @override
  String get settingsColorDefaultBadge => 'Padrão';

  @override
  String get settingsColorBlue => 'Azul';

  @override
  String get settingsColorGreen => 'Verde';

  @override
  String get settingsColorTeal => 'Verde-azulado';

  @override
  String get settingsColorPurple => 'Roxo';

  @override
  String get settingsColorRose => 'Rosa';

  @override
  String get settingsColorOrange => 'Laranja';

  @override
  String get settingsColorMustard => 'Mostarda';

  @override
  String get settingsColorGray => 'Cinza';

  @override
  String get settingsColorTerracotta => 'Terracota';

  @override
  String get settingsColorNavy => 'Azul-marinho';
}
