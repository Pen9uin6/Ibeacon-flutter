import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Beacon {
  final String? id; // 此存取id
  final String? uuid; // iBeacon UUID
  final String item; // 與此UUID綁定的物品名稱
  final int? home; // 是否是門口那顆

  Beacon({this.id, this.uuid, this.item = '', this.home});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'item': item,
      'home': home,
    };
  }
}

class BeaconDB {
  static Database? database;

  // init
  static Future<Database> initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'Beacons.db'),
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE Beacons(id TEXT PRIMARY KEY, uuid TEXT, item TEXT, home INTEGER)');
      },
      version: 1,
    );
    print('database initialized!');
    return database!;
  }

  // connect
  static Future<Database> getDBConnect() async {
    if (database != null) {
      return database!;
    }
    return await initDatabase();
  }

  // Create
  static Future<void> addBeacon(Beacon beacon) async {
    final Database db = await getDBConnect();
    await db.insert(
      'Beacons',
      beacon.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  static Future<List<Beacon>> getBeacons() async {
    final Database db = await getDBConnect();
    final List<Map<String, dynamic>> maps = await db.query('Beacons');
    return List.generate(maps.length, (i) {
      return Beacon(
        id: maps[i]['id'],
        uuid: maps[i]['uuid'],
        item: maps[i]['item'],
        home: maps[i]['home'],
      );
    });
  }

  // Update
  static Future<void> updateBeacon(Beacon beacon) async {
    final Database db = await getDBConnect();
    await db.update(
      'Beacons',
      beacon.toMap(),
      where: 'id = ?',
      whereArgs: [beacon.id],
    );
  }

  // Delete
  static Future<void> deleteBeacon(String id) async {
    final Database db = await getDBConnect();
    await db.delete(
      'Beacons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
