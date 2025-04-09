import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/swaprequest_model.dart';
import '../services/firestore_service.dart';

class SwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> acceptSwapRequest(String requestId, String userId) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      // Get the request details
      final requestDoc = await _firestore.collection('swapRequests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final request = SwapRequestModel.fromMap(requestDoc.data()!, requestId);
      
      // Create unique chat ID
      final chatId = [request.senderId, request.receiverId]..sort();
      final chatDocRef = _firestore.collection('chats').doc(chatId.join('_'));

      // Set chat data
      batch.set(chatDocRef, {
        'participants': [request.senderId, request.receiverId],
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          request.senderId: 0,
          request.receiverId: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update request status
      batch.update(_firestore.collection('swapRequests').doc(requestId), {
        'status': SwapRequestStatus.accepted.name,
        'chatId': chatDocRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();
      print('SwapService: Request accepted and chat created successfully');
    } catch (e) {
      print('SwapService: Error accepting request - $e');
      rethrow;
    }
  }

  Future<void> declineSwapRequest(String requestId, String userId) async {
    try {
      // Validate parameters
      if (requestId.isEmpty) {
        throw ArgumentError('Request ID cannot be empty');
      }
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      // Check authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Not authenticated or incorrect user ID');
      }

      final requestDoc = await _firestore
          .collection('swapRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Swap request not found');
      }

      final requestData = requestDoc.data()!;
      if (userId != requestData['receiverId']) {
        throw Exception('Not authorized to decline this request');
      }

      await _firestore
          .collection('swapRequests')
          .doc(requestId)
          .update({
        'status': SwapRequestStatus.declined.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('SwapService: Successfully declined request $requestId');
    } catch (e) {
      print('SwapService: Error declining request - $e');
      rethrow;
    }
  }

  Stream<List<SwapRequestModel>> watchReceivedRequests(String userId) {
    print('SwapService: Starting to watch requests for user $userId');
    return _firestore
        .collection('swapRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: SwapRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('SwapService: Retrieved ${snapshot.docs.length} pending requests');
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Ensure document ID is included
            print('SwapService: Processing request ${doc.id} - ${data['status']}');
            return SwapRequestModel.fromMap(data, doc.id);
          }).toList();
          return requests;
        });
  }

  Future<void> createSwapRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      // Check authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != senderId) {
        throw Exception('Not authenticated or incorrect sender ID');
      }

      if (senderId == receiverId) {
        throw Exception('Cannot send request to yourself');
      }

      final requestData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'status': SwapRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };

      await _firestore
          .collection('swapRequests')
          .add(requestData);

    } catch (e) {
      print('SwapService: Error creating swap request - $e');
      rethrow;
    }
  }

  Future<bool> hasExistingRequest(String senderId, String receiverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('swapRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: SwapRequestStatus.pending.name)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('SwapService: Error checking existing request - $e');
      rethrow;
    }
  }

  Future<void> cancelSwapRequest(String senderId, String receiverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('swapRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: SwapRequestStatus.pending.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('swapRequests')
            .doc(querySnapshot.docs.first.id)
            .delete();
      }
    } catch (e) {
      print('SwapService: Error canceling request - $e');
      rethrow;
    }
  }
}