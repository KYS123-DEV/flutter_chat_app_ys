import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인한 유저 정보 가져오기 게터
  User? get currentUser => _auth.currentUser;

  // 그룹 채팅방 생성 로직
  Future<String> createGroupChatRoom(List<String> receiverUids, String roomName) async {
    final String currentUid = _auth.currentUser!.uid;
    List<String> allParticipants = [currentUid, ...receiverUids];
    allParticipants.sort();

    if (allParticipants.length == 2) {
      final existingRooms = await _firestore
          .collection('chatRooms')
          .where('type', isEqualTo: 'single')
          .where('participants', isEqualTo: allParticipants)
          .get();

      if (existingRooms.docs.isNotEmpty) {
        return existingRooms.docs.first.id;
      }
    }

    DocumentReference roomRef = _firestore.collection('chatRooms').doc();
    String finalRoomName = roomName.isEmpty ? "그룹채팅 (${allParticipants.length}명)" : roomName;
    String roomType = allParticipants.length == 2 ? 'single' : 'group';

    Map<String, int> unreadCounts = {};
    for (String uid in allParticipants) {
      unreadCounts[uid] = 0;
    }

    await roomRef.set({
      'roomId': roomRef.id,
      'roomName': finalRoomName,
      'type': roomType,
      'participants': allParticipants,
      'lastMessage': '채팅방이 생성되었습니다.',
      'lastTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    });

    return roomRef.id;
  }

  // 매개변수를 2개로 줄이고, 참여자 명단은 내부에서 직접 조회하여 처리합니다.
  Future<void> sendMessage(String roomId, String text) async {
    if (text.trim().isEmpty) return;

    final String currentUid = _auth.currentUser!.uid;
    
    // 1. 내 프로필 정보 조회
    DocumentSnapshot myUserDoc = await _firestore.collection('users').doc(currentUid).get();
    String myName = '알 수 없는 사용자';
    String myProfile = '';

    if (myUserDoc.exists) {
      Map<String, dynamic> myData = myUserDoc.data() as Map<String, dynamic>;
      myName = myData['name'] ?? '이름 없음';
      myProfile = myData['profileUrl'] ?? '';
    }
    
    // 2. UI 대리인 없이, 서비스가 직접 해당 방의 참가자 명단(participants)을 조회합니다.
    DocumentSnapshot roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    List<dynamic> participants = [];
    if (roomDoc.exists) {
      Map<String, dynamic> roomData = roomDoc.data() as Map<String, dynamic>;
      participants = roomData['participants'] ?? [];
    }
    
    // 3. 내 정보 패키지를 탑재하여 새 메시지 모델 생성
    final newChat = ChatModel(
      text: text, 
      createdAt: DateTime.now(),
      senderId: currentUid,
      senderName: myName,
      senderProfile: myProfile,
    );

    // 4. 메시지 하위 컬렉션에 추가
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .add(newChat.toMap());

    // 5. 최상위 방 문서 업데이트 맵 준비
    Map<String, dynamic> roomUpdates = {
      'lastMessage': '$myName: $text',
      'lastTime': FieldValue.serverTimestamp(),
    };

    // 6. 나를 제외한 모든 참가자의 안 읽은 갯수를 1씩 증가
    for (dynamic uid in participants) {
      if (uid is String && uid != currentUid) {
        roomUpdates['unreadCounts.$uid'] = FieldValue.increment(1);
      }
    }

    // 7. 최근 대화방 메타데이터 최종 업데이트
    await _firestore.collection('chatRooms').doc(roomId).update(roomUpdates);
  }

  // 방 입장 시 카운트 리셋 함수
  Future<void> resetUnreadCount(String roomId) async {
    final String currentUid = _auth.currentUser!.uid;
    await _firestore.collection('chatRooms').doc(roomId).update({
      'unreadCounts.$currentUid': 0,
    });
  }

  // 채팅방 stream get
  Stream<List<ChatModel>> getChatStream(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  // 참여 중인 대화방 목록 stream get
  Stream<List<Map<String, dynamic>>> getChatRoomsStream() {
    final String currentUid = _auth.currentUser!.uid;

    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs.map((doc) => doc.data()).toList();

      rooms.sort((a, b) {
        final Timestamp? aTime = a['lastTime'] as Timestamp?;
        final Timestamp? bTime = b['lastTime'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1; 
        if (bTime == null) return 1;
        return bTime.compareTo(aTime);
      });

      return rooms;
    });
  }
}