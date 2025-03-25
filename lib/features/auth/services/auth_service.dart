import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }


  Future<User?> registerWithEmail(
    String email, 
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile in Firestore
      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        skillsOffering: [],
        skillsSeeking: [],
        joinDate: DateTime.now(),
      );
      
      await _firestore.addUser(user);
      
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already in use';
      default:
        return 'An error occurred. Please try again';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  sendPasswordResetEmail(String trim) {}
}