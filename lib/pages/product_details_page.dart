// ignore_for_file: deprecated_member_use, avoid_types_as_parameter_names

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

  // Helper widget for creating badges (similar to ProductCard)
  Widget _buildBadge(BuildContext context, String text, Color backgroundColor, IconData? icon) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6), // Add margin between badges
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: theme.colorScheme.onPrimary.withOpacity(0.9)),
          if (icon != null)
            const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary, // Assuming badge background contrasts well with onPrimary
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        // Use theme's AppBarTheme
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
            // Style from theme
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
          final bool hasDiscount = product.discountPrice != null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image with badges overlay
                Stack(
                  children: [
                    Hero(
                      tag: product.id, // Ensure Hero tag matches if used elsewhere
                      child: Container(
                        color: Colors.grey.shade100,
                        height: 300,
                        child: product.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: product.images.length,
                                itemBuilder: (context, index) => Image.network(
                                  product.images[index],
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, size: 80)),
                                ),
                              )
                            : const Center(child: Icon(Icons.image_not_supported_outlined, size: 80)),
                      ),
                    ),
                    // Badges positioned on the image
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                           if (product.isNew)
                             _buildBadge(context, 'جديد', Colors.blue.shade600, Icons.new_releases_outlined),
                           if (product.isFeatured)
                             _buildBadge(context, 'مميز', colorScheme.secondary, Icons.star_border_outlined),
                           if (hasDiscount)
                             _buildBadge(context, 'خصم!', colorScheme.error, Icons.local_offer_outlined),
                          //  if (product.isFreeShipping)
                          //    _buildBadge(context, 'شحن مجاني', Colors.green.shade600, Icons.local_shipping_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + favorite
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FavoriteButton(productId: product.id),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Price
                      Row(
                        children: [
                          Text(
                            "${product.discountPrice ?? product.price} جنيه",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: hasDiscount ? colorScheme.error : colorScheme.onSurface,
                            ),
                          ),
                          if (hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                "${product.price} جنيه",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text("الوصف", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(product.description, style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("المراجعات", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          if (reviewSnapshot.hasError || !reviewSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Text("حدث خطأ أثناء تحميل المراجعات."),
                            );
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
                                    itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber.shade600),
                                    itemCount: 5,
                                    itemSize: 20,
                                    unratedColor: Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 8),
                                  Text("(${avgRating.toStringAsFixed(1)}) ${reviews.length} مراجعة", style: theme.textTheme.bodyMedium),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (reviews.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(child: Text("لا توجد مراجعات حتى الآن.", style: TextStyle(color: Colors.grey))),
                                ),
                              ListView.separated(
                                itemCount: reviews.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) => const Divider(height: 24, thickness: 0.5),
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

