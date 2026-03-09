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
    String path = join(await getDatabasesPath(), 'chatflow_v10.db'); 
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
          CREATE TABLE groups(
            id TEXT PRIMARY KEY,
            name TEXT,
            avatarUrl TEXT,
            createdBy TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE group_members(
            groupId TEXT,
            username TEXT,
            PRIMARY KEY (groupId, username)
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
            PRIMARY KEY (id, localOwnerId)
          )
        ''');
      },
    );
  }

  Future<void> saveGroupLocally(String id, String name, List<String> members, String creator) async {
    final db = await database;
    await db.insert('groups', {
      'id': id,
      'name': name,
      'avatarUrl': "https://ui-avatars.com/api/?name=$name&background=random",
      'createdBy': creator,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    for (var username in members) {
      await db.insert('group_members', {
        'groupId': id,
        'username': username,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getMyGroups(String username) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.groupId
      WHERE gm.username = ?
    ''', [username]);
  }

  Future<bool> register(String username, String password) async {
    final db = await database;
    try {
      String avatar = "https://i.pravatar.cc/150?u=$username";
      await db.insert('users', {'username': username, 'password': password, 'avatarUrl': avatar});
      return true;
    } catch (e) { return false; }
  }

  Future<bool> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]);
    return maps.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getChatContacts(String currentUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT users.username, users.avatarUrl 
      FROM users 
      INNER JOIN messages ON (users.username = messages.senderId OR users.username = messages.receiverId)
      WHERE messages.localOwnerId = ? AND users.username != ?
    ''', [currentUserId, currentUserId]);
    return maps;
  }

  Future<void> sendRealMessage(MessageModel message) async {
    final db = await database;
    Map<String, dynamic> data = message.toJson();
    data['localOwnerId'] = message.senderId;
    await db.insert('messages', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
