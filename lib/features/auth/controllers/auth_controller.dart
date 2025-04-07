import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillswap/features/auth/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  

  AuthController(this._authService) {
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
     print("AuthController: Current User ID: ${user?.uid}"); 
      notifyListeners();
    });
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> login(String email, String password) async {
    try {
      await _authService.signInWithEmail(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      await _authService.registerWithEmail(email, password, name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}