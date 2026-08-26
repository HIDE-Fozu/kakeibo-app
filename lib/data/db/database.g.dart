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

class $InstallmentPlansTable extends InstallmentPlans
    with TableInfo<$InstallmentPlansTable, InstallmentPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentPlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _principalMeta = const VerificationMeta(
    'principal',
  );
  @override
  late final GeneratedColumn<int> principal = GeneratedColumn<int>(
    'principal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annualRatePercentMeta = const VerificationMeta(
    'annualRatePercent',
  );
  @override
  late final GeneratedColumn<double> annualRatePercent =
      GeneratedColumn<double>(
        'annual_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
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
  static const VerificationMeta _cardNameMeta = const VerificationMeta(
    'cardName',
  );
  @override
  late final GeneratedColumn<String> cardName = GeneratedColumn<String>(
    'card_name',
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
    principal,
    count,
    annualRatePercent,
    categoryId,
    dayOfMonth,
    startYm,
    cardName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('principal')) {
      context.handle(
        _principalMeta,
        principal.isAcceptableOrUnknown(data['principal']!, _principalMeta),
      );
    } else if (isInserting) {
      context.missing(_principalMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('annual_rate_percent')) {
      context.handle(
        _annualRatePercentMeta,
        annualRatePercent.isAcceptableOrUnknown(
          data['annual_rate_percent']!,
          _annualRatePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annualRatePercentMeta);
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
    if (data.containsKey('start_ym')) {
      context.handle(
        _startYmMeta,
        startYm.isAcceptableOrUnknown(data['start_ym']!, _startYmMeta),
      );
    } else if (isInserting) {
      context.missing(_startYmMeta);
    }
    if (data.containsKey('card_name')) {
      context.handle(
        _cardNameMeta,
        cardName.isAcceptableOrUnknown(data['card_name']!, _cardNameMeta),
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
  InstallmentPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      principal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      annualRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_rate_percent'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      startYm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ym'],
      )!,
      cardName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_name'],
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
  $InstallmentPlansTable createAlias(String alias) {
    return $InstallmentPlansTable(attachedDatabase, alias);
  }
}

class InstallmentPlanRow extends DataClass
    implements Insertable<InstallmentPlanRow> {
  final int id;
  final int principal;
  final int count;
  final double annualRatePercent;
  final int categoryId;
  final int dayOfMonth;
  final int startYm;
  final String? cardName;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InstallmentPlanRow({
    required this.id,
    required this.principal,
    required this.count,
    required this.annualRatePercent,
    required this.categoryId,
    required this.dayOfMonth,
    required this.startYm,
    this.cardName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['principal'] = Variable<int>(principal);
    map['count'] = Variable<int>(count);
    map['annual_rate_percent'] = Variable<double>(annualRatePercent);
    map['category_id'] = Variable<int>(categoryId);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['start_ym'] = Variable<int>(startYm);
    if (!nullToAbsent || cardName != null) {
      map['card_name'] = Variable<String>(cardName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InstallmentPlansCompanion toCompanion(bool nullToAbsent) {
    return InstallmentPlansCompanion(
      id: Value(id),
      principal: Value(principal),
      count: Value(count),
      annualRatePercent: Value(annualRatePercent),
      categoryId: Value(categoryId),
      dayOfMonth: Value(dayOfMonth),
      startYm: Value(startYm),
      cardName: cardName == null && nullToAbsent
          ? const Value.absent()
          : Value(cardName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InstallmentPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentPlanRow(
      id: serializer.fromJson<int>(json['id']),
      principal: serializer.fromJson<int>(json['principal']),
      count: serializer.fromJson<int>(json['count']),
      annualRatePercent: serializer.fromJson<double>(json['annualRatePercent']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      startYm: serializer.fromJson<int>(json['startYm']),
      cardName: serializer.fromJson<String?>(json['cardName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'principal': serializer.toJson<int>(principal),
      'count': serializer.toJson<int>(count),
      'annualRatePercent': serializer.toJson<double>(annualRatePercent),
      'categoryId': serializer.toJson<int>(categoryId),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'startYm': serializer.toJson<int>(startYm),
      'cardName': serializer.toJson<String?>(cardName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InstallmentPlanRow copyWith({
    int? id,
    int? principal,
    int? count,
    double? annualRatePercent,
    int? categoryId,
    int? dayOfMonth,
    int? startYm,
    Value<String?> cardName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InstallmentPlanRow(
    id: id ?? this.id,
    principal: principal ?? this.principal,
    count: count ?? this.count,
    annualRatePercent: annualRatePercent ?? this.annualRatePercent,
    categoryId: categoryId ?? this.categoryId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    startYm: startYm ?? this.startYm,
    cardName: cardName.present ? cardName.value : this.cardName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InstallmentPlanRow copyWithCompanion(InstallmentPlansCompanion data) {
    return InstallmentPlanRow(
      id: data.id.present ? data.id.value : this.id,
      principal: data.principal.present ? data.principal.value : this.principal,
      count: data.count.present ? data.count.value : this.count,
      annualRatePercent: data.annualRatePercent.present
          ? data.annualRatePercent.value
          : this.annualRatePercent,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      startYm: data.startYm.present ? data.startYm.value : this.startYm,
      cardName: data.cardName.present ? data.cardName.value : this.cardName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlanRow(')
          ..write('id: $id, ')
          ..write('principal: $principal, ')
          ..write('count: $count, ')
          ..write('annualRatePercent: $annualRatePercent, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('startYm: $startYm, ')
          ..write('cardName: $cardName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    principal,
    count,
    annualRatePercent,
    categoryId,
    dayOfMonth,
    startYm,
    cardName,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentPlanRow &&
          other.id == this.id &&
          other.principal == this.principal &&
          other.count == this.count &&
          other.annualRatePercent == this.annualRatePercent &&
          other.categoryId == this.categoryId &&
          other.dayOfMonth == this.dayOfMonth &&
          other.startYm == this.startYm &&
          other.cardName == this.cardName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InstallmentPlansCompanion extends UpdateCompanion<InstallmentPlanRow> {
  final Value<int> id;
  final Value<int> principal;
  final Value<int> count;
  final Value<double> annualRatePercent;
  final Value<int> categoryId;
  final Value<int> dayOfMonth;
  final Value<int> startYm;
  final Value<String?> cardName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const InstallmentPlansCompanion({
    this.id = const Value.absent(),
    this.principal = const Value.absent(),
    this.count = const Value.absent(),
    this.annualRatePercent = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.startYm = const Value.absent(),
    this.cardName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InstallmentPlansCompanion.insert({
    this.id = const Value.absent(),
    required int principal,
    required int count,
    required double annualRatePercent,
    required int categoryId,
    required int dayOfMonth,
    required int startYm,
    this.cardName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : principal = Value(principal),
       count = Value(count),
       annualRatePercent = Value(annualRatePercent),
       categoryId = Value(categoryId),
       dayOfMonth = Value(dayOfMonth),
       startYm = Value(startYm);
  static Insertable<InstallmentPlanRow> custom({
    Expression<int>? id,
    Expression<int>? principal,
    Expression<int>? count,
    Expression<double>? annualRatePercent,
    Expression<int>? categoryId,
    Expression<int>? dayOfMonth,
    Expression<int>? startYm,
    Expression<String>? cardName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (principal != null) 'principal': principal,
      if (count != null) 'count': count,
      if (annualRatePercent != null) 'annual_rate_percent': annualRatePercent,
      if (categoryId != null) 'category_id': categoryId,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (startYm != null) 'start_ym': startYm,
      if (cardName != null) 'card_name': cardName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InstallmentPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? principal,
    Value<int>? count,
    Value<double>? annualRatePercent,
    Value<int>? categoryId,
    Value<int>? dayOfMonth,
    Value<int>? startYm,
    Value<String?>? cardName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return InstallmentPlansCompanion(
      id: id ?? this.id,
      principal: principal ?? this.principal,
      count: count ?? this.count,
      annualRatePercent: annualRatePercent ?? this.annualRatePercent,
      categoryId: categoryId ?? this.categoryId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startYm: startYm ?? this.startYm,
      cardName: cardName ?? this.cardName,
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
    if (principal.present) {
      map['principal'] = Variable<int>(principal.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (annualRatePercent.present) {
      map['annual_rate_percent'] = Variable<double>(annualRatePercent.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (startYm.present) {
      map['start_ym'] = Variable<int>(startYm.value);
    }
    if (cardName.present) {
      map['card_name'] = Variable<String>(cardName.value);
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
    return (StringBuffer('InstallmentPlansCompanion(')
          ..write('id: $id, ')
          ..write('principal: $principal, ')
          ..write('count: $count, ')
          ..write('annualRatePercent: $annualRatePercent, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('startYm: $startYm, ')
          ..write('cardName: $cardName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
  static const VerificationMeta _installmentPlanIdMeta = const VerificationMeta(
    'installmentPlanId',
  );
  @override
  late final GeneratedColumn<int> installmentPlanId = GeneratedColumn<int>(
    'installment_plan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES installment_plans (id) ON DELETE CASCADE',
    ),
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
    installmentPlanId,
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
    if (data.containsKey('installment_plan_id')) {
      context.handle(
        _installmentPlanIdMeta,
        installmentPlanId.isAcceptableOrUnknown(
          data['installment_plan_id']!,
          _installmentPlanIdMeta,
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
      installmentPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_plan_id'],
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

  /// 分割払いの計画（installment_plans.id）。null=分割払い由来ではない。
  /// v10で追加。計画の編集/削除でこの取引群は作り直し/削除される（cascade）。
  final int? installmentPlanId;
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
    this.installmentPlanId,
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
    if (!nullToAbsent || installmentPlanId != null) {
      map['installment_plan_id'] = Variable<int>(installmentPlanId);
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
      installmentPlanId: installmentPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentPlanId),
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
      installmentPlanId: serializer.fromJson<int?>(json['installmentPlanId']),
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
      'installmentPlanId': serializer.toJson<int?>(installmentPlanId),
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
    Value<int?> installmentPlanId = const Value.absent(),
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
    installmentPlanId: installmentPlanId.present
        ? installmentPlanId.value
        : this.installmentPlanId,
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
      installmentPlanId: data.installmentPlanId.present
          ? data.installmentPlanId.value
          : this.installmentPlanId,
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
          ..write('installmentPlanId: $installmentPlanId, ')
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
    installmentPlanId,
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
          other.installmentPlanId == this.installmentPlanId &&
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
  final Value<int?> installmentPlanId;
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
    this.installmentPlanId = const Value.absent(),
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
    this.installmentPlanId = const Value.absent(),
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
    Expression<int>? installmentPlanId,
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
      if (installmentPlanId != null) 'installment_plan_id': installmentPlanId,
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
    Value<int?>? installmentPlanId,
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
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
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
    if (installmentPlanId.present) {
      map['installment_plan_id'] = Variable<int>(installmentPlanId.value);
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
          ..write('installmentPlanId: $installmentPlanId, ')
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

class $DeletedTransactionsTable extends DeletedTransactions
    with TableInfo<$DeletedTransactionsTable, DeletedTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedTransactionsTable(this.attachedDatabase, [this._alias]);
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
      ).withConverter<TxnType>($DeletedTransactionsTable.$convertertype);
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
      ).withConverter<CivilDate>($DeletedTransactionsTable.$converterdate);
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
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethod?, String>
  paymentMethod =
      GeneratedColumn<String>(
        'payment_method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PaymentMethod?>(
        $DeletedTransactionsTable.$converterpaymentMethodn,
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
  @override
  late final GeneratedColumnWithTypeConverter<TxnSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxnSource>($DeletedTransactionsTable.$convertersource);
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
  static const VerificationMeta _installmentPlanIdMeta = const VerificationMeta(
    'installmentPlanId',
  );
  @override
  late final GeneratedColumn<int> installmentPlanId = GeneratedColumn<int>(
    'installment_plan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    installmentPlanId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedTransactionRow> instance, {
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
    if (data.containsKey('installment_plan_id')) {
      context.handle(
        _installmentPlanIdMeta,
        installmentPlanId.isAcceptableOrUnknown(
          data['installment_plan_id']!,
          _installmentPlanIdMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeletedTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $DeletedTransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: $DeletedTransactionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      paymentMethod: $DeletedTransactionsTable.$converterpaymentMethodn.fromSql(
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
      source: $DeletedTransactionsTable.$convertersource.fromSql(
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
      installmentPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_plan_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedTransactionsTable createAlias(String alias) {
    return $DeletedTransactionsTable(attachedDatabase, alias);
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

class DeletedTransactionRow extends DataClass
    implements Insertable<DeletedTransactionRow> {
  final int id;
  final TxnType type;
  final int amount;
  final CivilDate date;
  final int categoryId;
  final PaymentMethod? paymentMethod;
  final String? storeName;
  final String? memo;
  final TxnSource source;
  final String? imagePath;
  final String? splitGroupId;
  final int? installmentPlanId;
  final DateTime deletedAt;
  const DeletedTransactionRow({
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
    this.installmentPlanId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>(
        $DeletedTransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount'] = Variable<int>(amount);
    {
      map['date'] = Variable<String>(
        $DeletedTransactionsTable.$converterdate.toSql(date),
      );
    }
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(
        $DeletedTransactionsTable.$converterpaymentMethodn.toSql(paymentMethod),
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
        $DeletedTransactionsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || splitGroupId != null) {
      map['split_group_id'] = Variable<String>(splitGroupId);
    }
    if (!nullToAbsent || installmentPlanId != null) {
      map['installment_plan_id'] = Variable<int>(installmentPlanId);
    }
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedTransactionsCompanion toCompanion(bool nullToAbsent) {
    return DeletedTransactionsCompanion(
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
      installmentPlanId: installmentPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentPlanId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedTransactionRow(
      id: serializer.fromJson<int>(json['id']),
      type: $DeletedTransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<CivilDate>(json['date']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      paymentMethod: $DeletedTransactionsTable.$converterpaymentMethodn
          .fromJson(serializer.fromJson<String?>(json['paymentMethod'])),
      storeName: serializer.fromJson<String?>(json['storeName']),
      memo: serializer.fromJson<String?>(json['memo']),
      source: $DeletedTransactionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      splitGroupId: serializer.fromJson<String?>(json['splitGroupId']),
      installmentPlanId: serializer.fromJson<int?>(json['installmentPlanId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $DeletedTransactionsTable.$convertertype.toJson(type),
      ),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<CivilDate>(date),
      'categoryId': serializer.toJson<int>(categoryId),
      'paymentMethod': serializer.toJson<String?>(
        $DeletedTransactionsTable.$converterpaymentMethodn.toJson(
          paymentMethod,
        ),
      ),
      'storeName': serializer.toJson<String?>(storeName),
      'memo': serializer.toJson<String?>(memo),
      'source': serializer.toJson<String>(
        $DeletedTransactionsTable.$convertersource.toJson(source),
      ),
      'imagePath': serializer.toJson<String?>(imagePath),
      'splitGroupId': serializer.toJson<String?>(splitGroupId),
      'installmentPlanId': serializer.toJson<int?>(installmentPlanId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedTransactionRow copyWith({
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
    Value<int?> installmentPlanId = const Value.absent(),
    DateTime? deletedAt,
  }) => DeletedTransactionRow(
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
    installmentPlanId: installmentPlanId.present
        ? installmentPlanId.value
        : this.installmentPlanId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedTransactionRow copyWithCompanion(DeletedTransactionsCompanion data) {
    return DeletedTransactionRow(
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
      installmentPlanId: data.installmentPlanId.present
          ? data.installmentPlanId.value
          : this.installmentPlanId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedTransactionRow(')
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
          ..write('installmentPlanId: $installmentPlanId, ')
          ..write('deletedAt: $deletedAt')
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
    installmentPlanId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedTransactionRow &&
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
          other.installmentPlanId == this.installmentPlanId &&
          other.deletedAt == this.deletedAt);
}

class DeletedTransactionsCompanion
    extends UpdateCompanion<DeletedTransactionRow> {
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
  final Value<int?> installmentPlanId;
  final Value<DateTime> deletedAt;
  const DeletedTransactionsCompanion({
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
    this.installmentPlanId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DeletedTransactionsCompanion.insert({
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
    this.installmentPlanId = const Value.absent(),
    required DateTime deletedAt,
  }) : type = Value(type),
       amount = Value(amount),
       date = Value(date),
       categoryId = Value(categoryId),
       source = Value(source),
       deletedAt = Value(deletedAt);
  static Insertable<DeletedTransactionRow> custom({
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
    Expression<int>? installmentPlanId,
    Expression<DateTime>? deletedAt,
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
      if (installmentPlanId != null) 'installment_plan_id': installmentPlanId,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DeletedTransactionsCompanion copyWith({
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
    Value<int?>? installmentPlanId,
    Value<DateTime>? deletedAt,
  }) {
    return DeletedTransactionsCompanion(
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
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      deletedAt: deletedAt ?? this.deletedAt,
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
        $DeletedTransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $DeletedTransactionsTable.$converterdate.toSql(date.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(
        $DeletedTransactionsTable.$converterpaymentMethodn.toSql(
          paymentMethod.value,
        ),
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
        $DeletedTransactionsTable.$convertersource.toSql(source.value),
      );
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (splitGroupId.present) {
      map['split_group_id'] = Variable<String>(splitGroupId.value);
    }
    if (installmentPlanId.present) {
      map['installment_plan_id'] = Variable<int>(installmentPlanId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedTransactionsCompanion(')
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
          ..write('installmentPlanId: $installmentPlanId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $PaymentCardsTable extends PaymentCards
    with TableInfo<$PaymentCardsTable, PaymentCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentCardsTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payDayMeta = const VerificationMeta('payDay');
  @override
  late final GeneratedColumn<int> payDay = GeneratedColumn<int>(
    'pay_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingDayMeta = const VerificationMeta(
    'closingDay',
  );
  @override
  late final GeneratedColumn<int> closingDay = GeneratedColumn<int>(
    'closing_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(31),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BusinessDayRule, String>
  businessDayRule =
      GeneratedColumn<String>(
        'business_day_rule',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('next'),
      ).withConverter<BusinessDayRule>(
        $PaymentCardsTable.$converterbusinessDayRule,
      );
  static const VerificationMeta _annualRatePercentMeta = const VerificationMeta(
    'annualRatePercent',
  );
  @override
  late final GeneratedColumn<double> annualRatePercent =
      GeneratedColumn<double>(
        'annual_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
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
    name,
    payDay,
    closingDay,
    businessDayRule,
    annualRatePercent,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentCardRow> instance, {
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
    if (data.containsKey('pay_day')) {
      context.handle(
        _payDayMeta,
        payDay.isAcceptableOrUnknown(data['pay_day']!, _payDayMeta),
      );
    } else if (isInserting) {
      context.missing(_payDayMeta);
    }
    if (data.containsKey('closing_day')) {
      context.handle(
        _closingDayMeta,
        closingDay.isAcceptableOrUnknown(data['closing_day']!, _closingDayMeta),
      );
    }
    if (data.containsKey('annual_rate_percent')) {
      context.handle(
        _annualRatePercentMeta,
        annualRatePercent.isAcceptableOrUnknown(
          data['annual_rate_percent']!,
          _annualRatePercentMeta,
        ),
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
  PaymentCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      payDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_day'],
      )!,
      closingDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing_day'],
      )!,
      businessDayRule: $PaymentCardsTable.$converterbusinessDayRule.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}business_day_rule'],
        )!,
      ),
      annualRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_rate_percent'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
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
  $PaymentCardsTable createAlias(String alias) {
    return $PaymentCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BusinessDayRule, String, String>
  $converterbusinessDayRule = const EnumNameConverter<BusinessDayRule>(
    BusinessDayRule.values,
  );
}

class PaymentCardRow extends DataClass implements Insertable<PaymentCardRow> {
  final int id;
  final String name;
  final int payDay;

  /// 締め日 1..31（31=月末締め・既定）。締め日までの利用は翌月払い、
  /// 締め日を過ぎた利用は翌々月払いになる。
  final int closingDay;
  final BusinessDayRule businessDayRule;
  final double annualRatePercent;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PaymentCardRow({
    required this.id,
    required this.name,
    required this.payDay,
    required this.closingDay,
    required this.businessDayRule,
    required this.annualRatePercent,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['pay_day'] = Variable<int>(payDay);
    map['closing_day'] = Variable<int>(closingDay);
    {
      map['business_day_rule'] = Variable<String>(
        $PaymentCardsTable.$converterbusinessDayRule.toSql(businessDayRule),
      );
    }
    map['annual_rate_percent'] = Variable<double>(annualRatePercent);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PaymentCardsCompanion toCompanion(bool nullToAbsent) {
    return PaymentCardsCompanion(
      id: Value(id),
      name: Value(name),
      payDay: Value(payDay),
      closingDay: Value(closingDay),
      businessDayRule: Value(businessDayRule),
      annualRatePercent: Value(annualRatePercent),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PaymentCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentCardRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      payDay: serializer.fromJson<int>(json['payDay']),
      closingDay: serializer.fromJson<int>(json['closingDay']),
      businessDayRule: $PaymentCardsTable.$converterbusinessDayRule.fromJson(
        serializer.fromJson<String>(json['businessDayRule']),
      ),
      annualRatePercent: serializer.fromJson<double>(json['annualRatePercent']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'payDay': serializer.toJson<int>(payDay),
      'closingDay': serializer.toJson<int>(closingDay),
      'businessDayRule': serializer.toJson<String>(
        $PaymentCardsTable.$converterbusinessDayRule.toJson(businessDayRule),
      ),
      'annualRatePercent': serializer.toJson<double>(annualRatePercent),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PaymentCardRow copyWith({
    int? id,
    String? name,
    int? payDay,
    int? closingDay,
    BusinessDayRule? businessDayRule,
    double? annualRatePercent,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PaymentCardRow(
    id: id ?? this.id,
    name: name ?? this.name,
    payDay: payDay ?? this.payDay,
    closingDay: closingDay ?? this.closingDay,
    businessDayRule: businessDayRule ?? this.businessDayRule,
    annualRatePercent: annualRatePercent ?? this.annualRatePercent,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PaymentCardRow copyWithCompanion(PaymentCardsCompanion data) {
    return PaymentCardRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      payDay: data.payDay.present ? data.payDay.value : this.payDay,
      closingDay: data.closingDay.present
          ? data.closingDay.value
          : this.closingDay,
      businessDayRule: data.businessDayRule.present
          ? data.businessDayRule.value
          : this.businessDayRule,
      annualRatePercent: data.annualRatePercent.present
          ? data.annualRatePercent.value
          : this.annualRatePercent,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentCardRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('payDay: $payDay, ')
          ..write('closingDay: $closingDay, ')
          ..write('businessDayRule: $businessDayRule, ')
          ..write('annualRatePercent: $annualRatePercent, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    payDay,
    closingDay,
    businessDayRule,
    annualRatePercent,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentCardRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.payDay == this.payDay &&
          other.closingDay == this.closingDay &&
          other.businessDayRule == this.businessDayRule &&
          other.annualRatePercent == this.annualRatePercent &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PaymentCardsCompanion extends UpdateCompanion<PaymentCardRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> payDay;
  final Value<int> closingDay;
  final Value<BusinessDayRule> businessDayRule;
  final Value<double> annualRatePercent;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PaymentCardsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.payDay = const Value.absent(),
    this.closingDay = const Value.absent(),
    this.businessDayRule = const Value.absent(),
    this.annualRatePercent = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PaymentCardsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int payDay,
    this.closingDay = const Value.absent(),
    this.businessDayRule = const Value.absent(),
    this.annualRatePercent = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       payDay = Value(payDay);
  static Insertable<PaymentCardRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? payDay,
    Expression<int>? closingDay,
    Expression<String>? businessDayRule,
    Expression<double>? annualRatePercent,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (payDay != null) 'pay_day': payDay,
      if (closingDay != null) 'closing_day': closingDay,
      if (businessDayRule != null) 'business_day_rule': businessDayRule,
      if (annualRatePercent != null) 'annual_rate_percent': annualRatePercent,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PaymentCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? payDay,
    Value<int>? closingDay,
    Value<BusinessDayRule>? businessDayRule,
    Value<double>? annualRatePercent,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PaymentCardsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      payDay: payDay ?? this.payDay,
      closingDay: closingDay ?? this.closingDay,
      businessDayRule: businessDayRule ?? this.businessDayRule,
      annualRatePercent: annualRatePercent ?? this.annualRatePercent,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (payDay.present) {
      map['pay_day'] = Variable<int>(payDay.value);
    }
    if (closingDay.present) {
      map['closing_day'] = Variable<int>(closingDay.value);
    }
    if (businessDayRule.present) {
      map['business_day_rule'] = Variable<String>(
        $PaymentCardsTable.$converterbusinessDayRule.toSql(
          businessDayRule.value,
        ),
      );
    }
    if (annualRatePercent.present) {
      map['annual_rate_percent'] = Variable<double>(annualRatePercent.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
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
    return (StringBuffer('PaymentCardsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('payDay: $payDay, ')
          ..write('closingDay: $closingDay, ')
          ..write('businessDayRule: $businessDayRule, ')
          ..write('annualRatePercent: $annualRatePercent, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PayablesTable extends Payables
    with TableInfo<$PayablesTable, PayableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayablesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES payment_cards (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _installmentCountMeta = const VerificationMeta(
    'installmentCount',
  );
  @override
  late final GeneratedColumn<int> installmentCount = GeneratedColumn<int>(
    'installment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _annualRatePercentMeta = const VerificationMeta(
    'annualRatePercent',
  );
  @override
  late final GeneratedColumn<double> annualRatePercent =
      GeneratedColumn<double>(
        'annual_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _totalMinorMeta = const VerificationMeta(
    'totalMinor',
  );
  @override
  late final GeneratedColumn<int> totalMinor = GeneratedColumn<int>(
    'total_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    transactionId,
    cardId,
    installmentCount,
    annualRatePercent,
    totalMinor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payables';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('installment_count')) {
      context.handle(
        _installmentCountMeta,
        installmentCount.isAcceptableOrUnknown(
          data['installment_count']!,
          _installmentCountMeta,
        ),
      );
    }
    if (data.containsKey('annual_rate_percent')) {
      context.handle(
        _annualRatePercentMeta,
        annualRatePercent.isAcceptableOrUnknown(
          data['annual_rate_percent']!,
          _annualRatePercentMeta,
        ),
      );
    }
    if (data.containsKey('total_minor')) {
      context.handle(
        _totalMinorMeta,
        totalMinor.isAcceptableOrUnknown(data['total_minor']!, _totalMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMinorMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {transactionId},
  ];
  @override
  PayableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayableRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      installmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_count'],
      )!,
      annualRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_rate_percent'],
      )!,
      totalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor'],
      )!,
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
  $PayablesTable createAlias(String alias) {
    return $PayablesTable(attachedDatabase, alias);
  }
}

class PayableRow extends DataClass implements Insertable<PayableRow> {
  final int id;
  final int transactionId;
  final int cardId;
  final int installmentCount;
  final double annualRatePercent;
  final int totalMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PayableRow({
    required this.id,
    required this.transactionId,
    required this.cardId,
    required this.installmentCount,
    required this.annualRatePercent,
    required this.totalMinor,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['card_id'] = Variable<int>(cardId);
    map['installment_count'] = Variable<int>(installmentCount);
    map['annual_rate_percent'] = Variable<double>(annualRatePercent);
    map['total_minor'] = Variable<int>(totalMinor);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PayablesCompanion toCompanion(bool nullToAbsent) {
    return PayablesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      cardId: Value(cardId),
      installmentCount: Value(installmentCount),
      annualRatePercent: Value(annualRatePercent),
      totalMinor: Value(totalMinor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PayableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayableRow(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      cardId: serializer.fromJson<int>(json['cardId']),
      installmentCount: serializer.fromJson<int>(json['installmentCount']),
      annualRatePercent: serializer.fromJson<double>(json['annualRatePercent']),
      totalMinor: serializer.fromJson<int>(json['totalMinor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'cardId': serializer.toJson<int>(cardId),
      'installmentCount': serializer.toJson<int>(installmentCount),
      'annualRatePercent': serializer.toJson<double>(annualRatePercent),
      'totalMinor': serializer.toJson<int>(totalMinor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PayableRow copyWith({
    int? id,
    int? transactionId,
    int? cardId,
    int? installmentCount,
    double? annualRatePercent,
    int? totalMinor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PayableRow(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    cardId: cardId ?? this.cardId,
    installmentCount: installmentCount ?? this.installmentCount,
    annualRatePercent: annualRatePercent ?? this.annualRatePercent,
    totalMinor: totalMinor ?? this.totalMinor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PayableRow copyWithCompanion(PayablesCompanion data) {
    return PayableRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      installmentCount: data.installmentCount.present
          ? data.installmentCount.value
          : this.installmentCount,
      annualRatePercent: data.annualRatePercent.present
          ? data.annualRatePercent.value
          : this.annualRatePercent,
      totalMinor: data.totalMinor.present
          ? data.totalMinor.value
          : this.totalMinor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayableRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('cardId: $cardId, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('annualRatePercent: $annualRatePercent, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    cardId,
    installmentCount,
    annualRatePercent,
    totalMinor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayableRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.cardId == this.cardId &&
          other.installmentCount == this.installmentCount &&
          other.annualRatePercent == this.annualRatePercent &&
          other.totalMinor == this.totalMinor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PayablesCompanion extends UpdateCompanion<PayableRow> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<int> cardId;
  final Value<int> installmentCount;
  final Value<double> annualRatePercent;
  final Value<int> totalMinor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PayablesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.installmentCount = const Value.absent(),
    this.annualRatePercent = const Value.absent(),
    this.totalMinor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PayablesCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required int cardId,
    this.installmentCount = const Value.absent(),
    this.annualRatePercent = const Value.absent(),
    required int totalMinor,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : transactionId = Value(transactionId),
       cardId = Value(cardId),
       totalMinor = Value(totalMinor);
  static Insertable<PayableRow> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<int>? cardId,
    Expression<int>? installmentCount,
    Expression<double>? annualRatePercent,
    Expression<int>? totalMinor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (cardId != null) 'card_id': cardId,
      if (installmentCount != null) 'installment_count': installmentCount,
      if (annualRatePercent != null) 'annual_rate_percent': annualRatePercent,
      if (totalMinor != null) 'total_minor': totalMinor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PayablesCompanion copyWith({
    Value<int>? id,
    Value<int>? transactionId,
    Value<int>? cardId,
    Value<int>? installmentCount,
    Value<double>? annualRatePercent,
    Value<int>? totalMinor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PayablesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      cardId: cardId ?? this.cardId,
      installmentCount: installmentCount ?? this.installmentCount,
      annualRatePercent: annualRatePercent ?? this.annualRatePercent,
      totalMinor: totalMinor ?? this.totalMinor,
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
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (installmentCount.present) {
      map['installment_count'] = Variable<int>(installmentCount.value);
    }
    if (annualRatePercent.present) {
      map['annual_rate_percent'] = Variable<double>(annualRatePercent.value);
    }
    if (totalMinor.present) {
      map['total_minor'] = Variable<int>(totalMinor.value);
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
    return (StringBuffer('PayablesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('cardId: $cardId, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('annualRatePercent: $annualRatePercent, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PayableSchedulesTable extends PayableSchedules
    with TableInfo<$PayableSchedulesTable, PayableScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayableSchedulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _payableIdMeta = const VerificationMeta(
    'payableId',
  );
  @override
  late final GeneratedColumn<int> payableId = GeneratedColumn<int>(
    'payable_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES payables (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ymMeta = const VerificationMeta('ym');
  @override
  late final GeneratedColumn<int> ym = GeneratedColumn<int>(
    'ym',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payableId, ym, amountMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payable_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayableScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payable_id')) {
      context.handle(
        _payableIdMeta,
        payableId.isAcceptableOrUnknown(data['payable_id']!, _payableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_payableIdMeta);
    }
    if (data.containsKey('ym')) {
      context.handle(_ymMeta, ym.isAcceptableOrUnknown(data['ym']!, _ymMeta));
    } else if (isInserting) {
      context.missing(_ymMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {payableId, ym},
  ];
  @override
  PayableScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayableScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payableId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payable_id'],
      )!,
      ym: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ym'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  $PayableSchedulesTable createAlias(String alias) {
    return $PayableSchedulesTable(attachedDatabase, alias);
  }
}

class PayableScheduleRow extends DataClass
    implements Insertable<PayableScheduleRow> {
  final int id;
  final int payableId;
  final int ym;
  final int amountMinor;
  const PayableScheduleRow({
    required this.id,
    required this.payableId,
    required this.ym,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payable_id'] = Variable<int>(payableId);
    map['ym'] = Variable<int>(ym);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  PayableSchedulesCompanion toCompanion(bool nullToAbsent) {
    return PayableSchedulesCompanion(
      id: Value(id),
      payableId: Value(payableId),
      ym: Value(ym),
      amountMinor: Value(amountMinor),
    );
  }

  factory PayableScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayableScheduleRow(
      id: serializer.fromJson<int>(json['id']),
      payableId: serializer.fromJson<int>(json['payableId']),
      ym: serializer.fromJson<int>(json['ym']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payableId': serializer.toJson<int>(payableId),
      'ym': serializer.toJson<int>(ym),
      'amountMinor': serializer.toJson<int>(amountMinor),
    };
  }

  PayableScheduleRow copyWith({
    int? id,
    int? payableId,
    int? ym,
    int? amountMinor,
  }) => PayableScheduleRow(
    id: id ?? this.id,
    payableId: payableId ?? this.payableId,
    ym: ym ?? this.ym,
    amountMinor: amountMinor ?? this.amountMinor,
  );
  PayableScheduleRow copyWithCompanion(PayableSchedulesCompanion data) {
    return PayableScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      payableId: data.payableId.present ? data.payableId.value : this.payableId,
      ym: data.ym.present ? data.ym.value : this.ym,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayableScheduleRow(')
          ..write('id: $id, ')
          ..write('payableId: $payableId, ')
          ..write('ym: $ym, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payableId, ym, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayableScheduleRow &&
          other.id == this.id &&
          other.payableId == this.payableId &&
          other.ym == this.ym &&
          other.amountMinor == this.amountMinor);
}

class PayableSchedulesCompanion extends UpdateCompanion<PayableScheduleRow> {
  final Value<int> id;
  final Value<int> payableId;
  final Value<int> ym;
  final Value<int> amountMinor;
  const PayableSchedulesCompanion({
    this.id = const Value.absent(),
    this.payableId = const Value.absent(),
    this.ym = const Value.absent(),
    this.amountMinor = const Value.absent(),
  });
  PayableSchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int payableId,
    required int ym,
    required int amountMinor,
  }) : payableId = Value(payableId),
       ym = Value(ym),
       amountMinor = Value(amountMinor);
  static Insertable<PayableScheduleRow> custom({
    Expression<int>? id,
    Expression<int>? payableId,
    Expression<int>? ym,
    Expression<int>? amountMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payableId != null) 'payable_id': payableId,
      if (ym != null) 'ym': ym,
      if (amountMinor != null) 'amount_minor': amountMinor,
    });
  }

  PayableSchedulesCompanion copyWith({
    Value<int>? id,
    Value<int>? payableId,
    Value<int>? ym,
    Value<int>? amountMinor,
  }) {
    return PayableSchedulesCompanion(
      id: id ?? this.id,
      payableId: payableId ?? this.payableId,
      ym: ym ?? this.ym,
      amountMinor: amountMinor ?? this.amountMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payableId.present) {
      map['payable_id'] = Variable<int>(payableId.value);
    }
    if (ym.present) {
      map['ym'] = Variable<int>(ym.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayableSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('payableId: $payableId, ')
          ..write('ym: $ym, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $InstallmentPlansTable installmentPlans = $InstallmentPlansTable(
    this,
  );
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RecurringRulesTable recurringRules = $RecurringRulesTable(this);
  late final $ChoreTasksTable choreTasks = $ChoreTasksTable(this);
  late final $ChoreRecordsTable choreRecords = $ChoreRecordsTable(this);
  late final $DeletedTransactionsTable deletedTransactions =
      $DeletedTransactionsTable(this);
  late final $PaymentCardsTable paymentCards = $PaymentCardsTable(this);
  late final $PayablesTable payables = $PayablesTable(this);
  late final $PayableSchedulesTable payableSchedules = $PayableSchedulesTable(
    this,
  );
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
    installmentPlans,
    transactions,
    recurringRules,
    choreTasks,
    choreRecords,
    deletedTransactions,
    paymentCards,
    payables,
    payableSchedules,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'installment_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chore_tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chore_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payables', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'payables',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payable_schedules', kind: UpdateKind.delete)],
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

  static MultiTypedResultKey<$InstallmentPlansTable, List<InstallmentPlanRow>>
  _installmentPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.installmentPlans,
    aliasName: 'categories__id__installment_plans__category_id',
  );

  $$InstallmentPlansTableProcessedTableManager get installmentPlansRefs {
    final manager = $$InstallmentPlansTableTableManager(
      $_db,
      $_db.installmentPlans,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _installmentPlansRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> installmentPlansRefs(
    Expression<bool> Function($$InstallmentPlansTableFilterComposer f) f,
  ) {
    final $$InstallmentPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installmentPlans,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlansTableFilterComposer(
            $db: $db,
            $table: $db.installmentPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> installmentPlansRefs<T extends Object>(
    Expression<T> Function($$InstallmentPlansTableAnnotationComposer a) f,
  ) {
    final $$InstallmentPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installmentPlans,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.installmentPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
            bool installmentPlansRefs,
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
                installmentPlansRefs = false,
                transactionsRefs = false,
                recurringRulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (installmentPlansRefs) db.installmentPlans,
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
                      if (installmentPlansRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          InstallmentPlanRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._installmentPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).installmentPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
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
        bool installmentPlansRefs,
        bool transactionsRefs,
        bool recurringRulesRefs,
      })
    >;
typedef $$InstallmentPlansTableCreateCompanionBuilder =
    InstallmentPlansCompanion Function({
      Value<int> id,
      required int principal,
      required int count,
      required double annualRatePercent,
      required int categoryId,
      required int dayOfMonth,
      required int startYm,
      Value<String?> cardName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$InstallmentPlansTableUpdateCompanionBuilder =
    InstallmentPlansCompanion Function({
      Value<int> id,
      Value<int> principal,
      Value<int> count,
      Value<double> annualRatePercent,
      Value<int> categoryId,
      Value<int> dayOfMonth,
      Value<int> startYm,
      Value<String?> cardName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$InstallmentPlansTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstallmentPlansTable,
          InstallmentPlanRow
        > {
  $$InstallmentPlansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias('installment_plans__category_id__categories__id');

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

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'installment_plans__id__transactions__installment_plan_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.installmentPlanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstallmentPlansTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentPlansTable> {
  $$InstallmentPlansTableFilterComposer({
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

  ColumnFilters<int> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardName => $composableBuilder(
    column: $table.cardName,
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

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.installmentPlanId,
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
}

class $$InstallmentPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentPlansTable> {
  $$InstallmentPlansTableOrderingComposer({
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

  ColumnOrderings<int> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardName => $composableBuilder(
    column: $table.cardName,
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

class $$InstallmentPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentPlansTable> {
  $$InstallmentPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startYm =>
      $composableBuilder(column: $table.startYm, builder: (column) => column);

  GeneratedColumn<String> get cardName =>
      $composableBuilder(column: $table.cardName, builder: (column) => column);

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

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.installmentPlanId,
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
}

class $$InstallmentPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentPlansTable,
          InstallmentPlanRow,
          $$InstallmentPlansTableFilterComposer,
          $$InstallmentPlansTableOrderingComposer,
          $$InstallmentPlansTableAnnotationComposer,
          $$InstallmentPlansTableCreateCompanionBuilder,
          $$InstallmentPlansTableUpdateCompanionBuilder,
          (InstallmentPlanRow, $$InstallmentPlansTableReferences),
          InstallmentPlanRow,
          PrefetchHooks Function({bool categoryId, bool transactionsRefs})
        > {
  $$InstallmentPlansTableTableManager(
    _$AppDatabase db,
    $InstallmentPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallmentPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> principal = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<double> annualRatePercent = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<int> startYm = const Value.absent(),
                Value<String?> cardName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InstallmentPlansCompanion(
                id: id,
                principal: principal,
                count: count,
                annualRatePercent: annualRatePercent,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                startYm: startYm,
                cardName: cardName,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int principal,
                required int count,
                required double annualRatePercent,
                required int categoryId,
                required int dayOfMonth,
                required int startYm,
                Value<String?> cardName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InstallmentPlansCompanion.insert(
                id: id,
                principal: principal,
                count: count,
                annualRatePercent: annualRatePercent,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                startYm: startYm,
                cardName: cardName,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstallmentPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, transactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
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
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$InstallmentPlansTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$InstallmentPlansTableReferences
                                            ._categoryIdTable(db)
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
                          InstallmentPlanRow,
                          $InstallmentPlansTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$InstallmentPlansTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InstallmentPlansTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.installmentPlanId == item.id,
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

typedef $$InstallmentPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentPlansTable,
      InstallmentPlanRow,
      $$InstallmentPlansTableFilterComposer,
      $$InstallmentPlansTableOrderingComposer,
      $$InstallmentPlansTableAnnotationComposer,
      $$InstallmentPlansTableCreateCompanionBuilder,
      $$InstallmentPlansTableUpdateCompanionBuilder,
      (InstallmentPlanRow, $$InstallmentPlansTableReferences),
      InstallmentPlanRow,
      PrefetchHooks Function({bool categoryId, bool transactionsRefs})
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
      Value<int?> installmentPlanId,
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
      Value<int?> installmentPlanId,
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

  static $InstallmentPlansTable _installmentPlanIdTable(_$AppDatabase db) => db
      .installmentPlans
      .createAlias('transactions__installment_plan_id__installment_plans__id');

  $$InstallmentPlansTableProcessedTableManager? get installmentPlanId {
    final $_column = $_itemColumn<int>('installment_plan_id');
    if ($_column == null) return null;
    final manager = $$InstallmentPlansTableTableManager(
      $_db,
      $_db.installmentPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_installmentPlanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PayablesTable, List<PayableRow>>
  _payablesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payables,
    aliasName: 'transactions__id__payables__transaction_id',
  );

  $$PayablesTableProcessedTableManager get payablesRefs {
    final manager = $$PayablesTableTableManager(
      $_db,
      $_db.payables,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_payablesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  $$InstallmentPlansTableFilterComposer get installmentPlanId {
    final $$InstallmentPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installmentPlanId,
      referencedTable: $db.installmentPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlansTableFilterComposer(
            $db: $db,
            $table: $db.installmentPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> payablesRefs(
    Expression<bool> Function($$PayablesTableFilterComposer f) f,
  ) {
    final $$PayablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableFilterComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  $$InstallmentPlansTableOrderingComposer get installmentPlanId {
    final $$InstallmentPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installmentPlanId,
      referencedTable: $db.installmentPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlansTableOrderingComposer(
            $db: $db,
            $table: $db.installmentPlans,
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

  $$InstallmentPlansTableAnnotationComposer get installmentPlanId {
    final $$InstallmentPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installmentPlanId,
      referencedTable: $db.installmentPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.installmentPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> payablesRefs<T extends Object>(
    Expression<T> Function($$PayablesTableAnnotationComposer a) f,
  ) {
    final $$PayablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableAnnotationComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
          PrefetchHooks Function({
            bool categoryId,
            bool installmentPlanId,
            bool payablesRefs,
          })
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
                Value<int?> installmentPlanId = const Value.absent(),
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
                installmentPlanId: installmentPlanId,
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
                Value<int?> installmentPlanId = const Value.absent(),
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
                installmentPlanId: installmentPlanId,
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
          prefetchHooksCallback:
              ({
                categoryId = false,
                installmentPlanId = false,
                payablesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (payablesRefs) db.payables],
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
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (installmentPlanId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.installmentPlanId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._installmentPlanIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._installmentPlanIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (payablesRefs)
                        await $_getPrefetchedData<
                          TransactionRow,
                          $TransactionsTable,
                          PayableRow
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._payablesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).payablesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
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
      PrefetchHooks Function({
        bool categoryId,
        bool installmentPlanId,
        bool payablesRefs,
      })
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
typedef $$DeletedTransactionsTableCreateCompanionBuilder =
    DeletedTransactionsCompanion Function({
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
      Value<int?> installmentPlanId,
      required DateTime deletedAt,
    });
typedef $$DeletedTransactionsTableUpdateCompanionBuilder =
    DeletedTransactionsCompanion Function({
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
      Value<int?> installmentPlanId,
      Value<DateTime> deletedAt,
    });

class $$DeletedTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $DeletedTransactionsTable> {
  $$DeletedTransactionsTableFilterComposer({
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

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<int> get installmentPlanId => $composableBuilder(
    column: $table.installmentPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeletedTransactionsTable> {
  $$DeletedTransactionsTableOrderingComposer({
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

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
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

  ColumnOrderings<int> get installmentPlanId => $composableBuilder(
    column: $table.installmentPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeletedTransactionsTable> {
  $$DeletedTransactionsTableAnnotationComposer({
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

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

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

  GeneratedColumn<int> get installmentPlanId => $composableBuilder(
    column: $table.installmentPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeletedTransactionsTable,
          DeletedTransactionRow,
          $$DeletedTransactionsTableFilterComposer,
          $$DeletedTransactionsTableOrderingComposer,
          $$DeletedTransactionsTableAnnotationComposer,
          $$DeletedTransactionsTableCreateCompanionBuilder,
          $$DeletedTransactionsTableUpdateCompanionBuilder,
          (
            DeletedTransactionRow,
            BaseReferences<
              _$AppDatabase,
              $DeletedTransactionsTable,
              DeletedTransactionRow
            >,
          ),
          DeletedTransactionRow,
          PrefetchHooks Function()
        > {
  $$DeletedTransactionsTableTableManager(
    _$AppDatabase db,
    $DeletedTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletedTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeletedTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
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
                Value<int?> installmentPlanId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
              }) => DeletedTransactionsCompanion(
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
                installmentPlanId: installmentPlanId,
                deletedAt: deletedAt,
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
                Value<int?> installmentPlanId = const Value.absent(),
                required DateTime deletedAt,
              }) => DeletedTransactionsCompanion.insert(
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
                installmentPlanId: installmentPlanId,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletedTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeletedTransactionsTable,
      DeletedTransactionRow,
      $$DeletedTransactionsTableFilterComposer,
      $$DeletedTransactionsTableOrderingComposer,
      $$DeletedTransactionsTableAnnotationComposer,
      $$DeletedTransactionsTableCreateCompanionBuilder,
      $$DeletedTransactionsTableUpdateCompanionBuilder,
      (
        DeletedTransactionRow,
        BaseReferences<
          _$AppDatabase,
          $DeletedTransactionsTable,
          DeletedTransactionRow
        >,
      ),
      DeletedTransactionRow,
      PrefetchHooks Function()
    >;
typedef $$PaymentCardsTableCreateCompanionBuilder =
    PaymentCardsCompanion Function({
      Value<int> id,
      required String name,
      required int payDay,
      Value<int> closingDay,
      Value<BusinessDayRule> businessDayRule,
      Value<double> annualRatePercent,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PaymentCardsTableUpdateCompanionBuilder =
    PaymentCardsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> payDay,
      Value<int> closingDay,
      Value<BusinessDayRule> businessDayRule,
      Value<double> annualRatePercent,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PaymentCardsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentCardsTable, PaymentCardRow> {
  $$PaymentCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PayablesTable, List<PayableRow>>
  _payablesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payables,
    aliasName: 'payment_cards__id__payables__card_id',
  );

  $$PayablesTableProcessedTableManager get payablesRefs {
    final manager = $$PayablesTableTableManager(
      $_db,
      $_db.payables,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_payablesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PaymentCardsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentCardsTable> {
  $$PaymentCardsTableFilterComposer({
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

  ColumnFilters<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closingDay => $composableBuilder(
    column: $table.closingDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BusinessDayRule, BusinessDayRule, String>
  get businessDayRule => $composableBuilder(
    column: $table.businessDayRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> payablesRefs(
    Expression<bool> Function($$PayablesTableFilterComposer f) f,
  ) {
    final $$PayablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableFilterComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PaymentCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentCardsTable> {
  $$PaymentCardsTableOrderingComposer({
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

  ColumnOrderings<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closingDay => $composableBuilder(
    column: $table.closingDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessDayRule => $composableBuilder(
    column: $table.businessDayRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentCardsTable> {
  $$PaymentCardsTableAnnotationComposer({
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

  GeneratedColumn<int> get payDay =>
      $composableBuilder(column: $table.payDay, builder: (column) => column);

  GeneratedColumn<int> get closingDay => $composableBuilder(
    column: $table.closingDay,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BusinessDayRule, String>
  get businessDayRule => $composableBuilder(
    column: $table.businessDayRule,
    builder: (column) => column,
  );

  GeneratedColumn<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> payablesRefs<T extends Object>(
    Expression<T> Function($$PayablesTableAnnotationComposer a) f,
  ) {
    final $$PayablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableAnnotationComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PaymentCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentCardsTable,
          PaymentCardRow,
          $$PaymentCardsTableFilterComposer,
          $$PaymentCardsTableOrderingComposer,
          $$PaymentCardsTableAnnotationComposer,
          $$PaymentCardsTableCreateCompanionBuilder,
          $$PaymentCardsTableUpdateCompanionBuilder,
          (PaymentCardRow, $$PaymentCardsTableReferences),
          PaymentCardRow,
          PrefetchHooks Function({bool payablesRefs})
        > {
  $$PaymentCardsTableTableManager(_$AppDatabase db, $PaymentCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> payDay = const Value.absent(),
                Value<int> closingDay = const Value.absent(),
                Value<BusinessDayRule> businessDayRule = const Value.absent(),
                Value<double> annualRatePercent = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PaymentCardsCompanion(
                id: id,
                name: name,
                payDay: payDay,
                closingDay: closingDay,
                businessDayRule: businessDayRule,
                annualRatePercent: annualRatePercent,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int payDay,
                Value<int> closingDay = const Value.absent(),
                Value<BusinessDayRule> businessDayRule = const Value.absent(),
                Value<double> annualRatePercent = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PaymentCardsCompanion.insert(
                id: id,
                name: name,
                payDay: payDay,
                closingDay: closingDay,
                businessDayRule: businessDayRule,
                annualRatePercent: annualRatePercent,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({payablesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (payablesRefs) db.payables],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (payablesRefs)
                    await $_getPrefetchedData<
                      PaymentCardRow,
                      $PaymentCardsTable,
                      PayableRow
                    >(
                      currentTable: table,
                      referencedTable: $$PaymentCardsTableReferences
                          ._payablesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PaymentCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).payablesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cardId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PaymentCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentCardsTable,
      PaymentCardRow,
      $$PaymentCardsTableFilterComposer,
      $$PaymentCardsTableOrderingComposer,
      $$PaymentCardsTableAnnotationComposer,
      $$PaymentCardsTableCreateCompanionBuilder,
      $$PaymentCardsTableUpdateCompanionBuilder,
      (PaymentCardRow, $$PaymentCardsTableReferences),
      PaymentCardRow,
      PrefetchHooks Function({bool payablesRefs})
    >;
typedef $$PayablesTableCreateCompanionBuilder =
    PayablesCompanion Function({
      Value<int> id,
      required int transactionId,
      required int cardId,
      Value<int> installmentCount,
      Value<double> annualRatePercent,
      required int totalMinor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PayablesTableUpdateCompanionBuilder =
    PayablesCompanion Function({
      Value<int> id,
      Value<int> transactionId,
      Value<int> cardId,
      Value<int> installmentCount,
      Value<double> annualRatePercent,
      Value<int> totalMinor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PayablesTableReferences
    extends BaseReferences<_$AppDatabase, $PayablesTable, PayableRow> {
  $$PayablesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias('payables__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<int>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PaymentCardsTable _cardIdTable(_$AppDatabase db) =>
      db.paymentCards.createAlias('payables__card_id__payment_cards__id');

  $$PaymentCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$PaymentCardsTableTableManager(
      $_db,
      $_db.paymentCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PayableSchedulesTable, List<PayableScheduleRow>>
  _payableSchedulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payableSchedules,
    aliasName: 'payables__id__payable_schedules__payable_id',
  );

  $$PayableSchedulesTableProcessedTableManager get payableSchedulesRefs {
    final manager = $$PayableSchedulesTableTableManager(
      $_db,
      $_db.payableSchedules,
    ).filter((f) => f.payableId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _payableSchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PayablesTableFilterComposer
    extends Composer<_$AppDatabase, $PayablesTable> {
  $$PayablesTableFilterComposer({
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

  ColumnFilters<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
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

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$PaymentCardsTableFilterComposer get cardId {
    final $$PaymentCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.paymentCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentCardsTableFilterComposer(
            $db: $db,
            $table: $db.paymentCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> payableSchedulesRefs(
    Expression<bool> Function($$PayableSchedulesTableFilterComposer f) f,
  ) {
    final $$PayableSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payableSchedules,
      getReferencedColumn: (t) => t.payableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayableSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.payableSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PayablesTableOrderingComposer
    extends Composer<_$AppDatabase, $PayablesTable> {
  $$PayablesTableOrderingComposer({
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

  ColumnOrderings<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
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

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentCardsTableOrderingComposer get cardId {
    final $$PaymentCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.paymentCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentCardsTableOrderingComposer(
            $db: $db,
            $table: $db.paymentCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayablesTable> {
  $$PayablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get annualRatePercent => $composableBuilder(
    column: $table.annualRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$PaymentCardsTableAnnotationComposer get cardId {
    final $$PaymentCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.paymentCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> payableSchedulesRefs<T extends Object>(
    Expression<T> Function($$PayableSchedulesTableAnnotationComposer a) f,
  ) {
    final $$PayableSchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payableSchedules,
      getReferencedColumn: (t) => t.payableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayableSchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.payableSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PayablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PayablesTable,
          PayableRow,
          $$PayablesTableFilterComposer,
          $$PayablesTableOrderingComposer,
          $$PayablesTableAnnotationComposer,
          $$PayablesTableCreateCompanionBuilder,
          $$PayablesTableUpdateCompanionBuilder,
          (PayableRow, $$PayablesTableReferences),
          PayableRow,
          PrefetchHooks Function({
            bool transactionId,
            bool cardId,
            bool payableSchedulesRefs,
          })
        > {
  $$PayablesTableTableManager(_$AppDatabase db, $PayablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> transactionId = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> installmentCount = const Value.absent(),
                Value<double> annualRatePercent = const Value.absent(),
                Value<int> totalMinor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PayablesCompanion(
                id: id,
                transactionId: transactionId,
                cardId: cardId,
                installmentCount: installmentCount,
                annualRatePercent: annualRatePercent,
                totalMinor: totalMinor,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int transactionId,
                required int cardId,
                Value<int> installmentCount = const Value.absent(),
                Value<double> annualRatePercent = const Value.absent(),
                required int totalMinor,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PayablesCompanion.insert(
                id: id,
                transactionId: transactionId,
                cardId: cardId,
                installmentCount: installmentCount,
                annualRatePercent: annualRatePercent,
                totalMinor: totalMinor,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PayablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                transactionId = false,
                cardId = false,
                payableSchedulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (payableSchedulesRefs) db.payableSchedules,
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
                        if (transactionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.transactionId,
                                    referencedTable: $$PayablesTableReferences
                                        ._transactionIdTable(db),
                                    referencedColumn: $$PayablesTableReferences
                                        ._transactionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (cardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cardId,
                                    referencedTable: $$PayablesTableReferences
                                        ._cardIdTable(db),
                                    referencedColumn: $$PayablesTableReferences
                                        ._cardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (payableSchedulesRefs)
                        await $_getPrefetchedData<
                          PayableRow,
                          $PayablesTable,
                          PayableScheduleRow
                        >(
                          currentTable: table,
                          referencedTable: $$PayablesTableReferences
                              ._payableSchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PayablesTableReferences(
                                db,
                                table,
                                p0,
                              ).payableSchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.payableId == item.id,
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

typedef $$PayablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PayablesTable,
      PayableRow,
      $$PayablesTableFilterComposer,
      $$PayablesTableOrderingComposer,
      $$PayablesTableAnnotationComposer,
      $$PayablesTableCreateCompanionBuilder,
      $$PayablesTableUpdateCompanionBuilder,
      (PayableRow, $$PayablesTableReferences),
      PayableRow,
      PrefetchHooks Function({
        bool transactionId,
        bool cardId,
        bool payableSchedulesRefs,
      })
    >;
typedef $$PayableSchedulesTableCreateCompanionBuilder =
    PayableSchedulesCompanion Function({
      Value<int> id,
      required int payableId,
      required int ym,
      required int amountMinor,
    });
typedef $$PayableSchedulesTableUpdateCompanionBuilder =
    PayableSchedulesCompanion Function({
      Value<int> id,
      Value<int> payableId,
      Value<int> ym,
      Value<int> amountMinor,
    });

final class $$PayableSchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PayableSchedulesTable,
          PayableScheduleRow
        > {
  $$PayableSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PayablesTable _payableIdTable(_$AppDatabase db) =>
      db.payables.createAlias('payable_schedules__payable_id__payables__id');

  $$PayablesTableProcessedTableManager get payableId {
    final $_column = $_itemColumn<int>('payable_id')!;

    final manager = $$PayablesTableTableManager(
      $_db,
      $_db.payables,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_payableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PayableSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $PayableSchedulesTable> {
  $$PayableSchedulesTableFilterComposer({
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

  ColumnFilters<int> get ym => $composableBuilder(
    column: $table.ym,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  $$PayablesTableFilterComposer get payableId {
    final $$PayablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.payableId,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableFilterComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayableSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $PayableSchedulesTable> {
  $$PayableSchedulesTableOrderingComposer({
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

  ColumnOrderings<int> get ym => $composableBuilder(
    column: $table.ym,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $$PayablesTableOrderingComposer get payableId {
    final $$PayablesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.payableId,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableOrderingComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayableSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayableSchedulesTable> {
  $$PayableSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ym =>
      $composableBuilder(column: $table.ym, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  $$PayablesTableAnnotationComposer get payableId {
    final $$PayablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.payableId,
      referencedTable: $db.payables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayablesTableAnnotationComposer(
            $db: $db,
            $table: $db.payables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayableSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PayableSchedulesTable,
          PayableScheduleRow,
          $$PayableSchedulesTableFilterComposer,
          $$PayableSchedulesTableOrderingComposer,
          $$PayableSchedulesTableAnnotationComposer,
          $$PayableSchedulesTableCreateCompanionBuilder,
          $$PayableSchedulesTableUpdateCompanionBuilder,
          (PayableScheduleRow, $$PayableSchedulesTableReferences),
          PayableScheduleRow,
          PrefetchHooks Function({bool payableId})
        > {
  $$PayableSchedulesTableTableManager(
    _$AppDatabase db,
    $PayableSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayableSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayableSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayableSchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> payableId = const Value.absent(),
                Value<int> ym = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
              }) => PayableSchedulesCompanion(
                id: id,
                payableId: payableId,
                ym: ym,
                amountMinor: amountMinor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int payableId,
                required int ym,
                required int amountMinor,
              }) => PayableSchedulesCompanion.insert(
                id: id,
                payableId: payableId,
                ym: ym,
                amountMinor: amountMinor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PayableSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({payableId = false}) {
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
                    if (payableId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.payableId,
                                referencedTable:
                                    $$PayableSchedulesTableReferences
                                        ._payableIdTable(db),
                                referencedColumn:
                                    $$PayableSchedulesTableReferences
                                        ._payableIdTable(db)
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

typedef $$PayableSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PayableSchedulesTable,
      PayableScheduleRow,
      $$PayableSchedulesTableFilterComposer,
      $$PayableSchedulesTableOrderingComposer,
      $$PayableSchedulesTableAnnotationComposer,
      $$PayableSchedulesTableCreateCompanionBuilder,
      $$PayableSchedulesTableUpdateCompanionBuilder,
      (PayableScheduleRow, $$PayableSchedulesTableReferences),
      PayableScheduleRow,
      PrefetchHooks Function({bool payableId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$InstallmentPlansTableTableManager get installmentPlans =>
      $$InstallmentPlansTableTableManager(_db, _db.installmentPlans);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(_db, _db.recurringRules);
  $$ChoreTasksTableTableManager get choreTasks =>
      $$ChoreTasksTableTableManager(_db, _db.choreTasks);
  $$ChoreRecordsTableTableManager get choreRecords =>
      $$ChoreRecordsTableTableManager(_db, _db.choreRecords);
  $$DeletedTransactionsTableTableManager get deletedTransactions =>
      $$DeletedTransactionsTableTableManager(_db, _db.deletedTransactions);
  $$PaymentCardsTableTableManager get paymentCards =>
      $$PaymentCardsTableTableManager(_db, _db.paymentCards);
  $$PayablesTableTableManager get payables =>
      $$PayablesTableTableManager(_db, _db.payables);
  $$PayableSchedulesTableTableManager get payableSchedules =>
      $$PayableSchedulesTableTableManager(_db, _db.payableSchedules);
}
