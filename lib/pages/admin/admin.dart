import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_brand_page.dart';
import 'update_brand_page.dart';
import 'add_offer_page.dart';
import 'update_offer_page.dart';
import 'reports_page.dart';
import '../../auth_model.dart';
import '../login_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> adminOptions = [
      {'title': 'Add Brand', 'icon': Icons.add_business, 'page': const AddBrandPage()},
      {'title': 'Update Brand', 'icon': Icons.edit, 'page': const UpdateBrandPage()},
      {'title': 'Add Offer', 'icon': Icons.add_box, 'page': const AddOfferPage()},
      {'title': 'Update Offer', 'icon': Icons.edit, 'page': const UpdateOfferPage()},
      {'title': 'Reports', 'icon': Icons.bar_chart, 'page': const ReportsPage()},
    ];
  final auth = Provider.of<AuthModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel'), centerTitle: true , actions: [
    ListTile(
                leading: const Icon(Icons.logout),
                // title: const Text('Logout'),
                onTap: () async {
                  auth.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
  ], ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 أعمدة
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: adminOptions.length,
        itemBuilder: (context, index) {
          final item = adminOptions[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item['page']),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], size: 40, color: Colors.orange),
                  const SizedBox(height: 10),
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
