import 'dart:async'; // Import async for StreamSubscription
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Keep track of the user object
  late StreamSubscription<User?> _authStateSubscription; // Subscription to auth state changes

  AuthModel() {
    // Initialize _user with the current user
    _user = _auth.currentUser;
    // Listen to authentication state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
      print("Auth State Changed: User is ${user == null ? 'logged out' : 'logged in'}");
      notifyListeners(); // Notify listeners whenever auth state changes
    });
  }

  // Getter to check if the user is logged in
  bool get isLoggedIn => _user != null;

  // Getter for the current user (can be null)
  User? get currentUser => _user;

  // Getter for the user's email (can be null)
  String? get email => _user?.email;

  Future<void> register(String email, String password) async {
    try {
      // createUserWithEmailAndPassword automatically signs the user in,
      // the listener will handle the state update and notifyListeners.
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Registration Error: $e");
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      // signInWithEmailAndPassword automatically updates the auth state,
      // the listener will handle the state update and notifyListeners.
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // signOut automatically updates the auth state,
      // the listener will handle the state update and notifyListeners.
      await _auth.signOut();
    } catch (e) {
      print("Logout Error: $e");
      // Handle logout error if necessary
    }
  }

  // Dispose the subscription when the model is disposed
  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}

