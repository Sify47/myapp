import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/pages/catalog_page.dart';
import 'package:myapp/pages/cart_page.dart';
import 'package:myapp/services/cart_service.dart';
import 'package:myapp/models/cart_item.dart'; // Import CartItem model
import 'offers_page.dart';
import 'account_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Updated list of pages for the new navigation bar
  final List<Widget> _pages = [
    const HomePage(), // 0: Home
    const CatalogPage(
      cat: 'All',
      initialCollection: "All",
    ), // 1: Shop (Catalog)
    // const OffersPage(), // 2: Offers
    const CartPage(), // 3: Cart
    const AccountPage(), // 4: Account
  ];

  @override
  Widget build(BuildContext context) {
    // Get CartService instance without listening here, as StreamBuilder will handle updates
    final cartService = Provider.of<CartService>(context, listen: false);

    return Scaffold(
      body: IndexedStack(
        // Use IndexedStack to keep state of pages
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed, // Ensure all items are visible
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: Colors.white,
          elevation: 0, // No elevation as we're using a custom shadow
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Shop',
            ),
            // const BottomNavigationBarItem(
            //   icon: Icon(Icons.local_offer_outlined),
            //   activeIcon: Icon(Icons.local_offer),
            //   label: 'Offer',
            // ),
            // Use StreamBuilder to listen for cart changes and update the badge
            BottomNavigationBarItem(
              icon: StreamBuilder<List<CartItem>>(
                stream: cartService.getCartItemsStream(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  return Badge(
                    isLabelVisible: items.isNotEmpty,
                    label: Text(
                      items.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined),
                  );
                },
              ),
              activeIcon: StreamBuilder<List<CartItem>>(
                stream: cartService.getCartItemsStream(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  return Badge(
                    isLabelVisible: items.isNotEmpty,
                    label: Text(
                      items.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: const Icon(Icons.shopping_bag),
                  );
                },
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
