import 'package:flutter/material.dart';
import '../viewmodels/chat_room_list_view_model.dart';
import 'chat_screen.dart';

class ChatRoomListScreen extends StatefulWidget {
  const ChatRoomListScreen({super.key});

  @override
  State<ChatRoomListScreen> createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  final ChatRoomListViewModel _viewModel = ChatRoomListViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('진행 중인 대화방'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _viewModel.chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('참여 중인 채팅방이 없습니다.'));
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final String roomId = room['roomId'] ?? '';
              final String roomName = room['roomName'] ?? '그룹채팅';
              final String lastMessage = room['lastMessage'] ?? '대화 내용 없음';
              
              final int myUnreadCount = _viewModel.getUnreadCount(room);

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.forum, color: Colors.white),
                ),
                title: Text(
                  roomName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: myUnreadCount > 0 
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        myUnreadCount > 99 ? '99+' : myUnreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )
                  : const Icon(Icons.chevron_right),
                onTap: () {
                  // 🚀 [수정]: ChatScreen 호출 시 roomName을 명시적으로 전달합니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        roomId: roomId, 
                        roomName: roomName
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}