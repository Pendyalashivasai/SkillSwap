import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/services/firestore_service.dart';

class ChatService {
  final FirestoreService _firestore;
  final String currentUserId;

  ChatService(this._firestore, this.currentUserId);

  Stream<List<ChatModel>> getChatStream() {
    return _firestore.getUserChatsStream(currentUserId);
  }

  Stream<QuerySnapshot> getMessageStream(String chatId) {
    return _firestore.getChatMessagesStream(chatId);
  }

  Future<void> sendMessage(String chatId, String content) async {
    try {
      await _firestore.sendMessage(chatId, currentUserId, content);
    } catch (e) {
      print('ChatService: Error sending message - $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _firestore.markChatAsRead(chatId, currentUserId);
    } catch (e) {
      print('ChatService: Error marking messages as read - $e');
      rethrow;
    }
  }

  Future<String> createChat(String otherUserId) async {
    try {
      return await _firestore.createChat(currentUserId, otherUserId);
    } catch (e) {
      print('ChatService: Error creating chat - $e');
      rethrow;
    }
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final chat = await _firestore.getChatById(chatId);
      return chat;
    } catch (e) {
      print('ChatService: Error getting chat - $e');
      rethrow;
    }
  }
}