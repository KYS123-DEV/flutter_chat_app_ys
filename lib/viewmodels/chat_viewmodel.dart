import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_app_ys/services/chat_service.dart';
import 'package:flutter_chat_app_ys/models/chat_model.dart';

class ChatViewModel extends ChangeNotifier {
  final String roomId;
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController messageController = TextEditingController();

  late final Stream<List<ChatModel>> chatStream;
  late final Future<DocumentSnapshot> roomInfoFuture;

  String get currentUid => _auth.currentUser!.uid;

  ChatViewModel({required this.roomId}) {
    _chatService.resetUnreadCount(roomId);
    chatStream = _chatService.getChatStream(roomId);
    roomInfoFuture = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(roomId)
        .get();
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;
    _chatService.sendMessage(roomId, messageController.text);
    messageController.clear();
  }

  void resetUnread() {
    _chatService.resetUnreadCount(roomId);
  }

  String formatDateTime(DateTime time) {
    final year = time.year.toString();
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  void dispose() {
    resetUnread();
    _chatService.closeChatSession();
    messageController.dispose();
    super.dispose();
  }
}
