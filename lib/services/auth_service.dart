import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
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

  // Sign out from all providers
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    // await FacebookAuth.instance.logOut();
  }

  // auth_service.dart

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

}