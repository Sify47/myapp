import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/cart_service.dart';
import 'package:myapp/models/product.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Import custom widgets
import '../widgets/search_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card_horizontal.dart';
import '../widgets/feature_banner.dart';
import '../widgets/favorite_button.dart';

// Import pages
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wafrha'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications page
              // Will be implemented later
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              // SearchBarWidget(
              //   onSearch: (query) {
              //     // Navigate to search results
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         // builder: (_) => CatalogPage(searchQuery: query),
              //           builder: (_) => CatalogPage(),
              //       ),
              //     );
              //   },
              // ),
              
              // Featured Offers Carousel
              _buildFeaturedOffers(context),
              
              const SizedBox(height: 24),
              
              // Categories Section
              _buildCategoriesSection(context),
              
              const SizedBox(height: 24),
              
              // Best Selling Products
              _buildBestSellingProducts(context),
              
              const SizedBox(height: 24),
              
              // Brands Section
              _buildBrandsSection(context),
              
              const SizedBox(height: 24),
              
              // Latest Offers
              _buildLatestOffers(context),
              
              const SizedBox(height: 24),
              
              // Features Section
              _buildFeaturesSection(context),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  // Featured Offers Carousel
  Widget _buildFeaturedOffers(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('products')
        //.orderBy('createdAt', descending: true)  // لو حابب ترتيب حسب تاريخ الإضافة
        .where('isFeatured', isEqualTo: true)
        .limit(5)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      
      final products = snapshot.data!.docs;
      
      return SizedBox(
        height: 200,
        child: PageView.builder(
          itemCount: products.length,
          controller: PageController(viewportFraction: 0.9),
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                      productId: product.id,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(product['images'][0]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gradient overlay for text visibility
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),

                    // Product name and price
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product['price'].toString()} ر.س',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Favorite button (لو تستخدمه مع المنتج)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: FavoriteButton(
                        productId: product.id,
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

  // Categories Section
  Widget _buildCategoriesSection(BuildContext context) {
    // Sample categories - in a real app, these would come from Firestore
    final categories = [
      {'name': 'إلكترونيات', 'image': 'https://via.placeholder.com/100?text=Electronics'},
      {'name': 'أزياء', 'image': 'https://via.placeholder.com/100?text=Fashion'},
      {'name': 'مطاعم', 'image': 'https://via.placeholder.com/100?text=Food'},
      {'name': 'جمال', 'image': 'https://via.placeholder.com/100?text=Beauty'},
      {'name': 'رياضة', 'image': 'https://via.placeholder.com/100?text=Sports'},
      {'name': 'منزل', 'image': 'https://via.placeholder.com/100?text=Home'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التصنيفات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CatalogPage()),
                  );
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryCard(
                name: category['name']!,
                imageUrl: category['image']!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // builder: (_) => CatalogPage(category: category['name']),
                      builder: (_) => CatalogPage(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Best Selling Products
  Widget _buildBestSellingProducts(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          // .orderBy('soldCount', descending: true)
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
          return const SizedBox(); // Hide section if no products
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
                    'الأكثر مبيعاً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // builder: (_) => const CatalogPage(sortBy: 'bestselling'),
                          builder: (_) => const CatalogPage(),
                        ),
                      );
                    },
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productData = products[index].data() as Map<String, dynamic>;
                  final product = Product.fromFirestore(products[index]);
                  
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
                              // Navigate to cart page
                              Navigator.of(context).pushNamed('/cart');
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
                'الماركات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BrandsPage()),
                  );
                },
                child: const Text('عرض الكل'),
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
                'أحدث العروض',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OffersPage()),
                  );
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('offers')
              // .orderBy('createdAt', descending: true)
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
                          builder: (_) => OfferDetailsPage(
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
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.black54, Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          
                          // Offer title
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
                          
                          // Favorite button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FavoriteButton(
                              productId: offer.id,
                              // offerData: offer.data() as Map<String, dynamic>,
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
        children: [
          const Text(
            'لماذا تختارنا',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const FeatureBanner(
            title: 'الدفع عند الاستلام',
            description: 'ادفع نقداً عند استلام طلبك',
            icon: Icons.payments_outlined,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          const FeatureBanner(
            title: 'توصيل سريع',
            description: 'نوصل طلبك بأسرع وقت ممكن',
            icon: Icons.local_shipping_outlined,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          const FeatureBanner(
            title: 'عروض حصرية',
            description: 'احصل على أفضل العروض والخصومات',
            icon: Icons.local_offer_outlined,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
  
  // Brand Card
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
            builder: (_) => BrandDetailsPage(
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
                child: imageUrl.endsWith('.svg')
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
