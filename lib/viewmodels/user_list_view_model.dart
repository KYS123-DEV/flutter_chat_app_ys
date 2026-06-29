import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'base_view_model.dart';

class UserListViewModel extends BaseViewModel {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  // 1. 화면이 그려질 때 1회성으로 사용할 캐싱된 스트림
  late final Stream<QuerySnapshot> usersStream;

  // 2. 체크된 사용자들의 UID를 담아두는 리스트 상태
  final List<String> _selectedUids = [];
  List<String> get selectedUids => _selectedUids;

  // 현재 내 UID (목록에서 나를 숨기기 위해 사용)
  String? get currentUid => _authService.currentUser?.uid;

  UserListViewModel() {
    // 기존 화면 initState에 있던 스트림 초기화 로직을 뷰모델 생성자에서 처리합니다.
    usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  // 3. 체크박스 선택/해제 로직
  void toggleSelection(String uid, bool? isSelected) {
    if (isSelected == true) {
      _selectedUids.add(uid);
    } else {
      _selectedUids.remove(uid);
    }
    notifyListeners(); // 화면에 체크 상태 변화와 상단바 버튼 생성 여부를 즉각 알립니다.
  }

  // 4. 채팅방 생성 로직 (View에서 넘겨받은 방 이름을 토대로 생성 후 roomId 반환)
  Future<String?> createAndGetRoomId(String roomName) async {
    if (_selectedUids.isEmpty) return null;
    
    // 서비스 계층 호출
    String roomId = await _chatService.createGroupChatRoom(_selectedUids, roomName);
    
    // 방 생성이 완료되면 선택된 목록을 초기화합니다.
    _selectedUids.clear();
    notifyListeners();
    
    return roomId; // 화면 이동을 위해 View로 방 ID를 리턴
  }
}