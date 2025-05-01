import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'offer_details_page.dart'; 
class BrandDetailsPage extends StatelessWidget {
  final String name;
  final String imageUrl;

  const BrandDetailsPage({super.key, required this.name, required this.imageUrl});

  List<Map<String, String>> getOffers(String brandName) {
    switch (brandName.toLowerCase()) {
      case 'nike':
        return [
          {'title': 'Up To 40% For All Collection', 'image': 'https://zouton.com/images/originals/blog/BANNER8_1594124351.png'},
          {'title': 'اشتر 2 واحصل على 1 مجاناً', 'image': 'https://cop.deals/wp-content/uploads/2018/06/Nike20SUMMER.jpg'},
        ];
      case 'adidas':
        return [
          {'brand': 'Adidas',
      'title': '8% Cash Back',
      // 'image': 'https://product-images.ibotta.com/admin/2020-04-23/0deb4a45f56feec3Ibotta_OfferCard_Adidas.png',
      'category': 'رياضي',
      'expiry' : '2025/7/1',
      'offerCode': "SAVE20", 'image': 'https://deals.hidubai.com/wp-content/uploads/2020/04/09144212/DEALS-IMAGE-701.jpg'},
          {'title': 'توصيل مجاني على كل الطلبات لاول طلب ليك', 'image': 'https://mir-s3-cdn-cf.behance.net/project_modules/max_3840/60f759108318811.5fbb80d2bab5b.jpg'},
        ];
      case 'puma':
        return [
          {'title': 'عرض نهاية الأسبوع - 50%', 'image': 'https://cdn.grabon.in/gograbon/images/web-images/uploads/1604657029705/puma-promo-code.jpg'},
          {'title': 'اشتر حذاء واحصل على جورب مجاني', 'image': 'https://myshoes.vn/image/cache/catalog/2022/banner/cata/giay-puma-chinh-hang-2280x1000.png'},
        ];
      case 'zara':
        return [
          {'title': 'Up To 70%', 'image': 'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg'},
          {'title': 'Up To 4o%', 'image': 'https://images.hotukdeals.com/threads/thread_large/default/3601744_1.jpg'},
        ];
      case 'samsung':
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
              
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfferDetailsPage(
                        title: offer['title']!,
                        imageUrl: offer['image']!,
                        description: offer['title']!,
                        category: offer['category']!,
                        expiry: offer['expiry']!,
                        offerCode: offer['offerCode']!,
                      ),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: offer['image']!.endsWith('.svg')
                            ? SvgPicture.network(
                                offer['image']!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                offer['image']!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
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
              ),
            
            )),
          ],
        ),
      ),
    );
  }
}