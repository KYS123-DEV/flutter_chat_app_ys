import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String? id;
  final String text;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final String senderProfile;

  ChatModel({
    this.id,
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
      id: doc.id,
      text: data['text'] ?? '',
      createdAt: time,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '알 수 없는 사용자',
      senderProfile: data['senderProfile'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'senderId': senderId,
      'senderName': senderName,
      'senderProfile': senderProfile,
    };
  }

  // 로컬 가공을 위한 중간 맵 획득용 객체화 게터
  Map<String, dynamic> toLocalRawMap() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfile': senderProfile,
    };
  }
}
