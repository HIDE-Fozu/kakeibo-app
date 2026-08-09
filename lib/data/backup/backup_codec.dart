import 'dart:convert';
import 'backup_data.dart';
import '../db/enums.dart';
import '../../domain/money/civil_date.dart';
import '../../domain/services/chore_schedule.dart'
    show kChoreIntervalMin, kChoreIntervalMax;

/// バックアップJSONの直列化と厳格検証。復元の唯一の門番。
class BackupCodec {
  /// バックアップ形式のバージョン。DBのschemaVersionとは独立に管理する。
  /// v2: categories[].parentId（内訳）を追加。
  /// v3: categories[].slug（安定キー）を追加。旧バックアップはnull復元。
  /// v4: recurringRules（定期ルール）と TxnSource.recurring を追加。
  ///     旧バックアップはルール空で復元。
  /// v5: choreTasks / choreRecords（つきいちタスク）を追加。
  ///     旧バックアップは空で復元。
  /// v6: つきいちタスクに dayOfMonth（毎月N日）を追加。
  /// v7: つきいちタスクに repeatUnit（毎月N日 / N日ごと）と intervalDays を追加。
  ///     v5以前は「N日ごと」だったので everyDays として復元する。
  static const int formatVersion = 7;

  const BackupCodec();

  String encode(BackupPayload p) {
    final root = <String, dynamic>{
      'formatVersion': p.formatVersion,
      'exportedAt': p.exportedAt?.toUtc().toIso8601String(),
      'categories': [
        for (final c in p.categories)
          {
            'id': c.id,
            'name': c.name,
            'type': c.type.name,
            'icon': c.icon,
            'sortOrder': c.sortOrder,
            'isArchived': c.isArchived,
            'isSystem': c.isSystem,
            'parentId': c.parentId,
            'slug': c.slug,
          },
      ],
      'transactions': [
        for (final t in p.transactions)
          {
            'id': t.id,
            'type': t.type.name,
            'amount': t.amount,
            'date': t.date.toIso(),
            'categoryId': t.categoryId,
            'paymentMethod': t.paymentMethod?.name,
            'storeName': t.storeName,
            'memo': t.memo,
            'source': t.source.name,
            'imagePath': t.imagePath,
            'splitGroupId': t.splitGroupId,
            'createdAt': t.createdAt.toUtc().toIso8601String(),
            'updatedAt': t.updatedAt.toUtc().toIso8601String(),
          },
      ],
      'recurringRules': [
        for (final r in p.recurringRules)
          {
            'id': r.id,
            'type': r.type.name,
            'amount': r.amount,
            'categoryId': r.categoryId,
            'dayOfMonth': r.dayOfMonth,
            'storeName': r.storeName,
            'memo': r.memo,
            'isActive': r.isActive,
            'startYm': r.startYm,
            'endYm': r.endYm,
            'lastGeneratedYm': r.lastGeneratedYm,
            'createdAt': r.createdAt.toUtc().toIso8601String(),
            'updatedAt': r.updatedAt.toUtc().toIso8601String(),
          },
      ],
      'choreTasks': [
        for (final t in p.choreTasks)
          {
            'id': t.id,
            'name': t.name,
            'emoji': t.emoji,
            'repeatUnit': t.repeatUnit.name,
            'dayOfMonth': t.dayOfMonth,
            'intervalDays': t.intervalDays,
            'anchorDate': t.anchorDate.toIso(),
            'archived': t.archived,
            'createdAt': t.createdAt.toUtc().toIso8601String(),
          },
      ],
      'choreRecords': [
        for (final r in p.choreRecords)
          {
            'id': r.id,
            'taskId': r.taskId,
            'doneDate': r.doneDate.toIso(),
            'memo': r.memo,
            'createdAt': r.createdAt.toUtc().toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }

  BackupPayload decode(String json) {
    Object? parsed;
    try {
      parsed = jsonDecode(json);
    } on FormatException catch (e) {
      throw BackupFormatError('JSONとして解釈できません: ${e.message}');
    }
    if (parsed is! Map<String, dynamic>) {
      throw BackupFormatError('ルートはオブジェクトである必要があります');
    }
    var root = parsed;

    // --- バージョン検証（範囲） ---
    final version = root['formatVersion'];
    if (version is! int || version < 1) {
      throw BackupVersionError('formatVersion が欠落または不正です: $version');
    }
    if (version > formatVersion) {
      throw BackupVersionError(
          'このバックアップ($version)はアプリの対応形式($formatVersion)より新しいため復元できません',
          newerThanApp: true);
    }
    root = _migrate(root, from: version);

    // --- 構造ヘルパ ---
    T req<T>(Map<String, dynamic> m, String key, String ctx) {
      final v = m[key];
      if (v is! T) {
        throw BackupFormatError('$ctx.$key が不正です（$T が必要）: $v');
      }
      return v;
    }

    T? opt<T>(Map<String, dynamic> m, String key, String ctx) {
      final v = m[key];
      if (v == null) return null;
      if (v is! T) {
        throw BackupFormatError('$ctx.$key が不正です（$T か null が必要）: $v');
      }
      return v;
    }

    E enumByName<E extends Enum>(List<E> values, String name, String ctx) {
      try {
        return values.byName(name);
      } on ArgumentError {
        throw BackupValidationError('$ctx: 未知の値 "$name"');
      }
    }

    DateTime instant(String iso, String ctx) {
      try {
        return DateTime.parse(iso).toUtc();
      } on FormatException {
        throw BackupFormatError('$ctx: 日時として解釈できません "$iso"');
      }
    }

    // --- exportedAt（任意・情報） ---
    final exportedAtRaw = opt<String>(root, 'exportedAt', 'root');
    final exportedAt =
        exportedAtRaw == null ? null : instant(exportedAtRaw, 'exportedAt');

    // --- categories ---
    final catsRaw = req<List<dynamic>>(root, 'categories', 'root');
    final categories = <BackupCategory>[];
    final catIds = <int>{};
    for (final (i, raw) in catsRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('categories[$i] がオブジェクトではありません');
      }
      final ctx = 'categories[$i]';
      final c = BackupCategory(
        id: req<int>(raw, 'id', ctx),
        name: req<String>(raw, 'name', ctx),
        type: enumByName(CategoryType.values, req<String>(raw, 'type', ctx),
            '$ctx.type'),
        icon: opt<String>(raw, 'icon', ctx),
        sortOrder: req<int>(raw, 'sortOrder', ctx),
        isArchived: req<bool>(raw, 'isArchived', ctx),
        isSystem: req<bool>(raw, 'isSystem', ctx),
        parentId: opt<int>(raw, 'parentId', ctx),
        slug: opt<String>(raw, 'slug', ctx),
      );
      if (c.name.isEmpty) {
        throw BackupValidationError('$ctx.name が空です');
      }
      if (!catIds.add(c.id)) {
        throw BackupValidationError('カテゴリID ${c.id} が重複しています');
      }
      categories.add(c);
    }
    for (final type in CategoryType.values) {
      if (!categories.any((c) => c.isSystem && c.type == type)) {
        throw BackupValidationError(
            'システム「未分類」(${type.name}) がバックアップに含まれていません');
      }
    }

    // --- 階層検証（v2）: 2段まで・type一致・システムは親のみ ---
    final catById = {for (final c in categories) c.id: c};
    for (final c in categories) {
      final p = c.parentId;
      if (p == null) continue;
      if (c.isSystem) {
        throw BackupValidationError('システムカテゴリ ${c.id} に parentId は指定できません');
      }
      if (p == c.id) {
        throw BackupValidationError('カテゴリ ${c.id} が自分自身を親にしています');
      }
      final parent = catById[p];
      if (parent == null) {
        throw BackupValidationError(
            'カテゴリ ${c.id} の parentId $p が同梱カテゴリに解決できません');
      }
      if (parent.parentId != null) {
        throw BackupValidationError(
            'カテゴリ ${c.id}: 内訳の下に内訳は置けません（階層は2段まで）');
      }
      if (parent.type != c.type) {
        throw BackupValidationError(
            'カテゴリ ${c.id}: type が親 ${parent.id} と一致しません');
      }
    }

    // --- transactions ---
    final txsRaw = req<List<dynamic>>(root, 'transactions', 'root');
    final transactions = <BackupTxn>[];
    final txIds = <int>{};
    for (final (i, raw) in txsRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('transactions[$i] がオブジェクトではありません');
      }
      final ctx = 'transactions[$i]';
      final amount = req<int>(raw, 'amount', ctx);
      if (amount < 0) {
        throw BackupValidationError('$ctx.amount が負です: $amount');
      }
      final dateRaw = req<String>(raw, 'date', ctx);
      final CivilDate date;
      try {
        date = CivilDate.parse(dateRaw);
      } on FormatException {
        throw BackupValidationError('$ctx.date が不正な日付です: "$dateRaw"');
      }
      final pmRaw = opt<String>(raw, 'paymentMethod', ctx);
      // v4以前のバックアップ（storeNameキー無し）は旧memo=店名。DBのv4マイグレーションと
      // 同じく店名へ寄せ、memoは空にする（新形式はそのまま両方を復元）。
      final rawMemo = opt<String>(raw, 'memo', ctx);
      final hasStoreKey = raw.containsKey('storeName');
      final storeName = hasStoreKey ? opt<String>(raw, 'storeName', ctx) : rawMemo;
      final memo = hasStoreKey ? rawMemo : null;
      final t = BackupTxn(
        id: req<int>(raw, 'id', ctx),
        type: enumByName(TxnType.values, req<String>(raw, 'type', ctx),
            '$ctx.type'),
        amount: amount,
        date: date,
        categoryId: req<int>(raw, 'categoryId', ctx),
        paymentMethod: pmRaw == null
            ? null
            : enumByName(PaymentMethod.values, pmRaw, '$ctx.paymentMethod'),
        storeName: storeName,
        memo: memo,
        source: enumByName(TxnSource.values, req<String>(raw, 'source', ctx),
            '$ctx.source'),
        imagePath: opt<String>(raw, 'imagePath', ctx),
        splitGroupId: opt<String>(raw, 'splitGroupId', ctx),
        createdAt: instant(req<String>(raw, 'createdAt', ctx), '$ctx.createdAt'),
        updatedAt: instant(req<String>(raw, 'updatedAt', ctx), '$ctx.updatedAt'),
      );
      if (!txIds.add(t.id)) {
        throw BackupValidationError('取引ID ${t.id} が重複しています');
      }
      if (!catIds.contains(t.categoryId)) {
        throw BackupValidationError(
            '$ctx.categoryId ${t.categoryId} が同梱カテゴリに解決できません');
      }
      transactions.add(t);
    }

    // --- recurringRules（v4） ---
    final rulesRaw = req<List<dynamic>>(root, 'recurringRules', 'root');
    final recurringRules = <BackupRecurringRule>[];
    final ruleIds = <int>{};
    bool validYm(int ym) {
      final m = ym % 100;
      return m >= 1 && m <= 12 && ym >= 100;
    }

    for (final (i, raw) in rulesRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('recurringRules[$i] がオブジェクトではありません');
      }
      final ctx = 'recurringRules[$i]';
      final amount = req<int>(raw, 'amount', ctx);
      if (amount < 0) {
        throw BackupValidationError('$ctx.amount が負です: $amount');
      }
      final dayOfMonth = req<int>(raw, 'dayOfMonth', ctx);
      if (dayOfMonth < 1 || dayOfMonth > 31) {
        throw BackupValidationError('$ctx.dayOfMonth が範囲外です: $dayOfMonth');
      }
      final startYm = req<int>(raw, 'startYm', ctx);
      final endYm = opt<int>(raw, 'endYm', ctx);
      final lastYm = opt<int>(raw, 'lastGeneratedYm', ctx);
      for (final (name, ym) in [
        ('startYm', startYm),
        ('endYm', endYm),
        ('lastGeneratedYm', lastYm)
      ]) {
        if (ym != null && !validYm(ym)) {
          throw BackupValidationError('$ctx.$name が YYYYMM ではありません: $ym');
        }
      }
      final r = BackupRecurringRule(
        id: req<int>(raw, 'id', ctx),
        type: enumByName(
            TxnType.values, req<String>(raw, 'type', ctx), '$ctx.type'),
        amount: amount,
        categoryId: req<int>(raw, 'categoryId', ctx),
        dayOfMonth: dayOfMonth,
        storeName: opt<String>(raw, 'storeName', ctx),
        memo: opt<String>(raw, 'memo', ctx),
        isActive: req<bool>(raw, 'isActive', ctx),
        startYm: startYm,
        endYm: endYm,
        lastGeneratedYm: lastYm,
        createdAt: instant(req<String>(raw, 'createdAt', ctx), '$ctx.createdAt'),
        updatedAt: instant(req<String>(raw, 'updatedAt', ctx), '$ctx.updatedAt'),
      );
      if (!ruleIds.add(r.id)) {
        throw BackupValidationError('定期ルールID ${r.id} が重複しています');
      }
      if (!catIds.contains(r.categoryId)) {
        throw BackupValidationError(
            '$ctx.categoryId ${r.categoryId} が同梱カテゴリに解決できません');
      }
      recurringRules.add(r);
    }

    // --- choreTasks / choreRecords（v5） ---
    final choreTasksRaw = req<List<dynamic>>(root, 'choreTasks', 'root');
    final choreTasks = <BackupChoreTask>[];
    final choreTaskIds = <int>{};
    for (final (i, raw) in choreTasksRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('choreTasks[$i] がオブジェクトではありません');
      }
      final ctx = 'choreTasks[$i]';
      final name = req<String>(raw, 'name', ctx);
      if (name.isEmpty) {
        throw BackupValidationError('$ctx.name が空です');
      }
      final dayOfMonth = req<int>(raw, 'dayOfMonth', ctx);
      if (dayOfMonth < 1 || dayOfMonth > 31) {
        throw BackupValidationError('$ctx.dayOfMonth が範囲外です: $dayOfMonth');
      }
      final intervalDays = req<int>(raw, 'intervalDays', ctx);
      if (intervalDays < kChoreIntervalMin ||
          intervalDays > kChoreIntervalMax) {
        throw BackupValidationError(
            '$ctx.intervalDays が範囲外です: $intervalDays');
      }
      final unitRaw = req<String>(raw, 'repeatUnit', ctx);
      final repeatUnit = ChoreRepeatUnit.values
          .where((u) => u.name == unitRaw)
          .firstOrNull;
      if (repeatUnit == null) {
        throw BackupValidationError('$ctx.repeatUnit が不正です: "$unitRaw"');
      }
      final anchorRaw = req<String>(raw, 'anchorDate', ctx);
      final CivilDate anchorDate;
      try {
        anchorDate = CivilDate.parse(anchorRaw);
      } on FormatException {
        throw BackupValidationError('$ctx.anchorDate が不正な日付です: "$anchorRaw"');
      }
      final t = BackupChoreTask(
        id: req<int>(raw, 'id', ctx),
        name: name,
        emoji: req<String>(raw, 'emoji', ctx),
        repeatUnit: repeatUnit,
        dayOfMonth: dayOfMonth,
        intervalDays: intervalDays,
        anchorDate: anchorDate,
        archived: req<bool>(raw, 'archived', ctx),
        createdAt: instant(req<String>(raw, 'createdAt', ctx), '$ctx.createdAt'),
      );
      if (!choreTaskIds.add(t.id)) {
        throw BackupValidationError('つきいちタスクID ${t.id} が重複しています');
      }
      choreTasks.add(t);
    }

    final choreRecordsRaw = req<List<dynamic>>(root, 'choreRecords', 'root');
    final choreRecords = <BackupChoreRecord>[];
    final choreRecordIds = <int>{};
    for (final (i, raw) in choreRecordsRaw.indexed) {
      if (raw is! Map<String, dynamic>) {
        throw BackupFormatError('choreRecords[$i] がオブジェクトではありません');
      }
      final ctx = 'choreRecords[$i]';
      final doneRaw = req<String>(raw, 'doneDate', ctx);
      final CivilDate doneDate;
      try {
        doneDate = CivilDate.parse(doneRaw);
      } on FormatException {
        throw BackupValidationError('$ctx.doneDate が不正な日付です: "$doneRaw"');
      }
      final r = BackupChoreRecord(
        id: req<int>(raw, 'id', ctx),
        taskId: req<int>(raw, 'taskId', ctx),
        doneDate: doneDate,
        memo: req<String>(raw, 'memo', ctx),
        createdAt: instant(req<String>(raw, 'createdAt', ctx), '$ctx.createdAt'),
      );
      if (!choreRecordIds.add(r.id)) {
        throw BackupValidationError('つきいち記録ID ${r.id} が重複しています');
      }
      if (!choreTaskIds.contains(r.taskId)) {
        throw BackupValidationError(
            '$ctx.taskId ${r.taskId} が同梱タスクに解決できません');
      }
      choreRecords.add(r);
    }

    return BackupPayload(
      formatVersion: formatVersion, // マイグレーション後は常に現行
      exportedAt: exportedAt,
      categories: categories,
      transactions: transactions,
      recurringRules: recurringRules,
      choreTasks: choreTasks,
      choreRecords: choreRecords,
    );
  }

  /// 古いバックアップを現行形式へ順送りに変換する。
  Map<String, dynamic> _migrate(Map<String, dynamic> root, {required int from}) {
    var v = from;
    var m = root;
    while (v < formatVersion) {
      switch (v) {
        case 1:
          m = _migrateV1toV2(m);
        case 2:
          m = _migrateV2toV3(m);
        case 3:
          m = _migrateV3toV4(m);
        case 4:
          m = _migrateV4toV5(m);
        case 5:
          m = _migrateV5toV6(m);
        case 6:
          m = _migrateV6toV7(m);
        default:
          throw BackupVersionError('formatVersion $v からの移行手順がありません');
      }
      v++;
    }
    return m;
  }

  /// v1→v2: categories に parentId を補完（v1は全て親＝null）。
  Map<String, dynamic> _migrateV1toV2(Map<String, dynamic> root) {
    final cats = root['categories'];
    if (cats is List) {
      for (final c in cats) {
        if (c is Map<String, dynamic>) c.putIfAbsent('parentId', () => null);
      }
    }
    return root;
  }

  /// v2→v3: categories に slug を補完（旧バックアップのシード行は名前からは
  /// 復元しない＝null。slug無しでもDBのマイグレーションで再付与される）。
  Map<String, dynamic> _migrateV2toV3(Map<String, dynamic> root) {
    final cats = root['categories'];
    if (cats is List) {
      for (final c in cats) {
        if (c is Map<String, dynamic>) c.putIfAbsent('slug', () => null);
      }
    }
    return root;
  }

  /// v3→v4: recurringRules を空で補完（旧バックアップに定期ルールは無い）。
  Map<String, dynamic> _migrateV3toV4(Map<String, dynamic> root) {
    root.putIfAbsent('recurringRules', () => <dynamic>[]);
    return root;
  }

  /// v4→v5: choreTasks / choreRecords を空で補完
  /// （旧バックアップにつきいちタスクは無い）。
  Map<String, dynamic> _migrateV4toV5(Map<String, dynamic> root) {
    root.putIfAbsent('choreTasks', () => <dynamic>[]);
    root.putIfAbsent('choreRecords', () => <dynamic>[]);
    return root;
  }

  /// v5→v6: つきいちタスクに「毎月N日」を追加。v5は「N日ごと」しか無いので、
  /// 次回期日（anchorDate + intervalDays）の「日」を毎月の予定日の初期値にする
  /// （DBスキーマ v7→v9 と同じ規則）。intervalDays は残し、v6→v7 が
  /// 「N日ごと」だったことの目印に使う。不正値は後段の検証に任せる。
  Map<String, dynamic> _migrateV5toV6(Map<String, dynamic> root) {
    final tasks = root['choreTasks'];
    if (tasks is List) {
      for (final t in tasks) {
        if (t is! Map<String, dynamic>) continue;
        final interval = t['intervalDays'];
        final anchorRaw = t['anchorDate'];
        var day = 1;
        if (interval is int && interval >= 1 && anchorRaw is String) {
          try {
            day = CivilDate.parse(anchorRaw).addDays(interval).day;
          } on FormatException {
            // anchorDate不正はデコード時のvalidationで拒否される。dayは仮値。
          }
        }
        t['dayOfMonth'] = day;
      }
    }
    return root;
  }

  /// v6→v7: 繰り返し方を明示する。intervalDays が残っていれば v5以前＝
  /// 「N日ごと」だったバックアップなので everyDays として復元し、
  /// 無ければ v6（毎月N日のみ）なので monthlyDay ＋既定間隔で補う。
  Map<String, dynamic> _migrateV6toV7(Map<String, dynamic> root) {
    final tasks = root['choreTasks'];
    if (tasks is List) {
      for (final t in tasks) {
        if (t is! Map<String, dynamic>) continue;
        final interval = t['intervalDays'];
        final wasInterval = interval is int && interval >= kChoreIntervalMin;
        t['repeatUnit'] = wasInterval
            ? ChoreRepeatUnit.everyDays.name
            : ChoreRepeatUnit.monthlyDay.name;
        t['intervalDays'] = wasInterval ? interval : 30;
      }
    }
    return root;
  }
}
