import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maritime_sync_queue.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE payload_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            battery INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertPayload(Map<String, dynamic> payload) async {
    final db = await instance.database;
    return await db.insert('payload_queue', payload);
  }

  Future<List<Map<String, dynamic>>> getPendingPayloads() async {
    final db = await instance.database;
    return await db.query('payload_queue', orderBy: 'timestamp ASC');
  }

  Future<void> clearQueue() async {
    final db = await instance.database;
    await db.delete('payload_queue');
  }
}
