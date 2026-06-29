import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String text;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final String senderProfile;

  ChatModel({
    required this.text,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    required this.senderProfile,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime time;
    if (data['createdAt'] != null) {
      time = (data['createdAt'] as Timestamp).toDate();
    } else {
      time = DateTime.now();
    }

    return ChatModel(
      text: data['text'] ?? '',
      createdAt: time,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '알 수 없는 사용자', // 🚀 안전장치 추가
      senderProfile: data['senderProfile'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'senderId': senderId,
      'senderName': senderName,       // 🚀 포함하여 저장
      'senderProfile': senderProfile, // 🚀 포함하여 저장
    };
  }
}