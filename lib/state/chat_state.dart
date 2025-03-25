import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/services/firestore_service.dart';

class ChatState extends ChangeNotifier {
  final FirestoreService _firestore;
  final String currentUserId;
  List<Chat> _chats = [];
  Map<String, List<Message>> _messages = {};

  ChatState(this._firestore, this.currentUserId);

  List<Chat> get chats => _chats;
  
  Future<void> loadChats() async {
    _chats = await _firestore.getUserChats(currentUserId);
    notifyListeners();
  }

  List<Message> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  Chat? getChat(String chatId) {
    return _chats.firstWhere((chat) => chat.id == chatId);
  }

  Future<void> loadMessages(String chatId) async {
    _messages[chatId] = await _firestore.getChatMessages(chatId);
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String content) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: currentUserId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _firestore.sendMessage(message);
    await loadMessages(chatId);
  }

  Future<void> markMessagesAsRead(String chatId) async {
    await _firestore.markMessagesAsRead(chatId, currentUserId);
    await loadMessages(chatId);
  }

  Stream<QuerySnapshot> getMessageStream(String chatId) {
    return _firestore.getMessageStream(chatId);
  }
}