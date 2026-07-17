import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_chat_app_ys/routes/app_router.dart';
import 'package:flutter_chat_app_ys/const/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // 1. 무조건 2초간 로고 화면 노출 대기
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. Firebase 로그인 상태 확인 후 분기 전문 스크린으로 이동
    context.goNamed(AppRouter.authGate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // 이미지의 바탕색인 #D9F1FD (217, 241, 253)로 통일
          color: splashColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png'),
              const SizedBox(height: 20), // 로고와 인디케이터 사이 여백 추가
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
