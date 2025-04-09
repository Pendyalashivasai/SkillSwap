import 'package:flutter/material.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/services/firestore_service.dart';

class SkillState extends ChangeNotifier {
  final FirestoreService _firestore;
  List<Skill> _availableSkills = [];
  List<UserModel> _allUsers = [];

  SkillState(this._firestore) {
    _loadSkills(); // Load skills when initialized
  }

  List<Skill> get availableSkills => _availableSkills;

  List<UserModel> getUsersOfferingSkill(String skillId) {
    try {
      print('SkillState: Getting users offering skill $skillId');
      return _allUsers.where((user) => 
        user.skillsOffering.any((skill) => skill.id == skillId)
      ).toList();
    } catch (e) {
      print('SkillState: Error getting users offering skill - $e');
      return [];
    }
  }

  Future<void> _loadSkills() async {
    try {
      print('SkillState: Loading skills and users...');
      
      // Load skills
      _availableSkills = await _firestore.getAllSkills();
      print('SkillState: Loaded ${_availableSkills.length} skills');
      
      // Load users
      _allUsers = await _firestore.getAllUsers();
      print('SkillState: Loaded ${_allUsers.length} users');
      
      notifyListeners();
    } catch (e) {
      print('SkillState: Error loading data - $e');
    }
  }

  Future<void> addCustomSkill(Skill skill) async {
    try {
      final skillId = await _firestore.addSkill(skill);
      final newSkill = skill.copyWith(id: skillId);
      _availableSkills.add(newSkill);
      notifyListeners();
    } catch (e) {
      print('SkillState: Error adding custom skill - $e');
      rethrow;
    }
  }
}