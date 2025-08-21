import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  String? _brandId;
  String? _brandname;
  late StreamSubscription<User?> _authStateSubscription;

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

  // ------------- Helper Methods ----------------

  Future<String?> _uploadBrandImage(File image) async {
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
        _brandname = userDoc.data()?['displayName'] as String?;
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

  Future<void> _saveUserToFirestore(User user, {String? username}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': username ?? user.displayName ?? '',
        // 'photoURL': user.photoURL ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'provider':
            user.providerData.isNotEmpty
                ? user.providerData[0].providerId
                : 'password',
        'emailVerified': user.emailVerified,
        'loyaltyPoints': 0,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // تجهيز Collection للمفضلة
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlistItems')
          .doc('init')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      throw 'فشل في حفظ بيانات المستخدم: ${e.toString()}';
    }
  }

  // ---------------- Register / Login ----------------

  Future<void> register(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _saveUserToFirestore(userCredential.user!, username: username);

      _user = userCredential.user;
      notifyListeners();
    } catch (e) {
      print("Registration Error: $e");
      rethrow;
    }
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
      // 1. Create account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // 2. Upload brand image
      String? imageUrl;
      if (brandImage != null) {
        imageUrl = await _uploadBrandImage(brandImage);
      }

      // 3. Create brand doc
      final brandDoc = await _firestore.collection('brands').add({
        'displayName': brandName,
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

      // 4. Save user with brandId
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': brandName,
        'loyaltyPoints': 0,
        'brandId': brandDoc.id,
        'role': 'brand_admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _user = userCredential.user;
      _brandId = brandDoc.id;
      notifyListeners();
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // تسجيل الدخول
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

        final snapshot = await userDoc.get();

        if (snapshot.exists) {
          // لو موجود -> اعمل تحديث للـ lastLogin
          await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});

          // جلب بيانات اضافية
          await _fetchUserBrandId();
          return true; // ✅ المستخدم موجود
        } else {
          print("⚠️ User not found in Firestore, skipping update.");
          return false; // ❌ مش موجود
        }
      }
      return false; // ❌ uid فاضى
    } catch (e) {
      print('Login error: $e');
      return false; // ❌ حصل خطأ
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'تم إلغاء عملية التسجيل';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
        _user = userCredential.user;
        notifyListeners();
      }
    } catch (e) {
      throw 'فشل تسجيل الدخول بحساب Google: ${e.toString()}';
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
