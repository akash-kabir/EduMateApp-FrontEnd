import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ScheduleDatabaseHelper {
  static final ScheduleDatabaseHelper instance = ScheduleDatabaseHelper._init();
  static Database? _database;

  ScheduleDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('schedule_cache.db');
    await _ensureTables(_database!);
    return _database!;
  }

  Future<void> _ensureTables(Database db) async {
    try {
      await db.execute('''
CREATE TABLE IF NOT EXISTS schedule_cache (
  semester TEXT PRIMARY KEY,
  data_json TEXT,
  updated_at_server TEXT,
  last_synced_local TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS electives_cache (
  semester TEXT PRIMARY KEY,
  data_json TEXT,
  updated_at_server TEXT,
  last_synced_local TEXT
)
''');
    } catch (e) {
      // Ignore
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE electives_cache (
  semester TEXT PRIMARY KEY,
  data_json TEXT,
  updated_at_server TEXT,
  last_synced_local TEXT
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE schedule_cache (
  semester TEXT PRIMARY KEY,
  data_json TEXT,
  updated_at_server TEXT,
  last_synced_local TEXT
)
''');
    await db.execute('''
CREATE TABLE electives_cache (
  semester TEXT PRIMARY KEY,
  data_json TEXT,
  updated_at_server TEXT,
  last_synced_local TEXT
)
''');
  }

  Future<void> cacheScheduleData(String semester, dynamic data, {String? serverUpdatedAt}) async {
    final db = await instance.database;
    final String jsonString = jsonEncode(data);
    final String now = DateTime.now().toIso8601String();

    await db.insert(
      'schedule_cache',
      {
        'semester': semester,
        'data_json': jsonString,
        'updated_at_server': serverUpdatedAt ?? '',
        'last_synced_local': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedScheduleData(String semester) async {
    final db = await instance.database;

    final maps = await db.query(
      'schedule_cache',
      columns: ['data_json'],
      where: 'semester = ?',
      whereArgs: [semester],
    );

    if (maps.isNotEmpty) {
      final jsonString = maps.first['data_json'] as String;
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>?;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<String?> getServerUpdatedAt(String semester) async {
    final db = await instance.database;
    final maps = await db.query(
      'schedule_cache',
      columns: ['updated_at_server'],
      where: 'semester = ?',
      whereArgs: [semester],
    );

    if (maps.isNotEmpty) {
      return maps.first['updated_at_server'] as String?;
    }
    return null;
  }

  Future<void> cacheElectiveData(String semester, dynamic data, {String? serverUpdatedAt}) async {
    final db = await instance.database;
    final String jsonString = jsonEncode(data);
    final String now = DateTime.now().toIso8601String();

    await db.insert(
      'electives_cache',
      {
        'semester': semester,
        'data_json': jsonString,
        'updated_at_server': serverUpdatedAt ?? '',
        'last_synced_local': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedElectiveData(String semester) async {
    final db = await instance.database;

    final maps = await db.query(
      'electives_cache',
      columns: ['data_json'],
      where: 'semester = ?',
      whereArgs: [semester],
    );

    if (maps.isNotEmpty) {
      final jsonString = maps.first['data_json'] as String;
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>?;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<String?> getServerUpdatedAtForElectives(String semester) async {
    final db = await instance.database;
    final maps = await db.query(
      'electives_cache',
      columns: ['updated_at_server'],
      where: 'semester = ?',
      whereArgs: [semester],
    );

    if (maps.isNotEmpty) {
      return maps.first['updated_at_server'] as String?;
    }
    return null;
  }

  Future<void> clearCache() async {
    final db = await instance.database;
    await db.delete('schedule_cache');
    await db.delete('electives_cache');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
