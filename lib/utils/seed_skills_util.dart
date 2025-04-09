import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillSeedUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedSkillsFromJson() async {
    try {
      // Check if skills already exist
      final skillsSnapshot = await _firestore.collection('skills').get();
      if (skillsSnapshot.docs.isNotEmpty) {
        print('Skills collection already has data. Skipping seed.');
        return;
      }

      // Read JSON file
      final String jsonContent = await rootBundle.loadString('assets/data/predefined_skills.json');
      final List<dynamic> skillsData = json.decode(jsonContent);

      // Create batch write
      final WriteBatch batch = _firestore.batch();

      // Process each skill
      for (var skillData in skillsData) {
        final docRef = _firestore.collection('skills').doc();
        final skill = {
          'id': docRef.id,
          'name': skillData['name'],
          'category': skillData['category'],
          'description': skillData['description'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'isSystemSkill': true,
          'averageRating': 0.0,
          'usageCount': 0
        };
        batch.set(docRef, skill);
      }

      // Commit batch
      await batch.commit();
      print('Successfully seeded ${skillsData.length} skills!');

    } catch (e) {
      print('Error seeding skills: $e');
      rethrow;
    }
  }
}