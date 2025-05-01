import 'package:flutter/material.dart';
import 'brand_details_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
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

  Widget _buildBrandTile(Map<String, String> brand) {
    return GestureDetector(
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
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[200],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: brand['name']!,
              child: brand['image']!.endsWith('.svg')
                  ? SvgPicture.network(
                      brand['image']!,
                      height: 90,
                      width: 90,
                      placeholderBuilder: (context) =>
                          const CircularProgressIndicator(),
                    )
                  : brand['image']!.startsWith('http')
                      ? Image.network(
                          brand['image']!,
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          brand['image']!,
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain,
                        ),
            ),
            const SizedBox(height: 10),
            Text(
              brand['name']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن ماركة...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredBrands.length,
        itemBuilder: (context, index) {
          final brand = _filteredBrands[index];
          return _buildBrandTile(brand);
        },
      ),
    );
  }
}
