import 'package:flutter/material.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/services/firestore_service.dart';

class UserState extends ChangeNotifier {
  UserModel? _currentUser;
  final FirestoreService _firestore;

  UserState(this._firestore);

  UserModel? get currentUser => _currentUser;
  List<Skill> get availableSkills => _availableSkills;
  
  List<Skill> _availableSkills = [
    Skill(id: '1', name: 'Flutter', category: 'Technology', proficiency: 1),
    Skill(id: '2', name: 'Guitar', category: 'Music', proficiency: 1),
    // Add more default skills
  ];

  Future<UserModel?> getUser(String userId) async {
    return _firestore.getUser(userId);
  }

  Future<void> loadCurrentUser(String userId) async {
    _currentUser = await _firestore.getUser(userId);
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _firestore.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> updateOfferingSkills(List<Skill> skills) async {
  _currentUser = _currentUser!.copyWith(skillsOffering: skills, skillsSeeking: [], name: '');
  await _firestore.updateUser(_currentUser!);
  notifyListeners();
}

Future<void> updateSeekingSkills(List<Skill> skills) async {
  _currentUser = _currentUser!.copyWith(skillsSeeking: skills, skillsOffering: [], name: '');
  await _firestore.updateUser(_currentUser!);
  notifyListeners();
}
}