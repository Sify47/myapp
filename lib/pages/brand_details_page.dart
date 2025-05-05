import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'offer_details_page.dart';
import 'package:url_launcher/url_launcher.dart';


class BrandDetailsPage extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String facebook;
  final String x;
  final String website;
  final String insta;

  const BrandDetailsPage({super.key, required this.name, required this.imageUrl , required this.facebook , required this.insta , required this.website , required this.x});

  List<Map<String, String>> getOffers(String brandName) {
    switch (brandName.toLowerCase()) {
      case 'nike':
        return [
          {
            'title': 'خصم يصل إلى 40% على كل الكوليكشن',
            'image': 'https://zouton.com/images/originals/blog/BANNER8_1594124351.png',
            'category': 'رياضي',
            'expiry': '2025/7/1',
            'offerCode': 'NIKE40'
          },
          {
            'title': 'اشترِ 2 واحصل على 1 مجانًا',
            'image': 'https://cop.deals/wp-content/uploads/2018/06/Nike20SUMMER.jpg',
            'category': 'رياضي',
            'expiry': '2025/8/1',
            'offerCode': 'BUY2GET1'
          },
        ];
      case 'adidas':
        return [
          {
            'title': '8% كاش باك',
            'image': 'https://deals.hidubai.com/wp-content/uploads/2020/04/09144212/DEALS-IMAGE-701.jpg',
            'category': 'رياضي',
            'expiry': '2025/7/1',
            'offerCode': 'SAVE20'
          },
          {
            'title': 'توصيل مجاني لأول طلب',
            'image': 'https://mir-s3-cdn-cf.behance.net/project_modules/max_3840/60f759108318811.5fbb80d2bab5b.jpg',
            'category': 'عروض عامة',
            'expiry': '2025/6/30',
            'offerCode': 'FREESHIP'
          },
        ];
      default:
        return [
          {
            'title': 'عرض عام - خصم 20%',
            'image': 'https://via.placeholder.com/300x150?text=Default+1',
            'category': 'عام',
            'expiry': '2025/12/31',
            'offerCode': 'DEFAULT20'
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = getOffers(name);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Hero(
              tag: name,
              child: imageUrl.endsWith('.svg')
                  ? SvgPicture.network(imageUrl, height: 120)
                  : Image.network(imageUrl, height: 120, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    
      IconButton(
        icon: Icon(Icons.facebook, color: Colors.blue),
        onPressed: () => launchUrl(Uri.parse(facebook)),
      ),
    
      IconButton(
        icon: Icon(Icons.camera_alt, color: Colors.purple),
        onPressed: () => launchUrl(Uri.parse(insta)),
      ),
    
      IconButton(
        icon: Icon(Icons.alternate_email, color: Colors.lightBlue),
        onPressed: () => launchUrl(Uri.parse(x)),
      ),
    
      IconButton(
        icon: Icon(Icons.language),
        onPressed: () => launchUrl(Uri.parse(website)),
      ),
  ],
),

          const SizedBox(height: 24),
          const Text(
            'العروض المتاحة:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...offers.map((offer) => AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OfferDetailsPage(
                          title: offer['title']!,
                          imageUrl: offer['image']!,
                          description: offer['title']!,
                          category: offer['category'] ?? 'عام',
                          expiry: offer['expiry'] ?? 'غير محدد',
                          offerCode: offer['offerCode'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          offer['image']!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(offer['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            if (offer['category'] != null)
                              Text('الفئة: ${offer['category']!}', style: const TextStyle(color: Colors.grey)),
                            if (offer['expiry'] != null)
                              Text('ينتهي في: ${offer['expiry']!}', style: const TextStyle(color: Colors.grey)),
                            if (offer['offerCode'] != null && offer['offerCode']!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('كود العرض: ${offer['offerCode']!}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
