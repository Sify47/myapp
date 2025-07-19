import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/models/product.dart';
import '../widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSearchQuery({
    required String userId,
    required String query,
  }) async {
    try {
      final userHistoryRef = _firestore
          .collection('users_search_history')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userHistoryRef);
        
        if (doc.exists) {
          final currentQueries = List<String>.from(doc.data()?['searches'] ?? []);
          currentQueries.remove(query);
          currentQueries.insert(0, query);
          
          transaction.update(userHistoryRef, {
            'searches': currentQueries.take(5).toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(userHistoryRef, {
            'userId': userId,
            'searches': [query],
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating search history: $e');
    }
  }

  Future<List<String>> getSearchHistory(String userId) async {
    try {
      final doc = await _firestore
          .collection('users_search_history')
          .doc(userId)
          .get();

      if (doc.exists) {
        return List<String>.from(doc.data()?['searches'] ?? []).take(5).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting search history: $e');
      return [];
    }
  }
}

class SearchPage extends StatefulWidget {
  final String userId;

  const SearchPage({required this.userId, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchHistoryService _historyService = SearchHistoryService();
  
  List<Product> _searchResults = [];
  List<String> _searchQueries = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchTextChanged);
  }

  Future<void> _loadSearchHistory() async {
    try {
      final queries = await _historyService.getSearchHistory(widget.userId);
      if (mounted) {
        setState(() => _searchQueries = queries);
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  void _onSearchTextChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else if (mounted) {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    if (mounted) {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });
    }

    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('tags', arrayContains: query)
          // .where('name', isEqualTo: query)
          .limit(20)
          .get();

      final results = productsSnapshot.docs.map((doc) {
        return Product.fromFirestore(doc);
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }

      await _historyService.addSearchQuery(
        userId: widget.userId,
        query: query,
      );

      if (!_searchQueries.contains(query)) {
        if (mounted) {
          setState(() {
            _searchQueries.insert(0, query);
            if (_searchQueries.length > 5) _searchQueries.removeLast();
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'حدث خطأ أثناء البحث: ${e.toString()}';
        });
      }
    }
  }

  Widget _buildSearchHistory() {
    if (_searchQueries.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آخر عمليات البحث',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchQueries.map((query) => Chip(
              label: Text(query),
              onDeleted: () => _removeFromHistory(query),
              deleteIcon: const Icon(Icons.close, size: 18),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromHistory(String query) async {
    try {
      final userHistoryRef = FirebaseFirestore.instance
          .collection('users_search_history')
          .doc(widget.userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(userHistoryRef);
        if (doc.exists) {
          final currentQueries = List<String>.from(doc.data()?['searches'] ?? []);
          currentQueries.remove(query);
          
          transaction.update(userHistoryRef, {
            'searches': currentQueries,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      if (mounted) {
        setState(() => _searchQueries.remove(query));
      }
    } catch (e) {
      debugPrint('Error removing from history: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر حذف البحث من السجل';
        });
      }
    }
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'اكتب كلمة البحث للبدء',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.90,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
          product: product,
          cardHeight: 160,
          // onTap: () {
          //   // التنقل لصفحة تفاصيل المنتج
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => ProductDetailsPage(product: product),
          //     ),
          //   );
          // },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'ابحث عن منتجات...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : const Icon(Icons.search),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_searchController.text.isEmpty) 
            _buildSearchHistory(),
          Expanded(
            child: _searchController.text.isEmpty
                ? const Center(
                    child: Text(
                      'استخدم شريط البحث للعثور على المنتجات',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}