import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/state/user_state.dart';

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
      
      // Just return the user credential
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }


 
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Create user profile in Firestore
        final user = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          joinDate: DateTime.now(),
          skillsOffering: [],
          skillsSeeking: [],
        );
        
        await _firestore.addUser(user);
        await userCredential.user?.updateDisplayName(name);
      }
      
      return userCredential.user;
    } catch (e) {
      rethrow;
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email address';
          break;
        default:
          errorMessage = 'An error occurred. Please try again';
      }
      throw errorMessage;
    } catch (e) {
      // Catch any other unexpected errors
      throw 'An unexpected error occurred. Please try again';
    }
  }
}