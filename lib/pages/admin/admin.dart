import 'package:flutter/material.dart';
import 'orderstatus.dart';
import 'package:provider/provider.dart';
import 'add_brand_page.dart';
import 'update_brand_page.dart';
import 'add_offer_page.dart';
import 'update_offer_page.dart';
import 'add_product_page.dart';
import 'list_products_page.dart';
import 'list_coupons_page.dart'; // Import List/Add Coupons Page
import 'reports_page.dart';
import '../../auth_model.dart';
import '../login_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Updated admin options to include coupon management
    final List<Map<String, dynamic>> adminOptions = [
      {
        'title': 'Add Brand',
        'icon': Icons.add_business,
        'page': const AddBrandPage(),
      },
      {
        'title': 'Update Brand',
        'icon': Icons.edit_note,
        'page': const UpdateBrandPage(),
      },
      {
        'title': 'Add Offer',
        'icon': Icons.add_box,
        'page': const AddOfferPage(),
      },
      {
        'title': 'Update Offer',
        'icon': Icons.edit_calendar,
        'page': const UpdateOfferPage(),
      },
      {
        'title': 'Add Product',
        'icon': Icons.add_shopping_cart,
        'page': const AddProductPage(),
      },
      {
        'title': 'Update Product',
        'icon': Icons.edit,
        'page': const ListProductsPage(),
      },
      {
        'title': 'Manage Coupons',
        'icon': Icons.discount,
        'page': const ListCouponsPage(),
      },
      {
        'title': 'Reports',
        'icon': Icons.bar_chart,
        'page': const ReportsPage(),
      },
      {
        'title': 'Orders',
        'icon': Icons.bar_chart,
        'page': const ManageOrdersPage(),
      },
    ];
    final auth = Provider.of<AuthModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Color(0xFF3366FF)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
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
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // Adjust aspect ratio if needed
        ),
        itemCount: adminOptions.length,
        itemBuilder: (context, index) {
          final item = adminOptions[index];
          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['page']),
                ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Color(0xFF3366FF), // Lighter shade for card
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'],
                    size: 40,
                    color: Color(0xFF3366FF),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
