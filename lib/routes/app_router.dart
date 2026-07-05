import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_chat_app_ys/screens/splash_screen.dart';
import 'package:flutter_chat_app_ys/screens/auth_gate.dart';
import 'package:flutter_chat_app_ys/screens/home_screen.dart';
import 'package:flutter_chat_app_ys/screens/chat_screen.dart';

class AppRouter {
  static const String splash = 'splash';
  static const String authGate = 'auth';
  static const String home = 'home';
  static const String chat = 'chat';

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 1. 스플래시 스크린
      GoRoute(
        path: '/',
        name: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // 2. 인증 게이트 (로그인 / 홈 분기)
      GoRoute(
        path: '/auth',
        name: authGate,
        builder: (context, state) => const AuthGate(),
      ),
      // 3. 메인 홈 화면 (친구 목록, 채팅방 목록, 내 정보 탭 포함)
      GoRoute(
        path: '/home',
        name: home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          // 4. 채팅방 화면 (하위 경로로 설정하여 Depth 구조 명시)
          // 파라미터 전달을 위해 extra 객체 활용
          GoRoute(
            path: 'chat',
            name: chat,
            builder: (context, state) {
              // 네비게이션 시 전달된 데이터 추출
              final extra = state.extra as Map<String, String>;
              return ChatScreen(
                roomId: extra['roomId'] ?? '',
                roomName: extra['roomName'] ?? '채팅방',
              );
            },
          ),
        ],
      ),
    ],
    // 전역 에러 페이지 설정 (유지보수성)
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page Not Found: ${state.error}'))),
  );
}
