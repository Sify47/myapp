import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:myapp/models/brand.dart';
import 'package:myapp/models/product.dart';
import 'package:myapp/models/review.dart';
import 'package:myapp/services/review_service.dart';
import 'package:myapp/services/brand_se.dart';
import 'package:myapp/widgets/favorite_button.dart';
import 'package:provider/provider.dart';

class ProductCardHorizontal extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = product.images.isNotEmpty
        ? product.images.first
        : 'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png';

    double? discountPercentage;
    if (product.discountPrice != null &&
        product.discountPrice! < product.price &&
        product.price > 0) {
      discountPercentage =
          ((product.price - product.discountPrice!) / product.price) * 100;
    }

    final theme = Theme.of(context);
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final brandService = Provider.of<BrandService>(context, listen: false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 130,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (discountPercentage != null && discountPercentage > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${discountPercentage.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
            
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Name
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

                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Ratings
                  StreamBuilder<List<Review>>(
                    stream: reviewService.getReviewsForProductStream(product.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              "حدث خطأ أثناء تحميل المراجعات",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        );
                      }

                      final reviews = snapshot.data!;
                      final avgRating = reviews.isNotEmpty
                          ? reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: avgRating,
                                itemBuilder: (context, _) => const Icon(
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
                  
                  // Price Section
                  Row(
                    children: [
                      Text(
                        '${(product.discountPrice ?? product.price)} ج.م',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (product.discountPrice != null &&
                          product.discountPrice! < product.price)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${product.price} ج.م',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
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
                        backgroundColor: const Color(0xFF3366FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                                    // const SizedBox(height: 6),
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}