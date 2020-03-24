import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

class TileStorageCachingManager {
  static TileStorageCachingManager _instance;

  /// default value of maximum number of persisted tiles,
  /// and average tile size ~ 0.017 mb -> so default cache size ~ 51 mb
  static int kDefaultMaxTileCount = 3000;
  static final kMaxRefreshRowsCount = 5;
  static final String _kDbName = 'tile_cach.db';
  static final String _kTilesTable = 'tiles';
  static final String _kZoomLevelColumn = 'zoom_level';
  static final String _kTileRowColumn = 'tile_row';
  static final String _kTileColumnColumn = 'tile_column';
  static final String _kTileDataColumn = 'tile_data';
  static final String _kIdColumn = '_id';
  static final String _kUpdateDateColumn = '_lastUpdateColumn';
  static final String _kSizeTriggerName = 'size_trigger';
  Database _db;

  final _lock = Lock();

  static TileStorageCachingManager _getInstance() {
    _instance ??= TileStorageCachingManager._internal();
    return _instance;
  }

  factory TileStorageCachingManager() => _getInstance();

  TileStorageCachingManager._internal();

  Future<Database> get database async {
    if (_db == null) {
      await _lock.synchronized(() async {
        if (_db == null) {
          final path = await _path;
          _db = await openDatabase(
            path,
            version: 1,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          );
        }
      });
    }
    return _db;
  }

  Future<String> get _path async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _kDbName);
    await Directory(databasePath).create(recursive: true);
    return path;
  }

  static String _getSizeTriggerQuery(int tileCount) => '''
        CREATE TRIGGER $_kSizeTriggerName 
	      BEFORE INSERT on $_kTilesTable
	      WHEN (select count(*) from $_kTilesTable) > $tileCount
	        BEGIN
		        DELETE from $_kTilesTable where $_kIdColumn in 
		          (select $_kIdColumn  from $_kTilesTable order by $_kUpdateDateColumn asc LIMIT $kMaxRefreshRowsCount);
	        END;
      ''';

  void _onConfigure(Database db) async {}

  void _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute('DROP TABLE IF EXISTS $_kTilesTable');
    batch.execute('''
      CREATE TABLE $_kTilesTable(
        $_kIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
        $_kZoomLevelColumn INTEGER NOT NULL,
        $_kTileColumnColumn INTEGER NOT NULL,
        $_kTileRowColumn INTEGER NOT NULL,
        $_kTileDataColumn BLOB NOT NULL,
        $_kUpdateDateColumn INTEGER NOT NULL
      )
    ''');
    batch.execute('''
       CREATE UNIQUE INDEX  tile_index ON $_kTilesTable (
         $_kZoomLevelColumn, 
         $_kTileColumnColumn, 
         $_kTileRowColumn
       )
    ''');
    batch.execute(_getSizeTriggerQuery(kDefaultMaxTileCount));
    await batch.commit();
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<Tuple2<Uint8List, DateTime>> getTile(Coords coords,
      {Duration valid}) async {
    List<Map> result = await (await database)
        .rawQuery('select $_kTileDataColumn, $_kUpdateDateColumn from tiles '
            'where $_kZoomLevelColumn = ${coords.z} AND '
            '$_kTileColumnColumn = ${coords.x} AND '
            '$_kTileRowColumn = ${coords.y} limit 1');
    return result.isNotEmpty
        ? Tuple2(
            result.first[_kTileDataColumn],
            DateTime.fromMicrosecondsSinceEpoch(
                result.first[_kUpdateDateColumn]))
        : null;
  }

  Future<void> saveTile(Uint8List tile, Coords cords) async {
    await (await database).insert(
        _kTilesTable,
        {
          _kZoomLevelColumn: cords.z,
          _kTileColumnColumn: cords.x,
          _kTileRowColumn: cords.y,
          _kUpdateDateColumn: DateTime.now().millisecondsSinceEpoch,
          _kTileDataColumn: tile
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> changeMaxTileCount(int maxTileCount) async {
    final db = await _getInstance().database;
    await db.transaction((txn) async {
      await txn.execute('DROP TRIGGER $_kSizeTriggerName');
      await txn.execute(_getSizeTriggerQuery(maxTileCount));
    });
  }
}
