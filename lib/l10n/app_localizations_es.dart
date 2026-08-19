// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Kakeibo';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get currencyLockedSubtitle => 'Bloqueado: ya existen transacciones';

  @override
  String get currencyLockedTitle => 'No se puede cambiar la moneda';

  @override
  String get currencyLockedBody =>
      'Para mantener la coherencia de los importes anteriores, la moneda no se puede cambiar una vez registradas las transacciones.';

  @override
  String settingsAutoBackupSubtitle(int generations) {
    return 'Copia automática: $generations generaciones (en el dispositivo)';
  }

  @override
  String get settingsBackupNowTitle => 'Hacer copia ahora';

  @override
  String get settingsExportJsonTitle => 'Exportar JSON';

  @override
  String get settingsExportJsonSubtitle =>
      'Cifrado opcional con frase de contraseña (sirve para restaurar)';

  @override
  String get settingsExportCsvTitle => 'Exportar CSV';

  @override
  String get settingsExportCsvSubtitle =>
      'Solo para consulta (no sirve para restaurar)';

  @override
  String get settingsRestoreTitle => 'Restaurar';

  @override
  String get settingsRestoreSubtitle => 'Reemplaza todos los datos';

  @override
  String get settingsTestUploadTitle =>
      'Colaborar con las pruebas (envío automático)';

  @override
  String get settingsTestUploadSubtitle =>
      'Para mejorar la lectura de recibos, los registros de escaneo y las fotos se envían automáticamente al desarrollador (solo durante el periodo de pruebas). Lo que registras en el libro de cuentas nunca se envía.';

  @override
  String get settingsShareTestDataTitle => 'Enviar datos de prueba';

  @override
  String get settingsShareTestDataSubtitle =>
      'Compartir todo manualmente (LINE/AirDrop)';

  @override
  String get settingsFetchCollectedTitle =>
      'Importar datos recopilados (solo desarrollador)';

  @override
  String get settingsFetchCollectedSubtitle =>
      'Importa los datos de todos los dispositivos a exports/ocr-collected de este dispositivo';

  @override
  String get settingsRetainImagesTitle =>
      'Guardar las imágenes de recibos en el dispositivo';

  @override
  String get settingsRetainImagesSubtitle =>
      'Por defecto se descartan tras guardar';

  @override
  String get settingsCategoryManageTitle => 'Gestionar categorías';

  @override
  String get settingsCategoryOrderTitle => 'Ordenar las categorías a mi manera';

  @override
  String get settingsCategoryOrderSubtitle =>
      'Desactivado = orden de uso reciente / Activado = orden fijo (mantén pulsada una casilla en la pantalla de entrada para reordenar)';

  @override
  String get settingsDataPolicyTitle => 'Sobre el tratamiento de los datos';

  @override
  String get settingsDataPolicyBody =>
      '・Tus registros se guardan solo en este dispositivo. Nunca se envían al exterior de forma automática.\n・La app hace copias de seguridad automáticas en el dispositivo, pero guarda también una exportación desde Ajustes por si cambias de dispositivo o se avería.';

  @override
  String get settingsPassphraseFieldLabel =>
      'Frase de contraseña (si se cifra)';

  @override
  String get settingsSaveAsIs => 'Guardar tal cual';

  @override
  String get settingsSaveEncrypted => 'Cifrar y guardar';

  @override
  String get settingsBackupSuccessSnackbar => 'Copia de seguridad creada';

  @override
  String settingsBackupFailedSnackbar(String error) {
    return 'Error en la copia: $error';
  }

  @override
  String settingsExportSavedSnackbar(String fileName) {
    return 'Guardado: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String settingsFetchCollectedSuccessSnackbar(int count) {
    return 'Se importaron $count elementos (exports/ocr-collected)';
  }

  @override
  String settingsFetchCollectedFailedSnackbar(String error) {
    return 'Error al importar: $error';
  }

  @override
  String get settingsNoScanRecordsSnackbar => 'Aún no hay registros de escaneo';

  @override
  String settingsShareTestDataSubject(int count) {
    return 'Datos de prueba del libro de cuentas ($count elementos)';
  }

  @override
  String settingsShareTestDataFailedSnackbar(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get entryTitleCreate => 'Entrada';

  @override
  String get entryTitleReceiptConfirm => 'Confirmar recibo';

  @override
  String get commonEdit => 'Editar';

  @override
  String get entryTypeExpense => 'Gasto';

  @override
  String get entryTypeIncome => 'Ingreso';

  @override
  String entryDateLabel(int year, int month, int day) {
    return '$day/$month/$year';
  }

  @override
  String get entryStartSplitButton => 'Añadir categoría';

  @override
  String get entryCategoryHeading => 'Categoría';

  @override
  String get entryDetailMemoLabel => 'Notas';

  @override
  String get entryStoreNameLabel => 'Nombre de la tienda';

  @override
  String get entryCompanyNameLabel => 'Nombre de la empresa';

  @override
  String get entrySaveContinueButton => 'Guardar y continuar';

  @override
  String get entrySavedSnackbar => 'Guardado';

  @override
  String get entryReceiptCaptureUnavailableSnackbar =>
      'La captura de recibos no está disponible en este dispositivo';

  @override
  String entryOcrFailedSnackbar(String error) {
    return 'Error al leer el recibo: $error';
  }

  @override
  String get entryReceiptSourceCamera => 'Hacer una foto';

  @override
  String get entryReceiptSourceLibrary => 'Elegir de las fotos';

  @override
  String get entryDeleteConfirmTitle => '¿Eliminar esta entrada?';

  @override
  String get entryDeleteConfirmContent => 'Se eliminará esta transacción.';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get batchPanelTitle => 'Desglose en lote';

  @override
  String get batchModeSelectAssign => 'Seleccionar y asignar';

  @override
  String get batchModePaint => 'Pintar';

  @override
  String get batchCancelButton => 'Cancelar';

  @override
  String get batchThisReceiptLabel => 'Este recibo:';

  @override
  String get batchTaxIncluded => 'IVA incl.';

  @override
  String get batchTaxExclusive8 => 'IVA aparte 8%';

  @override
  String get batchTaxExclusive10 => 'IVA aparte 10%';

  @override
  String get batchPaintHintNoCategory =>
      'Elige una categoría abajo y toca las filas para pintar';

  @override
  String batchPaintHintActive(String name) {
    return 'Pintando «$name»: toca filas (toca de nuevo para deshacer)';
  }

  @override
  String get batchSelectHint =>
      'Selecciona filas → toca una categoría abajo para asignar';

  @override
  String batchSelectionSummary(int count, String amount) {
    return '$count seleccionadas, $amount → toca una categoría abajo';
  }

  @override
  String get batchNoAssignmentsYet => '(Aún no hay asignaciones)';

  @override
  String get batchCategoryUnknown => 'Desconocida';

  @override
  String get batchDiffPickCategory =>
      'Resto (diferencia): toca para elegir categoría';

  @override
  String batchDiffCategorySuffix(String category) {
    return '$category (diferencia)';
  }

  @override
  String get batchReceiptFallbackLabel => 'Recibo';

  @override
  String get batchTotalLabel => 'Total';

  @override
  String batchExcessAmount(String amount, String excess) {
    return '$amount ✗ $excess de más';
  }

  @override
  String get restorePageTitle => 'Restaurar';

  @override
  String get restoreEmptyMessage => 'No hay copias de seguridad para restaurar';

  @override
  String get restoreConfirmTitle => '¿Restaurar esta copia?';

  @override
  String get restoreConfirmMessage =>
      'Se reemplazarán todos los datos actuales. El estado anterior se guarda automáticamente y podrás recuperarlo después.';

  @override
  String get restoreButton => 'Restaurar';

  @override
  String get restoreEmptyBackupTitle => 'Esta copia tiene 0 transacciones';

  @override
  String get restoreEmptyBackupMessage =>
      'Al restaurar se eliminarán todas tus transacciones actuales. ¿Restaurar de todos modos?';

  @override
  String get restoreEmptyBackupConfirmButton => 'Restaurar de todos modos';

  @override
  String restoreFailedMessage(String error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get restoreSuccessMessage => 'Restauración completada';

  @override
  String get restorePassphraseTitle => 'Introduce la frase de contraseña';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get categoryRenameAction => 'Cambiar nombre';

  @override
  String get categorySubcategoryRenameTitle => 'Cambiar nombre de subcategoría';

  @override
  String get categoryNameFieldLabel => 'Nombre';

  @override
  String get categorySubcategoryAddTitle => 'Añadir subcategoría';

  @override
  String get categoryIconFieldLabel => 'Icono (emoji, opcional)';

  @override
  String get categoryEditExistingTitle => 'Editar elementos existentes';

  @override
  String get categoryIconOrderTitle => 'Orden de los iconos';

  @override
  String get categoryIconOrderHint =>
      'Arrastra para reordenar (se muestran en tu orden)';

  @override
  String get categoryManageTitle => 'Gestionar categorías';

  @override
  String get categoryTabExpense => 'Gastos';

  @override
  String get categoryTabIncome => 'Ingresos';

  @override
  String get categorySubAddTitle => 'Añadir subcategoría';

  @override
  String get categoryAddTitle => 'Nueva categoría';

  @override
  String get categorySubRenameTitle => 'Cambiar nombre de subcategoría';

  @override
  String get categoryRenameTitle => 'Cambiar nombre de categoría';

  @override
  String get categorySubAddTooltip => 'Añadir subcategoría';

  @override
  String get categoryArchiveBlockedSnackbar =>
      'Archiva primero sus subcategorías';

  @override
  String get categoryArchivedSectionTitle => 'Archivadas';

  @override
  String categoryArchivedItemLabel(String name) {
    return '$name (archivada)';
  }

  @override
  String get splitCancel => 'Cancelar';

  @override
  String get splitBreakdownLabel => 'Desglose';

  @override
  String get splitTaxLabel => 'IVA';

  @override
  String get splitTaxIncludedToggle => 'IVA incl.';

  @override
  String get splitTaxExcludedToggle => 'IVA aparte';

  @override
  String get splitTaxIndividual => 'Individual';

  @override
  String get splitMemoHint => 'Nota';

  @override
  String get splitCategoryUnselected => 'Sin categoría';

  @override
  String get splitAmountEmpty => 'Sin importe';

  @override
  String splitTaxIncludedAmount(String amount) {
    return 'IVA incl. $amount';
  }

  @override
  String get splitOverLabel => 'Excedido';

  @override
  String get splitRemainingLabel => 'Restante';

  @override
  String summaryMonthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get summaryEmptyTitle => 'Aún no hay datos de este mes';

  @override
  String get summaryEmptyHint =>
      'Toca ＋ en el calendario para añadir una entrada';

  @override
  String get summaryIncomeLabel => 'Ingresos';

  @override
  String get summaryExpenseLabel => 'Gastos';

  @override
  String get summaryNetLabel => 'Balance';

  @override
  String get summaryCategoryBreakdownTitle => 'Gastos por categoría';

  @override
  String summaryArchivedSuffix(String name) {
    return '$name (archivada)';
  }

  @override
  String get summaryBreakdownCollapse => '▲ Desglose';

  @override
  String get summaryBreakdownExpand => '▼ Desglose';

  @override
  String get summaryNoBreakdownLabel => '(Sin desglose)';

  @override
  String get entryNoImage => 'Sin imagen';

  @override
  String get entryAmountReadFailed =>
      'No se pudo leer el importe. Introdúcelo manualmente.';

  @override
  String get entryStoreDirectInput => 'Introducir manualmente';

  @override
  String get entryStoreNameDialogTitle => 'Introduce el nombre de la tienda';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get calendarWeekdaySun => 'Dom';

  @override
  String get calendarWeekdayMon => 'Lun';

  @override
  String get calendarWeekdayTue => 'Mar';

  @override
  String get calendarWeekdayWed => 'Mié';

  @override
  String get calendarWeekdayThu => 'Jue';

  @override
  String get calendarWeekdayFri => 'Vie';

  @override
  String get calendarWeekdaySat => 'Sáb';

  @override
  String calendarMonthYearHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String calendarMonthSummary(String expense, String income, String net) {
    return 'Gastos $expense  Ingresos $income  Balance $net';
  }

  @override
  String calendarDayEmptyTitle(int month, int day) {
    return 'No hay registros del $day/$month';
  }

  @override
  String get calendarDayEmptyHintFirst =>
      'Añade tu primer registro con «Introducir importe» abajo a la derecha';

  @override
  String get calendarDayEmptyHint =>
      'Añade un registro con «Introducir importe» abajo a la derecha';

  @override
  String get calendarReceiptFallbackLabel => 'Recibo';

  @override
  String get calendarCategoryUnknown => 'Desconocida';

  @override
  String calendarCategoryArchivedLabel(String name) {
    return '$name (archivada)';
  }

  @override
  String get calendarUndoAction => 'Deshacer';

  @override
  String get trashMovedSnack =>
      'Movido a la papelera (restaurar desde Ajustes)';

  @override
  String get trashTitle => 'Papelera';

  @override
  String get settingsTrashSubtitle =>
      'Las transacciones eliminadas se conservan 30 días';

  @override
  String get trashEmpty => 'La papelera está vacía';

  @override
  String get trashRestore => 'Restaurar';

  @override
  String get trashRestoredSnack => 'Restaurado';

  @override
  String trashDeletedOn(String date) {
    return 'Eliminado el $date';
  }

  @override
  String get trashEmptyAction => 'Vaciar papelera';

  @override
  String get trashEmptyConfirmTitle => '¿Vaciar la papelera?';

  @override
  String get trashEmptyConfirmContent =>
      'Todos los elementos se eliminarán definitivamente. Esta acción no se puede deshacer.';

  @override
  String get splitTaxDialogTitle => 'Tipo de IVA por artículo';

  @override
  String get commonDone => 'Listo';

  @override
  String get splitRemainderLabel => 'Restante';

  @override
  String splitItemNumberLabel(int index) {
    return 'Artículo $index';
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
  String get onboardingTitle => 'Sobre tus datos';

  @override
  String get onboardingBody =>
      '・Tus registros se guardan solo en este dispositivo. No se envía nada al exterior.\n・La app hace copias automáticas en el dispositivo, pero guarda también una exportación desde Ajustes por si cambias o pierdes el dispositivo.';

  @override
  String get onboardingStartButton => 'Empezar';

  @override
  String get homeFabEntryLabel => 'Introducir importe';

  @override
  String get homeNavCalendar => 'Calendario';

  @override
  String get homeNavSummary => 'Resumen';

  @override
  String get homeNavSettings => 'Ajustes';

  @override
  String get categoryManualOrderSnackbar =>
      'Se aplicó tu orden personalizado (puedes revertirlo en Ajustes).';

  @override
  String get entryHintEnterAmount => 'Introduce un importe';

  @override
  String get entryHintAssignItemCategory =>
      'Asigna una categoría a cada artículo';

  @override
  String get entryHintAssignExceedsTotal => 'Las asignaciones superan el total';

  @override
  String get entryHintPickDiffCategory =>
      'Elige una categoría para la diferencia';

  @override
  String get entryHintSplitExceedsTotal => 'El desglose supera el total';

  @override
  String get entryHintPickCategory => 'Elige una categoría';

  @override
  String get entryHintEnterAmountAndCategory =>
      'Introduce un importe y una categoría';

  @override
  String get entryHintEnterRemainingAmount =>
      'Introduce también el importe restante';

  @override
  String get settingsBackupNever => 'Sin copias todavía';

  @override
  String get settingsBackupToday => 'Última copia: hoy';

  @override
  String settingsBackupDaysAgo(int days) {
    return 'Última copia: hace $days días';
  }

  @override
  String get recurringPageTitle => 'Movimientos fijos mensuales';

  @override
  String get settingsRecurringSubtitle =>
      'Registra automáticamente cada mes el alquiler, el sueldo, etc.';

  @override
  String get recurringEmptyMessage =>
      'Aún no hay nada.\nToca + para automatizar registros mensuales como el alquiler o el sueldo.';

  @override
  String get recurringAddTitle => 'Añadir movimiento fijo';

  @override
  String get recurringEditTitle => 'Editar movimiento fijo';

  @override
  String get recurringAmountLabel => 'Importe';

  @override
  String get recurringDayLabel => 'Día de repetición';

  @override
  String recurringEveryMonthDay(int day) {
    return 'El día $day de cada mes';
  }

  @override
  String dayOfMonthItem(int day) {
    return 'Día $day';
  }

  @override
  String get recurringDayClampNote =>
      'Si eliges el día 31, se registra el último día del mes (p. ej., el 28 de febrero).';

  @override
  String get recurringStartMonthLabel => 'Empieza';

  @override
  String get recurringStartThisMonth => 'Este mes';

  @override
  String get recurringStartNextMonth => 'El mes que viene';

  @override
  String get recurringEndMonthLabel => 'Termina';

  @override
  String get recurringEndNone => 'Sin fin (continuo)';

  @override
  String get recurringEndMonthNote =>
      'Se registra hasta este mes y luego se detiene';

  @override
  String get recurringActiveTitle => 'Activo';

  @override
  String get recurringActiveSubtitle =>
      'Desactívalo para pausar el registro automático';

  @override
  String get recurringPausedLabel => 'En pausa';

  @override
  String get recurringDeleteConfirmTitle => '¿Eliminar?';

  @override
  String get recurringDeleteConfirmContent =>
      'Se eliminará este movimiento fijo. Los registros ya creados se conservarán.';

  @override
  String entryHintPickCategoryForItem(int n) {
    return 'Elige una categoría para el artículo $n';
  }

  @override
  String get entryHintPickCategoryRemainder =>
      'Elige una categoría para la fila «Restante»';

  @override
  String get splitMemoDialogTitle => 'Escribe una nota';

  @override
  String choreNotificationBody(int day) {
    return 'Tarea mensual programada para el día $day';
  }

  @override
  String choreNotificationBodyInterval(int days) {
    return 'Han pasado $days días desde la última vez';
  }

  @override
  String get homeNavMonthly => 'Mensual';

  @override
  String get hubUpcomingSection => 'Próximamente este mes';

  @override
  String get hubUpcomingEmpty => 'No hay nada previsto para el resto del mes';

  @override
  String get hubRulesSection => 'Gastos fijos e ingresos';

  @override
  String get hubRulesEmpty =>
      'Con + puedes automatizar registros mensuales como el alquiler o el sueldo';

  @override
  String get hubChoresSection => 'Tareas periódicas';

  @override
  String get hubChoresEmpty =>
      'Con + puedes añadir tareas como cambiar el cepillo de dientes';

  @override
  String get hubChoreTimelineLabel => 'Tarea';

  @override
  String get ghostBadgeLabel => 'Previsto';

  @override
  String get forecastLabelMonthEnd => 'Previsión (fin de mes)';

  @override
  String forecastLabelAtDate(String date) {
    return 'Previsión (a $date)';
  }

  @override
  String choreOverdueDays(int days) {
    return '$days días de retraso';
  }

  @override
  String get choreDueToday => 'Hoy';

  @override
  String choreDaysLeft(int days) {
    return 'en $days días';
  }

  @override
  String choreNextDate(String date) {
    return 'Próxima: $date';
  }

  @override
  String get choreDoneButton => 'Hecho';

  @override
  String choreDoneSnackbar(String date) {
    return '✓ Registrado. Próxima: $date';
  }

  @override
  String get choreDupConfirmTitle => 'Ya registrado';

  @override
  String choreDupConfirmBody(String name) {
    return '«$name» ya tiene un registro ese día. ¿Añadir otro?';
  }

  @override
  String get choreDupConfirmAdd => 'Añadir';

  @override
  String get choreFormNewTitle => 'Nueva tarea';

  @override
  String get choreFormEditTitle => 'Editar tarea';

  @override
  String get choreFormNameLabel => 'Nombre';

  @override
  String get choreRepeatUnitLabel => 'Repetir';

  @override
  String get choreRepeatUnitMonthly => 'Cada mes';

  @override
  String get choreRepeatUnitEveryDays => 'Cada N días';

  @override
  String get choreFormDayLabel => 'Día';

  @override
  String get choreFormIntervalLabel => 'Intervalo';

  @override
  String choreIntervalDaysItem(int days) {
    return '$days días';
  }

  @override
  String choreIntervalEvery(int days) {
    return 'Cada $days días';
  }

  @override
  String get choreFormEmojiLabel => 'Emoji (📌 si se deja vacío)';

  @override
  String get choreFormArchiveButton => 'Archivar';

  @override
  String get choreFormDeleteButton => 'Eliminar esta tarea';

  @override
  String choreDeleteConfirmBody(int count) {
    return 'También se eliminarán $count registros del historial';
  }

  @override
  String get choreHistoryTitle => 'Historial';

  @override
  String get choreHistoryEmpty => 'Aún no hay registros';

  @override
  String get choreRecordEditTitle => 'Editar registro';

  @override
  String get choreRecordDeleteConfirm => '¿Eliminar este registro?';

  @override
  String get choreMemoLabel => 'Nota';

  @override
  String get settingsChoresTitle => 'Tareas periódicas';

  @override
  String get settingsChoresSubtitle => 'Hora del aviso y tareas archivadas';

  @override
  String get choreNotifyTimeLabel => 'Hora del aviso';

  @override
  String get chorePermissionChecking =>
      'Comprobando permiso de notificaciones…';

  @override
  String get chorePermissionNotAsked =>
      'El permiso se pedirá tras el primer registro';

  @override
  String get chorePermissionGranted => 'Las notificaciones están activadas';

  @override
  String get chorePermissionDenied => 'Las notificaciones no están permitidas';

  @override
  String get chorePermissionOpenSettings => 'Abrir Ajustes';

  @override
  String get choreArchivedSection => 'Tareas archivadas';

  @override
  String get choreArchivedEmpty => 'No hay tareas archivadas';

  @override
  String get choreUnarchiveButton => 'Restaurar';

  @override
  String get forecastAnchorSheetTitle => 'Fecha de referencia de la previsión';

  @override
  String get forecastAnchorSheetNote =>
      'Los importes previstos hasta la fecha de referencia (incluida) se suman al saldo real.';

  @override
  String get forecastAnchorMonthEnd => 'Fin de mes';

  @override
  String get calendarLegendChoreDone => 'hecho';

  @override
  String get calendarLegendChoreDue => 'tarea pendiente';

  @override
  String get calendarLegendChoreOverdue => 'atrasada';

  @override
  String get entryRecurringExpense => 'Gasto mensual';

  @override
  String get entryRecurringIncome => 'Ingreso mensual';

  @override
  String get entrySaveWithRuleExpense => 'Guardar (+ mensual)';

  @override
  String get entrySaveWithRuleIncome => 'Guardar (+ mensual)';

  @override
  String get entryRecurringNotePrefix => 'Se registrará automáticamente el día';

  @override
  String get entryRecurringNoteSuffix => 'de cada mes';

  @override
  String get entrySubcategoryAddButton => 'Añadir subcategoría';

  @override
  String get settingsColorTitle => 'Color';

  @override
  String get settingsColorSubtitle =>
      'El fondo, las líneas y los acentos se ajustan al color elegido';

  @override
  String get settingsColorPreset => 'Preajustes';

  @override
  String get settingsColorCustom => 'Personalizado';

  @override
  String get settingsColorApply => 'Aplicar';

  @override
  String get settingsColorDefaultBadge => 'Predeterminado';

  @override
  String get settingsColorBlue => 'Azul';

  @override
  String get settingsColorGreen => 'Verde';

  @override
  String get settingsColorTeal => 'Verde azulado';

  @override
  String get settingsColorPurple => 'Morado';

  @override
  String get settingsColorRose => 'Rosa';

  @override
  String get settingsColorOrange => 'Naranja';

  @override
  String get settingsColorMustard => 'Mostaza';

  @override
  String get settingsColorGray => 'Gris';

  @override
  String get settingsColorTerracotta => 'Terracota';

  @override
  String get settingsColorNavy => 'Azul marino';

  @override
  String get installmentTitle => 'Registrar pago a plazos';

  @override
  String get installmentAddButton => 'Pago a plazos';

  @override
  String get installmentPrincipalLabel => 'Importe de compra';

  @override
  String get installmentCountLabel => 'Número de pagos';

  @override
  String installmentCountItem(int n) {
    return '$n pagos';
  }

  @override
  String get installmentRateLabel => 'Tasa anual (%)';

  @override
  String get installmentCardPickLabel => 'Tarjetas guardadas';

  @override
  String get installmentCardNameLabel => 'Nombre de la tarjeta (opcional)';

  @override
  String get installmentDayLabel => 'Día de pago';

  @override
  String get installmentMonthlyLabel => 'Pago mensual';

  @override
  String get installmentFirstLabel => 'Primer pago';

  @override
  String get installmentFeeLabel => 'Intereses totales';

  @override
  String get installmentTotalLabel => 'Total a pagar';

  @override
  String installmentTxnMemo(int index, int count) {
    return 'Cuota $index/$count';
  }

  @override
  String get installmentEditTitle => 'Editar pago a plazos';

  @override
  String get installmentDeleteConfirmContent =>
      'Se eliminará este pago a plazos y todos sus pagos registrados.';

  @override
  String get hubInstallmentEmpty => 'Aún no hay pagos a plazos';
}
