import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_app_ys/services/auth_service.dart';
import 'base_viewmodel.dart';

// ChangeNotifier를 상속받아 View가 구독할 수 있는 뷰모델을 형성.
class LoginViewModel extends BaseViewModel {
  final AuthService _authService = AuthService();

  // 1. 텍스트 컨트롤러를 뷰모델이 소유하여 관리
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // 2. 상태 변수 및 게터
  bool _isSignUp = false;
  bool get isSignUp => _isSignUp;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 3. 로그인/회원가입 모드 전환 로직
  void toggleMode() {
    _isSignUp = !_isSignUp;
    passwordController.clear();
    passwordConfirmController.clear();
    notifyListeners(); // 상태가 변경되었음을 뷰(View)에 실시간 통보
  }

  // 4. 입력 폼 검증 및 인증 제출 비즈니스 로직
  Future<void> submit({
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final passwordConfirm = passwordConfirmController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    if (_isSignUp) {
      // 클라이언트 사이드 검증 로직
      if (!email.toLowerCase().endsWith('@gmail.com')) {
        onError('회원가입은 @gmail.com 계정만 허용됩니다.');
        return;
      }
      if (name.isEmpty) {
        onError('실명을 입력해주세요.');
        return;
      }
      if (password != passwordConfirm) {
        onError('비밀번호가 일치하지 않습니다. 다시 확인해주세요.');
        return;
      }
    }

    try {
      _isLoading = true;
      notifyListeners(); // 로딩 시작 알림

      if (_isSignUp) {
        await _authService.signUp(email, password, name);
      } else {
        await _authService.signIn(email, password);
      }

      onSuccess(); // 인증 성공 콜백 실행
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? '인증 오류가 발생했습니다.');
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 종료 알림
    }
  }

  // 5. 메모리 해제 전담
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
