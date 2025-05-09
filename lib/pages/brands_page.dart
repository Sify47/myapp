import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'brand_details_page.dart';

class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allBrands = [];
  List<Map<String, dynamic>> _filteredBrands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
    _searchController.addListener(_filterBrands);
  }

  Future<void> _fetchBrands() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('brands').get();
      final brands = snapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        _allBrands = brands;
        _filteredBrands = brands;
        _isLoading = false;
      });
    } catch (e) {
      Exception("Error fetching brands: $e");
    }
  }

  void _filterBrands() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBrands = _allBrands.where((brand) {
        final name = (brand['name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  Widget _buildBrandTile(Map<String, dynamic> brand, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + index * 100),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BrandDetailsPage(
                  name: brand['name'] ?? '',
                  imageUrl: brand['image'] ?? '',
                  facebook: brand['facebook'] ?? '',
                  x: brand['x'] ?? '',
                  insta: brand['instagram'] ?? '',
                  website: brand['website'] ?? '',
                  dec: brand['dec'] ?? '',
                ),
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).cardColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(2, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: brand['name'] ?? '',
                    child: (brand['image'] ?? '').toString().endsWith('.svg')
                        ? SvgPicture.network(brand['image'] ?? '', height: 80, width: 80)
                        : Image.network(brand['image'] ?? '', height: 80, width: 80, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brand['name'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // child: Container(
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).cardColor,
            //     borderRadius: BorderRadius.circular(30),
            //     boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            //   ),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث عن عرض أو براند...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchController.text = value),
                  ),
                ),
            ),
          // ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredBrands.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) => _buildBrandTile(_filteredBrands[index], index),
            ),
    );
  }
}
