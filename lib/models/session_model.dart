import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { pending, confirmed, rejected, canceled, completed }
enum SessionMode { online, inPerson }

class Session {
  final String id;
  final String skillId;
  final String skillName;
  final String teacherId;
  final String studentId;
  final DateTime startTime;
  final DateTime endTime;
  final SessionMode mode;
  final String? location;
  final SessionStatus status;
  final String notes;
  final DateTime createdAt;

  Session({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.teacherId,
    required this.studentId,
    required this.startTime,
    required this.endTime,
    required this.mode,
    this.location,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  Duration get duration => endTime.difference(startTime);

  factory Session.fromMap(Map<String, dynamic> map, String id) {
    return Session(
      id: id,
      skillId: map['skillId'],
      skillName: map['skillName'] ?? '',
      teacherId: map['teacherId'],
      studentId: map['studentId'],
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      mode: SessionMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => SessionMode.online,
      ),
      location: map['location'],
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.pending,
      ),
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillId': skillId,
      'skillName': skillName,
      'teacherId': teacherId,
      'studentId': studentId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'mode': mode.name,
      'location': location,
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}