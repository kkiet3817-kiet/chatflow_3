import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_model.dart';

class LocalMessageDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'chat_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            roomId TEXT,
            senderId TEXT,
            content TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  Future<List<MessageModel>> getMessages(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'roomId = ?',
      whereArgs: [roomId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return MessageModel.fromJson(maps[i]);
    });
  }

  Future<void> saveMessage(MessageModel message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
  }
}
