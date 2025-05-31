import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../widgets/favorite_button.dart';
import '../widgets/review_card.dart';
import '../widgets/add_review_dialog.dart';
import '../auth_model.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  void _showAddReviewDialog(BuildContext context, String productId) {
    final auth = Provider.of<AuthModel>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول أولاً لإضافة مراجعة.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(productId: productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final reviewService = Provider.of<ReviewService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        centerTitle: true,
        elevation: 1,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();
              if (productSnapshot.exists) {
                final product = Product.fromFirestore(productSnapshot);
                cartService.addItemToCart(product, quantity: 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت الإضافة إلى السلة')),
                );
              }
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text("أضف إلى السلة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('المنتج غير موجود.'));
          }

          final product = Product.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image
                Hero(
                  tag: product.id,
                  child: Container(
                    color: Colors.grey.shade100,
                    height: 300,
                    child: product.images.isNotEmpty
                        ? PageView.builder(
                            itemCount: product.images.length,
                            itemBuilder: (context, index) => Image.network(product.images[index], fit: BoxFit.contain),
                          )
                        : const Center(child: Icon(Icons.image_not_supported_outlined, size: 80)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + favorite
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          FavoriteButton(productId: product.id),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Price
                      Row(
                        children: [
                          Text(
                            "${product.discountPrice ?? product.price} ر.س",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: product.discountPrice != null ? Colors.red : Colors.black,
                            ),
                          ),
                          if (product.discountPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                "${product.price} ر.س",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text("الوصف", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(product.description, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Reviews
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("المراجعات", style: Theme.of(context).textTheme.titleLarge),
                          TextButton.icon(
                            onPressed: () => _showAddReviewDialog(context, product.id),
                            icon: const Icon(Icons.add_comment_outlined),
                            label: const Text("أضف مراجعة"),
                          ),
                        ],
                      ),
                      StreamBuilder<List<Review>>(
                        stream: reviewService.getReviewsForProductStream(product.id),
                        builder: (context, reviewSnapshot) {
                          if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          if (reviewSnapshot.hasError || !reviewSnapshot.hasData) {
                            return const Text("حدث خطأ أثناء تحميل المراجعات.");
                          }

                          final reviews = reviewSnapshot.data!;
                          final avgRating = reviews.isNotEmpty
                              ? reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length
                              : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: avgRating,
                                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                    itemCount: 5,
                                    itemSize: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text("(${avgRating.toStringAsFixed(1)} من 5) - ${reviews.length} مراجعة"),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (reviews.isEmpty)
                                const Text("لا توجد مراجعات حتى الآن.", style: TextStyle(color: Colors.grey)),
                              ListView.separated(
                                itemCount: reviews.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => ReviewCard(review: reviews[index]),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
