import 'package:flutter/material.dart';
import 'package:skillswap/models/session_model.dart';
import 'package:skillswap/services/firestore_service.dart';

class SessionState extends ChangeNotifier {
  final FirestoreService _firestore;
  final String currentUserId;
  List<Session> _sessions = [];

  SessionState(this._firestore, this.currentUserId);

  List<Session> get sessions => _sessions;
  
  Future<void> loadSessions() async {
    _sessions = await _firestore.getUserSessions(currentUserId);
    notifyListeners();
  }

  Session? getSession(String sessionId) {
    return _sessions.firstWhere((s) => s.id == sessionId);
  }

  Future<void> requestSession(Session session) async {
    await _firestore.addSession(session);
    await loadSessions();
  }

  Future<void> updateSessionStatus(String sessionId, SessionStatus status) async {
    await _firestore.updateSessionStatus(sessionId, status);
    await loadSessions();
  }

  Future<void> cancelSession(String sessionId) async {
    await _firestore.cancelSession(sessionId);
    await loadSessions();
  }

  List<Session> getUpcomingSessions() {
    return _sessions
        .where((s) => s.status == SessionStatus.confirmed)
        .where((s) => s.startTime.isAfter(DateTime.now()))
        .toList();
  }
}