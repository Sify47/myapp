import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';
import '../auth_model.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    String email = Provider.of<AuthModel>(context).email;
    String password = Provider.of<AuthModel>(context).password;
    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Mohamed Mostafa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('mohamed@example.com'),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );},
            ),
          ],
        ),
      ),
    );
  }
}