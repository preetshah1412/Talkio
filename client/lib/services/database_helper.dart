import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'talkio_offline.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderId TEXT,
        senderName TEXT,
        content TEXT,
        timestamp INTEGER,
        isMe INTEGER
      )
    ''');
    // We could add a 'chatId' or 'peerId' if we want to separate chats clearly.
    // For now, let's keep it simple or assume peerId is needed.
    // Let's add peerId to group messages by conversation.
    await db
        .execute('''
      ALTER TABLE messages ADD COLUMN peerId TEXT;
    ''')
        .catchError((e) {
          /* Ignore if fails during onCreate in dev */
        });
  }

  // Insert Message
  Future<int> insertMessage(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('messages', row);
  }

  // Get Messages for a peer
  Future<List<Map<String, dynamic>>> getMessages(String peerId) async {
    Database db = await database;
    return await db.query(
      'messages',
      where: 'peerId = ?',
      whereArgs: [peerId],
      orderBy: 'timestamp ASC',
    );
  }
}
