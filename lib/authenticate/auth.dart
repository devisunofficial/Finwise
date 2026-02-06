

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}

//TODO: Create a stream to Wrapper to listen to authentication state changes and navigate accordingly.

//TODO: Implement error handling for authentication failures and display appropriate messages to the user.
