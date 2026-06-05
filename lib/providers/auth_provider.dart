import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/network_config.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '255124081047-ipfov9s8mgmvqdl9e2fp88bh4pnt9ca9.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted sign-in
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _error = 'Failed to retrieve Google token.';
        _setLoading(false);
        return;
      }

      // Hybrid Auth: Send token to backend to verify and mint custom token
      final response = await http.post(
        Uri.parse('${NetworkConfig.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final customToken = body['data']['customToken'];

          // Sign in to Firebase with the Custom Token
          final userCredential = await _auth.signInWithCustomToken(customToken);

          if (userCredential.user != null) {
            // Fire-and-forget logging to avoid blocking the UI
            _logAuthEvent(userCredential.user!, 'LOGIN');
          }
        } else {
          _error = 'Backend authentication failed.';
        }
      } else {
        _error = 'Server error during authentication.';
        debugPrint('Backend Auth Error: ${response.body}');
      }

    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('ApiException: 10')) {
        _error = 'Firebase Config Error (10): Missing SHA-1 key in Firebase Console. Please add your debug SHA-1 to your Firebase Project Settings.';
        debugPrint('DEVELOPER ERROR: Missing SHA-1 fingerprint in Firebase.');
      } else {
        _error = 'Failed to sign in with Google. Please try again.';
        debugPrint('Google Sign-In Error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInAnonymously(BuildContext context) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          // Sync with backend using the Firebase ID token
          final response = await http.post(
            Uri.parse('${NetworkConfig.baseUrl}/auth/verify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          );

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['success'] == true) {
              _logAuthEvent(user, 'LOGIN_ANONYMOUS').catchError((e) => debugPrint('Error logging login: $e'));
            } else {
              _error = 'Backend sync failed.';
            }
          } else {
            _error = 'Server error during backend sync.';
            debugPrint('Backend Sync Error: ${response.body}');
          }
        }
      }
    } catch (e) {
      _error = 'Failed to sign in with Apple. Please try again.';
      debugPrint('Anonymous Sign-In Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      if (_user != null) {
        _logAuthEvent(_user!, 'LOGOUT').catchError((e) {
          debugPrint('Error logging logout: $e');
        });
      }
      _googleSignIn.signOut().catchError((e) {
        debugPrint('Google Sign-Out Error: $e');
        return null;
      });
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-Out Error: $e');
      _error = 'Failed to sign out.';
      notifyListeners();
    }
  }

  Future<void> _logAuthEvent(User user, String action) async {
    try {
      await _firestore.collection('user_logs').add({
        'uid': user.uid,
        'email': user.email ?? 'anonymous',
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fire-and-forget logging; we don't want to block auth on logging errors
      debugPrint('Failed to log auth event: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
