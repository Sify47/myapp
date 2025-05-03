import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'brand_details_page.dart';

class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _allBrands = [
    {'name': 'Zara', 'image': 'https://logos-world.net/wp-content/uploads/2020/05/Zara-Logo-1975-2008.png'},
    {'name': 'H&M', 'image': 'https://logos-world.net/wp-content/uploads/2020/04/HM-Logo.png'},
    {'name': 'New Balance', 'image': 'https://logos-world.net/wp-content/uploads/2020/09/New-Balance-Logo.png'},
    {'name': 'Nike', 'image': 'assets/nike.png'},
    {'name': 'Samsung', 'image': 'https://pngimg.com/uploads/samsung_logo/samsung_logo_PNG9.png'},
    {'name': 'Adidas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/2/20/Adidas_Logo.svg'},
    {'name': 'Puma', 'image': 'https://logodownload.org/wp-content/uploads/2014/07/puma-logo-0.png'},
  ];

  List<Map<String, String>> _filteredBrands = [];

  @override
  void initState() {
    super.initState();
    _filteredBrands = _allBrands;
    _searchController.addListener(_filterBrands);
  }

  void _filterBrands() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBrands = _allBrands.where((brand) {
        final name = brand['name']!.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBrandTile(Map<String, String> brand, int index) {
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
                  name: brand['name']!,
                  imageUrl: brand['image']!,
                ),
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: brand['name']!,
                    child: brand['image']!.endsWith('.svg')
                        ? SvgPicture.network(
                            brand['image']!,
                            height: 80,
                            width: 80,
                            placeholderBuilder: (_) => const CircularProgressIndicator(),
                          )
                        : brand['image']!.startsWith('http')
                            ? Image.network(
                                brand['image']!,
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                brand['image']!,
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brand['name']!,
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Brands'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 4,
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن البراند...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Theme.of(context).scaffoldBackgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredBrands.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return _buildBrandTile(_filteredBrands[index], index);
          },
        ),
      ),
    );
  }
}
