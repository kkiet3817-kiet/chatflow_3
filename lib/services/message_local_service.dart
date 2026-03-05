import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MessageLocalService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'simple_chat.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  static Future<void> saveMessage(String content) async {
    final db = await database;
    await db.insert('messages', {
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<String>> loadMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages', orderBy: 'timestamp ASC');
    return List.generate(maps.length, (i) => maps[i]['content'] as String);
  }
}
