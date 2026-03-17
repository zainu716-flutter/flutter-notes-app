import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign Up ──────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user?.updateDisplayName(name.trim());
      _status = AuthStatus.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _friendlyError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _status = AuthStatus.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _friendlyError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  Future<bool> sendPasswordReset({required String email}) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _status = AuthStatus.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _friendlyError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
