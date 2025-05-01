import 'package:flutter/material.dart';

class AuthModel with ChangeNotifier {
  String email = '';
  String password = '';

  void login(String email, String password) {
    this.email = email;
    this.password = password;
    notifyListeners();
  }

  void clear() {
    email = '';
    password = '';
    notifyListeners();
  }
}
