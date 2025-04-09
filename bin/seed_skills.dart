import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';

void main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Read JSON file directly using dart:io
    final file = File('assets/data/predefined_skills.json');
    final jsonContent = await file.readAsString();
    final List<dynamic> skillsData = json.decode(jsonContent);

    // Get Firestore instance
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Check if skills exist
    final existingSkills = await firestore.collection('skills').get();
    if (existingSkills.docs.isNotEmpty) {
      print('Skills already exist in the database.');
      exit(0);
    }

    // Create batch
    final batch = firestore.batch();

    // Add skills to batch
    for (var skillData in skillsData) {
      final docRef = firestore.collection('skills').doc();
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
    exit(0);
  } catch (e) {
    print('Error seeding skills: $e');
    exit(1);
  }
}