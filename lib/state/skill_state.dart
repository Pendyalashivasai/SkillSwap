import 'package:flutter/material.dart';
import 'package:skillswap/models/skill_model.dart' as skill_model;
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/services/firestore_service.dart';

class SkillState extends ChangeNotifier {
  final FirestoreService _firestore;
  List<skill_model.Skill> _availableSkills = [];
  List<UserModel> _allUsers = [];

  SkillState(this._firestore);

  List<skill_model.Skill> get availableSkills => _availableSkills;
  
  Future<void> loadAllData() async {
    await Future.wait([
      _loadSkills(),
      _loadUsers(),
    ]);
  }

  Future<void> _loadSkills() async {
    _availableSkills = await _firestore.getAllSkills();
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    _allUsers = await _firestore.getAllUsers();
    notifyListeners();
  }

  List<UserModel> getUsersOfferingSkill(String skillId) {
    return _allUsers.where((user) {
      return user.skillsOffering.any((skill) => skill.id == skillId);
    }).toList();
  }

  List<skill_model.Skill> getRecommendedSkills(String userId) {
    final user = _allUsers.firstWhere((u) => u.id == userId);
    return _availableSkills.where((skill) {
      return user.skillsSeeking.any((s) => s.category == skill.category);
    }).toList();
  }
}