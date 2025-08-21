import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatefulWidget {
  final String? cat;
  final String? initialCollection;
  final String? initialstyle;

  const CatalogPage({super.key, this.cat, this.initialCollection , this.initialstyle});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Map<String, String> brandNameToId = {};
  Map<String, String> collectionNameToId = {};

  List<Product> _products = [];
  List<String> categories = ['All'];
  List<String> brands = ['All'];
  List<String> collections = ['All'];
  final List<String> priceRanges = [
    'All Price',
    'Under 200',
    '200 - 500',
    '500 - 1000',
    'Up To 1000',
  ];

  String selectedCategory = 'All';
  String? selectedBrand;
  String? selectedCollection;
  // String? selectedstyle;
  String? selectedPriceRange;
  String _searchTerm = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.cat ?? 'All';
    selectedCollection = widget.initialCollection;
    selectedBrand = widget.initialstyle;
    Timer? searchTimer;

    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text.trim());
      searchTimer?.cancel();
      searchTimer = Timer(const Duration(milliseconds: 500), () {
        _loadProducts();
      });
    });

    _loadFilters()
        .then((_) {
          return _loadCollections();
        })
        .then((_) {
          // بعد تحميل الفلاتر والمجموعات، نتحقق من القيمة الأولية
          if (widget.initialCollection != null) {
            final collectionId = collectionNameToId[widget.initialCollection!];
            if (collectionId == null) {
              debugPrint(
                'Collection ID not found for: ${widget.initialCollection}',
              );
            }
          }
          return _loadProducts();
        });
    _loadCollections();
    _loadProducts();
  }

  Future<void> _loadFilters() async {
    try {
      final categorySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      final brandSnapshot = await FirebaseFirestore.instance.collection('styles').get();

      final fetchedCategories =
          categorySnapshot.docs
              .map((doc) => doc['name'] as String)
              .toSet()
              .toList();
      final fetchedBrands = <String, String>{};
      for (final doc in brandSnapshot.docs) {
        final name = doc['name'] as String?;
        if (name != null) {
          fetchedBrands[name] = doc.id;
        }
      }

      setState(() {
        brands = ['All', ...fetchedBrands.keys];
        // brandNameToId = fetchedBrands;
        categories = ['All', ...fetchedCategories];
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _loadCollections() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('collections')
              // .where('isActive', isEqualTo: true)
              // .orderBy("index" , descending: false)
              .get();

      final fetchedCollections = <String, String>{};
      for (final doc in snapshot.docs) {
        final name = doc['title'] as String?;
        if (name != null) {
          fetchedCollections[name] = doc.id;
        }
      }

      setState(() {
        collections = ['All', ...fetchedCollections.keys];
        collectionNameToId = fetchedCollections;
      });
    } catch (e) {
      debugPrint('Error loading collections: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('productStatus', isEqualTo: 'active');

      if (selectedCategory != 'All') {
        query = query.where('categories', arrayContains: selectedCategory);
      }

      if (selectedBrand != null) {
        // final brandId = brandNameToId[selectedBrand!];
        // if (brandId != null) {
          query = query.where('style', isEqualTo: selectedBrand);
        }
      

      if (selectedCollection != null && selectedCollection != 'All') {
        final collectionId = collectionNameToId[selectedCollection!];
        if (collectionId != null) {
          query = query.where('collectionId', isEqualTo: collectionId);
        } else {
          debugPrint('Collection ID not found for: $selectedCollection');
        }
      }

      final snapshot = await query.get();
      List<Product> result =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      if (selectedPriceRange != null) {
        result =
            result.where((product) {
              switch (selectedPriceRange) {
                case 'Under 200':
                  return product.price < 200;
                case '200 - 500':
                  return product.price >= 200 && product.price <= 500;
                case '500 - 1000':
                  return product.price > 500 && product.price <= 1000;
                case 'Up To 1000':
                  return product.price > 1000;
                default:
                  return true;
              }
            }).toList();
      }

      if (_searchTerm.isNotEmpty) {
        result =
            result.where((product) {
              return product.name.toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  ) ||
                  product.description.toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  );
            }).toList();
      }

      setState(() => _products = result);
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _filterChip({required String label, required IconData icon}) {
    return Chip(
      label: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: const Color(0xFF3366FF),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // شريط الفلاتر الأفقي
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // بحث
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // الفئة (Category)
                  PopupMenuButton<String>(
                    tooltip: 'Categories',
                    onSelected: (value) {
                      setState(() => selectedCategory = value);
                      _loadProducts();
                    },
                    itemBuilder:
                        (_) =>
                            categories
                                .map(
                                  (cat) => PopupMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                    child: _filterChip(
                      label: selectedCategory,
                      icon: Icons.category,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // البراند
                  PopupMenuButton<String>(
                    tooltip: 'Style',
                    onSelected: (value) {
                      setState(() => selectedBrand = value == 'All' ? null : value);
                      _loadProducts();
                    },
                    itemBuilder: (_) => brands.map((brand) => PopupMenuItem(
                      value: brand,
                      child: Text(brand),
                    )).toList(),
                    child: _filterChip(
                      label: selectedBrand ?? 'Styles',
                      icon: Icons.store,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // المجموعة (Collection)
                  PopupMenuButton<String>(
                    tooltip: 'Collections',
                    onSelected: (value) {
                      setState(
                        () =>
                            selectedCollection = value == 'All' ? null : value,
                      );
                      _loadProducts();
                    },
                    itemBuilder:
                        (_) =>
                            collections
                                .map(
                                  (col) => PopupMenuItem(
                                    value: col,
                                    child: Text(col),
                                  ),
                                )
                                .toList(),
                    child: _filterChip(
                      label: selectedCollection ?? 'Collections',
                      icon:
                          selectedCollection == 'Men'
                              ? Icons.male
                              : selectedCollection == 'Women'
                              ? Icons.female
                              : Icons.collections,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // السعر
                  PopupMenuButton<String>(
                    tooltip: 'Price',
                    onSelected: (value) {
                      setState(
                        () =>
                            selectedPriceRange =
                                value == 'All Price' ? null : value,
                      );
                      _loadProducts();
                    },
                    itemBuilder:
                        (_) =>
                            priceRanges
                                .map(
                                  (price) => PopupMenuItem(
                                    value: price,
                                    child: Text(price),
                                  ),
                                )
                                .toList(),
                    child: _filterChip(
                      label: selectedPriceRange ?? 'All Price',
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // إعادة تعيين
                  IconButton(
                    tooltip: 'Reset',
                    icon: const Icon(Icons.refresh, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'All';
                        // selectedBrand = null;
                        selectedCollection = null;
                        selectedPriceRange = null;
                        _searchController.clear();
                      });
                      _loadProducts();
                    },
                  ),
                ],
              ),
            ),
          ),

          // المنتجات
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? const Center(child: Text('No Products Found'))
                    : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: _products[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
