import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandDetailsPage extends StatelessWidget {
  final String name;
  final String imageUrl;

  const BrandDetailsPage({super.key, required this.name, required this.imageUrl});

  List<Map<String, String>> getOffers(String brandName) {
    switch (brandName.toLowerCase()) {
      case 'nike':
        return [
          {'title': 'خصم 30% على الجري', 'image': 'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg'},
          {'title': 'اشتر 2 واحصل على 1 مجاناً', 'image': 'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg'},
        ];
      case 'adidas':
        return [
          {'title': 'خصومات صيفية حتى 40%', 'image': 'https://via.placeholder.com/300x150?text=Adidas+1'},
          {'title': 'توصيل مجاني على كل الطلبات', 'image': 'https://via.placeholder.com/300x150?text=Adidas+2'},
        ];
      case 'puma':
        return [
          {'title': 'عرض نهاية الأسبوع - 25%', 'image': 'https://via.placeholder.com/300x150?text=Puma+1'},
          {'title': 'اشتر حذاء واحصل على جورب مجاني', 'image': 'https://via.placeholder.com/300x150?text=Puma+2'},
        ];
      default:
        return [
          {'title': 'عرض عام - خصومات حتى 20%', 'image': 'https://via.placeholder.com/300x150?text=Default+1'},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = getOffers(name);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: name,
              child: imageUrl.endsWith('.svg')
  ? SvgPicture.network(
      imageUrl,
      height: 150,
      placeholderBuilder: (context) => const CircularProgressIndicator(),
    )
  : imageUrl.startsWith('http')
    ? Image.network(
        imageUrl,
      height: 150,
        fit: BoxFit.contain,
      )
    : Image.asset(
        imageUrl,
      height: 150,
        fit: BoxFit.contain,
      )
,
              // child: Image.network(
              //   imageUrl,
              //   height: 150,
              //   // errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 100),
              // ),
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('العروض المتاحة:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...offers.map((offer) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      // child: Image.network(
                      //   offer['image']!,
                      //   height: 150,
                      //   width: double.infinity,
                      //   fit: BoxFit.cover,
                      // ),
                      child: offer['image']!.endsWith('.svg')
  ? SvgPicture.network(
      offer['image']!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
    )
  : offer['image']!.startsWith('http')
    ? Image.network(
        offer['image']!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
      )
    : Image.asset(
        offer['image']!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
      )
,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        offer['title']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    )
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}