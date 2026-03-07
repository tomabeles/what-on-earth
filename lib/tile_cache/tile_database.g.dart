// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tile_database.dart';

// ignore_for_file: type=lint
class $TileMetadataTableTable extends TileMetadataTable
    with TableInfo<$TileMetadataTableTable, TileMetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TileMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tileKeyMeta =
      const VerificationMeta('tileKey');
  @override
  late final GeneratedColumn<String> tileKey = GeneratedColumn<String>(
      'tile_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _layerIdMeta =
      const VerificationMeta('layerId');
  @override
  late final GeneratedColumn<String> layerId = GeneratedColumn<String>(
      'layer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _zoomLevelMeta =
      const VerificationMeta('zoomLevel');
  @override
  late final GeneratedColumn<int> zoomLevel = GeneratedColumn<int>(
      'zoom_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tileXMeta = const VerificationMeta('tileX');
  @override
  late final GeneratedColumn<int> tileX = GeneratedColumn<int>(
      'tile_x', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tileYMeta = const VerificationMeta('tileY');
  @override
  late final GeneratedColumn<int> tileY = GeneratedColumn<int>(
      'tile_y', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        tileKey,
        layerId,
        zoomLevel,
        tileX,
        tileY,
        fileSizeBytes,
        downloadedAt,
        lastAccessedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tile_metadata_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<TileMetadataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tile_key')) {
      context.handle(_tileKeyMeta,
          tileKey.isAcceptableOrUnknown(data['tile_key']!, _tileKeyMeta));
    } else if (isInserting) {
      context.missing(_tileKeyMeta);
    }
    if (data.containsKey('layer_id')) {
      context.handle(_layerIdMeta,
          layerId.isAcceptableOrUnknown(data['layer_id']!, _layerIdMeta));
    } else if (isInserting) {
      context.missing(_layerIdMeta);
    }
    if (data.containsKey('zoom_level')) {
      context.handle(_zoomLevelMeta,
          zoomLevel.isAcceptableOrUnknown(data['zoom_level']!, _zoomLevelMeta));
    } else if (isInserting) {
      context.missing(_zoomLevelMeta);
    }
    if (data.containsKey('tile_x')) {
      context.handle(
          _tileXMeta, tileX.isAcceptableOrUnknown(data['tile_x']!, _tileXMeta));
    } else if (isInserting) {
      context.missing(_tileXMeta);
    }
    if (data.containsKey('tile_y')) {
      context.handle(
          _tileYMeta, tileY.isAcceptableOrUnknown(data['tile_y']!, _tileYMeta));
    } else if (isInserting) {
      context.missing(_tileYMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tileKey};
  @override
  TileMetadataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TileMetadataTableData(
      tileKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tile_key'])!,
      layerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}layer_id'])!,
      zoomLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}zoom_level'])!,
      tileX: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tile_x'])!,
      tileY: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tile_y'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at'])!,
    );
  }

  @override
  $TileMetadataTableTable createAlias(String alias) {
    return $TileMetadataTableTable(attachedDatabase, alias);
  }
}

class TileMetadataTableData extends DataClass
    implements Insertable<TileMetadataTableData> {
  /// Composite key: `"{layer}/{z}/{x}/{y}"`.
  final String tileKey;
  final String layerId;
  final int zoomLevel;
  final int tileX;
  final int tileY;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final DateTime lastAccessedAt;
  const TileMetadataTableData(
      {required this.tileKey,
      required this.layerId,
      required this.zoomLevel,
      required this.tileX,
      required this.tileY,
      required this.fileSizeBytes,
      required this.downloadedAt,
      required this.lastAccessedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tile_key'] = Variable<String>(tileKey);
    map['layer_id'] = Variable<String>(layerId);
    map['zoom_level'] = Variable<int>(zoomLevel);
    map['tile_x'] = Variable<int>(tileX);
    map['tile_y'] = Variable<int>(tileY);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  TileMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return TileMetadataTableCompanion(
      tileKey: Value(tileKey),
      layerId: Value(layerId),
      zoomLevel: Value(zoomLevel),
      tileX: Value(tileX),
      tileY: Value(tileY),
      fileSizeBytes: Value(fileSizeBytes),
      downloadedAt: Value(downloadedAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory TileMetadataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TileMetadataTableData(
      tileKey: serializer.fromJson<String>(json['tileKey']),
      layerId: serializer.fromJson<String>(json['layerId']),
      zoomLevel: serializer.fromJson<int>(json['zoomLevel']),
      tileX: serializer.fromJson<int>(json['tileX']),
      tileY: serializer.fromJson<int>(json['tileY']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tileKey': serializer.toJson<String>(tileKey),
      'layerId': serializer.toJson<String>(layerId),
      'zoomLevel': serializer.toJson<int>(zoomLevel),
      'tileX': serializer.toJson<int>(tileX),
      'tileY': serializer.toJson<int>(tileY),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  TileMetadataTableData copyWith(
          {String? tileKey,
          String? layerId,
          int? zoomLevel,
          int? tileX,
          int? tileY,
          int? fileSizeBytes,
          DateTime? downloadedAt,
          DateTime? lastAccessedAt}) =>
      TileMetadataTableData(
        tileKey: tileKey ?? this.tileKey,
        layerId: layerId ?? this.layerId,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        tileX: tileX ?? this.tileX,
        tileY: tileY ?? this.tileY,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        downloadedAt: downloadedAt ?? this.downloadedAt,
        lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      );
  TileMetadataTableData copyWithCompanion(TileMetadataTableCompanion data) {
    return TileMetadataTableData(
      tileKey: data.tileKey.present ? data.tileKey.value : this.tileKey,
      layerId: data.layerId.present ? data.layerId.value : this.layerId,
      zoomLevel: data.zoomLevel.present ? data.zoomLevel.value : this.zoomLevel,
      tileX: data.tileX.present ? data.tileX.value : this.tileX,
      tileY: data.tileY.present ? data.tileY.value : this.tileY,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TileMetadataTableData(')
          ..write('tileKey: $tileKey, ')
          ..write('layerId: $layerId, ')
          ..write('zoomLevel: $zoomLevel, ')
          ..write('tileX: $tileX, ')
          ..write('tileY: $tileY, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tileKey, layerId, zoomLevel, tileX, tileY,
      fileSizeBytes, downloadedAt, lastAccessedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileMetadataTableData &&
          other.tileKey == this.tileKey &&
          other.layerId == this.layerId &&
          other.zoomLevel == this.zoomLevel &&
          other.tileX == this.tileX &&
          other.tileY == this.tileY &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class TileMetadataTableCompanion
    extends UpdateCompanion<TileMetadataTableData> {
  final Value<String> tileKey;
  final Value<String> layerId;
  final Value<int> zoomLevel;
  final Value<int> tileX;
  final Value<int> tileY;
  final Value<int> fileSizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const TileMetadataTableCompanion({
    this.tileKey = const Value.absent(),
    this.layerId = const Value.absent(),
    this.zoomLevel = const Value.absent(),
    this.tileX = const Value.absent(),
    this.tileY = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TileMetadataTableCompanion.insert({
    required String tileKey,
    required String layerId,
    required int zoomLevel,
    required int tileX,
    required int tileY,
    required int fileSizeBytes,
    required DateTime downloadedAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  })  : tileKey = Value(tileKey),
        layerId = Value(layerId),
        zoomLevel = Value(zoomLevel),
        tileX = Value(tileX),
        tileY = Value(tileY),
        fileSizeBytes = Value(fileSizeBytes),
        downloadedAt = Value(downloadedAt),
        lastAccessedAt = Value(lastAccessedAt);
  static Insertable<TileMetadataTableData> custom({
    Expression<String>? tileKey,
    Expression<String>? layerId,
    Expression<int>? zoomLevel,
    Expression<int>? tileX,
    Expression<int>? tileY,
    Expression<int>? fileSizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tileKey != null) 'tile_key': tileKey,
      if (layerId != null) 'layer_id': layerId,
      if (zoomLevel != null) 'zoom_level': zoomLevel,
      if (tileX != null) 'tile_x': tileX,
      if (tileY != null) 'tile_y': tileY,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TileMetadataTableCompanion copyWith(
      {Value<String>? tileKey,
      Value<String>? layerId,
      Value<int>? zoomLevel,
      Value<int>? tileX,
      Value<int>? tileY,
      Value<int>? fileSizeBytes,
      Value<DateTime>? downloadedAt,
      Value<DateTime>? lastAccessedAt,
      Value<int>? rowid}) {
    return TileMetadataTableCompanion(
      tileKey: tileKey ?? this.tileKey,
      layerId: layerId ?? this.layerId,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      tileX: tileX ?? this.tileX,
      tileY: tileY ?? this.tileY,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tileKey.present) {
      map['tile_key'] = Variable<String>(tileKey.value);
    }
    if (layerId.present) {
      map['layer_id'] = Variable<String>(layerId.value);
    }
    if (zoomLevel.present) {
      map['zoom_level'] = Variable<int>(zoomLevel.value);
    }
    if (tileX.present) {
      map['tile_x'] = Variable<int>(tileX.value);
    }
    if (tileY.present) {
      map['tile_y'] = Variable<int>(tileY.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TileMetadataTableCompanion(')
          ..write('tileKey: $tileKey, ')
          ..write('layerId: $layerId, ')
          ..write('zoomLevel: $zoomLevel, ')
          ..write('tileX: $tileX, ')
          ..write('tileY: $tileY, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TileDatabase extends GeneratedDatabase {
  _$TileDatabase(QueryExecutor e) : super(e);
  $TileDatabaseManager get managers => $TileDatabaseManager(this);
  late final $TileMetadataTableTable tileMetadataTable =
      $TileMetadataTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tileMetadataTable];
}

typedef $$TileMetadataTableTableCreateCompanionBuilder
    = TileMetadataTableCompanion Function({
  required String tileKey,
  required String layerId,
  required int zoomLevel,
  required int tileX,
  required int tileY,
  required int fileSizeBytes,
  required DateTime downloadedAt,
  required DateTime lastAccessedAt,
  Value<int> rowid,
});
typedef $$TileMetadataTableTableUpdateCompanionBuilder
    = TileMetadataTableCompanion Function({
  Value<String> tileKey,
  Value<String> layerId,
  Value<int> zoomLevel,
  Value<int> tileX,
  Value<int> tileY,
  Value<int> fileSizeBytes,
  Value<DateTime> downloadedAt,
  Value<DateTime> lastAccessedAt,
  Value<int> rowid,
});

class $$TileMetadataTableTableFilterComposer
    extends Composer<_$TileDatabase, $TileMetadataTableTable> {
  $$TileMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tileKey => $composableBuilder(
      column: $table.tileKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get layerId => $composableBuilder(
      column: $table.layerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get zoomLevel => $composableBuilder(
      column: $table.zoomLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tileX => $composableBuilder(
      column: $table.tileX, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tileY => $composableBuilder(
      column: $table.tileY, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnFilters(column));
}

class $$TileMetadataTableTableOrderingComposer
    extends Composer<_$TileDatabase, $TileMetadataTableTable> {
  $$TileMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tileKey => $composableBuilder(
      column: $table.tileKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get layerId => $composableBuilder(
      column: $table.layerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get zoomLevel => $composableBuilder(
      column: $table.zoomLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tileX => $composableBuilder(
      column: $table.tileX, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tileY => $composableBuilder(
      column: $table.tileY, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$TileMetadataTableTableAnnotationComposer
    extends Composer<_$TileDatabase, $TileMetadataTableTable> {
  $$TileMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tileKey =>
      $composableBuilder(column: $table.tileKey, builder: (column) => column);

  GeneratedColumn<String> get layerId =>
      $composableBuilder(column: $table.layerId, builder: (column) => column);

  GeneratedColumn<int> get zoomLevel =>
      $composableBuilder(column: $table.zoomLevel, builder: (column) => column);

  GeneratedColumn<int> get tileX =>
      $composableBuilder(column: $table.tileX, builder: (column) => column);

  GeneratedColumn<int> get tileY =>
      $composableBuilder(column: $table.tileY, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt, builder: (column) => column);
}

class $$TileMetadataTableTableTableManager extends RootTableManager<
    _$TileDatabase,
    $TileMetadataTableTable,
    TileMetadataTableData,
    $$TileMetadataTableTableFilterComposer,
    $$TileMetadataTableTableOrderingComposer,
    $$TileMetadataTableTableAnnotationComposer,
    $$TileMetadataTableTableCreateCompanionBuilder,
    $$TileMetadataTableTableUpdateCompanionBuilder,
    (
      TileMetadataTableData,
      BaseReferences<_$TileDatabase, $TileMetadataTableTable,
          TileMetadataTableData>
    ),
    TileMetadataTableData,
    PrefetchHooks Function()> {
  $$TileMetadataTableTableTableManager(
      _$TileDatabase db, $TileMetadataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TileMetadataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TileMetadataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TileMetadataTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> tileKey = const Value.absent(),
            Value<String> layerId = const Value.absent(),
            Value<int> zoomLevel = const Value.absent(),
            Value<int> tileX = const Value.absent(),
            Value<int> tileY = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<DateTime> lastAccessedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TileMetadataTableCompanion(
            tileKey: tileKey,
            layerId: layerId,
            zoomLevel: zoomLevel,
            tileX: tileX,
            tileY: tileY,
            fileSizeBytes: fileSizeBytes,
            downloadedAt: downloadedAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String tileKey,
            required String layerId,
            required int zoomLevel,
            required int tileX,
            required int tileY,
            required int fileSizeBytes,
            required DateTime downloadedAt,
            required DateTime lastAccessedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TileMetadataTableCompanion.insert(
            tileKey: tileKey,
            layerId: layerId,
            zoomLevel: zoomLevel,
            tileX: tileX,
            tileY: tileY,
            fileSizeBytes: fileSizeBytes,
            downloadedAt: downloadedAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TileMetadataTableTableProcessedTableManager = ProcessedTableManager<
    _$TileDatabase,
    $TileMetadataTableTable,
    TileMetadataTableData,
    $$TileMetadataTableTableFilterComposer,
    $$TileMetadataTableTableOrderingComposer,
    $$TileMetadataTableTableAnnotationComposer,
    $$TileMetadataTableTableCreateCompanionBuilder,
    $$TileMetadataTableTableUpdateCompanionBuilder,
    (
      TileMetadataTableData,
      BaseReferences<_$TileDatabase, $TileMetadataTableTable,
          TileMetadataTableData>
    ),
    TileMetadataTableData,
    PrefetchHooks Function()>;

class $TileDatabaseManager {
  final _$TileDatabase _db;
  $TileDatabaseManager(this._db);
  $$TileMetadataTableTableTableManager get tileMetadataTable =>
      $$TileMetadataTableTableTableManager(_db, _db.tileMetadataTable);
}
