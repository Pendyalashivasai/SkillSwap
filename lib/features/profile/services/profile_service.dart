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
    final imageUrl = await _storage.uploadProfileImage(userId, imagePath);
    await _firestore.updateUser(
      _currentUser!.copyWith(profileImageUrl: imageUrl),
    );
  }

  Stream<List<UserModel>> findSkillMatches(String skillId) {
    return _firestore.getUsersWithSkill(skillId);
  }

  Future<void> addCustomSkill(String userId, Skill skill) async {
    if (_currentUser == null) {
      await loadCurrentUser(userId);
    }
    await _firestore.updateUser(
      _currentUser!.copyWith(
        skillsOffering: [..._currentUser!.skillsOffering, skill],
      ),
    );
  }
}