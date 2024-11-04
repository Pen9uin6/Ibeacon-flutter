import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class Beacon {
  final String? id; // 此存取id
  final String? uuid; // iBeacon UUID
  final String item; // 與此UUID綁定的物品名稱
  final int? door; // 是否是門口那顆

  Beacon({this.id, this.uuid, this.item = '', this.door});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'item': item,
      'home': door,
    };
  }

  Beacon copyWith({
    String? id,
    String? uuid,
    String? item,
    int? door,
  }) {
    return Beacon(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      item: item ?? this.item,
      door: door ?? this.door,
    );
  }

  @override
  String toString() {
    return 'Beacon(id: $id, uuid: $uuid, item: $item, door: $door)';
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
        'CREATE TABLE Beacons(id TEXT PRIMARY KEY, uuid TEXT, item TEXT, home INTEGER)');
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
    return await db!.delete(table, where: 'id = ?', whereArgs: [id]);
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
        door: maps[i]['home'],
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
        door: maps.first['home'],
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
      );
    }
    return null;
  }
}
