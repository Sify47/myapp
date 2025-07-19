import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:myapp/models/review.dart';
import 'package:myapp/pages/product_details_page.dart';
import 'package:myapp/services/review_service.dart';
import '../models/brand.dart';
import '../models/product.dart';
import '../services/brand_se.dart';
import '../widgets/favorite_button.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double cardHeight;

  const ProductCard({super.key, required this.product, this.cardHeight = 220});
  
  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final theme = Theme.of(context);
  final reviewService = Provider.of<ReviewService>(context, listen: false);
  final brandService = Provider.of<BrandService>(context, listen: false);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(productId: product.id),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.green.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج + زر المفضلة
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child:
                        product.images.isNotEmpty
                            ? Image.network(
                              product.images[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder:
                                  (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                            )
                            : const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                  ),
                  Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(productId: product.id),
                ),
                ],
              ),
            ),
            // التفاصيل والسعر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<Brand>(
                    stream: brandService.getBrandStream(product.brandId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text(
                          "علامة تجارية",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        );
                      }
                      
                      final brand = snapshot.data!;
                      return Text(
                        brand.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),

                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                                    const SizedBox(height: 6),

                  StreamBuilder<List<Review>>(
                      stream: reviewService.getReviewsForProductStream(
                        product.id,
                      ),
                      builder: (context, snapshot) {

                        final reviews = snapshot.data!;
                        final avgRating =
                            reviews.isNotEmpty
                                ? reviews.fold(
                                      0.0,
                                      (sum, r) => sum + r.rating,
                                    ) /
                                    reviews.length
                                : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: avgRating,
                                  itemBuilder:
                                      (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                  itemCount: 5,
                                  itemSize: 20,
                                  unratedColor: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "(${avgRating.toStringAsFixed(1)})",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                          ],
                        );
                      },
                    ),
 
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${product.discountPrice ?? product.price} جنيه',
                        style: TextStyle(
                          color:
                              product.discountPrice != null
                                  ? Colors.redAccent
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (product.discountPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${product.price} جنيه',
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cartService.addItemToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.name} تمت إضافته إلى السلة',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'أضف للسلة',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Color(0xFF3366FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
