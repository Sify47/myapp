import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_model.dart';
import 'login_page.dart';
import 'edit_pro.dart';

class AccountPage extends StatelessWidget {
const AccountPage({super.key});

@override
Widget build(BuildContext context) {
final auth = Provider.of<AuthModel>(context);
final User? user = FirebaseAuth.instance.currentUser;

return Scaffold(
  appBar: AppBar(
    title: const Center(child: Text('Account')),
  ),
  body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: user == null
        ? const Center(child: Text('لا يوجد مستخدم مسجل حالياً'))
        : Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=${user.email}',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user.email ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                '********',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('تعديل الحساب'),
                onTap: () {
                  // Navigator.push(
                    // context,
                    // MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  // );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  auth.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
  ),
);
}
}