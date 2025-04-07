// user_model.dart
import 'skill_model.dart';

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
    List<int>? profileImageData, // Add this field
    List<Skill>? skillsOffering,
    List<Skill>? skillsSeeking,
    bool? hasCompletedOnboarding,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImageData: profileImageData ?? this.profileImageData, // Add this field
      joinDate: joinDate,
      skillsOffering: skillsOffering ?? this.skillsOffering,
      skillsSeeking: skillsSeeking ?? this.skillsSeeking,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id, // Changed to _id for MongoDB
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'profileImageData': profileImageData, // Add this field
      'joinDate': joinDate.toIso8601String(),
      'skillsOffering': skillsOffering.map((s) => s.toMap()).toList(),
      'skillsSeeking': skillsSeeking.map((s) => s.toMap()).toList(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['_id'] ?? map['id']).toString(), // Handle both MongoDB _id and regular id
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String?,
      profileImageData: map['profileImageData'] as List<int>?, // Add this field
      joinDate: map['joinDate'] != null 
          ? DateTime.parse(map['joinDate'])
          : DateTime.now(),
      skillsOffering: (map['skillsOffering'] as List?)
          ?.map((s) => Skill.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      skillsSeeking: (map['skillsSeeking'] as List?)
          ?.map((s) => Skill.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, profileImageUrl: $profileImageUrl, profileImageData: $profileImageData)'; // Add this field
  }
}