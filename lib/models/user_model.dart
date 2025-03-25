// user_model.dart
import 'skill_model.dart';

class UserModel {
  final String id;
  final String name;
  final String? profileImageUrl;
  final DateTime joinDate;
  final List<Skill> skillsOffering;
  final List<Skill> skillsSeeking;

  UserModel({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.joinDate,
    required this.skillsOffering,
    required this.skillsSeeking, required String email,
  });

  UserModel copyWith({
    String? name,
    String? profileImageUrl,
    List<Skill>? skillsOffering,
    List<Skill>? skillsSeeking,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinDate: joinDate,
      skillsOffering: skillsOffering ?? this.skillsOffering,
      skillsSeeking: skillsSeeking ?? this.skillsSeeking, email: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'joinDate': joinDate.toIso8601String(),
      'skillsOffering': skillsOffering.map((s) => s.toMap()).toList(),
      'skillsSeeking': skillsSeeking.map((s) => s.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      profileImageUrl: map['profileImageUrl'],
      joinDate: DateTime.parse(map['joinDate']),
      skillsOffering: (map['skillsOffering'] as List)
          .map((s) => Skill.fromMap(s))
          .toList(),
      skillsSeeking: (map['skillsSeeking'] as List)
          .map((s) => Skill.fromMap(s))
          .toList(), email: '',
    );
  }
}