import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatefulWidget {
  final String cat;
  const CatalogPage({super.key, required this.cat});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Map<String, String> brandNameToId = {};

  List<Product> _products = [];
  List<String> categories = ['الكل'];
  List<String> brands = ['كل البراندات'];
  final List<String> priceRanges = [
    'كل الأسعار',
    'أقل من 50',
    '50 - 100',
    '100 - 200',
    'أكثر من 200',
  ];

  String selectedCategory = 'الكل';
  String? selectedBrand;
  String? selectedPriceRange;
  String _searchTerm = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.cat;
    Timer? searchTimer;

_searchController.addListener(() {
  setState(() => _searchTerm = _searchController.text.trim());
  
  // إلغاء المؤقت السابق إذا كان موجوداً
  searchTimer?.cancel();
  
  // إنشاء مؤقت جديد (500 مللي ثانية بعد آخر كتابة)
  searchTimer = Timer(const Duration(milliseconds: 500), () {
    _loadProducts();
  });
});
    _loadFilters();
    _loadProducts();
  }

  Future<void> _loadFilters() async {
    try {
      final categorySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      final brandSnapshot =
          await FirebaseFirestore.instance
              .collection('brands')
              // .where('productStatus', isEqualTo: 'active')
              .get();

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
        brands = ['كل البراندات', ...fetchedBrands.keys];
        brandNameToId = fetchedBrands;
        categories = ['الكل', ...fetchedCategories];
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('productStatus', isEqualTo: 'active');

      if (selectedCategory != 'الكل') {
        query = query.where('categories', arrayContains: selectedCategory);
      }

      if (selectedBrand != null) {
        final brandId = brandNameToId[selectedBrand!];
        if (brandId != null) {
          query = query.where('brandId', isEqualTo: brandId);
        }
      }

      final snapshot = await query.get();
      List<Product> result =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      if (selectedPriceRange != null) {
        result =
            result.where((product) {
              switch (selectedPriceRange) {
                case 'أقل من 50':
                  return product.price < 50;
                case '50 - 100':
                  return product.price >= 50 && product.price <= 100;
                case '100 - 200':
                  return product.price >= 100 && product.price <= 200;
                case 'أكثر من 200':
                  return product.price > 200;
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

  InputDecoration dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
    );
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
          // ✅ شريط الفلاتر الأفقي
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 🔍 بحث
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث...',
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

                  // 📦 الفئة (Category)
                  PopupMenuButton<String>(
                    tooltip: 'الفئة',
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

                  // 🏭 البراند
                  PopupMenuButton<String>(
                    tooltip: 'البراند',
                    onSelected: (value) {
                      setState(
                        () =>
                            selectedBrand =
                                value == 'كل البراندات' ? null : value,
                      );
                      _loadProducts();
                    },
                    itemBuilder:
                        (_) =>
                            brands
                                .map(
                                  (brand) => PopupMenuItem(
                                    value: brand,
                                    child: Text(brand),
                                  ),
                                )
                                .toList(),
                    child: _filterChip(
                      label: selectedBrand ?? 'كل البراندات',
                      icon: Icons.store,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 💰 السعر
                  PopupMenuButton<String>(
                    tooltip: 'السعر',
                    onSelected: (value) {
                      setState(
                        () =>
                            selectedPriceRange =
                                value == 'كل الأسعار' ? null : value,
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
                      label: selectedPriceRange ?? 'كل الأسعار',
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🔄 إعادة تعيين
                  IconButton(
                    tooltip: 'إعادة تعيين',
                    icon: const Icon(Icons.refresh, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'الكل';
                        selectedBrand = null;
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

          // 🔲 المنتجات
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? const Center(child: Text('لا توجد منتجات'))
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
