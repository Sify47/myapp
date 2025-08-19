import 'package:cached_network_image/cached_network_image.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/pages/cart_page.dart';
import 'package:myapp/searchpage.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/cart_service.dart';
import 'package:myapp/models/product.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Custom widgets
import '../widgets/search_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card_horizontal.dart';
import '../widgets/feature_banner.dart';
import '../widgets/favorite_button.dart';
import 'package:myapp/auth_model.dart';

// Pages
import 'brand_details_page.dart';
import 'brands_page.dart';
import 'offer_details_page.dart';
import 'offers_page.dart';
import 'catalog_page.dart';
import 'product_details_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final auth = Provider.of<AuthModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dolabk'),
        backgroundColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Color(0xFF3366FF),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined , color: Color(0xFF3366FF),),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(userId: auth.currentUser!.uid),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildFeaturedOffers(context),
              const SizedBox(height: 24),
              _buildCollectionsSection(context),
              const SizedBox(height: 24),
              _buildstyle(context),
              const SizedBox(height: 24),
              _buildFlashSaleSection(context),
              const SizedBox(height: 24),
              _buildCategoriesSection(context),
              const SizedBox(height: 24),
              _buildBestSellingProducts(context),
              const SizedBox(height: 24),
              // _buildBrandsSection(context),
              // const SizedBox(height: 24),
              // _buildLatestOffers(context),
              // const SizedBox(height: 24),
              _buildFeaturesSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('collections').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 170,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final collections = snapshot.data!.docs;

        // تصفية المجموعات للحصول على "Men" و"Women" فقط
        final menCollection = collections.firstWhere(
          (doc) => doc['title'] == 'Men',
          orElse: () => throw Exception('Men collection not found'),
        );

        final womenCollection = collections.firstWhere(
          (doc) => doc['title'] == 'Women',
          orElse: () => throw Exception('Women collection not found'),
        );

        return Column(
          children: [
            // صف أفقي للرجالي والحريمي
            Row(
              children: [
                // قسم الرجالي (Men)
                Expanded(
                  child: _buildCollectionBanner(
                    context: context,
                    title: menCollection['title'],
                    imageUrl: menCollection['imageUrl'],
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 4),
                // قسم الحريمي (Women)
                Expanded(
                  child: _buildCollectionBanner(
                    context: context,
                    title: womenCollection['title'],
                    imageUrl: womenCollection['imageUrl'],
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 16),
            // باقي المجموعات (إن وجدت)
          ],
        );
      },
    );
  }

  Widget _buildCollectionBanner({
    required BuildContext context,
    required String title,
    required String imageUrl,
    required Color color, // إضافة معامل اللون
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CatalogPage(cat: 'All', initialCollection: title),
          ),
        );
      },
      child: Container(
        height: 170,
        margin: const EdgeInsets.symmetric(horizontal: 10), // تعديل الهامش
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color, // استخدام اللون المحدد
          image: DecorationImage(
            image: NetworkImage(imageUrl, scale: 2),
            alignment: Alignment.centerRight,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildstyle(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('styles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data!.docs;

        return SizedBox(
          height: 100,
          child: PageView.builder(
            itemCount: banners.length,
            controller: PageController(viewportFraction: 0.6, keepPage: true),
            padEnds: false,
            itemBuilder: (context, index) {
              final banner = banners[index];
              final data = banner.data() as Map<String, dynamic>;
              // final title = data['title'] ?? 'عرض خاص'; // النص الذي تريد عرضه

              return GestureDetector(
                onTap: () => _handleBannerTap(context, data),
                child: Container(
                  width: 250,
                  height: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // الصورة مع تقليل الإضاءة
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(
                              0.4,
                            ), // نسبة التعتيم (0.3 = 30%)
                            BlendMode.darken,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: data['image_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error_outline,
                                    size: 24,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      // النص في المنتصف
                      Center(
                        child: Text(
                          data['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFlashSaleSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('flashSaleSettings')
              .doc('currentSale')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildInactiveFlashSale();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool isActive = data['isActive'] ?? false;
        final Timestamp? endTime = data['saleEndTime'] as Timestamp?;

        if (!isActive || endTime == null) {
          return _buildInactiveFlashSale();
        }

        final DateTime saleEndTime = endTime.toDate();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red[50]!.withOpacity(0.3),
                Colors.white.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Fire Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FLASH SALE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildCountdownTimer(saleEndTime),
                      ],
                    ),
                  ],
                ),
              ),
              // Products List
              _buildFlashSaleProducts(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInactiveFlashSale() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: const Text(
        'No active flash sale',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildCountdownTimer(DateTime endTime) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final remaining = endTime.difference(DateTime.now());

        if (remaining.isNegative) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Sale Ended',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[700],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m ${remaining.inSeconds.remainder(60)}s',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashSaleProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .where('inFlashSale', isEqualTo: true)
              .limit(6)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No flash deals available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final product = Product.fromFirestore(snapshot.data!.docs[index]);
              return _buildPremiumFlashSaleItem(context, product);
            },
          ),
        );
      },
    );
  }

  Widget _buildPremiumFlashSaleItem(BuildContext context, Product product) {
    // ignore: unnecessary_null_comparison
    // final discountPercentage = product.discountPrice != null;
    double? discountPercentage;
    if (product.discountPrice != null &&
        product.discountPrice! < product.price &&
        product.price > 0) {
      discountPercentage =
          ((product.price - product.discountPrice!) / product.price) * 100;
    }
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(productId: product.id),
            ),
          ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16, bottom: 16, top: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with Ribbon
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.images.first,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) =>
                                Container(color: Colors.grey[200], height: 160),
                        errorWidget:
                            (_, __, ___) => Container(
                              color: Colors.grey[200],
                              height: 160,
                              child: const Icon(Icons.error),
                            ),
                      ),
                    ),

                    // Discount Ribbon
                    Positioned(
                      top: 12,
                      right: -20,
                      child: Transform.rotate(
                        angle: 0.79, // 45 degrees in radians
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.red,
                          child: Center(
                            child: Text(
                              '${discountPercentage?.toInt()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Product Details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price with original price crossed out
                      Row(
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(2)}L.E',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.price.toStringAsFixed(2)}L.E',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stock progress bar
                      LinearProgressIndicator(
                        value: product.stock / 100, // Assuming max stock is 100
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.red,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Left: ${product.stock}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Hot Icon
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Featured Offers Carousel
  Widget _buildFeaturedOffers(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ads_banners')
              .where('active', isEqualTo: true)
              .orderBy('order', descending: false)
              .limit(5)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 160,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data!.docs;

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                itemCount: banners.length,
                controller: PageController(viewportFraction: 0.95),
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final data = banner.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      _handleBannerTap(context, data);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: data['image_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder:
                              (context, url) =>
                                  Container(color: Colors.grey[200]),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _handleBannerTap(BuildContext context, Map<String, dynamic> data) {
    final type = data['link_type'];
    final value = data['link_value'];

    switch (type) {
      case 'product':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(productId: value),
          ),
        );
        break;
      case 'category':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CatalogPage(cat: value)),
        );
        break;
      case 'url':
        launchUrl(Uri.parse(value));
        break;
      default:
        break;
    }
  }

  // Categories Section
  Widget _buildCategoriesSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('categories')
              // .where('isActive', isEqualTo: true)
              .orderBy("index" , descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final categories = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => const CatalogPage(
                                cat: 'All',
                                initialCollection: "All",
                              ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final data = category.data() as Map<String, dynamic>;

                  return _buildCategoryItem(
                    context: context,
                    name: data['name'],
                    imageUrl: data['imageUrl'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CatalogPage(cat: data['name']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String name,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 30),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 50, height: 12, color: Colors.grey.shade200),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Failed to load categories',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // Best Selling Products
  Widget _buildBestSellingProducts(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Best Selling',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CatalogPage(cat: 'All'),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = Product.fromFirestore(products[index]);

                  return ProductCardHorizontal(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetailsPage(productId: product.id),
                        ),
                      );
                    },
                    onAddToCart: () {
                      cartService.addItemToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product.name} has been added to cart',
                          ),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartPage(),
                                ),
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
  }

  // Brands Section
  Widget _buildBrandsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Brands',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BrandsPage()),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('brands').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final brands = snapshot.data!.docs;
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return _buildBrandCard(
                    context,
                    brand['name'],
                    brand['image'],
                    brand['x'],
                    brand['instagram'],
                    brand['facebook'],
                    brand['website'],
                    brand['description'],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Latest Offers
  Widget _buildLatestOffers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Offers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OffersPage()),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('offers')
                  .limit(10)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final offers = snapshot.data!.docs;
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: offers.length,
                padding: const EdgeInsets.only(left: 16),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OfferDetailsPage(
                                title: offer['title'],
                                imageUrl: offer['image'],
                                description: offer['description'],
                                expiry: offer['expiry'],
                                category: offer['category'],
                                offerCode: offer['offerCode'],
                              ),
                        ),
                      );
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(offer['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Colors.black54, Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              offer['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FavoriteButton(productId: offer.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Features Section
  Widget _buildFeaturesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Why Choose Us',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FeatureBanner(
            title: 'Cash on Delivery',
            description: 'Pay when you receive your order',
            icon: Icons.payments_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 12),
          FeatureBanner(
            title: 'Fast Delivery',
            description: 'We deliver your order quickly',
            icon: Icons.local_shipping_outlined,
            color: Color(0xFF3366FF),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(
    BuildContext context,
    String name,
    String imageUrl,
    String x,
    String inst,
    String face,
    String website,
    String dec,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => BrandDetailsPage(
                  name: name,
                  imageUrl: imageUrl,
                  facebook: face,
                  x: x,
                  website: website,
                  insta: inst,
                  dec: dec,
                ),
          ),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child:
                    imageUrl.endsWith('.svg')
                        ? SvgPicture.network(imageUrl, width: 80, height: 80)
                        : Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
