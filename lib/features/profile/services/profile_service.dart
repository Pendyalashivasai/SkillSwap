import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/services/mongodb_service.dart';
import 'package:skillswap/state/user_state.dart';

class ProfileService {
  final MongoDBService _mongodb;
  final UserState _userState;
  final FirestoreService _firestore = FirestoreService();

  ProfileService(this._mongodb, this._userState);

  Future<String> updateProfilePicture(String userId, String imagePath) async {
    try {
      // Upload the image to MongoDB and get the URL
      final imageUrl = await _mongodb.uploadProfileImage(
        userId,
        File(imagePath),
      );
      print('ProfileService: Generated image URL - $imageUrl');

      // Update the user's profile in Firestore
      await _firestore.updateUser(userId, {
        'profileImageUrl': imageUrl,
        'lastProfileUpdate': FieldValue.serverTimestamp(),
      });
      print('ProfileService: Updated user with image URL - $imageUrl');

      // Update the local state
      await _userState.updateProfileImage(userId, imageUrl);
      print('ProfileService: Updated local user state with image URL - $imageUrl');

      return imageUrl;
    } catch (e) {
      print('ProfileService: Error updating profile picture - $e');
      rethrow;
    }
  }

  Future<void> loadCurrentUser(String userId) async {
    try {
      final userData = await _mongodb.getUser(userId);
      if (userData != null) {
        print('ProfileService: Raw user data - $userData');
       final userModel = UserModel.fromMap(userData);
        _userState.setCurrentUserId(userModel.id);

        print('ProfileService: Loaded user with image URL - ${_userState.currentUser?.profileImageUrl}');
      }
    } catch (e) {
      print('ProfileService: Error loading user - $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final userData = await _mongodb.getUser(userId);
      if (userData != null) {
        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('ProfileService: Error getting user - $e');
      rethrow;
    }
  }

  Future<void> addCustomSkill(String userId, Skill skill) async {
    if (_userState.currentUser == null || _userState.currentUser!.id != userId) {
      await loadCurrentUser(userId);
    }

    if (_userState.currentUser == null) {
      throw Exception("Error: Cannot add skill, user not found.");
    }

    final updatedSkills = [..._userState.currentUser!.skillsOffering, skill];
    final updatedUser = _userState.currentUser!.copyWith(skillsOffering: updatedSkills);
    
    await _mongodb.updateUser(userId, {'skillsOffering': updatedSkills});
    _userState.setCurrentUserId(updatedUser.id); // Update local state
 // Update local state
  }
}