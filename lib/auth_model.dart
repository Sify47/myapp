import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AuthModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _brandId;
  String? _brandname;
  late StreamSubscription<User?> _authStateSubscription;
  Future<String?> _uploadBrandImage(File image) async {
    // try {
    //   final ref = _storage.ref().child('brand_images/${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    //   await ref.putFile(image);
    //   return await ref.getDownloadURL();
    // } catch (e) {
    //   print('Error uploading brand image: $e');
    //   return null;
    // }
    try {
      final ref = _storage.ref().child(
        'brand_images/${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading brand image: $e');
      return null;
    }
  }

  AuthModel() {
    _user = _auth.currentUser;
    _authStateSubscription = _auth.authStateChanges().listen((
      User? user,
    ) async {
      _user = user;
      if (user != null) {
        await _fetchUserBrandId();
      } else {
        _brandId = null;
      }
      notifyListeners();
    });
  }

  bool get isLoggedIn => _user != null;
  User? get currentUser => _user;
  String? get email => _user?.email;
  String? get brandId => _brandId;
  String? get brandname => _brandname;

  Future<void> _fetchUserBrandId() async {
    if (_user == null) {
      _brandId = null;
      return;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (userDoc.exists) {
        _brandId = userDoc.data()?['brandId'] as String?;
        _brandname = userDoc.data()?['name'] as String?;
        print('Fetched brandId: $_brandId');
      } else {
        _brandId = null;
        print('User document does not exist');
      }
    } catch (e) {
      _brandId = null;
      print('Error fetching brandId: $e');
    }
    notifyListeners();
  }

  Future<void> registerWithBrand({
  required String email,
  required String password,
  required String brandName,
  required String brandCategory,
  File? brandImage,
  required String brandDescription,
  required String brandWebsite,
  required String brandFacebook,
  required String brandTwitter,
  required String brandInstagram,
}) async {
  try {
    // 1. Create user account
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    // 2. Upload image if exists
    String? imageUrl;
    if (brandImage != null) {
      imageUrl = await _uploadBrandImage(brandImage);
    }

    // 3. Create brand document
    final brandDoc = await _firestore.collection('brands').add({
      'name': brandName,
      'category': brandCategory,
      'description': brandDescription,
      'adminEmail': email,
      'image': imageUrl,
      'instagram': brandInstagram,
      'facebook': brandFacebook,
      'x': brandTwitter,
      'website': brandWebsite,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Create user document with brandId
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'brandId': brandDoc.id,
      'role': 'brand_admin',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 5. Update local state
    _user = userCredential.user;
    _brandId = brandDoc.id;
    notifyListeners();
  } catch (e) {
    print('Registration error: $e');
    rethrow;
  }
}


  // Future<void> registerWithBrand({
  //   required String email,
  //   required String password,
  //   required String brandName,
  //   required String brandCategory,
  //   File? brandImage,
  //   required String brandDescription,
  //   required String brandWebsite,
  //   required String brandFacebook,
  //   required String brandTwitter,
  //   required String brandInstagram,
  // }) async {
  //   try {
  //     // 1. Create user account
  //     final userCredential = await _auth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     String? imageUrl;
  //     if (brandImage != null) {
  //       imageUrl = await _uploadBrandImage(brandImage);
  //     }

  //     // 2. Create brand document
  //     final brandDoc = await _firestore.collection('brands').add({
  //       'name': brandName,
  //       'category': brandCategory,
  //       'description': brandDescription,
  //       'adminEmail': email,
  //       "image": imageUrl,
  //       'instagram': brandInstagram,
  //       'facebook': brandFacebook,
  //       'x': brandTwitter,
  //       // 'imageUrl': imageUrl,
  //       'website': brandWebsite,
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });

  //     // 3. Update user document with brandId
  //     await _firestore.collection('users').doc(userCredential.user!.uid).set({
  //       'email': email,
  //       'brandId': brandDoc.id,
  //       'role': 'brand_admin',
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });

  //     // 4. Update local state
  //     _user = userCredential.user;
  //     _brandId = brandDoc.id;
  //     notifyListeners();
  //   } catch (e) {
  //     print('Registration error: $e');
  //     rethrow;
  //   }
  // }

  Future<void> register(String email, String password) async {
    try {
      // createUserWithEmailAndPassword automatically signs the user in,
      // the listener will handle the state update and notifyListeners.
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Registration Error: $e");
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _fetchUserBrandId();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> loginwithbran(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _fetchUserBrandId();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _brandId = null;
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
