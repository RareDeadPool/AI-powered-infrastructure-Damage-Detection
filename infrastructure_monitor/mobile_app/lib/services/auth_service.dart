import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error during Google Sign In: $e');
      return null;
    }
  }

  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error during Email Login: $e');
      rethrow;
    }
  }

  static Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String governmentId,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      
      if (user != null) {
        // Update Firebase profile name
        await user.updateDisplayName(fullName);
        
        // Save additional details to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'governmentId': governmentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error during Email Sign Up: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
