import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/wishlist_service.dart';
import '../widgets/product_card.dart'; // Re-use ProductCard for display

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistService = Provider.of<WishlistService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<String>>(
        stream: wishlistService.getWishlistProductIdsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'قائمة المفضلة فارغة.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final productIds = snapshot.data!;

          // Now, fetch product details for each ID
          // Note: Fetching many individual documents can be inefficient.
          // Consider structuring data differently or using backend functions for larger scale.
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7, // Adjust aspect ratio for product cards
            ),
            itemCount: productIds.length,
            itemBuilder: (context, index) {
              final productId = productIds[index];
              // Fetch product details using a FutureBuilder for each item
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    // Show a placeholder while loading product details
                    return const Card(child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  }
                  if (productSnapshot.hasError || !productSnapshot.hasData || !productSnapshot.data!.exists) {
                    // Handle error or product not found - maybe show a placeholder or remove from wishlist?
                    // For now, just show an empty card or an error indicator
                    return Card(
                      child: Center(
                        child: Icon(Icons.error_outline, color: Colors.red.shade200),
                      ),
                    );
                  }

                  final product = Product.fromFirestore(productSnapshot.data!);
                  // Use the existing ProductCard widget
                  return ProductCard(product: product);
                },
              );
            },
          );
        },
      ),
    );
  }
}

