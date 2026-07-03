import 'package:flutter/material.dart';
import 'user_list_screen.dart';
import 'chat_room_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스

  // 탭에 따라 보여줄 화면 목록
  final List<Widget> _screens = [
    const UserListScreen(), // 0번 탭: 친구(유저) 목록
    const ChatRoomListScreen(), // 1번 탭: 최근 대화방 목록
    const ProfileScreen(), // 2번째 탭 추가 : 내 프로필
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // 상태를 유지하며 화면 전환
      ),
      // 카카오톡 스타일의 하단 내비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '친구'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }
}
