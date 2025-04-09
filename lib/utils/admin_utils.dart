import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill_model.dart';

class AdminUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedSkills() async {
    try {
      // Check if skills already exist
      final skillsSnapshot = await _firestore.collection('skills').limit(1).get();
      if (skillsSnapshot.docs.isNotEmpty) {
        print('Skills collection is not empty, skipping seed');
        return;
      }

      // Load and parse the skills data
      final String jsonString = await rootBundle.loadString('assets/data/predefined_skills.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> skillsData = jsonData['skills'];
      final batch = _firestore.batch();

      // Create batch operations for all skills
      for (var skillData in skillsData) {
        final skillDoc = _firestore.collection('skills').doc();
        final skill = {
          'id': skillDoc.id,
          'name': skillData['name'],
          'category': skillData['category'],
          'description': skillData['description'],
          'proficiency': 1,
          'demandLevel': 1,
          'averageRating': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'isSystemSkill': true
        };
        batch.set(skillDoc, skill);
      }

      // Commit the batch
      await batch.commit();
      print('Successfully seeded ${skillsData.length} predefined skills');
    } catch (e) {
      print('Error seeding predefined skills: $e');
      rethrow;
    }
  }
}