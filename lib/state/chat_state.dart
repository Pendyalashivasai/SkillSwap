import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatState extends ChangeNotifier {
  final FirestoreService _firestore;
  final String currentUserId;
  List<ChatModel> _chats = [];
  StreamSubscription<List<ChatModel>>? _chatsSubscription;

  ChatState(this._firestore, this.currentUserId) {
    _initializeChats();
  }

  List<ChatModel> get chats => _chats;

  Stream<List<ChatModel>> getChatStream() {
    return _firestore.getUserChatsStream(currentUserId);
  }

  Future<void> sendMessage(String chatId, String content) async {
    try {
      await _firestore.sendMessage(chatId, currentUserId, content);
    } catch (e) {
      print('ChatState: Error sending message - $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _firestore.markChatAsRead(chatId, currentUserId);
    } catch (e) {
      print('ChatState: Error marking messages as read - $e');
    }
  }

  void _initializeChats() {
    print('ChatState: Initializing chats for user $currentUserId');
    _chatsSubscription?.cancel();
    _chatsSubscription = _firestore.getUserChatsStream(currentUserId).listen(
      (updatedChats) {
        print('ChatState: Received ${updatedChats.length} chats');
        _chats = updatedChats;
        notifyListeners();
      },
      onError: (e) => print('ChatState: Error listening to chats - $e'),
    );
  }

  Stream<QuerySnapshot> getMessageStream(String chatId) {
    return _firestore.getChatMessagesStream(chatId);
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }
}