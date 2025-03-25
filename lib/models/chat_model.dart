class Chat {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Chat({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  String get participantName => ''; // Fetch from user service
  String? get participantAvatar => null; // Fetch from user service
}