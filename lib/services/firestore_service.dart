import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      
      print("FirestoreService: Successfully fetched user with ID: $uid");
      return UserModel.fromMap(data);
    } catch (e) {
      print("FirestoreService: Error fetching user - $e");
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      print('FirestoreService: Updating user with updates - $updates');
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
  Future<List<Skill>> getAllSkills() async {
    try {
      print('FirestoreService: Fetching all skills');
      final snapshot = await _firestore.collection('skills').get();
      
      final skills = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is included
        return Skill.fromMap(data);
      }).toList();

      print('FirestoreService: Fetched ${skills.length} skills');
      return skills;
    } catch (e) {
      print('FirestoreService: Error fetching skills - $e');
      rethrow;
    }
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
      // Add the current user's ID as the creator
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User must be authenticated to add skills');
      }

      final skillData = {
        ...skill.toMap(),
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('skills').add(skillData);
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

  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      return await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final otherUserId = (data['participants'] as List)
            .firstWhere((id) => id != userId);
        
        // Get other user's details
        final otherUser = await getUser(otherUserId);
        
        data['participantDetails'] = {
          otherUserId: {
            'name': otherUser?.name ?? 'Unknown',
            'profileImageUrl': otherUser?.profileImageUrl,
          }
        };
        
        return ChatModel.fromMap(data, doc.id);
      }));
    } catch (e) {
      print('FirestoreService: Error getting user chats - $e');
      rethrow;
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    final snapshot = await _firestore
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => Message.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> sendMessage(String chatId, String senderId, String content) async {
    try {
      final batch = _firestore.batch();
      
      // Get chat to find the receiver
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data()!;
      final receiverId = (chatData['participants'] as List<dynamic>)
          .firstWhere((id) => id != senderId);

      // Add message
      final messageRef = _firestore
          .collection('chats/$chatId/messages')
          .doc();

      batch.set(messageRef, {
        'senderId': senderId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat metadata with unread count for RECEIVER
      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.$receiverId': FieldValue.increment(1), // Increment receiver's unread count
      });

      await batch.commit();
      print('FirestoreService: Message sent successfully');
    } catch (e) {
      print('FirestoreService: Error sending message - $e');
      rethrow;
    }
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

  Future<String> createChat(String userId1, String userId2) async {
    try {
      final chatId = [userId1, userId2]..sort();
      final chatDocId = chatId.join('_');

      // Check if chat exists
      final existingChat = await _firestore.collection('chats').doc(chatDocId).get();
      if (existingChat.exists) {
        return chatDocId;
      }

      // Create new chat
      await _firestore.collection('chats').doc(chatDocId).set({
        'participants': [userId1, userId2],
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          userId1: 0,
          userId2: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      return chatDocId;
    } catch (e) {
      print('FirestoreService: Error creating chat - $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getChatMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    print('FirestoreService: Getting chats stream for user $userId');
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          print('FirestoreService: Retrieved ${snapshot.docs.length} chats');
          final chats = await Future.wait(snapshot.docs.map((doc) async {
            final data = doc.data();
            // Properly cast the participants list
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != userId,
              orElse: () => '',
            );
            
            // Get other user's details
            final otherUser = await getUser(otherUserId);
            
            // Update data with properly typed participants
            data['participants'] = participants;
            data['participantDetails'] = {
              otherUserId: {
                'name': otherUser?.name ?? 'Unknown',
                'profileImageUrl': otherUser?.profileImageUrl,
              }
            };
            
            return ChatModel.fromMap(data, doc.id);
          }));
          return chats;
        });
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Update messages
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {'unreadCounts.$userId': 0}
      );

      await batch.commit();
    } catch (e) {
      print('FirestoreService: Error marking chat as read - $e');
      rethrow;
    }
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('FirestoreService: Error getting chat by ID - $e');
      rethrow;
    }
  }
}