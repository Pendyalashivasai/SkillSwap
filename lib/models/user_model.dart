// user_model.dart
import 'skill_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String email;
  final List<int>? profileImageData; // Add this field
  final DateTime joinDate;
  final List<Skill> skillsOffering;
  final List<Skill> skillsSeeking;
  final bool hasCompletedOnboarding;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.profileImageData, // Add this field
    DateTime? joinDate,
    List<Skill>? skillsOffering,
    List<Skill>? skillsSeeking,
    this.hasCompletedOnboarding = false,
  }) : joinDate = joinDate ?? DateTime.now(),
       skillsOffering = skillsOffering ?? [],
       skillsSeeking = skillsSeeking ?? [];

  UserModel copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    List<int>? profileImageData,
    List<Skill>? skillsOffering,
    List<Skill>? skillsSeeking,
    bool? hasCompletedOnboarding,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl, // Preserve profileImageUrl
      profileImageData: profileImageData ?? this.profileImageData,
      joinDate: joinDate,
      skillsOffering: skillsOffering ?? this.skillsOffering,
      skillsSeeking: skillsSeeking ?? this.skillsSeeking,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl, // Include in Firestore document
      'joinDate': joinDate,
      'skillsOffering': skillsOffering.map((s) => s.toMap()).toList(),
      'skillsSeeking': skillsSeeking.map((s) => s.toMap()).toList(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      joinDate: _parseDateTime(map['joinDate']),
      skillsOffering: _parseSkills(map['skillsOffering']),
      skillsSeeking: _parseSkills(map['skillsSeeking']),
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }

  static List<Skill> _parseSkills(dynamic skills) {
    return (skills as List?)
        ?.map((s) => Skill.fromMap(s as Map<String, dynamic>))
        .toList() ?? [];
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, profileImageUrl: $profileImageUrl, profileImageData: $profileImageData)'; // Add this field
  }
}