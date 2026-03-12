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
    // Tăng version lên để SQLite tự động cập nhật cấu trúc bảng
    String path = join(await getDatabasesPath(), 'chatflow_v11.db'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            username TEXT PRIMARY KEY,
            password TEXT,
            avatarUrl TEXT,
            displayName TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE groups(
            id TEXT PRIMARY KEY,
            name TEXT,
            avatarUrl TEXT,
            createdBy TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT,
            senderId TEXT,
            receiverId TEXT,
            roomId TEXT,
            content TEXT,
            imageUrl TEXT, 
            createdAt TEXT,
            localOwnerId TEXT,
            isUnsent INTEGER DEFAULT 0,
            isLiked INTEGER DEFAULT 0,
            isSeen INTEGER DEFAULT 0,
            isEdited INTEGER DEFAULT 0,
            type TEXT DEFAULT 'text',
            replyTo TEXT,
            PRIMARY KEY (id, localOwnerId)
          )
        ''');
      },
    );
  }

  Future<void> insertMessage(MessageModel message) async {
    final db = await database;
    Map<String, dynamic> data = message.toJson();
    data['localOwnerId'] = message.senderId;
    // Chuyển boolean sang integer cho SQLite
    data['isUnsent'] = message.isUnsent ? 1 : 0;
    data['isLiked'] = message.isLiked ? 1 : 0;
    data['isSeen'] = message.isSeen ? 1 : 0;
    
    await db.insert('messages', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageModel>> getMessages(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages', where: 'roomId = ?', orderBy: 'createdAt ASC');
    return List.generate(maps.length, (i) => MessageModel.fromJson(maps[i]));
  }

  Future<bool> register(String username, String password) async {
    final db = await database;
    try {
      await db.insert('users', {'username': username, 'password': password}, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) { return false; }
  }
}
