import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users'; // Moved to a constant

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Passenger sign up
  Future<User?> signUpPassenger({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        // Add user data to Firestore, using the constant
        await _firestore.collection(_usersCollection).doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'passenger',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors
      print('Error signing up: ${e.message}'); // Log the error
      throw _handleAuthError(e.code); // Improved error handling
    } catch (e) {
      // Handle generic errors
      print('Unexpected error during sign up: $e');
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Use this method for passenger login to maintain backward compatibility
  Future<User?> signInPassenger({
    required String email,
    required String password,
  }) async {
    return signIn(email: email, password: password, role: 'passenger');
  }

  // Driver/Admin login
  Future<User?> signIn({
    required String email,
    required String password,
    required String role, // Added role parameter
  }) async {
    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        // Check the user's role in Firestore
        final String? userRole = await getUserRole(user.uid);
        if (userRole == role) {
          return user;
        }
        else{
          await signOut();
          throw 'Incorrect Role';
        }
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in: ${e.message}');
      throw _handleAuthError(e.code);
    } catch (e) {
      print('Unexpected error during sign in: $e');
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final DocumentSnapshot userDoc =
      await _firestore.collection(_usersCollection).doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      return null; // Or throw an exception if you prefer
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // Optionally clear shared preferences here
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Handle Firebase Auth errors (Improved)
  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An unknown error occurred. Please try again later.';
    }
  }
}

