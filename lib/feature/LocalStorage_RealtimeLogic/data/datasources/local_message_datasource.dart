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
    // Nâng cấp lên v10 để hỗ trợ Nhóm
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

  // --- LOGIC NHÓM ---
  Future<void> createGroup(String name, List<String> memberUsernames, String creator) async {
    final db = await database;
    String groupId = "group_${DateTime.now().millisecondsSinceEpoch}";
    
    // 1. Tạo nhóm
    await db.insert('groups', {
      'id': groupId,
      'name': name,
      'avatarUrl': "https://ui-avatars.com/api/?name=$name&background=random",
      'createdBy': creator,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 2. Thêm các thành viên (bao gồm cả người tạo)
    for (var username in [...memberUsernames, creator]) {
      await db.insert('group_members', {
        'groupId': groupId,
        'username': username,
      });
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

  // --- LOGIC USER & CHAT ---
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

  Future<List<Map<String, dynamic>>> getAllUsersExceptMe(String me) async {
    final db = await database;
    return await db.query('users', where: 'username != ?', whereArgs: [me]);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId) async {
    final db = await database;
    return await db.query('users', where: 'username LIKE ? AND username != ?', whereArgs: ['%$query%', currentUserId]);
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

  Future<List<MessageModel>> getMessages(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages', where: 'roomId = ?', whereArgs: [roomId], orderBy: 'createdAt ASC');
    return List.generate(maps.length, (i) => MessageModel.fromJson(maps[i]));
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
    // Lưu cho người gửi
    Map<String, dynamic> data = message.toJson();
    data['localOwnerId'] = message.senderId;
    await db.insert('messages', data, conflictAlgorithm: ConflictAlgorithm.replace);

    // Nếu là chat 1-1 (có receiverId), lưu cho người nhận
    if (message.receiverId != null && message.receiverId!.isNotEmpty) {
      Map<String, dynamic> rData = message.toJson();
      rData['localOwnerId'] = message.receiverId;
      await db.insert('messages', rData, conflictAlgorithm: ConflictAlgorithm.replace);
    } 
    // Nếu là chat nhóm, chúng ta cần lưu cho tất cả thành viên trong nhóm (giả lập server)
    else if (message.roomId.startsWith("group_")) {
      final members = await db.query('group_members', where: 'groupId = ?', whereArgs: [message.roomId]);
      for (var member in members) {
        String mUser = member['username'] as String;
        if (mUser != message.senderId) {
          Map<String, dynamic> gData = message.toJson();
          gData['localOwnerId'] = mUser;
          await db.insert('messages', gData, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
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
