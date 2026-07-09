import 'dart:convert';
import 'backup_data.dart';
import '../db/enums.dart';
import '../../domain/money/civil_date.dart';

/// バックアップJSONの直列化と厳格検証。復元の唯一の門番。
class BackupCodec {
  /// バックアップ形式のバージョン。DBのschemaVersionとは独立に管理する。
  /// v2: categories[].parentId（内訳）を追加。
  static const int formatVersion = 2;

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

    return BackupPayload(
      formatVersion: formatVersion, // マイグレーション後は常に現行
      exportedAt: exportedAt,
      categories: categories,
      transactions: transactions,
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
}
