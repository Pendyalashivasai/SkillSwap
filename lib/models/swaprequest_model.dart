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

  factory SwapRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return SwapRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: SwapRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SwapRequestStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}