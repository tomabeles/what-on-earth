// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_database.dart';

// ignore_for_file: type=lint
class $PinsTable extends Pins with TableInfo<$PinsTable, Pin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latDegMeta = const VerificationMeta('latDeg');
  @override
  late final GeneratedColumn<double> latDeg = GeneratedColumn<double>(
      'lat_deg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonDegMeta = const VerificationMeta('lonDeg');
  @override
  late final GeneratedColumn<double> lonDeg = GeneratedColumn<double>(
      'lon_deg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconIdMeta = const VerificationMeta('iconId');
  @override
  late final GeneratedColumn<int> iconId = GeneratedColumn<int>(
      'icon_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, latDeg, lonDeg, name, note, iconId, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pins';
  @override
  VerificationContext validateIntegrity(Insertable<Pin> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lat_deg')) {
      context.handle(_latDegMeta,
          latDeg.isAcceptableOrUnknown(data['lat_deg']!, _latDegMeta));
    } else if (isInserting) {
      context.missing(_latDegMeta);
    }
    if (data.containsKey('lon_deg')) {
      context.handle(_lonDegMeta,
          lonDeg.isAcceptableOrUnknown(data['lon_deg']!, _lonDegMeta));
    } else if (isInserting) {
      context.missing(_lonDegMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('icon_id')) {
      context.handle(_iconIdMeta,
          iconId.isAcceptableOrUnknown(data['icon_id']!, _iconIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pin(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      latDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat_deg'])!,
      lonDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon_deg'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      iconId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}icon_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PinsTable createAlias(String alias) {
    return $PinsTable(attachedDatabase, alias);
  }
}

class Pin extends DataClass implements Insertable<Pin> {
  final String id;
  final double latDeg;
  final double lonDeg;
  final String name;
  final String? note;
  final int iconId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Pin(
      {required this.id,
      required this.latDeg,
      required this.lonDeg,
      required this.name,
      this.note,
      required this.iconId,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lat_deg'] = Variable<double>(latDeg);
    map['lon_deg'] = Variable<double>(lonDeg);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['icon_id'] = Variable<int>(iconId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PinsCompanion toCompanion(bool nullToAbsent) {
    return PinsCompanion(
      id: Value(id),
      latDeg: Value(latDeg),
      lonDeg: Value(lonDeg),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      iconId: Value(iconId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Pin.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pin(
      id: serializer.fromJson<String>(json['id']),
      latDeg: serializer.fromJson<double>(json['latDeg']),
      lonDeg: serializer.fromJson<double>(json['lonDeg']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      iconId: serializer.fromJson<int>(json['iconId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'latDeg': serializer.toJson<double>(latDeg),
      'lonDeg': serializer.toJson<double>(lonDeg),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'iconId': serializer.toJson<int>(iconId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Pin copyWith(
          {String? id,
          double? latDeg,
          double? lonDeg,
          String? name,
          Value<String?> note = const Value.absent(),
          int? iconId,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Pin(
        id: id ?? this.id,
        latDeg: latDeg ?? this.latDeg,
        lonDeg: lonDeg ?? this.lonDeg,
        name: name ?? this.name,
        note: note.present ? note.value : this.note,
        iconId: iconId ?? this.iconId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Pin copyWithCompanion(PinsCompanion data) {
    return Pin(
      id: data.id.present ? data.id.value : this.id,
      latDeg: data.latDeg.present ? data.latDeg.value : this.latDeg,
      lonDeg: data.lonDeg.present ? data.lonDeg.value : this.lonDeg,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      iconId: data.iconId.present ? data.iconId.value : this.iconId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pin(')
          ..write('id: $id, ')
          ..write('latDeg: $latDeg, ')
          ..write('lonDeg: $lonDeg, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('iconId: $iconId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, latDeg, lonDeg, name, note, iconId, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pin &&
          other.id == this.id &&
          other.latDeg == this.latDeg &&
          other.lonDeg == this.lonDeg &&
          other.name == this.name &&
          other.note == this.note &&
          other.iconId == this.iconId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PinsCompanion extends UpdateCompanion<Pin> {
  final Value<String> id;
  final Value<double> latDeg;
  final Value<double> lonDeg;
  final Value<String> name;
  final Value<String?> note;
  final Value<int> iconId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PinsCompanion({
    this.id = const Value.absent(),
    this.latDeg = const Value.absent(),
    this.lonDeg = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.iconId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PinsCompanion.insert({
    required String id,
    required double latDeg,
    required double lonDeg,
    required String name,
    this.note = const Value.absent(),
    this.iconId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        latDeg = Value(latDeg),
        lonDeg = Value(lonDeg),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Pin> custom({
    Expression<String>? id,
    Expression<double>? latDeg,
    Expression<double>? lonDeg,
    Expression<String>? name,
    Expression<String>? note,
    Expression<int>? iconId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latDeg != null) 'lat_deg': latDeg,
      if (lonDeg != null) 'lon_deg': lonDeg,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (iconId != null) 'icon_id': iconId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PinsCompanion copyWith(
      {Value<String>? id,
      Value<double>? latDeg,
      Value<double>? lonDeg,
      Value<String>? name,
      Value<String?>? note,
      Value<int>? iconId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return PinsCompanion(
      id: id ?? this.id,
      latDeg: latDeg ?? this.latDeg,
      lonDeg: lonDeg ?? this.lonDeg,
      name: name ?? this.name,
      note: note ?? this.note,
      iconId: iconId ?? this.iconId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (latDeg.present) {
      map['lat_deg'] = Variable<double>(latDeg.value);
    }
    if (lonDeg.present) {
      map['lon_deg'] = Variable<double>(lonDeg.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (iconId.present) {
      map['icon_id'] = Variable<int>(iconId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinsCompanion(')
          ..write('id: $id, ')
          ..write('latDeg: $latDeg, ')
          ..write('lonDeg: $lonDeg, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('iconId: $iconId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PinDatabase extends GeneratedDatabase {
  _$PinDatabase(QueryExecutor e) : super(e);
  $PinDatabaseManager get managers => $PinDatabaseManager(this);
  late final $PinsTable pins = $PinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [pins];
}

typedef $$PinsTableCreateCompanionBuilder = PinsCompanion Function({
  required String id,
  required double latDeg,
  required double lonDeg,
  required String name,
  Value<String?> note,
  Value<int> iconId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PinsTableUpdateCompanionBuilder = PinsCompanion Function({
  Value<String> id,
  Value<double> latDeg,
  Value<double> lonDeg,
  Value<String> name,
  Value<String?> note,
  Value<int> iconId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PinsTableFilterComposer extends Composer<_$PinDatabase, $PinsTable> {
  $$PinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latDeg => $composableBuilder(
      column: $table.latDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lonDeg => $composableBuilder(
      column: $table.lonDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get iconId => $composableBuilder(
      column: $table.iconId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PinsTableOrderingComposer extends Composer<_$PinDatabase, $PinsTable> {
  $$PinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latDeg => $composableBuilder(
      column: $table.latDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lonDeg => $composableBuilder(
      column: $table.lonDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get iconId => $composableBuilder(
      column: $table.iconId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PinsTableAnnotationComposer
    extends Composer<_$PinDatabase, $PinsTable> {
  $$PinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latDeg =>
      $composableBuilder(column: $table.latDeg, builder: (column) => column);

  GeneratedColumn<double> get lonDeg =>
      $composableBuilder(column: $table.lonDeg, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get iconId =>
      $composableBuilder(column: $table.iconId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PinsTableTableManager extends RootTableManager<
    _$PinDatabase,
    $PinsTable,
    Pin,
    $$PinsTableFilterComposer,
    $$PinsTableOrderingComposer,
    $$PinsTableAnnotationComposer,
    $$PinsTableCreateCompanionBuilder,
    $$PinsTableUpdateCompanionBuilder,
    (Pin, BaseReferences<_$PinDatabase, $PinsTable, Pin>),
    Pin,
    PrefetchHooks Function()> {
  $$PinsTableTableManager(_$PinDatabase db, $PinsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> latDeg = const Value.absent(),
            Value<double> lonDeg = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> iconId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PinsCompanion(
            id: id,
            latDeg: latDeg,
            lonDeg: lonDeg,
            name: name,
            note: note,
            iconId: iconId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double latDeg,
            required double lonDeg,
            required String name,
            Value<String?> note = const Value.absent(),
            Value<int> iconId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PinsCompanion.insert(
            id: id,
            latDeg: latDeg,
            lonDeg: lonDeg,
            name: name,
            note: note,
            iconId: iconId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PinsTableProcessedTableManager = ProcessedTableManager<
    _$PinDatabase,
    $PinsTable,
    Pin,
    $$PinsTableFilterComposer,
    $$PinsTableOrderingComposer,
    $$PinsTableAnnotationComposer,
    $$PinsTableCreateCompanionBuilder,
    $$PinsTableUpdateCompanionBuilder,
    (Pin, BaseReferences<_$PinDatabase, $PinsTable, Pin>),
    Pin,
    PrefetchHooks Function()>;

class $PinDatabaseManager {
  final _$PinDatabase _db;
  $PinDatabaseManager(this._db);
  $$PinsTableTableManager get pins => $$PinsTableTableManager(_db, _db.pins);
}
