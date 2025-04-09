import 'package:cloud_firestore/cloud_firestore.dart';

class Skill {
  final String id;
  final String name;
  final String category;
  final int proficiency; // 1-5 scale
  final String? description;
  final int demandLevel;
  final double averageRating;
  final String? createdBy;
  final DateTime? createdAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.proficiency,
    this.description,
    this.demandLevel = 1,
    this.averageRating = 0,
    this.createdBy,
    this.createdAt,
  });

  factory Skill.fromMap(Map<String, dynamic> map, [String? id]) {
    return Skill(
      id: id ?? map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      proficiency: map['proficiency'] ?? 1,
      description: map['description'],
      demandLevel: map['demandLevel'] ?? 1,
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  get usersOffering => null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'proficiency': proficiency,
      'description': description,
      'demandLevel': demandLevel,
      'averageRating': averageRating,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    int? proficiency,
    String? description,
    int? demandLevel,
    double? averageRating,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      proficiency: proficiency ?? this.proficiency,
      description: description ?? this.description,
      demandLevel: demandLevel ?? this.demandLevel,
      averageRating: averageRating ?? this.averageRating,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}