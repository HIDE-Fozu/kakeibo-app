// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryType>($CategoriesTable.$convertertype);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    icon,
    sortOrder,
    isArchived,
    isSystem,
    slug,
    parentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $CategoriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryType, String, String> $convertertype =
      const EnumNameConverter<CategoryType>(CategoryType.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sortOrder;
  final bool isArchived;
  final bool isSystem;

  /// 安定キー（シードカテゴリのみ非null）。表示名(name)から独立し、絵文字・
  /// 自動税率・多言語シードの結び付け先になる。ユーザー作成カテゴリはnull。
  /// v5で追加。既存シード行は名前一致でバックフィルする（database.dartのmigration）。
  final String? slug;

  /// 非null=内訳（親カテゴリのid）。階層は2段まで（アプリ側で保証）。
  final int? parentId;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    required this.sortOrder,
    required this.isArchived,
    required this.isSystem,
    this.slug,
    this.parentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_system'] = Variable<bool>(isSystem);
    if (!nullToAbsent || slug != null) {
      map['slug'] = Variable<String>(slug);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      isSystem: Value(isSystem),
      slug: slug == null && nullToAbsent ? const Value.absent() : Value(slug),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $CategoriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      slug: serializer.fromJson<String?>(json['slug']),
      parentId: serializer.fromJson<int?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $CategoriesTable.$convertertype.toJson(type),
      ),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isSystem': serializer.toJson<bool>(isSystem),
      'slug': serializer.toJson<String?>(slug),
      'parentId': serializer.toJson<int?>(parentId),
    };
  }

  CategoryRow copyWith({
    int? id,
    String? name,
    CategoryType? type,
    Value<String?> icon = const Value.absent(),
    int? sortOrder,
    bool? isArchived,
    bool? isSystem,
    Value<String?> slug = const Value.absent(),
    Value<int?> parentId = const Value.absent(),
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    icon: icon.present ? icon.value : this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    isSystem: isSystem ?? this.isSystem,
    slug: slug.present ? slug.value : this.slug,
    parentId: parentId.present ? parentId.value : this.parentId,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      slug: data.slug.present ? data.slug.value : this.slug,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('isSystem: $isSystem, ')
          ..write('slug: $slug, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    icon,
    sortOrder,
    isArchived,
    isSystem,
    slug,
    parentId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.isSystem == this.isSystem &&
          other.slug == this.slug &&
          other.parentId == this.parentId);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<CategoryType> type;
  final Value<String?> icon;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<bool> isSystem;
  final Value<String?> slug;
  final Value<int?> parentId;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.slug = const Value.absent(),
    this.parentId = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required CategoryType type,
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.slug = const Value.absent(),
    this.parentId = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<bool>? isSystem,
    Expression<String>? slug,
    Expression<int>? parentId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (isSystem != null) 'is_system': isSystem,
      if (slug != null) 'slug': slug,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<CategoryType>? type,
    Value<String?>? icon,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<bool>? isSystem,
    Value<String?>? slug,
    Value<int?>? parentId,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      isSystem: isSystem ?? this.isSystem,
      slug: slug ?? this.slug,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type.value),
      );
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('isSystem: $isSystem, ')
          ..write('slug: $slug, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxnType>($TransactionsTable.$convertertype);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CivilDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CivilDate>($TransactionsTable.$converterdate);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethod?, String>
  paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<PaymentMethod?>($TransactionsTable.$converterpaymentMethodn);
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxnSource>($TransactionsTable.$convertersource);
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _splitGroupIdMeta = const VerificationMeta(
    'splitGroupId',
  );
  @override
  late final GeneratedColumn<String> splitGroupId = GeneratedColumn<String>(
    'split_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    date,
    categoryId,
    paymentMethod,
    storeName,
    memo,
    source,
    imagePath,
    splitGroupId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('split_group_id')) {
      context.handle(
        _splitGroupIdMeta,
        splitGroupId.isAcceptableOrUnknown(
          data['split_group_id']!,
          _splitGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: $TransactionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      paymentMethod: $TransactionsTable.$converterpaymentMethodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_method'],
        ),
      ),
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      source: $TransactionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      splitGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_group_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxnType, String, String> $convertertype =
      const EnumNameConverter<TxnType>(TxnType.values);
  static TypeConverter<CivilDate, String> $converterdate =
      const CivilDateConverter();
  static JsonTypeConverter2<PaymentMethod, String, String>
  $converterpaymentMethod = const EnumNameConverter<PaymentMethod>(
    PaymentMethod.values,
  );
  static JsonTypeConverter2<PaymentMethod?, String?, String?>
  $converterpaymentMethodn = JsonTypeConverter2.asNullable(
    $converterpaymentMethod,
  );
  static JsonTypeConverter2<TxnSource, String, String> $convertersource =
      const EnumNameConverter<TxnSource>(TxnSource.values);
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final TxnType type;
  final int amount;
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;

  /// 店舗名。v4でmemoから分離（memoは自由記述の詳細専用に）。null=未設定。
  final String? storeName;
  final String? memo;
  final TxnSource source;
  final String? imagePath;

  /// 同じレシート（詳細入力の1回）から生まれた取引を束ねるID。null=単独取引。
  /// v3で追加。日別一覧のグループカード表示と「詳細入力で開き直す」に使う。
  final String? splitGroupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.paymentMethod,
    this.storeName,
    this.memo,
    required this.source,
    this.imagePath,
    this.splitGroupId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount'] = Variable<int>(amount);
    {
      map['date'] = Variable<String>(
        $TransactionsTable.$converterdate.toSql(date),
      );
    }
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(
        $TransactionsTable.$converterpaymentMethodn.toSql(paymentMethod),
      );
    }
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    {
      map['source'] = Variable<String>(
        $TransactionsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || splitGroupId != null) {
      map['split_group_id'] = Variable<String>(splitGroupId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      date: Value(date),
      categoryId: Value(categoryId),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      source: Value(source),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      splitGroupId: splitGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(splitGroupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<CivilDate>(json['date']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      paymentMethod: $TransactionsTable.$converterpaymentMethodn.fromJson(
        serializer.fromJson<String?>(json['paymentMethod']),
      ),
      storeName: serializer.fromJson<String?>(json['storeName']),
      memo: serializer.fromJson<String?>(json['memo']),
      source: $TransactionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      splitGroupId: serializer.fromJson<String?>(json['splitGroupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<CivilDate>(date),
      'categoryId': serializer.toJson<int>(categoryId),
      'paymentMethod': serializer.toJson<String?>(
        $TransactionsTable.$converterpaymentMethodn.toJson(paymentMethod),
      ),
      'storeName': serializer.toJson<String?>(storeName),
      'memo': serializer.toJson<String?>(memo),
      'source': serializer.toJson<String>(
        $TransactionsTable.$convertersource.toJson(source),
      ),
      'imagePath': serializer.toJson<String?>(imagePath),
      'splitGroupId': serializer.toJson<String?>(splitGroupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    TxnType? type,
    int? amount,
    CivilDate? date,
    int? categoryId,
    Value<PaymentMethod?> paymentMethod = const Value.absent(),
    Value<String?> storeName = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    TxnSource? source,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> splitGroupId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    storeName: storeName.present ? storeName.value : this.storeName,
    memo: memo.present ? memo.value : this.memo,
    source: source ?? this.source,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    splitGroupId: splitGroupId.present ? splitGroupId.value : this.splitGroupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      memo: data.memo.present ? data.memo.value : this.memo,
      source: data.source.present ? data.source.value : this.source,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      splitGroupId: data.splitGroupId.present
          ? data.splitGroupId.value
          : this.splitGroupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('storeName: $storeName, ')
          ..write('memo: $memo, ')
          ..write('source: $source, ')
          ..write('imagePath: $imagePath, ')
          ..write('splitGroupId: $splitGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    date,
    categoryId,
    paymentMethod,
    storeName,
    memo,
    source,
    imagePath,
    splitGroupId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.categoryId == this.categoryId &&
          other.paymentMethod == this.paymentMethod &&
          other.storeName == this.storeName &&
          other.memo == this.memo &&
          other.source == this.source &&
          other.imagePath == this.imagePath &&
          other.splitGroupId == this.splitGroupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<TxnType> type;
  final Value<int> amount;
  final Value<CivilDate> date;
  final Value<int> categoryId;
  final Value<PaymentMethod?> paymentMethod;
  final Value<String?> storeName;
  final Value<String?> memo;
  final Value<TxnSource> source;
  final Value<String?> imagePath;
  final Value<String?> splitGroupId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.storeName = const Value.absent(),
    this.memo = const Value.absent(),
    this.source = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.splitGroupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required TxnType type,
    required int amount,
    required CivilDate date,
    required int categoryId,
    this.paymentMethod = const Value.absent(),
    this.storeName = const Value.absent(),
    this.memo = const Value.absent(),
    required TxnSource source,
    this.imagePath = const Value.absent(),
    this.splitGroupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : type = Value(type),
       amount = Value(amount),
       date = Value(date),
       categoryId = Value(categoryId),
       source = Value(source);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? date,
    Expression<int>? categoryId,
    Expression<String>? paymentMethod,
    Expression<String>? storeName,
    Expression<String>? memo,
    Expression<String>? source,
    Expression<String>? imagePath,
    Expression<String>? splitGroupId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (categoryId != null) 'category_id': categoryId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (storeName != null) 'store_name': storeName,
      if (memo != null) 'memo': memo,
      if (source != null) 'source': source,
      if (imagePath != null) 'image_path': imagePath,
      if (splitGroupId != null) 'split_group_id': splitGroupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<TxnType>? type,
    Value<int>? amount,
    Value<CivilDate>? date,
    Value<int>? categoryId,
    Value<PaymentMethod?>? paymentMethod,
    Value<String?>? storeName,
    Value<String?>? memo,
    Value<TxnSource>? source,
    Value<String?>? imagePath,
    Value<String?>? splitGroupId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      storeName: storeName ?? this.storeName,
      memo: memo ?? this.memo,
      source: source ?? this.source,
      imagePath: imagePath ?? this.imagePath,
      splitGroupId: splitGroupId ?? this.splitGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $TransactionsTable.$converterdate.toSql(date.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(
        $TransactionsTable.$converterpaymentMethodn.toSql(paymentMethod.value),
      );
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $TransactionsTable.$convertersource.toSql(source.value),
      );
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (splitGroupId.present) {
      map['split_group_id'] = Variable<String>(splitGroupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('storeName: $storeName, ')
          ..write('memo: $memo, ')
          ..write('source: $source, ')
          ..write('imagePath: $imagePath, ')
          ..write('splitGroupId: $splitGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RecurringRulesTable extends RecurringRules
    with TableInfo<$RecurringRulesTable, RecurringRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxnType>($RecurringRulesTable.$convertertype);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _startYmMeta = const VerificationMeta(
    'startYm',
  );
  @override
  late final GeneratedColumn<int> startYm = GeneratedColumn<int>(
    'start_ym',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endYmMeta = const VerificationMeta('endYm');
  @override
  late final GeneratedColumn<int> endYm = GeneratedColumn<int>(
    'end_ym',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastGeneratedYmMeta = const VerificationMeta(
    'lastGeneratedYm',
  );
  @override
  late final GeneratedColumn<int> lastGeneratedYm = GeneratedColumn<int>(
    'last_generated_ym',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    categoryId,
    dayOfMonth,
    storeName,
    memo,
    isActive,
    startYm,
    endYm,
    lastGeneratedYm,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('start_ym')) {
      context.handle(
        _startYmMeta,
        startYm.isAcceptableOrUnknown(data['start_ym']!, _startYmMeta),
      );
    } else if (isInserting) {
      context.missing(_startYmMeta);
    }
    if (data.containsKey('end_ym')) {
      context.handle(
        _endYmMeta,
        endYm.isAcceptableOrUnknown(data['end_ym']!, _endYmMeta),
      );
    }
    if (data.containsKey('last_generated_ym')) {
      context.handle(
        _lastGeneratedYmMeta,
        lastGeneratedYm.isAcceptableOrUnknown(
          data['last_generated_ym']!,
          _lastGeneratedYmMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $RecurringRulesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      startYm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ym'],
      )!,
      endYm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ym'],
      ),
      lastGeneratedYm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_generated_ym'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecurringRulesTable createAlias(String alias) {
    return $RecurringRulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxnType, String, String> $convertertype =
      const EnumNameConverter<TxnType>(TxnType.values);
}

class RecurringRuleRow extends DataClass
    implements Insertable<RecurringRuleRow> {
  final int id;
  final TxnType type;
  final int amount;
  final int categoryId;

  /// 毎月の起票日 1..31。短い月は末日に丸める（31日→2月は28/29日）。
  final int dayOfMonth;
  final String? storeName;
  final String? memo;

  /// false=一時停止（起票しない）。停止中も lastGeneratedYm は進めず、
  /// 再開時に停止期間分をさかのぼって起票しない（applyDue 参照）。
  final bool isActive;

  /// 起票を開始する月（YYYY*100+MM。例: 2026年8月=202608）。
  final int startYm;

  /// 起票する最後の月（両端含む）。null=無期限。
  final int? endYm;

  /// 最後に起票した月。null=まだ一度も起票していない。
  final int? lastGeneratedYm;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecurringRuleRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.dayOfMonth,
    this.storeName,
    this.memo,
    required this.isActive,
    required this.startYm,
    this.endYm,
    this.lastGeneratedYm,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>(
        $RecurringRulesTable.$convertertype.toSql(type),
      );
    }
    map['amount'] = Variable<int>(amount);
    map['category_id'] = Variable<int>(categoryId);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['start_ym'] = Variable<int>(startYm);
    if (!nullToAbsent || endYm != null) {
      map['end_ym'] = Variable<int>(endYm);
    }
    if (!nullToAbsent || lastGeneratedYm != null) {
      map['last_generated_ym'] = Variable<int>(lastGeneratedYm);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecurringRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurringRulesCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      categoryId: Value(categoryId),
      dayOfMonth: Value(dayOfMonth),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      isActive: Value(isActive),
      startYm: Value(startYm),
      endYm: endYm == null && nullToAbsent
          ? const Value.absent()
          : Value(endYm),
      lastGeneratedYm: lastGeneratedYm == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGeneratedYm),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecurringRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringRuleRow(
      id: serializer.fromJson<int>(json['id']),
      type: $RecurringRulesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      memo: serializer.fromJson<String?>(json['memo']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      startYm: serializer.fromJson<int>(json['startYm']),
      endYm: serializer.fromJson<int?>(json['endYm']),
      lastGeneratedYm: serializer.fromJson<int?>(json['lastGeneratedYm']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $RecurringRulesTable.$convertertype.toJson(type),
      ),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<int>(categoryId),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'storeName': serializer.toJson<String?>(storeName),
      'memo': serializer.toJson<String?>(memo),
      'isActive': serializer.toJson<bool>(isActive),
      'startYm': serializer.toJson<int>(startYm),
      'endYm': serializer.toJson<int?>(endYm),
      'lastGeneratedYm': serializer.toJson<int?>(lastGeneratedYm),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecurringRuleRow copyWith({
    int? id,
    TxnType? type,
    int? amount,
    int? categoryId,
    int? dayOfMonth,
    Value<String?> storeName = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    bool? isActive,
    int? startYm,
    Value<int?> endYm = const Value.absent(),
    Value<int?> lastGeneratedYm = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecurringRuleRow(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    storeName: storeName.present ? storeName.value : this.storeName,
    memo: memo.present ? memo.value : this.memo,
    isActive: isActive ?? this.isActive,
    startYm: startYm ?? this.startYm,
    endYm: endYm.present ? endYm.value : this.endYm,
    lastGeneratedYm: lastGeneratedYm.present
        ? lastGeneratedYm.value
        : this.lastGeneratedYm,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecurringRuleRow copyWithCompanion(RecurringRulesCompanion data) {
    return RecurringRuleRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      memo: data.memo.present ? data.memo.value : this.memo,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      startYm: data.startYm.present ? data.startYm.value : this.startYm,
      endYm: data.endYm.present ? data.endYm.value : this.endYm,
      lastGeneratedYm: data.lastGeneratedYm.present
          ? data.lastGeneratedYm.value
          : this.lastGeneratedYm,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRuleRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('storeName: $storeName, ')
          ..write('memo: $memo, ')
          ..write('isActive: $isActive, ')
          ..write('startYm: $startYm, ')
          ..write('endYm: $endYm, ')
          ..write('lastGeneratedYm: $lastGeneratedYm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    categoryId,
    dayOfMonth,
    storeName,
    memo,
    isActive,
    startYm,
    endYm,
    lastGeneratedYm,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringRuleRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.dayOfMonth == this.dayOfMonth &&
          other.storeName == this.storeName &&
          other.memo == this.memo &&
          other.isActive == this.isActive &&
          other.startYm == this.startYm &&
          other.endYm == this.endYm &&
          other.lastGeneratedYm == this.lastGeneratedYm &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecurringRulesCompanion extends UpdateCompanion<RecurringRuleRow> {
  final Value<int> id;
  final Value<TxnType> type;
  final Value<int> amount;
  final Value<int> categoryId;
  final Value<int> dayOfMonth;
  final Value<String?> storeName;
  final Value<String?> memo;
  final Value<bool> isActive;
  final Value<int> startYm;
  final Value<int?> endYm;
  final Value<int?> lastGeneratedYm;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RecurringRulesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.storeName = const Value.absent(),
    this.memo = const Value.absent(),
    this.isActive = const Value.absent(),
    this.startYm = const Value.absent(),
    this.endYm = const Value.absent(),
    this.lastGeneratedYm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecurringRulesCompanion.insert({
    this.id = const Value.absent(),
    required TxnType type,
    required int amount,
    required int categoryId,
    required int dayOfMonth,
    this.storeName = const Value.absent(),
    this.memo = const Value.absent(),
    this.isActive = const Value.absent(),
    required int startYm,
    this.endYm = const Value.absent(),
    this.lastGeneratedYm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : type = Value(type),
       amount = Value(amount),
       categoryId = Value(categoryId),
       dayOfMonth = Value(dayOfMonth),
       startYm = Value(startYm);
  static Insertable<RecurringRuleRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<int>? categoryId,
    Expression<int>? dayOfMonth,
    Expression<String>? storeName,
    Expression<String>? memo,
    Expression<bool>? isActive,
    Expression<int>? startYm,
    Expression<int>? endYm,
    Expression<int>? lastGeneratedYm,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (storeName != null) 'store_name': storeName,
      if (memo != null) 'memo': memo,
      if (isActive != null) 'is_active': isActive,
      if (startYm != null) 'start_ym': startYm,
      if (endYm != null) 'end_ym': endYm,
      if (lastGeneratedYm != null) 'last_generated_ym': lastGeneratedYm,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecurringRulesCompanion copyWith({
    Value<int>? id,
    Value<TxnType>? type,
    Value<int>? amount,
    Value<int>? categoryId,
    Value<int>? dayOfMonth,
    Value<String?>? storeName,
    Value<String?>? memo,
    Value<bool>? isActive,
    Value<int>? startYm,
    Value<int?>? endYm,
    Value<int?>? lastGeneratedYm,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RecurringRulesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      storeName: storeName ?? this.storeName,
      memo: memo ?? this.memo,
      isActive: isActive ?? this.isActive,
      startYm: startYm ?? this.startYm,
      endYm: endYm ?? this.endYm,
      lastGeneratedYm: lastGeneratedYm ?? this.lastGeneratedYm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $RecurringRulesTable.$convertertype.toSql(type.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (startYm.present) {
      map['start_ym'] = Variable<int>(startYm.value);
    }
    if (endYm.present) {
      map['end_ym'] = Variable<int>(endYm.value);
    }
    if (lastGeneratedYm.present) {
      map['last_generated_ym'] = Variable<int>(lastGeneratedYm.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRulesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('storeName: $storeName, ')
          ..write('memo: $memo, ')
          ..write('isActive: $isActive, ')
          ..write('startYm: $startYm, ')
          ..write('endYm: $endYm, ')
          ..write('lastGeneratedYm: $lastGeneratedYm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ChoreTasksTable extends ChoreTasks
    with TableInfo<$ChoreTasksTable, ChoreTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoreTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('📌'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChoreRepeatUnit, String>
  repeatUnit = GeneratedColumn<String>(
    'repeat_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthlyDay'),
  ).withConverter<ChoreRepeatUnit>($ChoreTasksTable.$converterrepeatUnit);
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CivilDate, String> anchorDate =
      GeneratedColumn<String>(
        'anchor_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CivilDate>($ChoreTasksTable.$converteranchorDate);
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    emoji,
    repeatUnit,
    dayOfMonth,
    intervalDays,
    anchorDate,
    archived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chore_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChoreTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChoreTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChoreTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      repeatUnit: $ChoreTasksTable.$converterrepeatUnit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat_unit'],
        )!,
      ),
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      anchorDate: $ChoreTasksTable.$converteranchorDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}anchor_date'],
        )!,
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChoreTasksTable createAlias(String alias) {
    return $ChoreTasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChoreRepeatUnit, String, String>
  $converterrepeatUnit = const EnumNameConverter<ChoreRepeatUnit>(
    ChoreRepeatUnit.values,
  );
  static TypeConverter<CivilDate, String> $converteranchorDate =
      const CivilDateConverter();
}

class ChoreTaskRow extends DataClass implements Insertable<ChoreTaskRow> {
  final int id;
  final String name;
  final String emoji;

  /// 繰り返し方（v9で追加）。monthlyDay=毎月N日 / everyDays=N日ごと。
  final ChoreRepeatUnit repeatUnit;
  final int dayOfMonth;

  /// N日ごとの間隔 1..999（v7の interval_days を v9で復活）。
  final int intervalDays;
  final CivilDate anchorDate;
  final bool archived;
  final DateTime createdAt;
  const ChoreTaskRow({
    required this.id,
    required this.name,
    required this.emoji,
    required this.repeatUnit,
    required this.dayOfMonth,
    required this.intervalDays,
    required this.anchorDate,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    {
      map['repeat_unit'] = Variable<String>(
        $ChoreTasksTable.$converterrepeatUnit.toSql(repeatUnit),
      );
    }
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['interval_days'] = Variable<int>(intervalDays);
    {
      map['anchor_date'] = Variable<String>(
        $ChoreTasksTable.$converteranchorDate.toSql(anchorDate),
      );
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChoreTasksCompanion toCompanion(bool nullToAbsent) {
    return ChoreTasksCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      repeatUnit: Value(repeatUnit),
      dayOfMonth: Value(dayOfMonth),
      intervalDays: Value(intervalDays),
      anchorDate: Value(anchorDate),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory ChoreTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChoreTaskRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      repeatUnit: $ChoreTasksTable.$converterrepeatUnit.fromJson(
        serializer.fromJson<String>(json['repeatUnit']),
      ),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      anchorDate: serializer.fromJson<CivilDate>(json['anchorDate']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'repeatUnit': serializer.toJson<String>(
        $ChoreTasksTable.$converterrepeatUnit.toJson(repeatUnit),
      ),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'anchorDate': serializer.toJson<CivilDate>(anchorDate),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChoreTaskRow copyWith({
    int? id,
    String? name,
    String? emoji,
    ChoreRepeatUnit? repeatUnit,
    int? dayOfMonth,
    int? intervalDays,
    CivilDate? anchorDate,
    bool? archived,
    DateTime? createdAt,
  }) => ChoreTaskRow(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    repeatUnit: repeatUnit ?? this.repeatUnit,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    intervalDays: intervalDays ?? this.intervalDays,
    anchorDate: anchorDate ?? this.anchorDate,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  ChoreTaskRow copyWithCompanion(ChoreTasksCompanion data) {
    return ChoreTaskRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      repeatUnit: data.repeatUnit.present
          ? data.repeatUnit.value
          : this.repeatUnit,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      anchorDate: data.anchorDate.present
          ? data.anchorDate.value
          : this.anchorDate,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChoreTaskRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('repeatUnit: $repeatUnit, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    emoji,
    repeatUnit,
    dayOfMonth,
    intervalDays,
    anchorDate,
    archived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChoreTaskRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.repeatUnit == this.repeatUnit &&
          other.dayOfMonth == this.dayOfMonth &&
          other.intervalDays == this.intervalDays &&
          other.anchorDate == this.anchorDate &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class ChoreTasksCompanion extends UpdateCompanion<ChoreTaskRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<ChoreRepeatUnit> repeatUnit;
  final Value<int> dayOfMonth;
  final Value<int> intervalDays;
  final Value<CivilDate> anchorDate;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  const ChoreTasksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.repeatUnit = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.anchorDate = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChoreTasksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.emoji = const Value.absent(),
    this.repeatUnit = const Value.absent(),
    required int dayOfMonth,
    this.intervalDays = const Value.absent(),
    required CivilDate anchorDate,
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       dayOfMonth = Value(dayOfMonth),
       anchorDate = Value(anchorDate);
  static Insertable<ChoreTaskRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<String>? repeatUnit,
    Expression<int>? dayOfMonth,
    Expression<int>? intervalDays,
    Expression<String>? anchorDate,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (repeatUnit != null) 'repeat_unit': repeatUnit,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (anchorDate != null) 'anchor_date': anchorDate,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChoreTasksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? emoji,
    Value<ChoreRepeatUnit>? repeatUnit,
    Value<int>? dayOfMonth,
    Value<int>? intervalDays,
    Value<CivilDate>? anchorDate,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
  }) {
    return ChoreTasksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      repeatUnit: repeatUnit ?? this.repeatUnit,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      intervalDays: intervalDays ?? this.intervalDays,
      anchorDate: anchorDate ?? this.anchorDate,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (repeatUnit.present) {
      map['repeat_unit'] = Variable<String>(
        $ChoreTasksTable.$converterrepeatUnit.toSql(repeatUnit.value),
      );
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (anchorDate.present) {
      map['anchor_date'] = Variable<String>(
        $ChoreTasksTable.$converteranchorDate.toSql(anchorDate.value),
      );
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoreTasksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('repeatUnit: $repeatUnit, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ChoreRecordsTable extends ChoreRecords
    with TableInfo<$ChoreRecordsTable, ChoreRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoreRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chore_tasks (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CivilDate, String> doneDate =
      GeneratedColumn<String>(
        'done_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CivilDate>($ChoreRecordsTable.$converterdoneDate);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, taskId, doneDate, memo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chore_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChoreRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChoreRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChoreRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      doneDate: $ChoreRecordsTable.$converterdoneDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}done_date'],
        )!,
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChoreRecordsTable createAlias(String alias) {
    return $ChoreRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<CivilDate, String> $converterdoneDate =
      const CivilDateConverter();
}

class ChoreRecordRow extends DataClass implements Insertable<ChoreRecordRow> {
  final int id;
  final int taskId;
  final CivilDate doneDate;
  final String memo;
  final DateTime createdAt;
  const ChoreRecordRow({
    required this.id,
    required this.taskId,
    required this.doneDate,
    required this.memo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    {
      map['done_date'] = Variable<String>(
        $ChoreRecordsTable.$converterdoneDate.toSql(doneDate),
      );
    }
    map['memo'] = Variable<String>(memo);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChoreRecordsCompanion toCompanion(bool nullToAbsent) {
    return ChoreRecordsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      doneDate: Value(doneDate),
      memo: Value(memo),
      createdAt: Value(createdAt),
    );
  }

  factory ChoreRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChoreRecordRow(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      doneDate: serializer.fromJson<CivilDate>(json['doneDate']),
      memo: serializer.fromJson<String>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'doneDate': serializer.toJson<CivilDate>(doneDate),
      'memo': serializer.toJson<String>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChoreRecordRow copyWith({
    int? id,
    int? taskId,
    CivilDate? doneDate,
    String? memo,
    DateTime? createdAt,
  }) => ChoreRecordRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    doneDate: doneDate ?? this.doneDate,
    memo: memo ?? this.memo,
    createdAt: createdAt ?? this.createdAt,
  );
  ChoreRecordRow copyWithCompanion(ChoreRecordsCompanion data) {
    return ChoreRecordRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      doneDate: data.doneDate.present ? data.doneDate.value : this.doneDate,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChoreRecordRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('doneDate: $doneDate, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, doneDate, memo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChoreRecordRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.doneDate == this.doneDate &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt);
}

class ChoreRecordsCompanion extends UpdateCompanion<ChoreRecordRow> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<CivilDate> doneDate;
  final Value<String> memo;
  final Value<DateTime> createdAt;
  const ChoreRecordsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.doneDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChoreRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required CivilDate doneDate,
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : taskId = Value(taskId),
       doneDate = Value(doneDate);
  static Insertable<ChoreRecordRow> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? doneDate,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (doneDate != null) 'done_date': doneDate,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChoreRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<CivilDate>? doneDate,
    Value<String>? memo,
    Value<DateTime>? createdAt,
  }) {
    return ChoreRecordsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      doneDate: doneDate ?? this.doneDate,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (doneDate.present) {
      map['done_date'] = Variable<String>(
        $ChoreRecordsTable.$converterdoneDate.toSql(doneDate.value),
      );
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoreRecordsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('doneDate: $doneDate, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RecurringRulesTable recurringRules = $RecurringRulesTable(this);
  late final $ChoreTasksTable choreTasks = $ChoreTasksTable(this);
  late final $ChoreRecordsTable choreRecords = $ChoreRecordsTable(this);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final TransactionDao transactionDao = TransactionDao(
    this as AppDatabase,
  );
  late final RecurringRuleDao recurringRuleDao = RecurringRuleDao(
    this as AppDatabase,
  );
  late final ChoreDao choreDao = ChoreDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    transactions,
    recurringRules,
    choreTasks,
    choreRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chore_tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chore_records', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      required CategoryType type,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<bool> isSystem,
      Value<String?> slug,
      Value<int?> parentId,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<CategoryType> type,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<bool> isSystem,
      Value<String?> slug,
      Value<int?> parentId,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias('categories__parent_id__categories__id');

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecurringRulesTable, List<RecurringRuleRow>>
  _recurringRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurringRules,
    aliasName: 'categories__id__recurring_rules__category_id',
  );

  $$RecurringRulesTableProcessedTableManager get recurringRulesRefs {
    final manager = $$RecurringRulesTableTableManager(
      $_db,
      $_db.recurringRules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryType, CategoryType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recurringRulesRefs(
    Expression<bool> Function($$RecurringRulesTableFilterComposer f) f,
  ) {
    final $$RecurringRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableFilterComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recurringRulesRefs<T extends Object>(
    Expression<T> Function($$RecurringRulesTableAnnotationComposer a) f,
  ) {
    final $$RecurringRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool parentId,
            bool transactionsRefs,
            bool recurringRulesRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                type: type,
                icon: icon,
                sortOrder: sortOrder,
                isArchived: isArchived,
                isSystem: isSystem,
                slug: slug,
                parentId: parentId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required CategoryType type,
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                type: type,
                icon: icon,
                sortOrder: sortOrder,
                isArchived: isArchived,
                isSystem: isSystem,
                slug: slug,
                parentId: parentId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                transactionsRefs = false,
                recurringRulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (recurringRulesRefs) db.recurringRules,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$CategoriesTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recurringRulesRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          RecurringRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._recurringRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool parentId,
        bool transactionsRefs,
        bool recurringRulesRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required TxnType type,
      required int amount,
      required CivilDate date,
      required int categoryId,
      Value<PaymentMethod?> paymentMethod,
      Value<String?> storeName,
      Value<String?> memo,
      required TxnSource source,
      Value<String?> imagePath,
      Value<String?> splitGroupId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<TxnType> type,
      Value<int> amount,
      Value<CivilDate> date,
      Value<int> categoryId,
      Value<PaymentMethod?> paymentMethod,
      Value<String?> storeName,
      Value<String?> memo,
      Value<TxnSource> source,
      Value<String?> imagePath,
      Value<String?> splitGroupId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxnType, TxnType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CivilDate, CivilDate, String> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PaymentMethod?, PaymentMethod, String>
  get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxnSource, TxnSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitGroupId => $composableBuilder(
    column: $table.splitGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitGroupId => $composableBuilder(
    column: $table.splitGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CivilDate, String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PaymentMethod?, String> get paymentMethod =>
      $composableBuilder(
        column: $table.paymentMethod,
        builder: (column) => column,
      );

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get splitGroupId => $composableBuilder(
    column: $table.splitGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<TxnType> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<CivilDate> date = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<PaymentMethod?> paymentMethod = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<TxnSource> source = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> splitGroupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amount: amount,
                date: date,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                storeName: storeName,
                memo: memo,
                source: source,
                imagePath: imagePath,
                splitGroupId: splitGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required TxnType type,
                required int amount,
                required CivilDate date,
                required int categoryId,
                Value<PaymentMethod?> paymentMethod = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required TxnSource source,
                Value<String?> imagePath = const Value.absent(),
                Value<String?> splitGroupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                date: date,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                storeName: storeName,
                memo: memo,
                source: source,
                imagePath: imagePath,
                splitGroupId: splitGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$TransactionsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$RecurringRulesTableCreateCompanionBuilder =
    RecurringRulesCompanion Function({
      Value<int> id,
      required TxnType type,
      required int amount,
      required int categoryId,
      required int dayOfMonth,
      Value<String?> storeName,
      Value<String?> memo,
      Value<bool> isActive,
      required int startYm,
      Value<int?> endYm,
      Value<int?> lastGeneratedYm,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$RecurringRulesTableUpdateCompanionBuilder =
    RecurringRulesCompanion Function({
      Value<int> id,
      Value<TxnType> type,
      Value<int> amount,
      Value<int> categoryId,
      Value<int> dayOfMonth,
      Value<String?> storeName,
      Value<String?> memo,
      Value<bool> isActive,
      Value<int> startYm,
      Value<int?> endYm,
      Value<int?> lastGeneratedYm,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$RecurringRulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRuleRow> {
  $$RecurringRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('recurring_rules__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxnType, TxnType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endYm => $composableBuilder(
    column: $table.endYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastGeneratedYm => $composableBuilder(
    column: $table.lastGeneratedYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endYm => $composableBuilder(
    column: $table.endYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastGeneratedYm => $composableBuilder(
    column: $table.lastGeneratedYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get startYm =>
      $composableBuilder(column: $table.startYm, builder: (column) => column);

  GeneratedColumn<int> get endYm =>
      $composableBuilder(column: $table.endYm, builder: (column) => column);

  GeneratedColumn<int> get lastGeneratedYm => $composableBuilder(
    column: $table.lastGeneratedYm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringRulesTable,
          RecurringRuleRow,
          $$RecurringRulesTableFilterComposer,
          $$RecurringRulesTableOrderingComposer,
          $$RecurringRulesTableAnnotationComposer,
          $$RecurringRulesTableCreateCompanionBuilder,
          $$RecurringRulesTableUpdateCompanionBuilder,
          (RecurringRuleRow, $$RecurringRulesTableReferences),
          RecurringRuleRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$RecurringRulesTableTableManager(
    _$AppDatabase db,
    $RecurringRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<TxnType> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> startYm = const Value.absent(),
                Value<int?> endYm = const Value.absent(),
                Value<int?> lastGeneratedYm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecurringRulesCompanion(
                id: id,
                type: type,
                amount: amount,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                storeName: storeName,
                memo: memo,
                isActive: isActive,
                startYm: startYm,
                endYm: endYm,
                lastGeneratedYm: lastGeneratedYm,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required TxnType type,
                required int amount,
                required int categoryId,
                required int dayOfMonth,
                Value<String?> storeName = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int startYm,
                Value<int?> endYm = const Value.absent(),
                Value<int?> lastGeneratedYm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecurringRulesCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                storeName: storeName,
                memo: memo,
                isActive: isActive,
                startYm: startYm,
                endYm: endYm,
                lastGeneratedYm: lastGeneratedYm,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecurringRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$RecurringRulesTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn:
                                    $$RecurringRulesTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecurringRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringRulesTable,
      RecurringRuleRow,
      $$RecurringRulesTableFilterComposer,
      $$RecurringRulesTableOrderingComposer,
      $$RecurringRulesTableAnnotationComposer,
      $$RecurringRulesTableCreateCompanionBuilder,
      $$RecurringRulesTableUpdateCompanionBuilder,
      (RecurringRuleRow, $$RecurringRulesTableReferences),
      RecurringRuleRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$ChoreTasksTableCreateCompanionBuilder =
    ChoreTasksCompanion Function({
      Value<int> id,
      required String name,
      Value<String> emoji,
      Value<ChoreRepeatUnit> repeatUnit,
      required int dayOfMonth,
      Value<int> intervalDays,
      required CivilDate anchorDate,
      Value<bool> archived,
      Value<DateTime> createdAt,
    });
typedef $$ChoreTasksTableUpdateCompanionBuilder =
    ChoreTasksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> emoji,
      Value<ChoreRepeatUnit> repeatUnit,
      Value<int> dayOfMonth,
      Value<int> intervalDays,
      Value<CivilDate> anchorDate,
      Value<bool> archived,
      Value<DateTime> createdAt,
    });

final class $$ChoreTasksTableReferences
    extends BaseReferences<_$AppDatabase, $ChoreTasksTable, ChoreTaskRow> {
  $$ChoreTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChoreRecordsTable, List<ChoreRecordRow>>
  _choreRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.choreRecords,
    aliasName: 'chore_tasks__id__chore_records__task_id',
  );

  $$ChoreRecordsTableProcessedTableManager get choreRecordsRefs {
    final manager = $$ChoreRecordsTableTableManager(
      $_db,
      $_db.choreRecords,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_choreRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChoreTasksTableFilterComposer
    extends Composer<_$AppDatabase, $ChoreTasksTable> {
  $$ChoreTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChoreRepeatUnit, ChoreRepeatUnit, String>
  get repeatUnit => $composableBuilder(
    column: $table.repeatUnit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CivilDate, CivilDate, String> get anchorDate =>
      $composableBuilder(
        column: $table.anchorDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> choreRecordsRefs(
    Expression<bool> Function($$ChoreRecordsTableFilterComposer f) f,
  ) {
    final $$ChoreRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreRecords,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreRecordsTableFilterComposer(
            $db: $db,
            $table: $db.choreRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChoreTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $ChoreTasksTable> {
  $$ChoreTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatUnit => $composableBuilder(
    column: $table.repeatUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChoreTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChoreTasksTable> {
  $$ChoreTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChoreRepeatUnit, String> get repeatUnit =>
      $composableBuilder(
        column: $table.repeatUnit,
        builder: (column) => column,
      );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CivilDate, String> get anchorDate =>
      $composableBuilder(
        column: $table.anchorDate,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> choreRecordsRefs<T extends Object>(
    Expression<T> Function($$ChoreRecordsTableAnnotationComposer a) f,
  ) {
    final $$ChoreRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreRecords,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.choreRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChoreTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChoreTasksTable,
          ChoreTaskRow,
          $$ChoreTasksTableFilterComposer,
          $$ChoreTasksTableOrderingComposer,
          $$ChoreTasksTableAnnotationComposer,
          $$ChoreTasksTableCreateCompanionBuilder,
          $$ChoreTasksTableUpdateCompanionBuilder,
          (ChoreTaskRow, $$ChoreTasksTableReferences),
          ChoreTaskRow,
          PrefetchHooks Function({bool choreRecordsRefs})
        > {
  $$ChoreTasksTableTableManager(_$AppDatabase db, $ChoreTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoreTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoreTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoreTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<ChoreRepeatUnit> repeatUnit = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<CivilDate> anchorDate = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChoreTasksCompanion(
                id: id,
                name: name,
                emoji: emoji,
                repeatUnit: repeatUnit,
                dayOfMonth: dayOfMonth,
                intervalDays: intervalDays,
                anchorDate: anchorDate,
                archived: archived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> emoji = const Value.absent(),
                Value<ChoreRepeatUnit> repeatUnit = const Value.absent(),
                required int dayOfMonth,
                Value<int> intervalDays = const Value.absent(),
                required CivilDate anchorDate,
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChoreTasksCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                repeatUnit: repeatUnit,
                dayOfMonth: dayOfMonth,
                intervalDays: intervalDays,
                anchorDate: anchorDate,
                archived: archived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChoreTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({choreRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (choreRecordsRefs) db.choreRecords],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (choreRecordsRefs)
                    await $_getPrefetchedData<
                      ChoreTaskRow,
                      $ChoreTasksTable,
                      ChoreRecordRow
                    >(
                      currentTable: table,
                      referencedTable: $$ChoreTasksTableReferences
                          ._choreRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChoreTasksTableReferences(
                            db,
                            table,
                            p0,
                          ).choreRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.taskId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChoreTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChoreTasksTable,
      ChoreTaskRow,
      $$ChoreTasksTableFilterComposer,
      $$ChoreTasksTableOrderingComposer,
      $$ChoreTasksTableAnnotationComposer,
      $$ChoreTasksTableCreateCompanionBuilder,
      $$ChoreTasksTableUpdateCompanionBuilder,
      (ChoreTaskRow, $$ChoreTasksTableReferences),
      ChoreTaskRow,
      PrefetchHooks Function({bool choreRecordsRefs})
    >;
typedef $$ChoreRecordsTableCreateCompanionBuilder =
    ChoreRecordsCompanion Function({
      Value<int> id,
      required int taskId,
      required CivilDate doneDate,
      Value<String> memo,
      Value<DateTime> createdAt,
    });
typedef $$ChoreRecordsTableUpdateCompanionBuilder =
    ChoreRecordsCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<CivilDate> doneDate,
      Value<String> memo,
      Value<DateTime> createdAt,
    });

final class $$ChoreRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ChoreRecordsTable, ChoreRecordRow> {
  $$ChoreRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChoreTasksTable _taskIdTable(_$AppDatabase db) =>
      db.choreTasks.createAlias('chore_records__task_id__chore_tasks__id');

  $$ChoreTasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$ChoreTasksTableTableManager(
      $_db,
      $_db.choreTasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChoreRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ChoreRecordsTable> {
  $$ChoreRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CivilDate, CivilDate, String> get doneDate =>
      $composableBuilder(
        column: $table.doneDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChoreTasksTableFilterComposer get taskId {
    final $$ChoreTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.choreTasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTasksTableFilterComposer(
            $db: $db,
            $table: $db.choreTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChoreRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChoreRecordsTable> {
  $$ChoreRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneDate => $composableBuilder(
    column: $table.doneDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChoreTasksTableOrderingComposer get taskId {
    final $$ChoreTasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.choreTasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTasksTableOrderingComposer(
            $db: $db,
            $table: $db.choreTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChoreRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChoreRecordsTable> {
  $$ChoreRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CivilDate, String> get doneDate =>
      $composableBuilder(column: $table.doneDate, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChoreTasksTableAnnotationComposer get taskId {
    final $$ChoreTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.choreTasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.choreTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChoreRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChoreRecordsTable,
          ChoreRecordRow,
          $$ChoreRecordsTableFilterComposer,
          $$ChoreRecordsTableOrderingComposer,
          $$ChoreRecordsTableAnnotationComposer,
          $$ChoreRecordsTableCreateCompanionBuilder,
          $$ChoreRecordsTableUpdateCompanionBuilder,
          (ChoreRecordRow, $$ChoreRecordsTableReferences),
          ChoreRecordRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$ChoreRecordsTableTableManager(_$AppDatabase db, $ChoreRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoreRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoreRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoreRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<CivilDate> doneDate = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChoreRecordsCompanion(
                id: id,
                taskId: taskId,
                doneDate: doneDate,
                memo: memo,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required CivilDate doneDate,
                Value<String> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChoreRecordsCompanion.insert(
                id: id,
                taskId: taskId,
                doneDate: doneDate,
                memo: memo,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChoreRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$ChoreRecordsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$ChoreRecordsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChoreRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChoreRecordsTable,
      ChoreRecordRow,
      $$ChoreRecordsTableFilterComposer,
      $$ChoreRecordsTableOrderingComposer,
      $$ChoreRecordsTableAnnotationComposer,
      $$ChoreRecordsTableCreateCompanionBuilder,
      $$ChoreRecordsTableUpdateCompanionBuilder,
      (ChoreRecordRow, $$ChoreRecordsTableReferences),
      ChoreRecordRow,
      PrefetchHooks Function({bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(_db, _db.recurringRules);
  $$ChoreTasksTableTableManager get choreTasks =>
      $$ChoreTasksTableTableManager(_db, _db.choreTasks);
  $$ChoreRecordsTableTableManager get choreRecords =>
      $$ChoreRecordsTableTableManager(_db, _db.choreRecords);
}
