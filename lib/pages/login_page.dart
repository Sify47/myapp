import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_model.dart';
import '../widgets/custom_button.dart';
import 'main_page.dart';
import 'admin/admin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  void _submit() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();
  final auth = Provider.of<AuthModel>(context, listen: false);

  if (email.isNotEmpty && password.isNotEmpty) {
    try {
      // await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (email == 'admin@wafrha.com') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
      } else {
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
        if (_isLogin) {
        await auth.login(email, password);
      } else {
        await auth.register(email, password);
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('من فضلك أدخل البريد وكلمة المرور')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Wafrha")),
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _submit,
                text: _isLogin ? 'Login' : 'Register',
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? "Don't have an account? Register" : "Already have an account? Login",
                ),
              ),
//               TextButton(
//   onPressed: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const AdminPage()),
//     );
//   },
//   child: const Text(
//     'تسجيل دخول المدير',
//     style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
//   ),
// ),

            ],
          ),
        ),
      ),
    );
  }
}
