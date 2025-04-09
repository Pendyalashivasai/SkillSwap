import 'package:flutter/material.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/services/mongodb_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final MongoDBService _mongodb;
  String? _currentUserId;
  UserModel? _currentUser;

  UserState(this._mongodb);

  String? get currentUserId => _currentUserId;
  UserModel? get currentUser => _currentUser;

  List<Skill> get availableSkills => _availableSkills;

  List<Skill> _availableSkills = [
    Skill(id: '1', name: 'Flutter', category: 'Technology', proficiency: 1),
    Skill(id: '2', name: 'Guitar', category: 'Music', proficiency: 1),
    // Add more default skills
  ];

  void setCurrentUserId(String uid) {
    print("UserState: Setting current user ID: $uid");
    _currentUserId = uid;
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    if (_currentUserId == null) return;

    try {
      // Get user data from Firestore
      final firestoreUser = await _firestore.getUser(_currentUserId!);
      if (firestoreUser != null) {
        // Get profile image URL from MongoDB
        final mongoData = await _mongodb.getUser(_currentUserId!);
        if (mongoData != null && mongoData['profileImageUrl'] != null) {
          // Merge MongoDB profile image with Firestore data
          _currentUser = firestoreUser.copyWith(
            profileImageUrl: mongoData['profileImageUrl'],
          );
        } else {
          _currentUser = firestoreUser;
        }
        print("UserState: Loaded user with profileImageUrl - ${_currentUser?.profileImageUrl}");
        notifyListeners();
      }
    } catch (e) {
      print("UserState: Error loading user data: $e");
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final firestoreUser = await _firestore.getUser(userId);
      if (firestoreUser != null) {
        final mongoData = await _mongodb.getUser(userId);
        if (mongoData != null && mongoData['profileImageUrl'] != null) {
          return firestoreUser.copyWith(
            profileImageUrl: mongoData['profileImageUrl'],
          );
        }
        return firestoreUser;
      }
      return null;
    } catch (e) {
      print("UserState: Error getting user - $e");
      return null;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      // Check if it's the current user
      if (_currentUser?.id == userId) {
        return _currentUser;
      }

      // Fetch from database
      final userData = await _firestore.getUser(userId);
      if (userData == null) {
        print('UserState: User not found with ID: $userId');
        return null;
      }

      return UserModel.fromMap(userData as Map<String, dynamic>);
    } catch (e) {
      print('UserState: Error getting user - $e');
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      // Don't fetch from MongoDB here - use the existing profileImageUrl
      print('UserState: Current profileImageUrl - ${updatedUser.profileImageUrl}');

      // Include profileImageUrl in updates
      final updates = {
        'name': updatedUser.name,
        'email': updatedUser.email,
        'profileImageUrl': updatedUser.profileImageUrl, // Include this
        'skillsOffering': updatedUser.skillsOffering.map((s) => s.toMap()).toList(),
        'skillsSeeking': updatedUser.skillsSeeking.map((s) => s.toMap()).toList(),
        'hasCompletedOnboarding': updatedUser.hasCompletedOnboarding,
      };

      // Update Firestore
      await _firestore.updateUser(updatedUser.id, updates);

      // Update local state with the same user model
      _currentUser = updatedUser;
      notifyListeners();

      print('UserState: Updated local state with profileImageUrl - ${_currentUser?.profileImageUrl}');
    } catch (e) {
      print('UserState: Error updating profile - $e');
      rethrow;
    }
  }

  Future<void> updateOfferingSkills(List<Skill> skills) async {
    try {
      // Update local state
      _currentUser = _currentUser!.copyWith(skillsOffering: skills);

      // Update Firestore
      final updates = {'skillsOffering': skills.map((s) => s.toMap()).toList()};
      await _firestore.updateUser(_currentUser!.id , updates);

      notifyListeners();
    } catch (e) {
      print('UserState: Error updating offering skills - $e');
      rethrow;
    }
  }

  Future<void> updateSeekingSkills(List<Skill> skills) async {
    try {
      // Update local state
      _currentUser = _currentUser!.copyWith(skillsSeeking: skills);

      // Update Firestore
      final updates = {'skillsSeeking': skills.map((s) => s.toMap()).toList()};
      await _firestore.updateUser(_currentUser!.id, updates);

      notifyListeners();
    } catch (e) {
      print('UserState: Error updating seeking skills - $e');
      rethrow;
    }
  }

  Future<void> completeOnboarding() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        hasCompletedOnboarding: true,
      );
      await _firestore.updateUser(updatedUser.id, {'hasCompletedOnboarding': true});
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print("UserState: Error completing onboarding - $e");
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      // Update Firestore using FirestoreService
      await _firestore.updateUserData(userId, updates);

      // Update local state
      if (_currentUser != null && userId == _currentUser!.id) {
        _currentUser = _currentUser!.copyWith(
          profileImageUrl: updates['profileImageUrl'] ?? _currentUser!.profileImageUrl,
          skillsOffering: updates['skillsOffering'] != null
              ? (updates['skillsOffering'] as List)
                  .map((s) => Skill.fromMap(s))
                  .toList()
              : _currentUser!.skillsOffering,
          skillsSeeking: updates['skillsSeeking'] != null
              ? (updates['skillsSeeking'] as List)
                  .map((s) => Skill.fromMap(s))
                  .toList()
              : _currentUser!.skillsSeeking,
        );
        notifyListeners();
      }
    } catch (e) {
      print('UserState: Error updating user - $e');
      rethrow;
    }
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      // Update Firestore first
      await _firestore.updateUser(userId, {'profileImageUrl': imageUrl});

      // Update local state
      if (_currentUser != null && userId == _currentUser!.id) {
        final updatedUser = _currentUser!.copyWith(profileImageUrl: imageUrl);
        _currentUser = updatedUser; // Replace entire user object
        print("UserState: Updated local profile image URL - $imageUrl");
        notifyListeners();
      }
    } catch (e) {
      print('UserState: Error updating profile image - $e');
      rethrow;
    }
  }

  Future<void> updateUserSkills(String userId, Map<String, dynamic> skillUpdates) async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      print('UserState: Current auth user ID: ${currentUser?.uid}');
      print('UserState: Attempting to update user ID: $userId');
      print('UserState: User is authenticated: ${currentUser != null}');

      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Not authorized to update this user\'s skills');
      }

      // Update Firestore
      await _firestore.updateUser(userId , skillUpdates);

      // Reload user data after update
      await loadCurrentUser();
    } catch (e) {
      print('UserState: Error updating user skills - $e');
      rethrow;
    }
  }
}