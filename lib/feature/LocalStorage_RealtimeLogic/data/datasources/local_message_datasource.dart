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
    String path = join(await getDatabasesPath(), 'chatflow_v8.db'); // Nâng cấp v8
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            username TEXT PRIMARY KEY,
            password TEXT,
            avatarUrl TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT,
            senderId TEXT,
            receiverId TEXT,
            content TEXT,
            createdAt TEXT,
            localOwnerId TEXT,
            isUnsent INTEGER DEFAULT 0,
            isLiked INTEGER DEFAULT 0,
            PRIMARY KEY (id, localOwnerId)
          )
        ''');
      },
    );
  }

  Future<bool> register(String username, String password) async {
    final db = await database;
    try {
      String avatar = "https://i.pravatar.cc/150?u=$username";
      await db.insert('users', {'username': username, 'password': password, 'avatarUrl': avatar});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]);
    return maps.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId) async {
    final db = await database;
    return await db.query(
      'users',
      where: 'username LIKE ? AND username != ?',
      whereArgs: ['%$query%', currentUserId],
    );
  }

  // Lấy danh sách những người đã từng chat cùng (Unique)
  Future<List<Map<String, dynamic>>> getChatContacts(String currentUserId) async {
    final db = await database;
    // Tìm tất cả senderId hoặc receiverId trong các tin nhắn mà currentUserId là chủ sở hữu
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT users.username, users.avatarUrl 
      FROM users 
      INNER JOIN messages ON (users.username = messages.senderId OR users.username = messages.receiverId)
      WHERE messages.localOwnerId = ? AND users.username != ?
    ''', [currentUserId, currentUserId]);
    return maps;
  }

  Future<List<MessageModel>> getChatHistory(String currentUserId, String otherUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: '((senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)) AND localOwnerId = ?',
      whereArgs: [currentUserId, otherUserId, otherUserId, currentUserId, currentUserId],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => MessageModel.fromJson(maps[i]));
  }

  Future<void> sendRealMessage(MessageModel message) async {
    final db = await database;
    Map<String, dynamic> senderData = message.toJson();
    senderData['localOwnerId'] = message.senderId;
    await db.insert('messages', senderData, conflictAlgorithm: ConflictAlgorithm.replace);

    Map<String, dynamic> receiverData = message.toJson();
    receiverData['localOwnerId'] = message.receiverId;
    await db.insert('messages', receiverData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMessage(MessageModel message, String currentUserId) async {
    final db = await database;
    await db.update('messages', message.toJson(), where: 'id = ? AND localOwnerId = ?', whereArgs: [message.id, currentUserId]);
  }

  Future<void> deleteMessage(String id, String currentUserId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ? AND localOwnerId = ?', whereArgs: [id, currentUserId]);
  }
}
