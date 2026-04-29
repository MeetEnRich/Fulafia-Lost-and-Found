import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_and_found/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password, then store profile in Firestore.
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String matricNumber,
    required String faculty,
    required String department,
    required String phoneNumber,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Registration failed');

      // Update display name
      await user.updateDisplayName(fullName);

      // Create user profile in Firestore
      final userModel = UserModel(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        matricNumber: matricNumber.trim().toUpperCase(),
        faculty: faculty,
        department: department,
        phoneNumber: phoneNumber.trim(),
        role: 'student',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Login failed');

      return await getUserProfile(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Fetch user profile from Firestore.
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Update user profile in Firestore.
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Fetch all users (admin only).
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Update a user's role (admin only).
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  /// Convert Firebase auth exceptions to user-friendly messages.
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('An account with this email already exists');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'user-not-found':
        return Exception('No account found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'user-disabled':
        return Exception('This account has been disabled');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later');
      case 'invalid-credential':
        return Exception('Invalid email or password');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}
