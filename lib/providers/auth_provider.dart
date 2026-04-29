import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lost_and_found/models/user_model.dart';
import 'package:lost_and_found/services/auth_service.dart';
import 'package:lost_and_found/services/storage_service.dart';
import 'package:lost_and_found/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // ── Getters ─────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  // ── Initialize ──────────────────────────────────────────────────────────

  /// Check if user is already logged in and load profile.
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      try {
        _user = await _authService.getUserProfile(firebaseUser.uid);
        if (_user != null) {
          NotificationService().startListening(_user!.uid);
        }
      } catch (e) {
        // User auth exists but profile doesn't — sign out
        await _authService.logout();
      }
    }
    notifyListeners();
  }

  // ── Register ────────────────────────────────────────────────────────────

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String matricNumber,
    required String faculty,
    required String department,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        matricNumber: matricNumber,
        faculty: faculty,
        department: department,
        phoneNumber: phoneNumber,
      );
      if (_user != null) {
        NotificationService().startListening(_user!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.login(email: email, password: password);
      if (_user != null) {
        NotificationService().startListening(_user!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    NotificationService().stopListening();
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // ── Password Reset ──────────────────────────────────────────────────────

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // ── Update Profile ──────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    File? profileImage,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      String? imageUrl = _user!.profileImageUrl;

      if (profileImage != null) {
        imageUrl = await _storageService.uploadProfileImage(
          imageFile: profileImage,
          uid: _user!.uid,
        );
      }

      _user = _user!.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImageUrl: imageUrl,
      );

      await _authService.updateUserProfile(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // ── Admin Functions ─────────────────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() async {
    return await _authService.getAllUsers();
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _authService.updateUserRole(uid, role);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
