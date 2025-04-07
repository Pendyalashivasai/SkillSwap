import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/models/session_model.dart';
import 'package:skillswap/models/skill_model.dart' as skill_model;
import 'package:skillswap/models/user_model.dart';

import '../models/skill_model.dart';
import '../models/swaprequest_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUser(UserModel user) async {
    try {
      final userData = user.toMap();
      // Remove MongoDB specific fields
      userData.remove('_id');
      userData.remove('profileImageUrl'); // Don't store image URL in Firestore
      
      await _firestore.collection('users').doc(user.id).set(userData);
      print('FirestoreService: Added user with ID: ${user.id}');
    } catch (e) {
      print('FirestoreService: Error adding user - $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    print("FirestoreService: Attempting to fetch user with ID: $uid");
    
    if (uid.isEmpty) {
      print("FirestoreService: Attempted to fetch user with empty uid");
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        print("FirestoreService: User not found for ID $uid");
        return null;
      }

      final data = doc.data()!;
      data['_id'] = doc.id; // Add ID for MongoDB compatibility
      data['profileImageUrl'] = null; // Will be populated from MongoDB later
      
      print("FirestoreService: Successfully fetched user with ID: $uid");
      return UserModel.fromMap(data);
    } catch (e) {
      print("FirestoreService: Error fetching user - $e");
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      print('FirestoreService: Updated user with ID: $userId');
    } catch (e) {
      print('FirestoreService: Error updating user - $e');
      rethrow;
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updates);
      print('FirestoreService: Updated user data for ID: $userId');
    } catch (e) {
      print('FirestoreService: Error updating user data - $e');
      rethrow;
    }
  }

  Future<void> updateUserSkills(String userId, Map<String, dynamic> skillUpdates) async {
    try {
      await _firestore.collection('users').doc(userId).update(skillUpdates);
      print('FirestoreService: Updated user skills for ID: $userId');
    } catch (e) {
      print('FirestoreService: Error updating user skills - $e');
      rethrow;
    }
  }

  Stream<List<UserModel>> getUsersWithSkill(String skillId) {
    return _firestore
        .collection('users')
        .where('skillsOffering.id', isEqualTo: skillId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['_id'] = doc.id;
              data['profileImageUrl'] = null; // Will be populated from MongoDB
              return UserModel.fromMap(data);
            }).toList());
  }

  // Skill Methods
  Future<List<skill_model.Skill>> getAllSkills() async {
    final snapshot = await _firestore.collection('skills').get();
    return snapshot.docs
        .map((doc) => skill_model.Skill.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        data['profileImageUrl'] = null; // Will be populated from MongoDB
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('FirestoreService: Error getting all users - $e');
      return [];
    }
  }

 Future<String> addSkill(Skill skill) async {
  try {
    final docRef = await _firestore.collection('skills').add(skill.toMap());
    print('FirestoreService: Added skill with ID: ${docRef.id}');
    
    // Update the document with its own ID
    await docRef.update({'id': docRef.id});
    
    return docRef.id;
  } catch (e) {
    print('FirestoreService: Error adding skill - $e');
    rethrow;
  }
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

Future<void> createSwapRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final swapRequest = SwapRequestModel(
        id: '', // Will be set by Firestore
        senderId: senderId,
        receiverId: receiverId,
        status: SwapRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('swapRequests')
          .add(swapRequest.toMap());

      // Update the document with its ID
      await docRef.update({'id': docRef.id});

      print('SwapRequest created with ID: ${docRef.id}');
    } catch (e) {
      print('Error creating swap request: $e');
      rethrow;
    }
  }

Future<List<SwapRequestModel>> getReceivedRequests(String userId) async {
  try {
    final snapshot = await _firestore
        .collection('swapRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: SwapRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SwapRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  } catch (e) {
    print('FirestoreService: Error fetching received requests - $e');
    rethrow;
  }
}

Future<void> updateSwapRequest(String requestId, SwapRequestStatus status) async {
  try {
    await _firestore.collection('swapRequests').doc(requestId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('FirestoreService: Updated request $requestId to ${status.name}');
  } catch (e) {
    print('FirestoreService: Error updating request status - $e');
    rethrow;
  }
}


}