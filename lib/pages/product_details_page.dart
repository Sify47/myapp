import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:badges/badges.dart' as badges;
import '../models/product.dart';
import '../models/review.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../widgets/favorite_button.dart';
import '../widgets/product_card_horizontal.dart';
import '../widgets/review_card.dart';
import '../widgets/add_review_dialog.dart';
import '../auth_model.dart';
import 'cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final PageController _imageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;
  Map<String, String> selectedAttributes = {};
  late Future<DocumentSnapshot> _productFuture;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _showAppBarTitle = _scrollController.offset > 200;
    });
  }

  void _showAddReviewDialog(BuildContext context, String productId) {
    final auth = Provider.of<AuthModel>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء تسجيل الدخول أولاً لإضافة مراجعة.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3366FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(productId: productId),
    );
  }

  Widget _buildBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeChip(String name, String value, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAttributes[name] = isSelected ? '' : value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(left: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3366FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3366FF) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedProducts(String productId, CartService cartService) {
    return FutureBuilder<DocumentSnapshot>(
      future: _productFuture,
      builder: (context, productSnapshot) {
        if (!productSnapshot.hasData) {
          return const SizedBox();
        }

        final product = Product.fromFirestore(productSnapshot.data!);
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('brandId', isEqualTo: product.brandId)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final products = snapshot.data!.docs
                .where((doc) => doc.id != productId)
                .map((doc) => Product.fromFirestore(doc))
                .toList();

            if (products.isEmpty) {
              return const SizedBox();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '🔄 منتجات مشابهة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 200,
                        child: ProductCardHorizontal(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsPage(productId: product.id),
                              ),
                            );
                          },
                          onAddToCart: () {
                            cartService.addItemToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تمت إضافة ${product.name} إلى السلة 🛒'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                action: SnackBarAction(
                                  label: 'عرض',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CartPage()),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF3366FF)),
                strokeWidth: 3,
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'المنتج غير موجود',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final product = Product.fromFirestore(snapshot.data!);
          final bool hasDiscount = product.discountPrice != null;
          final discountPercentage = hasDiscount
              ? ((product.price - product.discountPrice!) / product.price * 100).round()
              : 0;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 420,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: _showAppBarTitle ? 4 : 0,
                title: _showAppBarTitle
                    ? Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Product Images
                      PageView.builder(
                        controller: _imageController,
                        itemCount: product.images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) => CachedNetworkImage(
                          imageUrl: product.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  const Color(0xFF3366FF).withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Gradient Overlay
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Action Buttons
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        left: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.7),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.7),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.share,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final box = context.findRenderObject() as RenderBox?;
                                      await Share.share(
                                        '${product.name}\n${product.description}\nالسعر: ${product.price} ج.م',
                                        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FavoriteButton(productId: product.id),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Image Indicators
                      Positioned(
                        bottom: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            product.images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentImageIndex == index ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index
                                    ? const Color(0xFF3366FF)
                                    : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Product Badges
                      Positioned(
                        top: 120,
                        right: 20,
                        child: Column(
                          children: [
                            if (product.isNew)
                              _buildBadge('🆕 جديد', const Color(0xFF3366FF), icon: Icons.new_releases),
                            if (product.isFeatured)
                              _buildBadge('⭐ مميز', Colors.amber, icon: Icons.star),
                            if (hasDiscount)
                              _buildBadge(
                                '🎯 خصم $discountPercentage%',
                                Colors.red,
                                icon: Icons.local_offer,
                              ),
                          ].map((badge) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: badge,
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Header
                      const SizedBox(height: 24),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rating and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StreamBuilder<List<Review>>(
                            stream: reviewService.getReviewsForProductStream(product.id),
                            builder: (context, snapshot) {
                              final reviews = snapshot.data ?? [];
                              final avgRating = reviews.isNotEmpty
                                  ? reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length
                                  : 0.0;

                              return Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: avgRating,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 24,
                                    unratedColor: Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "(${avgRating.toStringAsFixed(1)})",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasDiscount)
                                Text(
                                  "${product.price} ج.م",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                "${product.discountPrice ?? product.price} ج.م",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3366FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: product.stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: product.stock > 0 ? Colors.green.shade100 : Colors.red.shade100,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.stock > 0 ? Icons.check_circle : Icons.error,
                              color: product.stock > 0 ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.stock > 0 ? '🟢 متوفر في المخزون' : '🔴 غير متوفر',
                              style: TextStyle(
                                color: product.stock > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Description
                      const Text(
                        "📝 الوصف",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Attributes
                      if (product.attributes.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🎨 المواصفات",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...product.attributes.map((attr) {
                              final name = attr['name'];
                              final values = List<String>.from(attr['values'] ?? []);
                              final currentValue = selectedAttributes[name] ?? '';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "• $name",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: values.map((value) {
                                        return _buildAttributeChip(
                                          name,
                                          value,
                                          currentValue == value,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }),
                          ],
                        ),

                      // Tags
                      if (product.tags.isNotEmpty) ...[
                        const Text(
                          "🏷️ العلامات",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: const Color(0xFF3366FF).withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelStyle: const TextStyle(
                                color: Color(0xFF3366FF),
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Recommended Products
                      _buildRecommendedProducts(product.id, cartService),
                      const SizedBox(height: 32),

                      // Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "💬 التقييمات",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddReviewDialog(context, product.id),
                            icon: const Icon(
                              Icons.add_comment,
                              color: Color(0xFF3366FF),
                            ),
                            label: const Text(
                              "أضف مراجعة",
                              style: TextStyle(
                                color: Color(0xFF3366FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reviews List
                      StreamBuilder<List<Review>>(
                        stream: reviewService.getReviewsForProductStream(product.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final reviews = snapshot.data ?? [];
                          final avgRating = reviews.isNotEmpty
                              ? reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length
                              : 0.0;

                          return Column(
                            children: [
                              if (reviews.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.reviews, size: 60, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "لا توجد مراجعات حتى الآن",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => _showAddReviewDialog(context, product.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3366FF),
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text("كن أول من يقيم"),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          RatingBarIndicator(
                                            rating: avgRating,
                                            itemBuilder: (context, _) => const Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber,
                                            ),
                                            itemCount: 5,
                                            itemSize: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "${avgRating.toStringAsFixed(1)}/5 • ${reviews.length} مراجعة",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ListView.separated(
                                      itemCount: reviews.length,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      separatorBuilder: (_, __) => const Divider(height: 32),
                                      itemBuilder: (context, index) => ReviewCard(review: reviews[index]),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // Add to Cart Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3366FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                final productSnapshot = await _productFuture;
                if (productSnapshot.exists) {
                  final product = Product.fromFirestore(productSnapshot);

                  if (product.attributes.isNotEmpty) {
                    final allSelected = product.attributes.every(
                      (attr) => selectedAttributes.containsKey(attr['name']) && 
                              selectedAttributes[attr['name']]!.isNotEmpty,
                    );

                    if (!allSelected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('الرجاء اختيار جميع المواصفات المطلوبة'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF3366FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  cartService.addItemToCart(
                    product,
                    quantity: 1,
                    selectedAttributes: selectedAttributes,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تمت إضافة المنتج إلى السلة بنجاح 🎉'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "أضف إلى السلة",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}