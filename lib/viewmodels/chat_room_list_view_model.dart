import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatRoomListViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  late final Stream<List<Map<String, dynamic>>> chatRoomsStream;
  
  String get currentUid => FirebaseAuth.instance.currentUser!.uid;

  ChatRoomListViewModel() {
    chatRoomsStream = _chatService.getChatRoomsStream();
  }

  int getUnreadCount(Map<String, dynamic> room) {
    Map<String, dynamic> unreadCounts = {};
    if (room['unreadCounts'] != null) {
      unreadCounts = Map<String, dynamic>.from(room['unreadCounts']);
    }
    return (unreadCounts[currentUid] ?? 0) as int;
  }
}