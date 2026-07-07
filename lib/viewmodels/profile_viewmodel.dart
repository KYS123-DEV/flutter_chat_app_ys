import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app_ys/models/user_model.dart';
import 'package:flutter_chat_app_ys/services/auth_service.dart';
import 'base_viewmodel.dart';

class ProfileViewModel extends BaseViewModel {
  final AuthService _authService = AuthService();

  // View에서 사용하던 컨트롤러를 뷰모델로 이전
  final TextEditingController nameController = TextEditingController();

  // 1. 순수 데이터 모델 상태
  UserModel? _userProfile;
  UserModel? get userProfile => _userProfile;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // 스트림 구독을 메모리에서 관리하기 위한 변수
  StreamSubscription<UserModel>? _profileSubscription;

  ProfileViewModel() {
    _subscribeToProfile();
  }

  // 2. 핵심 로직: 뷰모델이 직접 DB 스트림을 구독하고 상태를 갱신합니다.
  void _subscribeToProfile() {
    _profileSubscription = _authService.getMyProfileStream().listen((user) {
      // 스트림이 처음 들어왔을 때 딱 한 번만 텍스트 컨트롤러에 이름을 세팅합니다. (커서 튐 완벽 방지)
      if (_userProfile == null) {
        nameController.text = user.name;
      }

      _userProfile = user;
      notifyListeners(); // 데이터가 갱신될 때마다 View에 알림
    });
  }

  // 3. 이름 저장 비즈니스 로직
  Future<void> saveName({required VoidCallback onSuccess}) async {
    final newName = nameController.text.trim();

    // 변경사항이 없거나 비어있으면 서버 통신 차단 (최적화)
    if (newName.isEmpty || newName == _userProfile?.name) return;

    _isSaving = true;
    notifyListeners();

    await _authService.updateName(newName);

    _isSaving = false;
    notifyListeners();

    onSuccess(); // View에 성공 콜백 전달
  }

  // 4. 로그아웃 로직
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // 5. 메모리 누수 방지
  @override
  void dispose() {
    _profileSubscription?.cancel(); // 뷰모델 파괴 시 스트림 구독 해제
    nameController.dispose();
    super.dispose();
  }
}
