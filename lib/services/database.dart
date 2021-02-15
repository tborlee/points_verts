import 'package:path/path.dart';
import 'package:points_verts/models/my_walk.dart';
import 'package:points_verts/models/walk.dart';
import 'package:points_verts/models/walk_filter.dart';
import 'package:points_verts/services/prefs.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer';

const String TAG = "dev.alpagaga.points_verts.DBProvider";

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await getDatabaseInstance();
    return _database;
  }

  Future<Database> getDatabaseInstance() async {
    log("Creating new database client", name: TAG);
    return openDatabase(
        join(await getDatabasesPath(), 'points_verts_database.db'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        version: 7);
  }

  Future<void> _createWalksTable(Database db) async {
    await PrefsProvider.prefs.setString("last_walk_update", null);
    await db.execute("DROP TABLE IF EXISTS walks");
    await db.execute(
        "CREATE TABLE walks(id INTEGER PRIMARY KEY, city TEXT, entity TEXT, type TEXT, province TEXT, date DATE, longitude DOUBLE, latitude DOUBLE, status TEXT, meeting_point TEXT, meeting_point_info TEXT, organizer TEXT, contact_first_name TEXT, contact_last_name TEXT, contact_phone_number TEXT, ign TEXT, transport TEXT, fifteen_km TINYINT, wheelchair TINYINT, stroller TINYINT, extra_orientation TINYINT, extra_walk TINYINT, guided TINYINT, bike TINYINT, mountain_bike TINYINT, water_supply TINYINT, be_wapp TINYINT, last_updated DATETIME)");
    await db.execute("CREATE INDEX walks_date_index on walks(date)");
    await db.execute("CREATE INDEX walks_city_index on walks(city)");
  }

  Future<void> _createMyWalksTable(Database db) async {
    await db.execute("DROP TABLE IF EXISTS my_walks");
    await db.execute(
        "CREATE TABLE my_walks(id INTEGER PRIMARY KEY, walk_id INTEGER, score TINYINT, created_at DATETIME, updated_at DATETIME, FOREIGN KEY (walk_id) REFERENCES walks(id))");
  }

  void _onCreate(Database db, int version) async {
    await _createWalksTable(db);
    await _createMyWalksTable(db);
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion <= 5) {
      await _createWalksTable(db);
    }
    if (oldVersion <= 6) {
      await _createMyWalksTable(db);
    }
  }

  Future<List<DateTime>> getWalkDates() async {
    final Database db = await database;
    final now = DateTime.now();
    final lastMidnight = new DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> maps = await db.query('walks',
        columns: ['date'],
        groupBy: "date",
        orderBy: "date ASC",
        where: 'date >= ?',
        whereArgs: [lastMidnight.toIso8601String()]);
    return List.generate(maps.length, (i) {
      return DateTime.parse(maps[i]['date']);
    });
  }

  Future<void> insertWalks(List<Walk> walks) async {
    log("Inserting ${walks.length} walks in database", name: TAG);
    final Database db = await database;
    final Batch batch = db.batch();
    for (Walk walk in walks) {
      batch.insert("walks", walk.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<void> insertMyWalk(MyWalk myWalk) async {
    log("Inserting my walk in database", name: TAG);
    final Database db = await database;
    await db.insert("my_walks", myWalk.toMap());
  }

  Future<int> deleteMyWalk(MyWalk myWalk) async {
    log("Deleting my walk with id ${myWalk.id}");
    final Database db = await database;
    return db.delete("my_walks", where: "id = ?", whereArgs: [myWalk.id]);
  }

  Future<int> deleteOldWalks() async {
    final now = DateTime.now();
    final lastMidnight = new DateTime(now.year, now.month, now.day);
    log("Deleting old walks before $lastMidnight", name: TAG);
    final Database db = await database;
    return await db.delete("walks",
        where: 'date < ?', whereArgs: [lastMidnight.toIso8601String()]);
  }

  Future<List<Walk>> getSortedWalks({WalkFilter filter}) async {
    final Database db = await database;
    List<Map<String, dynamic>> maps;
    if (filter != null) {
      maps = await db.query('walks',
          where: _generateWhereFromFilter(filter),
          whereArgs: _generateArgsFromFilter(filter),
          orderBy: "city ASC");
    } else {
      maps = await db.query('walks', orderBy: "city ASC");
    }
    return List.generate(maps.length, (i) {
      return _walkFromDb(maps, i);
    });
  }

  String _generateWhereFromFilter(WalkFilter filter) {
    String where = "1=1";
    if (filter.filterByProvince()) {
      List<String> provinces = filter.provinceFilter();
      where = where + " and province in ${provinces.map((e) => "?")}";
    }
    if (!filter.cancelledWalks) {
      where = where + " and status != ?";
    }
    if (filter.fifteenKm) where = where + " and fifteen_km = 1";
    if (filter.wheelchair) where = where + " and wheelchair = 1";
    if (filter.stroller) where = where + " and stroller = 1";
    if (filter.extraOrientation) where = where + " and extra_orientation = 1";
    if (filter.extraWalk) where = where + " and extra_walk = 1";
    if (filter.guided) where = where + " and guided = 1";
    if (filter.bike) where = where + " and bike = 1";
    if (filter.mountainBike) where = where + " and mountain_bike = 1";
    if (filter.waterSupply) where = where + " and water_supply = 1";
    if (filter.beWapp) where = where + " and be_wapp = 1";
    if (filter.transport) where = where + " and transport is not null";
    return where;
  }

  List<dynamic> _generateArgsFromFilter(WalkFilter filter) {
    List<dynamic> args = [];
    if (filter.filterByProvince()) {
      List<String> provinces = filter.provinceFilter();
      args.addAll(provinces);
    }
    if (!filter.cancelledWalks) {
      args.add("Annulé");
    }
    return args;
  }

  Future<List<Walk>> getWalks(DateTime date, {WalkFilter filter}) async {
    log("Retrieving walks from database for $date", name: TAG);
    if (date == null) return [];
    final Database db = await database;
    List<Map<String, dynamic>> maps;
    if (filter != null) {
      String where = "date = ?" + _generateWhereFromFilter(filter);
      List<dynamic> args = [date.toIso8601String()];
      args.addAll(_generateArgsFromFilter(filter));
      maps = await db.query('walks', where: where, whereArgs: args);
    } else {
      maps = await db.query('walks',
          where: 'date = ?', whereArgs: [date.toIso8601String()]);
    }
    return List.generate(maps.length, (i) {
      return _walkFromDb(maps, i);
    });
  }

  Future<Walk> getWalk(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('walks', where: 'id = ?', whereArgs: [id]);
    if (maps.length == 1) {
      return _walkFromDb(maps, 0);
    } else {
      return null;
    }
  }

  Future<List<Walk>> getWalksByIds(List<int> ids) async {
    final Database db = await database;
    List<Map<String, dynamic>> maps =
        await db.query("walks", where: 'id IN (${ids.join(', ')})');
    return List.generate(maps.length, (i) {
      return _walkFromDb(maps, i);
    });
  }

  Future<List<MyWalk>> getMyWalks() async {
    log("Retrieving my walks from database", name: TAG);
    final Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('my_walks');
    List<int> walkIds =
        List.generate(maps.length, (index) => maps[index]['walk_id']);
    List<Walk> walks = await getWalksByIds(walkIds);
    return List.generate(maps.length, (i) {
      Walk walk = walks.firstWhere(
          (element) => element.id == maps[i]['walk_id'],
          orElse: () => null);
      return _myWalkFromDb(maps, i, walk);
    });
  }

  Walk _walkFromDb(List<Map<String, dynamic>> maps, int i) {
    return Walk(
        id: maps[i]['id'],
        city: maps[i]['city'],
        entity: maps[i]['entity'],
        type: maps[i]['type'],
        province: maps[i]['province'],
        date: DateTime.parse(maps[i]['date']),
        long: maps[i]['longitude'],
        lat: maps[i]['latitude'],
        status: maps[i]['status'],
        meetingPoint: maps[i]['meeting_point'],
        meetingPointInfo: maps[i]['meeting_point_info'],
        organizer: maps[i]['organizer'],
        contactFirstName: maps[i]['contact_first_name'],
        contactLastName: maps[i]['contact_last_name'],
        contactPhoneNumber: maps[i]['contact_phone_number'] != null
            ? maps[i]['contact_phone_number'].toString()
            : null,
        ign: maps[i]['ign'],
        transport: maps[i]['transport'],
        fifteenKm: maps[i]['fifteen_km'] == 1 ? true : false,
        wheelchair: maps[i]['wheelchair'] == 1 ? true : false,
        stroller: maps[i]['stroller'] == 1 ? true : false,
        extraOrientation: maps[i]['extra_orientation'] == 1 ? true : false,
        extraWalk: maps[i]['extra_walk'] == 1 ? true : false,
        guided: maps[i]['guided'] == 1 ? true : false,
        bike: maps[i]['bike'] == 1 ? true : false,
        mountainBike: maps[i]['mountain_bike'] == 1 ? true : false,
        waterSupply: maps[i]['water_supply'] == 1 ? true : false,
        beWapp: maps[i]['be_wapp'] == 1 ? true : false,
        lastUpdated: DateTime.parse(maps[i]['last_updated']));
  }

  MyWalk _myWalkFromDb(List<Map<String, dynamic>> maps, int i, Walk walk) {
    return MyWalk(
        id: maps[i]['id'],
        walk: walk,
        score: maps[i]['score'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']));
  }
}
