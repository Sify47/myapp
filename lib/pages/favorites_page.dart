import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/pages/catalog_page.dart';
import 'package:myapp/services/wishlist_service.dart'; // تأكد من المسار الصحيح
import '../models/product.dart';
import '../widgets/product_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final WishlistService _wishlistService = WishlistService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAllFavorites,
            // onPressed: _addTestFavorite,
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _wishlistService.getWishlistProductIdsStream(),
        builder: (context, snapshot) {
          // طباعة للتdebug
          debugPrint('Wishlist snapshot state: ${snapshot.connectionState}');
          debugPrint('Has data: ${snapshot.hasData}');
          debugPrint('Has error: ${snapshot.hasError}');
          
          if (snapshot.hasError) {
            debugPrint('Error: ${snapshot.error}');
            return Center(
              child: Text('حدث خطأ: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteProductIds = snapshot.data ?? [];
          debugPrint('Favorite products count: ${favoriteProductIds.length}');

          if (favoriteProductIds.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: favoriteProductIds.length,
            itemBuilder: (context, index) {
              final productId = favoriteProductIds[index];
              debugPrint('Loading product: $productId');
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get(),
                builder: (context, productSnapshot) {
                  debugPrint('Product ${productSnapshot.connectionState} for $productId');
                  
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildProductPlaceholder();
                  }

                  if (productSnapshot.hasError) {
                    debugPrint('Product error: ${productSnapshot.error}');
                    return _buildProductError();
                  }

                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    debugPrint('Product $productId does not exist');
                    // إزالة المنتج غير موجود من المفضلة تلقائياً
                    _removeNonExistentProduct(productId);
                    return _buildProductNotFound();
                  }

                  try {
                    final product = Product.fromFirestore(productSnapshot.data!);
                    return ProductCard(
                      product: product,
                      onFavoriteChanged: (isFavorite) {
                        if (!isFavorite) {
                          _wishlistService.removeFromWishlist(productId);
                        }
                      },
                    );
                  } catch (e) {
                    debugPrint('Error parsing product: $e');
                    return _buildProductError();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('جاري التحميل...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductError() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(height: 8),
            Text('خطأ في التحميل', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductNotFound() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart, color: Colors.grey, size: 24),
            SizedBox(height: 8),
            Text('المنتج غير موجود', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'قائمة المفضلة فارغة',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف المنتجات التي تعجبك إلى المفضلة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatalogPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3366FF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('استكشاف المنتجات'),
          ),
        ],
      ),
    );
  }

  void _clearAllFavorites() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('مسح الكل'),
      content: const Text('هل تريد مسح جميع المنتجات من المفضلة؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              // الحل البديل بدون استخدام getWishlistCollectionRef
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final wishlistRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('wishlistItems');
                
                final snapshot = await wishlistRef.get();
                final batch = FirebaseFirestore.instance.batch();
                
                for (final doc in snapshot.docs) {
                  batch.delete(doc.reference);
                }
                
                await batch.commit();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح المفضلة بنجاح')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('حدث خطأ أثناء المسح')),
              );
            }
          },
          child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
  void _removeNonExistentProduct(String productId) async {
    try {
      await _wishlistService.removeFromWishlist(productId);
      debugPrint('Removed non-existent product: $productId');
    } catch (e) {
      debugPrint('Error removing non-existent product: $e');
    }
  }

  // دالة لإضافة منتج تجريبي (للتجربة فقط)
  // void _addTestFavorite() async {
  //   try {
  //     // جلب أول منتج من قاعدة البيانات لإضافته للتجربة
  //     final productsSnapshot = await FirebaseFirestore.instance
  //         .collection('products')
  //         .limit(1)
  //         .get();
      
  //     if (productsSnapshot.docs.isNotEmpty) {
  //       final testProductId = productsSnapshot.docs.first.id;
        
  //       await _wishlistService.addToWishlist(testProductId);
        
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('تم إضافة منتج تجريبي')),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error adding test favorite: $e');
  //   }
  // }
}