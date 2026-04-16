import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

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
    required XFile governmentIdImage,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      
      if (user != null) {
        try {
          // 1. Upload Government ID Image to Cloudinary (using FirebaseService bridge)
          final String? govIdUrl = await FirebaseService.uploadImage(
            'user_ids/${user.uid}', 
            governmentIdImage.path,
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            print('Sign up: Image upload timed out');
            return null;
          });
          
          // 2. Update Firebase profile name
          await user.updateDisplayName(fullName);
          
          // 3. Save additional details to Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': fullName,
            'email': email,
            'phone': phone,
            'governmentIdUrl': govIdUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'isApproved': false, // Verification pending
          });
        } catch (e) {
          // IMPORTANT: If any step fails (like Firestore permissions),
          // delete the account so the user can try again after fixing the issue.
          print('Sign up process failed after auth: $e. Rolling back account.');
          await user.delete();
          rethrow;
        }
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

  static Future<void> updateProfile({String? fullName, String? phone}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (fullName != null) {
      await user.updateDisplayName(fullName);
    }

    if (phone != null || fullName != null) {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
    }
  }
}
