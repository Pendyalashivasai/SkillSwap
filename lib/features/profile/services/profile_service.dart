  import 'package:skillswap/models/skill_model.dart';
  import 'package:skillswap/models/user_model.dart';
  import 'package:skillswap/services/firestore_service.dart';
  import 'package:skillswap/services/storage_service.dart';

  class ProfileService {
    final FirestoreService _firestore;
    final StorageService _storage;
    UserModel? _currentUser;

    ProfileService(this._firestore, this._storage);

    Future<void> loadCurrentUser(String userId) async {
      _currentUser = await _firestore.getUser(userId);
    }

    Future<void> updateProfilePicture(String userId, String imagePath) async {
  if (_currentUser == null || _currentUser!.id != userId) {
    await loadCurrentUser(userId); // Load user if not already loaded
  }
  
  if (_currentUser == null) {
    throw Exception("Error: Unable to update profile picture, user not found.");
  }

  final imageUrl = await _storage.uploadProfileImage(userId, imagePath);
  final updatedUser = _currentUser!.copyWith(profileImageUrl: imageUrl);
  
  await _firestore.updateUser(updatedUser);
  _currentUser = updatedUser; // Update local state
}

    Stream<List<UserModel>> findSkillMatches(String skillId) {
      return _firestore.getUsersWithSkill(skillId);
    }

   Future<void> addCustomSkill(String userId, Skill skill) async {
  if (_currentUser == null || _currentUser!.id != userId) {
    await loadCurrentUser(userId);
  }

  if (_currentUser == null) {
    throw Exception("Error: Cannot add skill, user not found.");
  }

  final updatedSkills = [..._currentUser!.skillsOffering, skill];
  final updatedUser = _currentUser!.copyWith(skillsOffering: updatedSkills);
  
  await _firestore.updateUser(updatedUser);
  _currentUser = updatedUser; // Update local state
}

  }