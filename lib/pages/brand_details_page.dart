import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'offer_details_page.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class BrandDetailsPage extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String facebook;
  final String x;
  final String website;
  final String insta;
  final String dec;
  // final String id;

  const BrandDetailsPage({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.facebook,
    required this.insta,
    required this.website,
    required this.x,
    required this.dec,
    // required this.id,
  });

  @override
  State<BrandDetailsPage> createState() => _BrandDetailsPageState();
}

class _BrandDetailsPageState extends State<BrandDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";
  bool _isLoading = false;
  List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text.trim();
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          // .where('brandId', isEqualTo: widget.name)
          .where('productStatus', isEqualTo: 'active')
          .get();

      setState(() {
        _products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحميل المنتجات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Product> _filterProducts() {
    if (_searchTerm.isEmpty) return _products;

    return _products.where((product) {
      return product.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (product.description.toLowerCase().contains(_searchTerm.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredProducts = _filterProducts();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            tabs: [Tab(text: 'العروض'), Tab(text: 'المنتجات')],
            labelColor: Colors.black,
            indicatorColor: Colors.deepPurple,
          ),
        ),
        body: TabBarView(
          children: [
            // تبويب العروض من Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('brand', isEqualTo: widget.name)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد عروض متاحة'));
                }

                final offers = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final offerData = offer.data() as Map<String, dynamic>;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfferDetailsPage(
                                title: offerData['title'] ?? '',
                                imageUrl: offerData['image'] ?? '',
                                description: offerData['description'] ?? '',
                                category: offerData['category'] ?? 'عام',
                                expiry: offerData['expiry'] ?? 'غير محدد',
                                offerCode: offerData['offerCode'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: Image.network(
                                offerData['image'] ?? '',
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 160,
                                  child: Center(
                                    child: Text("خطأ في تحميل الصورة"),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offerData['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'الفئة: ${offerData['category'] ?? 'عام'}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'ينتهي في: ${offerData['expiry'] ?? 'غير محدد'}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  if ((offerData['offerCode'] ?? '').isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'كود العرض: ${offerData['offerCode']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
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
                  },
                );
              },
            ),

            // تبويب المنتجات المعدل
            RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF3366FF),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ابحث عن منتج...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Icons.search,
                              color: const Color(0xFF3366FF),
                            ),
                            suffixIcon: _searchTerm.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600]),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: _isLoading
                        ? SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFF3366FF),
                              ),
                            ),
                          )
                        : filteredProducts.isEmpty
                            ? SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    'لا توجد منتجات متاحة',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            : SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final product = filteredProducts[index];
                                    return ProductCard(product: product);
                                  },
                                  childCount: filteredProducts.length,
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _isScrolled
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF3366FF),
                child: const Icon(Icons.arrow_upward),
                onPressed: () => _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              )
            : null,
        persistentFooterButtons: [
          FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(
                        child: widget.imageUrl.endsWith('.svg')
                            ? SvgPicture.network(widget.imageUrl, height: 80)
                            : Image.network(widget.imageUrl, height: 80),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.dec,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'تابعنا على:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.facebook,
                              color: Color(0xFF3366FF),
                            ),
                            onPressed: () => launchUrl(Uri.parse(widget.facebook)),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.purple,
                            ),
                            onPressed: () => launchUrl(Uri.parse(widget.insta)),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.alternate_email,
                              color: Colors.lightBlue,
                            ),
                            onPressed: () => launchUrl(Uri.parse(widget.x)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.language),
                            onPressed: () => launchUrl(Uri.parse(widget.website)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}