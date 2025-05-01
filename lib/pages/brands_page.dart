import 'package:flutter/material.dart';
import 'brand_details_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandsPage extends StatelessWidget {
  const BrandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> brands = [
      {'name': 'Nike', 'image': 'assets/nike.png'},
      {'name': 'Nike', 'image': 'assets/nike.png'},
      {'name': 'Nike', 'image': 'assets/nike.png'},
      {'name': 'Nike', 'image': 'assets/nike.png'},
      {'name': 'Adidas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/2/20/Adidas_Logo.svg'},
      {'name': 'Puma', 'image': 'https://1000logos.net/wp-content/uploads/2017/05/PUMA-logo.jpg'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Row(mainAxisAlignment: MainAxisAlignment.center ,children: [Text('Brands')])),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BrandDetailsPage(name: brand['name']!, imageUrl: brand['image']!),
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
      placeholderBuilder: (context) => const CircularProgressIndicator(),
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
      )
,

                  ),
                  const SizedBox(height: 10),
                  Text(brand['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}