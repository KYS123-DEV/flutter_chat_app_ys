import 'package:flutter/material.dart';
import '../viewmodels/chat_view_model.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({
    super.key, 
    required this.roomId, 
    required this.roomName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(roomId: widget.roomId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.roomName.isNotEmpty ? widget.roomName : '채팅방'),
      ), 
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: StreamBuilder<List<ChatModel>>(
                  stream: _viewModel.chatStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('첫 메시지를 보내보세요!'));
                    }
                
                    final chats = snapshot.data!;
                    return ListView.builder(
                      reverse: true,
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        bool isMe = chat.senderId == _viewModel.currentUid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 20,
                                  child: chat.senderProfile.isNotEmpty 
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(chat.senderProfile,
                                              errorBuilder: (c, e, s) => const Icon(Icons.person)),
                                        ) 
                                      : const Icon(Icons.person),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe) ...[
                                    Text(chat.senderName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.yellow[400] : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(chat.text, style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _viewModel.formatDateTime(chat.createdAt),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _viewModel.messageController,
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                       _viewModel.sendMessage();
                      if (!mounted) return;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}