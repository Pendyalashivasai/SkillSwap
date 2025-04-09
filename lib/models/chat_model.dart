import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final Map<String, dynamic> participantDetails; // Stores names and profile images
  final String requestId; // Reference to the original swap request

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCounts,
    required this.createdAt,
    required this.participantDetails,
    required this.requestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'participantDetails': participantDetails,
      'requestId': requestId,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null 
          ? (map['lastMessageTime'] as Timestamp).toDate() 
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantDetails: Map<String, dynamic>.from(map['participantDetails'] ?? {}),
      requestId: map['requestId'] ?? '',
    );
  }
}