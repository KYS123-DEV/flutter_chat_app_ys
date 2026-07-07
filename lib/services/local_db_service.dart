import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_chat_app_ys/models/chat_model.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Firestore의 messages 하위 컬렉션 구조를 SQLite 테이블로 정의
        // roomId 필드를 추가하여 어떤 방의 메시지인지 구별.
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            roomId TEXT,
            text TEXT,
            createdAt TEXT,
            senderId TEXT,
            senderName TEXT,
            senderProfile TEXT
          )
        ''');

        // 정렬 및 방별 조회를 최적화하기 위한 인덱스 생성
        await db.execute(
          'CREATE INDEX idx_room_time ON messages (roomId, createdAt DESC)',
        );

        // 채팅방 목록 캐시 테이블 신설
        await db.execute('''
          CREATE TABLE chat_rooms (
            roomId TEXT PRIMARY KEY,
            roomName TEXT,
            type TEXT,
            lastMessage TEXT,
            lastTime TEXT,
            participants TEXT,
            unreadCounts TEXT
          )
        ''');
      },
    );
  }

  // 특정 채팅방의 로컬 캐시 데이터 조회
  Future<List<ChatModel>> getMessages(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'roomId = ?',
      whereArgs: [roomId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) {
      return ChatModel(
        text: map['text'] ?? '',
        createdAt: DateTime.parse(map['createdAt']),
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        senderProfile: map['senderProfile'] ?? '',
      );
    }).toList();
  }

  // 서버에서 가져온 최신 메시지들을 로컬 SQLite에 벌크(Bulk) 저장
  Future<void> saveMessages(
    String roomId,
    List<Map<String, dynamic>> rawChats,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (var chat in rawChats) {
      batch.insert(
        'messages',
        {
          'id': chat['id'], // Firestore Document ID를 Primary Key로 활용하여 중복 방지
          'roomId': roomId,
          'text': chat['text'] ?? '',
          'createdAt': chat['createdAt'] != null
              ? (chat['createdAt'] as DateTime).toIso8601String()
              : DateTime.now().toIso8601String(),
          'senderId': chat['senderId'] ?? '',
          'senderName': chat['senderName'] ?? '',
          'senderProfile': chat['senderProfile'] ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // 이미 존재하면 덮어쓰기
      );
    }
    await batch.commit(noResult: true);
  }

  // 로컬에 저장된 채팅방 전체 목록 최신순 조회
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_rooms',
      orderBy: 'lastTime DESC',
    );
    return maps;
  }

  // 서버에서 동기화된 채팅방 정보 벌크 Upsert
  Future<void> saveChatRooms(List<Map<String, dynamic>> rooms) async {
    final db = await database;
    final batch = db.batch();

    for (var room in rooms) {
      batch.insert(
        'chat_rooms',
        room,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
