import 'dart:io';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_chat_app_ys/routes/app_router.dart';
import 'package:flutter_chat_app_ys/const/colors.dart';

void main() async {
  //플러터 프레임워크 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 윈도우/리눅스 환경일 경우 SQLite FFI 초기화 가드 배치
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    // .router 생성자
    return MaterialApp.router(
      title: '기본 채팅 App',
      debugShowCheckedModeBanner: false,

      // go_router 주입
      routerConfig: AppRouter.router,

      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        if (child == null) return const SizedBox.shrink();

        final double targetWidth = mediaQueryData.size.width > 600
            ? 600.0
            : mediaQueryData.size.width;

        return Material(
          color: greyColor,
          child: Center(
            child: MediaQuery(
              data: mediaQueryData.copyWith(
                size: Size(targetWidth, mediaQueryData.size.height),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(color: whiteColor, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
