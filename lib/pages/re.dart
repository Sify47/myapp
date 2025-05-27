import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReAuthPage extends StatefulWidget {
  final User user;

  const ReAuthPage({required this.user, super.key});

  @override
  State<ReAuthPage> createState() => _ReAuthPageState();
}

class _ReAuthPageState extends State<ReAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _reauthenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: _passwordController.text.trim(),
      );
      await widget.user.reauthenticateWithCredential(credential);
      Navigator.pop(context, true); // إشارة نجاح
    } on FirebaseAuthException catch (e) {
      String message = 'فشل إعادة التحقق. تأكد من كلمة المرور.';
      if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعادة تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'يرجى إدخال كلمة المرور الخاصة بحسابك لإكمال التحديث',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _reauthenticate,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تأكيد'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
