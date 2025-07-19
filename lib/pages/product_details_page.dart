import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
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
  int _currentImageIndex = 0;
  Map<String, String> selectedAttributes = {};
  late Future<DocumentSnapshot> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _showAddReviewDialog(BuildContext context, String productId) {
    final auth = Provider.of<AuthModel>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الدخول أولاً لإضافة مراجعة.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF3366FF),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(productId: productId),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(left: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3366FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3366FF) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.w500,
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
                height: 220,
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
                    'منتجات مشابهة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCardHorizontal(
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
                              content: Text('تمت إضافة ${product.name} إلى السلة'),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'عرض السلة',
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
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder<DocumentSnapshot>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF3366FF)),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.grey),
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
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
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
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                const Color(0xFF3366FF),
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
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 10,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.3),
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
                            const SizedBox(width: 10),
                            FavoriteButton(productId: product.id),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            product.images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentImageIndex == index ? 20 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index
                                    ? const Color(0xFF3366FF)
                                    : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 100,
                        right: 15,
                        child: Column(
                          children: [
                            if (product.isNew)
                              _buildBadge('جديد', const Color(0xFF3366FF)),
                            if (product.isFeatured)
                              _buildBadge('مميز', Colors.amber),
                            if (hasDiscount)
                              _buildBadge(
                                'خصم $discountPercentage%',
                                Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Product Header
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                          StreamBuilder<List<Review>>(
                            stream: reviewService.getReviewsForProductStream(
                              product.id,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const SizedBox();
                              }

                              final reviews = snapshot.data!;
                              final avgRating = reviews.isNotEmpty
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${product.discountPrice ?? product.price} ج.م",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3366FF),
                                  ),
                                ),
                                if (hasDiscount)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Text(
                                      "${product.price} ج.م",
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: product.stock > 0
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: product.stock > 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                            ),
                          ),
                          child: Text(
                            product.stock > 0 ? 'متوفر' : 'غير متوفر',
                            style: TextStyle(
                              color: product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      "الوصف",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Attributes
                    if (product.attributes.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "المواصفات",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...product.attributes.map((attr) {
                            final name = attr['name'];
                            final values = List<String>.from(attr['values'] ?? []);
                            final currentValue = selectedAttributes[name] ?? '';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                const SizedBox(height: 16),
                              ],
                            );
                          }),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Tags
                    if (product.tags.isNotEmpty) ...[
                      Text(
                        "العلامات",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: product.tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelStyle: TextStyle(
                                    color: const Color(0xFF3366FF),
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Recommended Products
                    _buildRecommendedProducts(product.id, cartService),
                    const SizedBox(height: 24),

                    // Reviews Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "التقييمات",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddReviewDialog(context, product.id),
                          icon: const Icon(
                            Icons.add_comment,
                            color: Color(0xFF3366FF),
                          ),
                          label: Text(
                            "أضف مراجعة",
                            style: TextStyle(
                              color: const Color(0xFF3366FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reviews List
                    StreamBuilder<List<Review>>(
                      stream: reviewService.getReviewsForProductStream(
                        product.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  Color(0xFF3366FF),
                                ),
                              ),
                            ),
                          );
                        }
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
                            ? reviews.fold(
                                  0.0,
                                  (sum, r) => sum + r.rating,
                                ) /
                                reviews.length
                            : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  "(${avgRating.toStringAsFixed(1)}) ${reviews.length} مراجعة",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (reviews.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.reviews,
                                        size: 50,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "لا توجد مراجعات حتى الآن",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _showAddReviewDialog(context, product.id),
                                        child: const Text("كن أول من يقيم"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ListView.separated(
                              itemCount: reviews.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 24, thickness: 0.5),
                              itemBuilder: (context, index) =>
                                  ReviewCard(review: reviews[index]),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3366FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.shopping_cart,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                "أضف إلى السلة",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final productSnapshot = await FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.productId)
                    .get();
                if (productSnapshot.exists) {
                  final product = Product.fromFirestore(productSnapshot);

                  // Check if all attributes are selected
                  if (product.attributes.isNotEmpty) {
                    final allSelected = product.attributes.every(
                      (attr) =>
                          selectedAttributes.containsKey(attr['name']) &&
                          selectedAttributes[attr['name']]!.isNotEmpty,
                    );

                    if (!allSelected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء اختيار جميع المواصفات المطلوبة'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF3366FF),
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
                    const SnackBar(
                      content: Text('تمت إضافة المنتج إلى السلة بنجاح'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}