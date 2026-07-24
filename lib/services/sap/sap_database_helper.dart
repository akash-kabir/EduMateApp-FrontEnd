import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/sap/attendance_record.dart';

class SapDatabaseHelper {
  static final SapDatabaseHelper instance = SapDatabaseHelper._init();
  static Database? _database;

  SapDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sap_attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE attendance_records (
  id $idType,
  subject $textType,
  totalClasses $intType,
  presentClasses $intType,
  semesterId $textType,
  lastSyncedAt $textType
)
''');
  }

  Future<void> insertBatch(List<AttendanceRecord> records) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var record in records) {
      batch.insert('attendance_records', record.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<AttendanceRecord>> getAttendanceForSemester(String semesterId) async {
    final db = await instance.database;
    final maps = await db.query(
      'attendance_records',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
    );

    if (maps.isNotEmpty) {
      return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<void> clearAttendanceForSemester(String semesterId) async {
    final db = await instance.database;
    await db.delete(
      'attendance_records',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
    );
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('attendance_records');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
