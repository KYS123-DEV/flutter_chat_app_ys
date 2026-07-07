import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_app_ys/models/chat_model.dart';
import 'package:flutter_chat_app_ys/services/local_db_service.dart';

class ChatRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDbService _localDb = LocalDbService();

  // 실시간 UI 업데이트를 중계할 브로드캐스트 스트림 컨트롤러
  StreamController<List<ChatModel>>? _chatStreamController;
  StreamSubscription<QuerySnapshot>? _serverSubscription;

  // 채팅방 목록 중계를 위한 브로드캐스트 스트림 컨트롤러
  StreamController<List<Map<String, dynamic>>>? _roomsStreamController;
  StreamSubscription<QuerySnapshot>? _roomsSubscription;

  // 채팅방 목록 스트림
  Stream<List<Map<String, dynamic>>> getChatRoomsStream(String currentUid) {
    // 기존 스트림이 있다면 닫아주고 새로 생성하여 상태 꼬임 방지
    if (_roomsStreamController == null || _roomsStreamController!.isClosed) {
      _roomsStreamController =
          StreamController<List<Map<String, dynamic>>>.broadcast();
    }

    // 1. 로컬 캐시를 즉시 반환하여 무대기 화면 진입 보장
    _loadLocalChatRooms();

    // 2. 내가 참여자로 포함된 방의 실시간 변화 관측
    _roomsSubscription?.cancel();
    _roomsSubscription = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) {
            if (_roomsStreamController != null &&
                !_roomsStreamController!.isClosed) {
              _roomsStreamController!.add([]);
            }
            return;
          }

          List<Map<String, dynamic>> processedRooms = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();

            // DateTime 포맷팅 안정성 확보
            String lastTimeIso = DateTime.now().toIso8601String();
            if (data['lastTime'] != null) {
              lastTimeIso = (data['lastTime'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }

            // 복잡한 자료형(List, Map)을 SQLite가 인식하도록 JSON String화 변환 처리
            processedRooms.add({
              'roomId': doc.id,
              'roomName': data['roomName'] ?? '그룹채팅',
              'type': data['type'] ?? 'single',
              'lastMessage': data['lastMessage'] ?? '',
              'lastTime': lastTimeIso,
              'participants': jsonEncode(data['participants'] ?? []),
              'unreadCounts': jsonEncode(data['unreadCounts'] ?? {}),
            });
          }

          // SQLite 로컬 영속성 레이어 업데이트
          await _localDb.saveChatRooms(processedRooms);

          // 최종 로컬 디스크의 데이터를 읽어 디코딩 후 파이프라인에 발행
          final finalLocalRooms = await _readAndDecodeLocalRooms();
          if (_roomsStreamController != null &&
              !_roomsStreamController!.isClosed) {
            _roomsStreamController!.add(finalLocalRooms);
          }
        });

    return _roomsStreamController!.stream;
  }

  Future<void> _loadLocalChatRooms() async {
    final finalLocalRooms = await _readAndDecodeLocalRooms();
    if (_roomsStreamController != null && !_roomsStreamController!.isClosed) {
      _roomsStreamController!.add(finalLocalRooms);
    }
  }

  // SQLite 내부 데이터 파싱 캡슐화 헬퍼 메소드
  Future<List<Map<String, dynamic>>> _readAndDecodeLocalRooms() async {
    final localRaw = await _localDb.getChatRooms();

    return localRaw.map((room) {
      // UI 계층이 가공 없이 원본 규격 그대로 쓸 수 있도록 복원(Runtime Type 보장)
      return {
        'roomId': room['roomId'],
        'roomName': room['roomName'],
        'type': room['type'],
        'lastMessage': room['lastMessage'],
        'lastTime': room['lastTime'] != null
            ? DateTime.parse(room['lastTime'])
            : null,
        'participants':
            jsonDecode(room['participants'] ?? '[]') as List<dynamic>,
        'unreadCounts':
            jsonDecode(room['unreadCounts'] ?? '{}') as Map<String, dynamic>,
      };
    }).toList();
  }

  // 개별 채팅방 메시지 스트림 비즈니스 로직
  Stream<List<ChatModel>> getChatStream(String roomId) {
    // 방 진입 시 기존 메시지용 스트림은 안전하게 완전히 새로 열어 이전 방 데이터 잔상이 남는 것을 방지
    _serverSubscription?.cancel();
    _chatStreamController?.close();
    _chatStreamController = StreamController<List<ChatModel>>.broadcast();

    // 1. 로컬 SQLite에 저장되어 있던 기존 캐시 데이터를 즉시 화면에 띄움. (네트워크 지연 0초 효과)
    _loadLocalCache(roomId);

    // 2. 서버에서 '최신 데이터'만 실시간 리스닝.
    _serverSubscription = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50) // 최신 메시지 유동적 동기화 경계 설정 (확장성)
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.docs.isEmpty) {
              if (_chatStreamController != null &&
                  !_chatStreamController!.isClosed) {
                _chatStreamController!.add([]);
              }
              return;
            }

            // 서버에서 가져온 데이터를 객체화
            List<ChatModel> serverChats = snapshot.docs
                .map((doc) => ChatModel.fromFirestore(doc))
                .toList();

            // SQLite 캐시에 저장하기 편하도록 raw 맵 리스트로 전환
            List<Map<String, dynamic>> rawLocalList = serverChats
                .map((chat) => chat.toLocalRawMap())
                .toList();

            // 로컬 데이터베이스에 영구 갱신 저장 (배치 인서트)
            await _localDb.saveMessages(roomId, rawLocalList);
            final updatedCombinedChats = await _localDb.getMessages(roomId);

            if (_chatStreamController != null &&
                !_chatStreamController!.isClosed) {
              _chatStreamController!.add(updatedCombinedChats);
            }
          },
          onError: (error) {
            if (_chatStreamController != null &&
                !_chatStreamController!.isClosed) {
              _chatStreamController!.addError(error);
            }
          },
        );

    return _chatStreamController!.stream;
  }

  Future<void> _loadLocalCache(String roomId) async {
    final cachedChats = await _localDb.getMessages(roomId);
    if (_chatStreamController != null && !_chatStreamController!.isClosed) {
      _chatStreamController!.add(cachedChats);
    }
  }

  // 특정 방을 나갈 때 '메시지 스트림만' 정밀 타격하여 자원 해제
  void clearChatStream() {
    _serverSubscription?.cancel();
    _serverSubscription = null;
    _chatStreamController?.close();
    _chatStreamController = null;
  }

  // 앱 로그아웃 등 완전 종료 시에만 호출
  void disposeAll() {
    _serverSubscription?.cancel();
    _roomsSubscription?.cancel();
    _chatStreamController?.close();
    _roomsStreamController?.close();
  }
}
