import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/models/session_model.dart';
import 'package:skillswap/models/skill_model.dart' as skill_model;
import 'package:skillswap/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Stream<List<UserModel>> getUsersWithSkill(String skillId) {
    return _firestore
        .collection('users')
        .where('skillsOffering', arrayContains: skillId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Skill Methods
  Future<List<skill_model.Skill>> getAllSkills() async {
    final snapshot = await _firestore.collection('skills').get();
    return snapshot.docs
        .map((doc) => skill_model.Skill.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addSkill(skill_model.Skill skill) async {
    await _firestore.collection('skills').add(skill.toMap());
  }

  Future<void> updateSkillDemand(String skillId, int increment) async {
    await _firestore.collection('skills').doc(skillId).update({
      'demandLevel': FieldValue.increment(increment),
    });
  }
  // Add to existing FirestoreService class
Future<List<Chat>> getUserChats(String userId) async {
  final snapshot = await _firestore
      .collection('chats')
      .where('participants', arrayContains: userId)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    final participants = List<String>.from(data['participants']);
    final participantIds = participants.where((id) => id != userId).toList();
    
    return Chat(
      id: doc.id,
      participantIds: participantIds,
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCounts'][userId] ?? 0,
    );
  }).toList();
}

Future<List<Message>> getChatMessages(String chatId) async {
  final snapshot = await _firestore
      .collection('chats/$chatId/messages')
      .orderBy('timestamp', descending: true)
      .get();

  return snapshot.docs.map((doc) => Message.fromMap(doc.data(), doc.id)).toList();
}

Future<void> sendMessage(Message message) async {
  final batch = _firestore.batch();
  
  // Add message to subcollection
  final messageRef = _firestore
      .collection('chats/${message.chatId}/messages')
      .doc(message.id);
  batch.set(messageRef, message.toMap());

  // Update chat last message
  final chatRef = _firestore.collection('chats').doc(message.chatId);
  batch.update(chatRef, {
    'lastMessage': message.content,
    'lastMessageTime': FieldValue.serverTimestamp(),
    'unreadCounts.${message.senderId}': 0,
    'unreadCounts.${message.receiverId}': FieldValue.increment(1),
  });

  await batch.commit();
}

Stream<QuerySnapshot> getMessageStream(String chatId) {
  return _firestore
      .collection('chats/$chatId/messages')
      .orderBy('timestamp', descending: true)
      .snapshots();
}

Future<void> markMessagesAsRead(String chatId, String userId) async {
  await _firestore.collection('chats').doc(chatId).update({
    'unreadCounts.$userId': 0,
  });
}

Future<List<Session>> getUserSessions(String userId) async {
  final snapshot = await _firestore
      .collection('sessions')
      .where('participants', arrayContains: userId)
      .orderBy('startTime')
      .get();

  return snapshot.docs.map((doc) => Session.fromMap(doc.data(), doc.id)).toList();
}

Future<void> addSession(Session session) async {
  await _firestore.collection('sessions').doc(session.id).set({
    ...session.toMap(),
    'participants': [session.teacherId, session.studentId],
  });
}

Future<void> updateSessionStatus(String sessionId, SessionStatus status) async {
  await _firestore.collection('sessions').doc(sessionId).update({
    'status': status.name,
  });
}

Future<void> cancelSession(String sessionId) async {
  await _firestore.collection('sessions').doc(sessionId).update({
    'status': SessionStatus.canceled.name,
  });
}
}