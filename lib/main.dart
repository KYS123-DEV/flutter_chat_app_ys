import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '기본 채팅 App',
      debugShowCheckedModeBanner: false,
      
      // 완벽하게 보정된 반응형 글로벌 뷰포트 빌더
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        
        // 브라우저 너비가 600px보다 크면 600px로 고정하고, 작으면 모바일 화면 너비 그대로 사용
        final double targetWidth = mediaQueryData.size.width > 600 ? 600.0 : mediaQueryData.size.width;

        return Material(
          color: Colors.grey[300], // 웹 브라우저 좌우 빈 공간에 채워질 배경색
          child: Center(
            // 🔥 핵심: 하위 모든 스크린이 웹 전체 화면이 아닌 '제한된 너비'를 기기 사이즈로 인식하도록 주입
            child: MediaQuery(
              data: mediaQueryData.copyWith(
                size: Size(targetWidth, mediaQueryData.size.height),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Container(
                  color: Colors.white, // 앱 본체의 기본 배경색 보장
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}