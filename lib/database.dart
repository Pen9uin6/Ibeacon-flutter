import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class Beacon {
  String id; // 此存取id
  String uuid; // iBeacon UUID
  String item; // 與此UUID綁定的物品名稱
  int? door; // 是否是門口那顆
  int isMissing; // 是否遺失

  Beacon({ required this.id, required this.uuid, this.item = '', this.door, this.isMissing = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'item': item,
      'door': door,
      'isMissing': isMissing,
    };
  }

  @override
  String toString() {
    return 'Beacon(id: $id, uuid: $uuid, item: $item, door: $door, isMissing: $isMissing)';
  }
}

class BeaconDB {
  static Database? _database;
  static final _databaseName = "Beacons1.db";
  static final _databaseVersion = 1;
  static final table = 'Beacons';

  BeaconDB._privateConstructor();
  static final BeaconDB instance = BeaconDB._privateConstructor();

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE Beacons(id TEXT PRIMARY KEY, uuid TEXT, item TEXT, door INTEGER, isMissing INTEGER)');
  }

  static Future<int> insert(Beacon beacon) async {
    Database? db = await instance.database;
    return await db!.insert(table, beacon.toMap());
  }

  static Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database? db = await instance.database;
    return await db!.query(table);
  }

  static Future<int?> queryRowCount() async {
    Database? db = await instance.database;
    return Sqflite.firstIntValue(
        await db!.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  static Future<int> update(Beacon beacon) async {
    Database? db = await instance.database;
    return await db!
        .update(table, beacon.toMap(), where: 'id = ?', whereArgs: [beacon.id]);
  }

  static Future<int> delete(String id) async {
    Database? db = await instance.database;
    // 確認該 Beacon 是否存在
    final existingBeacon = await db!.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existingBeacon.isEmpty) {
      return 0;
    }
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  //////////////////////////////////////////////////////
  // Read all
  static Future<List<Beacon>> getBeacons() async {
    Database? db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query('Beacons');
    return List.generate(maps.length, (i) {
      return Beacon(
        id: maps[i]['id'],
        uuid: maps[i]['uuid'],
        item: maps[i]['item'],
        door: maps[i]['door'],
        isMissing: maps[i]['isMissing']
      );
    });
  }

  // 根據UUID查找 Beacon
  static Future<Beacon?> getBeaconByUUID(String uuid) async{
    Database? db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'Beacons',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (maps.isNotEmpty) {
      return Beacon(
        id: maps.first['id'],
        uuid: maps.first['uuid'],
        item: maps.first['item'],
        door: maps.first['door'],
        isMissing: maps.first['isMissing'],
      );
    }
    return null;
  }

  // 根據物品名稱查找 Beacon
  static Future<Beacon?> getBeaconByName(String item) async {
    Database? db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'Beacons',
      where: 'item = ?',
      whereArgs: [item],
    );
    if (maps.isNotEmpty) {
      return Beacon(
        id: maps.first['id'],
        uuid: maps.first['uuid'],
        item: maps.first['item'],
        door: maps.first['home'],
        isMissing: maps.first['isMissing'],
      );
    }
    return null;
  }
}
