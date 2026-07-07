import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_app_ys/viewmodels/user_list_viewmodel.dart';
import 'package:flutter_chat_app_ys/routes/app_router.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserListViewModel _viewModel = UserListViewModel();

  @override
  Widget build(BuildContext context) {
    // Scaffold 전체를 감싸서 AppBar까지 상태에 따라 리빌드되도록 변경
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('친구 목록'),
            actions: [
              // AppBar가 상태를 감지하여 정상적으로 버튼을 표시.
              if (_viewModel.selectedUids.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.forum, color: Colors.blue),
                  onPressed: () {
                    _navigateToChat(
                      "그룹채팅 (${_viewModel.selectedUids.length + 1}명)",
                    );
                  },
                ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _viewModel.usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('등록된 사용자가 없습니다.'));
              }

              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final String userUid = user['uid'] ?? '';
                  final String userName = user['name'] ?? '이름 없음';
                  final String profileUrl = user['profileUrl'] ?? '';

                  if (userUid == _viewModel.currentUid) {
                    return const SizedBox.shrink();
                  }

                  return CheckboxListTile(
                    value: _viewModel.selectedUids.contains(userUid),
                    secondary: CircleAvatar(
                      child: profileUrl.isNotEmpty
                          ? Image.network(profileUrl)
                          : const Icon(Icons.person),
                    ),
                    title: Text(userName),
                    subtitle: Text(user['email'] ?? ''),
                    onChanged: (bool? value) {
                      _viewModel.toggleSelection(userUid, value);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  //채팅방 이동 함수
  void _navigateToChat(String roomName) async {
    // 비동기 작업 실행
    String? roomId = await _viewModel.createAndGetRoomId(roomName);

    // 비동기 작업이 끝난 후, 이 위젯이 여전히 화면에 있는지 '반드시' 체크
    if (!mounted) return;

    // roomId가 있고, 화면이 존재할 때만 내비게이션 실행
    if (roomId != null) {
      context.pushNamed(
        AppRouter.chat,
        extra: {
          'roomId': roomId,
          'roomName': roomName.isEmpty ? "채팅방" : roomName,
        },
      );
    }
  }
}
