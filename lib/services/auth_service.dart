import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    // await FacebookAuth.instance.logOut();
  }

  //Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential);
      return userCredential.user;
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }

  //Sign in with facebook
//   Future<User?> signInWithFacebook() async {
//     try {
//       final LoginResult result = await FacebookAuth.instance.login();
//       if (result.status == LoginStatus.success) {
//         final OAuthCredential credential =
//         FacebookAuthProvider.credential(result.accessToken!.token);
//         final userCredential = await FirebaseAuth.instance.signInWithCredential(
//             credential);
//         return userCredential.user;
//       } else {
//         return null;
//       }
//     } catch (e) {
//       print("Facebook Sign-In error: $e");
//       return null;
//     }
//   }

  //Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent (or processing) to $email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        print('Firebase Auth Error for password reset: ${e.code}');
        throw FirebaseAuthException(
          code: 'generic-password-reset-message',
          message: 'If an account exists for that email, a password reset link has been sent.',
        );
      } else {
        print('Error sending password reset email: ${e.code} - ${e.message}');
        throw e;
      }
    } catch (e) {
      print('Unexpected error in sendPasswordResetEmail: $e');
      rethrow;
    }
  }
}