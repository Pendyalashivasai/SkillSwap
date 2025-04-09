import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapRequestStatus { pending, accepted, declined }

class SwapRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final SwapRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SwapRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SwapRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return SwapRequestModel(
      id: map['id'] ?? docId, // Use document ID if 'id' field is not set
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: SwapRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SwapRequestStatus.pending,
      ),
      createdAt: map['createdAt'] is String 
        ? DateTime.parse(map['createdAt'])
        : (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
        ? (map['updatedAt'] is String 
          ? DateTime.parse(map['updatedAt'])
          : (map['updatedAt'] as Timestamp).toDate())
        : null,
    );
  }
}