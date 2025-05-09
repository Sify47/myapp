import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? email;

  Future<void> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      this.email = email;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      this.email = email;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void logout() async {
    await _auth.signOut();
    email = null;
    notifyListeners();
  }
}
