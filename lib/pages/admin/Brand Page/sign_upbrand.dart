import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../auth_model.dart';
import '../brand_admin_page.dart';
import 'loginbrand.dart';

class BrandSignupPage extends StatefulWidget {
  const BrandSignupPage({super.key});

  @override
  State<BrandSignupPage> createState() => _BrandSignupPageState();
}

class _BrandSignupPageState extends State<BrandSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _brandCategoryController = TextEditingController();
  final _brandDescriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();

  File? _brandImage;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _brandImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
  try {
    final fileName = 'brands/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    // رفع الصورة
    final uploadTask = await storageRef.putFile(image);

    // الحصول على رابط التحميل
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    debugPrint('Image upload error: $e');
    return null;
  }
}


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _brandNameController.dispose();
    _brandCategoryController.dispose();
    _brandDescriptionController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'كلمة المرور غير متطابقة');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthModel>(context, listen: false);
      final firestore = FirebaseFirestore.instance;

      // 1. Upload brand image if exists
      String? imageUrl;
      if (_brandImage != null) {
        imageUrl = await _uploadImage(_brandImage!);
      }

      // 2. Create brand document
      // final brandDoc = await firestore.collection('brands').add({
      //   'name': _brandNameController.text.trim(),
      //   'category': _brandCategoryController.text.trim(),
      //   'description': _brandDescriptionController.text.trim(),
      //   'website': _websiteController.text.trim(),
      //   'facebook': _facebookController.text.trim(),
      //   'x': _twitterController.text.trim(),
      //   'instagram': _instagramController.text.trim(),
      //   'image': imageUrl,
      //   'createdAt': FieldValue.serverTimestamp(),
      //   'adminEmail': _emailController.text.trim(),
      // });

      // 3. Register user with brand
      await auth.registerWithBrand(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        brandName: _brandNameController.text.toUpperCase().trim(),
        brandCategory: _brandCategoryController.text.trim(),
        brandDescription: _brandDescriptionController.text.trim(),
        brandWebsite: _websiteController.text.trim(),
        brandFacebook: _facebookController.text.trim(),
        brandTwitter: _twitterController.text.trim(),
        brandInstagram: _instagramController.text.trim(),
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3526394875.
        brandImage: _brandImage,
      );

      // 4. Navigate to brand admin page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BrandAdminPage()),
          (route) => false,
        );
      }
    // } on FirebaseAuthException catch (e) {
      // setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // String _getErrorMessage(String code) {
  //   switch (code) {
  //     case 'email-already-in-use':
  //       return 'البريد الإلكتروني مستخدم بالفعل';
  //     case 'invalid-email':
  //       return 'بريد إلكتروني غير صالح';
  //     case 'weak-password':
  //       return 'كلمة المرور ضعيفة';
  //     default:
  //       return 'حدث خطأ أثناء التسجيل';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل علامة تجارية جديدة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة البراند
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _brandImage != null
                      ? FileImage(_brandImage!)
                      : null,
                  child: _brandImage == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'معلومات الحساب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'بريد إلكتروني غير صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء تأكيد كلمة المرور';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'معلومات العلامة التجارية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _brandNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم العلامة التجارية',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم العلامة التجارية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _brandCategoryController,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال فئة العلامة التجارية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _brandDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال وصف العلامة التجارية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط الموقع الإلكتروني',
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _facebookController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط الفيسبوك',
                  prefixIcon: Icon(Icons.facebook),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _twitterController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط تويتر',
                  prefixIcon: Icon(Icons.circle_outlined), // يمكن استبدالها بأيقونة تويتر
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _instagramController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط إنستجرام',
                  prefixIcon: Icon(Icons.camera_alt), // يمكن استبدالها بأيقونة إنستجرام
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تسجيل العلامة التجارية',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BrandLoginPage()),
                  );
                },
                child: const Text('لديك حساب بالفعل؟ سجل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}