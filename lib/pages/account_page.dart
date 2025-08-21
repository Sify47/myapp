import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/pages/loyalty_page.dart';
import 'package:myapp/pages/order_history_page.dart';
import 'package:myapp/pages/support_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../auth_model.dart';
import 'login_page.dart';
import 'edit_pro.dart';
import 'favorites_page.dart';
// import 'settings_page.dart';
// import 'address_page.dart';
// import 'payment_methods_page.dart';
// import 'notifications_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthModel>(context, listen: false);
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings),
        //     onPressed: () {
        //       // Navigator.push(
        //       //   context,
        //       //   MaterialPageRoute(builder: (_) => const SettingsPage()),
        //       // );
        //     },
        //   ),
        // ],
      ),
      body: user == null ? _buildGuestView(context) : _buildUserView(context, user, auth),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3366FF), width: 2),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Color(0xFF3366FF),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'مرحباً بك!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'سجل الدخول للوصول إلى جميع الميزات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureGrid(context),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3366FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserView(BuildContext context, User user, AuthModel auth) {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const Center(child: Text("لم يتم العثور على بيانات المستخدم"));
      }

      final userData = snapshot.data!.data() as Map<String, dynamic>;

      return SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF3366FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(
                        userData["photoURL"] ??
                            'https://cdn-icons-png.flaticon.com/512/9131/9131478.png',
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData["displayName"] ?? "المستخدم",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData["email"] ?? user.email ?? "",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Orders', Icons.shopping_bag, () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
                      }),
                      _buildStatItem('Favorite', Icons.favorite, () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FavoritesPage()));
                      }),
                      _buildStatItem('Loyalty', Icons.loyalty_rounded, () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LoyaltyPage()));
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle('Menu'),
                  _buildMenuTile('Orders', Icons.shopping_bag_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
                  }),
                  _buildMenuTile('Favorite', Icons.favorite_border, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
                  }),
                  _buildMenuTile('Settings', Icons.settings, () {}),
                  _buildMenuTile('Help', Icons.help_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
                  }),
                  _buildMenuTile('About Us', Icons.badge_rounded, () {}),
                  _buildMenuTile1('Logout', Icons.logout, Colors.red, () async {
                    await auth.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildFeatureCard('طلباتي', Icons.shopping_bag, Colors.blue),
        _buildFeatureCard('المفضلة', Icons.favorite, Colors.red),
        _buildFeatureCard('العناوين', Icons.location_on, Colors.green),
        _buildFeatureCard('الإعدادات', Icons.settings, Colors.orange),
      ],
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildMenuTile1(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}